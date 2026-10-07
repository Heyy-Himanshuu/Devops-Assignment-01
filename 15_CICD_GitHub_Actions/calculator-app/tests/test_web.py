import pytest

from app.web import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_index(client):
    r = client.get("/")
    assert r.status_code == 200
    assert b"Hello World" in r.data


def test_health(client):
    assert client.get("/health").get_json()["status"] == "ok"


def test_api_add(client):
    assert client.get("/api/add?a=2&b=3").get_json()["result"] == 5


def test_api_divide_by_zero_is_400(client):
    assert client.get("/api/divide?a=1&b=0").status_code == 400


def test_api_missing_args_is_400(client):
    assert client.get("/api/add?a=1").status_code == 400


def test_api_unknown_op_is_404(client):
    assert client.get("/api/sqrt?a=1&b=2").status_code == 404
