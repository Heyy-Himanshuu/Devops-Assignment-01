# calculator-app

Session 16 demo app: calculator logic (`app/calculator.py`) behind a small Flask API (`app/web.py`).
CI: [`s16-ci.yml`](../../.github/workflows/s16-ci.yml) · CD: [`s16-cd.yml`](../../.github/workflows/s16-cd.yml)

| Route | Example |
| --- | --- |
| `GET /` | `Hello World from the Session 16 CI/CD calculator (version <sha>)` |
| `GET /health` | `{"status": "ok", "version": "<sha>"}` |
| `GET /api/<add\|subtract\|multiply\|divide>?a=&b=` | `/api/multiply?a=6&b=7` → `{"result": 42.0, ...}` |

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
flake8 app tests && pytest -v --cov=app
./build.sh                                   # -> build/ (what CI uploads as an artifact)
docker build -t calculator . && docker run --rm -p 8000:8000 calculator
```
