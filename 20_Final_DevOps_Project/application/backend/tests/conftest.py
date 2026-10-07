import os

# Point the app at a throwaway sqlite file BEFORE it is imported, so tests never touch Postgres.
os.environ["DATABASE_URL"] = "sqlite:///./test.db"
os.environ["MONTHLY_BUDGET"] = "10000"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.db import Base, engine  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture()
def client():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as c:
        yield c


@pytest.fixture()
def seeded(client):
    rows = [
        {"title": "Groceries", "amount": "1250.50", "category": "FOOD", "payment_method": "UPI", "spent_on": "2026-10-02"},
        {"title": "Metro card", "amount": "500", "category": "TRANSPORT", "payment_method": "CARD", "spent_on": "2026-10-03"},
        {"title": "Dinner", "amount": "849.50", "category": "FOOD", "payment_method": "CARD", "spent_on": "2026-10-05"},
        {"title": "September rent", "amount": "15000", "category": "RENT", "payment_method": "NETBANKING", "spent_on": "2026-09-01"},
    ]
    for r in rows:
        assert client.post("/api/expenses", json=r).status_code == 201
    return client
