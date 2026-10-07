# devsecops-app — DevSecOps Dashboard (Flask)

The course's Session 17 demo app, hardened (see [`../README.md`](../README.md) for what changed and why).
It is built, scanned, pushed and deployed by [`.github/workflows/s17-devsecops.yml`](../../.github/workflows/s17-devsecops.yml).

| Method | Route | Description |
| --- | --- | --- |
| `GET` | `/` | Dashboard UI |
| `GET` | `/health` | Health check (used by the readiness/liveness probes) |
| `GET` | `/api/status` | App info, uptime, Python version |
| `GET` | `/api/greet/<name>` | Greeting for a name |
| `POST` | `/api/add` | `{"number1": 1, "number2": 2}` |
| `POST` | `/api/calculate` | `{"a": 6, "b": 7, "operation": "multiply"}` (add/subtract/multiply/divide/power/modulo) |
| `POST` | `/api/pipeline/run` | Simulated CI/CD pipeline run |

## Run locally

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -v                       # 8 tests
FLASK_DEBUG=1 python app/app.py # dev server on 127.0.0.1:5001 (debug is opt-in)

docker build -t devsecops-app .
docker run --rm -p 5001:5001 devsecops-app   # gunicorn, uid 65534
```

## Run the security checks locally

```bash
bandit -c security/bandit.yaml -r app --severity-level high
pip-audit -r requirements.txt
docker run --rm -v "$PWD":/src -w /src aquasec/trivy:0.67.2 fs --config security/trivy.yaml .
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD":/src -w /src \
  aquasec/trivy:0.67.2 image --config security/trivy.yaml devsecops-app
docker run --rm -v "$(git rev-parse --show-toplevel)":/repo -w /repo zricethezav/gitleaks:v8.28.0 git \
  --config 16_DevSecOps/devsecops-app/security/gitleaks.toml \
  --gitleaks-ignore-path 16_DevSecOps/devsecops-app/security/.gitleaksignore \
  --log-opts="-- 16_DevSecOps/devsecops-app" --redact .
```
