from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

Category = Literal["FOOD", "TRANSPORT", "RENT", "UTILITIES", "SHOPPING", "ENTERTAINMENT", "HEALTH", "OTHER"]
PaymentMethod = Literal["UPI", "CARD", "CASH", "NETBANKING"]


class ExpenseCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    amount: Decimal = Field(gt=0, max_digits=12, decimal_places=2)
    category: Category = "OTHER"
    payment_method: PaymentMethod = "UPI"
    spent_on: date
    notes: str = ""


class ExpenseUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    amount: Decimal | None = Field(default=None, gt=0, max_digits=12, decimal_places=2)
    category: Category | None = None
    payment_method: PaymentMethod | None = None
    spent_on: date | None = None
    notes: str | None = None


class ExpenseOut(ExpenseCreate):
    id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)


class CategoryTotal(BaseModel):
    category: str
    total: Decimal
    count: int


class SummaryOut(BaseModel):
    month: str | None
    currency: str
    total: Decimal
    count: int
    budget: Decimal
    budget_remaining: Decimal
    by_category: list[CategoryTotal]
    by_payment_method: dict[str, Decimal]
