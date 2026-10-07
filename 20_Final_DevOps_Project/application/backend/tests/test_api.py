from decimal import Decimal


def test_health_does_not_need_db(client):
    assert client.get("/health").json() == {"status": "UP"}


def test_ready_checks_database(client):
    assert client.get("/ready").json() == {"status": "READY"}


def test_root_reports_service(client):
    body = client.get("/").json()
    assert body["service"] == "SpendBoard API"


def test_create_and_get_expense(client):
    created = client.post(
        "/api/expenses",
        json={"title": "Electricity bill", "amount": "1999.99", "category": "UTILITIES", "spent_on": "2026-10-04"},
    )
    assert created.status_code == 201
    expense = created.json()
    assert Decimal(expense["amount"]) == Decimal("1999.99")
    assert expense["payment_method"] == "UPI"  # default
    fetched = client.get(f"/api/expenses/{expense['id']}")
    assert fetched.status_code == 200
    assert fetched.json()["title"] == "Electricity bill"


def test_validation_rejects_bad_input(client):
    assert client.post("/api/expenses", json={"title": "x", "amount": "-5", "spent_on": "2026-10-01"}).status_code == 422
    assert client.post("/api/expenses", json={"title": "x", "amount": "5", "category": "CRYPTO", "spent_on": "2026-10-01"}).status_code == 422
    assert client.get("/api/expenses?month=2026-13").status_code == 422


def test_list_filters_by_month_and_category(seeded):
    october = seeded.get("/api/expenses?month=2026-10").json()
    assert [e["title"] for e in october] == ["Dinner", "Metro card", "Groceries"]  # newest first
    food = seeded.get("/api/expenses?category=food").json()
    assert {e["title"] for e in food} == {"Groceries", "Dinner"}


def test_update_expense(seeded):
    first = seeded.get("/api/expenses").json()[0]
    resp = seeded.put(f"/api/expenses/{first['id']}", json={"amount": "900", "notes": "split with Rahul"})
    assert resp.status_code == 200
    assert Decimal(resp.json()["amount"]) == Decimal("900")
    assert resp.json()["notes"] == "split with Rahul"


def test_delete_expense_then_404(seeded):
    first = seeded.get("/api/expenses").json()[0]
    assert seeded.delete(f"/api/expenses/{first['id']}").status_code == 204
    assert seeded.get(f"/api/expenses/{first['id']}").status_code == 404
    assert seeded.delete(f"/api/expenses/{first['id']}").status_code == 404


def test_summary_totals_and_budget(seeded):
    s = seeded.get("/api/expenses/summary?month=2026-10").json()
    assert Decimal(s["total"]) == Decimal("2600.00")
    assert s["count"] == 3
    assert Decimal(s["budget_remaining"]) == Decimal("7400.00")  # MONTHLY_BUDGET=10000 from conftest
    assert s["by_category"][0] == {"category": "FOOD", "total": "2100.00", "count": 2}
    assert Decimal(s["by_payment_method"]["CARD"]) == Decimal("1349.50")


def test_metrics_endpoint_is_prometheus_text(seeded):
    seeded.get("/api/expenses")
    text = seeded.get("/metrics").text
    assert "http_requests_total" in text
    assert 'handler="/api/expenses"' in text
