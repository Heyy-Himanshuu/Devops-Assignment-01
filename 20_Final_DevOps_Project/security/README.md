# security/

Configuration for every scanner the pipeline (`.github/workflows/s21-final.yml`) runs.
Each scanner is a separate job, and the **security gate** job refuses to let an image be pushed or
deployed unless all of them passed.

| Stage | Tool | Config | What fails the build |
| --- | --- | --- | --- |
| Lint | ruff | `application/backend/ruff.toml` | any lint error |
| SAST | Bandit 1.9 | `bandit.yaml` | a HIGH-severity finding |
| SCA | pip-audit 2.10 + `trivy fs` | `trivy.yaml` | a known CVE in a pinned Python / npm dependency (HIGH/CRITICAL, fix available) |
| Secret scan | Gitleaks 8.28 | `gitleaks.toml` | any secret pattern in the git history of `20_Final_DevOps_Project/` |
| Image scan | `trivy image` (backend + frontend) | `trivy.yaml`, `.trivyignore` | HIGH/CRITICAL CVE with a released fix in the OS or language packages |
| Gate | shell | — | any of the above `failure`/`cancelled`/`skipped` |

Kubernetes-side hardening lives in the chart: non-root UIDs (10001 backend, 101 frontend),
`allowPrivilegeEscalation: false`, all Linux capabilities dropped, a read-only root filesystem for the
API, a `RuntimeDefault` seccomp profile, and the database password only ever coming from a Secret that
is created out of band (`kubectl create secret generic spendboard-db ...`) - never from Git.
