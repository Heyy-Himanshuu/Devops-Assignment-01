# Session 17 — Complete CI/CD & DevSecOps

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

The course's Flask "DevSecOps Dashboard" goes through a pipeline where security checks are
**gates**, not reports. Code is built and unit-tested, then scanned three ways in parallel: SAST,
SCA and secret scanning. It is packaged into an image, and the image itself is scanned. Only if every
check passes does a security gate open, the *same* image bytes get pushed to GHCR, and it is deployed
to Kubernetes and smoke-tested.

Every run linked below is a real run on this repository. Four of the six runs failed, and each
failure was something real:

- the course code ships a Flask debugger (remote code execution)
- my Trivy config silently ignored one of its keys
- the kubelet refused a non-root check
- a deliberately bad change (a vulnerable dependency plus a hardcoded key) was blocked

Adapted from `session-17-devsecops/demo` in the course repo
[`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros).

---

## Labs

| # | Lab | What it demonstrates | Submission |
| --- | --- | --- | --- |
| 1 | **The pipeline** | One fully green run, stage by stage: build → unit tests → SAST → SCA → secret scan → Docker build → image scan → security gate → push to GHCR → deploy to Kubernetes. | [`01-pipeline/submission.md`](./01-pipeline/submission.md) |
| 2 | **Security gates in action** | Four blocked runs, each diagnosed and fixed: Bandit B201, a Trivy config pitfall, `runAsNonRoot` vs a named user, and a PR-style change with a vulnerable dependency plus a leaked key. | [`02-security-gate/submission.md`](./02-security-gate/submission.md) |

**Workflow:** [`.github/workflows/s17-devsecops.yml`](../.github/workflows/s17-devsecops.yml) ·
**Runs:** [Actions → S17 DevSecOps pipeline](https://github.com/Heyy-Himanshuu/Devops-Assignment-01/actions/workflows/s17-devsecops.yml) ·
**Image:** [`ghcr.io/heyy-himanshuu/s17-devsecops-app`](https://github.com/Heyy-Himanshuu/Devops-Assignment-01/pkgs/container/s17-devsecops-app)

---

## Expected flow → how it is wired

```
Code
 ↓
1. Build ───────────── pip install + compileall + import check
 ↓
2. Unit Test ───────── pytest + coverage, JUnit artifact
 ↓
 ├─► 3. SAST ───────── Bandit            (gate: any HIGH severity)
 ├─► 4. SCA ────────── pip-audit + Trivy fs  (gate: any known vuln / HIGH+CRITICAL with a fix)
 └─► 5. Secret Scan ── Gitleaks over the app's full git history
 ↓        (6 needs all three)
6. Docker Build ────── image saved as an artifact (docker save)
 ↓
7. Container Image Scan ── Trivy on that exact tarball  (gate: HIGH+CRITICAL with a fix)
 ↓
8. Security Gate ───── if: always(); summarises 1–7, fails unless every one succeeded
 ↓
9. Push Image ──────── docker load the scanned tarball → push :<sha> and :latest to GHCR
 ↓
10. Deploy to Kubernetes ── kind on the runner, pull secret, apply, rollout status, curl
```

The three scanners only read the source, so they fan out in parallel after the tests instead of
running one after another. The result is the same, it finishes sooner, and one bad commit can trip
several gates in a single run (see run 5 in lab 2).

## Tools and their configuration

| Stage | Tool | Config file | What fails the job |
| --- | --- | --- | --- |
| SAST | [Bandit](https://bandit.readthedocs.io) 1.8.6 | [`security/bandit.yaml`](./devsecops-app/security/bandit.yaml) | any **HIGH**-severity finding (`--severity-level high`); a separate step prints every severity without failing |
| SCA | [pip-audit](https://pypi.org/project/pip-audit/) 2.9.0 | — (flags in workflow) | any known vulnerability in `requirements.txt`, including transitive dependencies |
| SCA | [Trivy](https://trivy.dev) 0.67.2 `fs` | [`security/trivy.yaml`](./devsecops-app/security/trivy.yaml), [`security/.trivyignore`](./devsecops-app/security/.trivyignore) | HIGH/CRITICAL with a released fix |
| Secret scanning | [Gitleaks](https://github.com/gitleaks/gitleaks) 8.28.0 | [`security/gitleaks.toml`](./devsecops-app/security/gitleaks.toml), [`security/.gitleaksignore`](./devsecops-app/security/.gitleaksignore) | any finding in any commit that touched the app (fingerprints of reviewed findings are ignored) |
| Image scanning | Trivy 0.67.2 `image` | same `trivy.yaml` | HIGH/CRITICAL with a released fix, in OS packages or Python packages |
| Security gate | plain bash over `needs.*.result` | — | any upstream job that is `failure`, `cancelled` or `skipped` |

Trivy and Gitleaks run from their official Docker images pinned to an exact version, not from
third-party wrapper actions. A floating action tag can be re-pointed by whoever controls it. A
pinned image runs code you already chose.

---

## What I changed from the course demo, and why

| Course version | Problem | This version |
| --- | --- | --- |
| `app.run(host="0.0.0.0", debug=True)` and `CMD ["python", "app/app.py"]` | The container serves the **Werkzeug debugger**, an interactive Python console, to anyone who can reach it. Bandit B201 is HIGH. | Debug is opt-in via `FLASK_DEBUG`, the dev server binds to localhost, and the image runs **gunicorn** |
| Runs as root | — | `USER 65534:65534` + `runAsNonRoot` / `allowPrivilegeEscalation: false` in the Deployment |
| `trivy image --severity HIGH,CRITICAL` | With no `--exit-code 1`, Trivy prints the table and **exits 0**, so the "gate" can never fail | `exit-code: 1` in `trivy.yaml` |
| Builds the image **three times** (build, scan, push jobs) | The image you scan is not, byte for byte, the image you push | Build once, `docker save` → artifact → scan that tarball → push that tarball |
| Pushes to a personal Docker Hub with a stored token | — | GHCR with the run's short-lived `GITHUB_TOKEN`, nothing stored |
| Deployment uses `imagePullPolicy: Always` against `:<sha>` and no probes | — | Readiness and liveness probes on `/health`, `rollout status` waited on, curl through the Service |
| CodeQL for SAST | CodeQL is a good tool, but it reports to the repository's Security tab and does not fail the job on findings unless extra steps are added | Bandit, a Python-specific SAST tool: findings print in the job log and gating on severity is a single flag |

---

## Repository layout

```
16_DevSecOps/
├── README.md                    <- this index
├── devsecops-app/               <- application (Flask) + Dockerfile + tests
│   ├── app/                     <- app.py, config.py, templates/, static/
│   ├── tests/test_app.py        <- 8 pytest tests
│   ├── Dockerfile               <- gunicorn, non-root (uid 65534)
│   ├── k8s/                     <- Deployment (probes, securityContext) + NodePort Service
│   └── security/                <- bandit.yaml, trivy.yaml, .trivyignore, gitleaks.toml, .gitleaksignore
├── 01-pipeline/                 <- submission.md + screenshots/
└── 02-security-gate/            <- submission.md + screenshots/
.github/workflows/s17-devsecops.yml
```
