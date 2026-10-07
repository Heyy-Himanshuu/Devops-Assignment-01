from decimal import Decimal

from fastapi import Depends, FastAPI, HTTPException, Query, status
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import extract, func, select
from sqlalchemy.orm import Session

from .config import settings
from .db import get_db
from .models import Expense
from .schemas import CategoryTotal, ExpenseCreate, ExpenseOut, ExpenseUpdate, SummaryOut

MONTH = Query(default=None, pattern=r"^\d{4}-(0[1-9]|1[0-2])$", description="YYYY-MM")


# The schema is owned by Alembic (`alembic upgrade head`), never by the app at startup:
# in Kubernetes an initContainer runs the migration before uvicorn starts.
app = FastAPI(title=settings.app_name, version=settings.app_version)
Instrumentator(excluded_handlers=["/metrics", "/health", "/ready"]).instrument(app).expose(app, endpoint="/metrics")


def _month_filter(stmt, month: str | None):
    if month:
        year, mon = (int(x) for x in month.split("-"))
        stmt = stmt.where(extract("year", Expense.spent_on) == year, extract("month", Expense.spent_on) == mon)
    return stmt


@app.get("/")
def root():
    return {"service": settings.app_name, "version": settings.app_version, "environment": settings.environment, "docs": "/docs"}


@app.get("/health")
def health():
    """Liveness: the process is up. Deliberately does not touch the database."""
    return {"status": "UP"}


@app.get("/ready")
def ready(db: Session = Depends(get_db)):
    """Readiness: only report READY when the database answers a query."""
    db.execute(select(func.count(Expense.id)))
    return {"status": "READY"}


@app.get("/api/config")
def public_config():
    return {"currency": settings.currency, "monthly_budget": settings.monthly_budget, "environment": settings.environment}


@app.get("/api/expenses", response_model=list[ExpenseOut])
def list_expenses(category: str | None = None, month: str | None = MONTH, db: Session = Depends(get_db)):
    stmt = select(Expense).order_by(Expense.spent_on.desc(), Expense.id.desc())
    if category:
        stmt = stmt.where(Expense.category == category.upper())
    return list(db.scalars(_month_filter(stmt, month)))


@app.get("/api/expenses/summary", response_model=SummaryOut)
def summary(month: str | None = MONTH, db: Session = Depends(get_db)):
    by_cat = db.execute(
        _month_filter(select(Expense.category, func.sum(Expense.amount), func.count(Expense.id)), month)
        .group_by(Expense.category)
        .order_by(func.sum(Expense.amount).desc())
    ).all()
    by_pay = db.execute(_month_filter(select(Expense.payment_method, func.sum(Expense.amount)), month).group_by(Expense.payment_method)).all()
    total = sum((Decimal(t) for _, t, _ in by_cat), Decimal("0"))
    budget = Decimal(str(settings.monthly_budget))
    return SummaryOut(
        month=month,
        currency=settings.currency,
        total=total,
        count=sum(c for _, _, c in by_cat),
        budget=budget,
        budget_remaining=budget - total,
        by_category=[CategoryTotal(category=c, total=Decimal(t), count=n) for c, t, n in by_cat],
        by_payment_method={m: Decimal(t) for m, t in by_pay},
    )


@app.get("/api/expenses/{expense_id}", response_model=ExpenseOut)
def get_expense(expense_id: int, db: Session = Depends(get_db)):
    expense = db.get(Expense, expense_id)
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    return expense


@app.post("/api/expenses", response_model=ExpenseOut, status_code=status.HTTP_201_CREATED)
def create_expense(payload: ExpenseCreate, db: Session = Depends(get_db)):
    expense = Expense(**payload.model_dump())
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


@app.put("/api/expenses/{expense_id}", response_model=ExpenseOut)
def update_expense(expense_id: int, payload: ExpenseUpdate, db: Session = Depends(get_db)):
    expense = db.get(Expense, expense_id)
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(expense, key, value)
    db.commit()
    db.refresh(expense)
    return expense


@app.delete("/api/expenses/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense(expense_id: int, db: Session = Depends(get_db)):
    expense = db.get(Expense, expense_id)
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    db.delete(expense)
    db.commit()
