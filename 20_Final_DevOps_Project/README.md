# Session 21 — Final DevOps Project: SpendBoard

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

**SpendBoard** is a small expense tracker: log what you spent, see the month against a budget, and
break it down by category and payment method. It is the vehicle for one end-to-end DevOps project that
uses everything from the course:

```text
Application → Git → GitHub → CI pipeline → Build & Test → Security scanning → Docker image
  → Container registry (GHCR) → Kubernetes → Helm → Monitoring → GitOps (Argo CD)
          + Terraform for the cloud infrastructure, + a troubleshooting challenge
```

The DevOps layer follows the course's TaskBoard reference (FastAPI + React + Postgres). The application
domain, code, chart and pipeline were written from scratch for this project, as the course's grading
policy requires. Five real bugs in the TaskBoard reference were found and fixed along the way (listed in
[Lessons learned](#14-lessons-learned)).

Everything shown was run for real on macOS (Apple Silicon): Docker Desktop 29.2, a 3-node `kind`
cluster (Kubernetes v1.35), GitHub Actions on the public repository, and LocalStack 4.9 standing in for
AWS. Every terminal screenshot is the real output of the command at its top. Browser screenshots are
headless-Chrome captures of the real UIs. Nothing is mocked.

---

## Contents

1. [Architecture](#1-architecture)
2. [Technologies](#2-technologies)
3. [Repository layout](#3-repository-layout)
4. [Application](#4-application)
5. [Docker](#5-docker)
6. [Terraform infrastructure](#6-terraform-infrastructure)
7. [Kubernetes deployment](#7-kubernetes-deployment)
8. [Helm](#8-helm)
9. [CI/CD pipeline](#9-cicd-pipeline)
10. [DevSecOps](#10-devsecops)
11. [Monitoring](#11-monitoring)
12. [GitOps — and the end-to-end demo](#12-gitops)
13. [Troubleshooting challenge](#13-troubleshooting-challenge)
14. [Lessons learned](#14-lessons-learned)

---

## 1. Architecture

```mermaid
flowchart TB
  dev["Developer<br/>git push"] --> gh["GitHub<br/>Heyy-Himanshuu/Devops-Assignment-01"]
  gh --> ci

  subgraph ci["GitHub Actions — s21-final.yml"]
    direction LR
    t["1. tests<br/>pytest · ruff · node --test · vite build"] --> s["2-4. SAST · SCA · secrets<br/>Bandit · pip-audit · Trivy fs · Gitleaks"]
    s --> b["5. buildx<br/>amd64 + arm64 OCI archive"] --> i["6. Trivy image scan"] --> g{"7. security<br/>gate"}
    g -->|open| p["8. push<br/>skopeo → GHCR :sha"] --> d["9. Helm deploy to kind<br/>helm test + smoke test"] --> bump["10. commit new tag<br/>to gitops/"]
  end

  p --> ghcr[("GHCR<br/>spendboard-backend<br/>spendboard-frontend")]
  bump --> gh
  argo["Argo CD<br/>(auto-sync + self-heal)"] -->|polls| gh
  argo -->|helm template + apply| k8s

  subgraph k8s["kind cluster devops-hw (1 control plane + 2 workers)"]
    ing["ingress-nginx"] -->|/| fe["frontend Deployment<br/>nginx-unprivileged ×2"]
    ing -->|/api| be["backend Deployment<br/>FastAPI ×2-5 (HPA)"]
    fe -->|/api proxy| be
    be --> pg[("Postgres<br/>PVC 1Gi")]
    cm["ConfigMap"] -.-> be
    sec["Secret<br/>(created out of band)"] -.-> be & pg
    prom["Prometheus<br/>ServiceMonitor + rules"] -->|/metrics| be
    graf["Grafana"] --> prom
  end
  ghcr -->|pull| k8s

  tf["Terraform"] --> aws["AWS (LocalStack)<br/>VPC · 2 public + 2 private subnets · NAT<br/>S3 backups bucket · IAM role · (EKS)"]
  pg -.->|pg_dump| aws
```

## 2. Technologies

| Layer | Used here |
| --- | --- |
| Application | Python 3.12, FastAPI 0.142, SQLAlchemy 2.1, Alembic 1.20, psycopg 3.3; React 19 + Vite 8; PostgreSQL 16 |
| Tests and quality | pytest 9 + pytest-cov (11 tests, 99% coverage), ruff 0.16, `node --test` |
| Containers | Docker (multi-stage builds, non-root, slim runtime images), Docker Compose, buildx (amd64 + arm64) |
| Registry | GitHub Container Registry (GHCR), images tagged with the short git SHA |
| Orchestration | Kubernetes 1.35 on `kind` 0.31, ingress-nginx 1.12, metrics-server |
| Packaging | Helm 4.1 (chart + `helm test`), a Helm "environment" chart for GitOps |
| IaC | Terraform 1.16, AWS provider 6.x, LocalStack 4.9 |
| CI/CD | GitHub Actions, `helm/kind-action`, skopeo |
| DevSecOps | Bandit, pip-audit, Trivy 0.67 (fs + image), Gitleaks 8.28, security-gate job |
| Monitoring | kube-prometheus-stack 92 (Prometheus 3, Grafana 13, Alertmanager), prometheus-fastapi-instrumentator |
| GitOps | Argo CD 3.5 (automated sync, prune, self-heal) |

## 3. Repository layout

```
20_Final_DevOps_Project/
├── application/
│   ├── backend/            FastAPI app, Alembic migration, pytest suite, ruff config
│   ├── frontend/           React + Vite UI, nginx.conf, node tests
│   ├── scripts/seed.sh     seeds a month of sample expenses through the API
│   └── screenshots/
├── docker/                 backend.Dockerfile, frontend.Dockerfile, docker-compose.yml
├── kubernetes/
│   ├── namespace.yaml      namespace (Pod Security "restricted" warnings on)
│   ├── load-images.sh      import local images into the kind nodes
│   └── troubleshooting/    the 6 broken/fixed scenarios + README
├── helm/spendboard/        the application chart (+ values-local.yaml, values-ci.yaml)
├── terraform/              VPC, subnets, NAT, S3 backups, IAM, optional EKS
├── security/               Bandit / Trivy / Gitleaks configs, first scan report
├── monitoring/             PrometheusRule, Grafana dashboard JSON, stack values
├── gitops/
│   ├── argocd/             the Argo CD Application
│   └── environments/local/ environment chart: pins the app chart + per-env values (tag bumped by CI)
├── cicd/screenshots/       pipeline evidence
└── README.md               this file

.github/workflows/s21-final.yml   ← the pipeline. It lives at the repo root because GitHub only
                                     runs workflows from <repo>/.github/workflows/.
```

---

## 4. Application

**Backend.** FastAPI with SQLAlchemy and Postgres. Alembic owns the schema
(`alembic/versions/0001_create_expenses.py`); the app never runs `create_all` at start-up.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` | liveness: process is up (does **not** touch the DB) |
| GET | `/ready` | readiness: runs a query; fails if the DB is unreachable |
| GET | `/metrics` | Prometheus metrics (request count, latency histogram per handler) |
| GET | `/api/config` | currency, monthly budget, environment, version (from the ConfigMap) |
| GET | `/api/expenses?month=YYYY-MM&category=` | list, newest first |
| POST | `/api/expenses` | create (validated: amount > 0, known category / payment method) |
| GET / PUT / DELETE | `/api/expenses/{id}` | read / partial update / delete |
| GET | `/api/expenses/summary?month=` | totals by category and payment method, budget remaining |

**Frontend.** React + Vite, served by nginx, which also proxies `/api/` to the backend Service. The
backend address is injected at container start (`BACKEND_URL`, through the nginx image's envsubst
templates), so one image works in Compose and in Kubernetes.

**Tests run before anything is built.** 11 pytest cases against a throwaway SQLite database (never the
real one), at 99% coverage, plus ruff lint and format checks:

![pytest](application/screenshots/01-pytest.png)
![ruff](application/screenshots/02-ruff.png)

Frontend unit tests (pure helpers) and the production build:

![frontend](application/screenshots/03-frontend-test-build.png)

---

## 5. Docker

| Image | Build | Runs as | Notes |
| --- | --- | --- | --- |
| [`backend.Dockerfile`](docker/backend.Dockerfile) | 2 stages: dependencies into a venv, then a slim runtime | UID 10001 | `apt-get upgrade` + Debian's `libpq5` (see [DevSecOps](#10-devsecops)); `HEALTHCHECK` on `/health` |
| [`frontend.Dockerfile`](docker/frontend.Dockerfile) | 2 stages: Node 22 builds the bundle **on the build platform** (`--platform=$BUILDPLATFORM`), then `nginx-unprivileged` | UID 101, port 8080 | `apk upgrade` in the runtime stage |

[`docker-compose.yml`](docker/docker-compose.yml) runs the full stack with one command. A one-shot
`migrate` service runs `alembic upgrade head` once Postgres is healthy, and the backend only starts after
it **completed successfully**:

![compose build](docker/screenshots/01-compose-build.png)
![compose up](docker/screenshots/02-compose-up.png)

Seeding through the nginx proxy, then the monthly summary:

![seed](docker/screenshots/03-seed-and-api.png)

Health, readiness and metrics endpoints, and proof that neither container runs as root:

![nonroot](docker/screenshots/04-health-metrics-nonroot.png)

The UI on `http://localhost:3000`:

![ui](docker/screenshots/05-ui-localhost-3000.png)

---

## 6. Terraform infrastructure

> **The AWS API is emulated by LocalStack 4.9 (community).** Nothing ran in a real AWS account. EKS is
> a LocalStack Pro feature, so the EKS resources are written, validated and planned but not applied.
> See [`terraform/README.md`](terraform/README.md) for the file-by-file breakdown and diagram.

Resources: a VPC with **two public and two private subnets** across two AZs, an IGW, a NAT gateway +
EIP, route tables, a node security group, an S3 bucket for database backups (versioned, AES256,
public access blocked, 30-day lifecycle on `pg_dump/`), and a least-privilege IAM role that can only
write under `pg_dump/`. 22 resources in all.

`init` → `fmt` / `validate` → `plan`:

![init](terraform/screenshots/01-init.png)
![validate](terraform/screenshots/02-fmt-validate.png)
![plan](terraform/screenshots/03-plan.png)

`apply` and its outputs:

![apply](terraform/screenshots/04-apply.png)

Checked independently with the AWS CLI rather than trusting Terraform's own view: the 4 subnets with
their CIDRs, AZs and public-IP setting, the NAT gateway, bucket versioning and encryption:

![verify](terraform/screenshots/05-verify-with-aws-cli.png)

The bucket put to real use. A `pg_dump` of the **live Kubernetes database** was streamed into it and
read back:

![backup](terraform/screenshots/06-pg-dump-to-bucket.png)

The EKS part, planned with `-var enable_eks=true` (control plane, node group and 5 IAM resources):

![eks plan](terraform/screenshots/07-plan-with-eks.png)

**LocalStack quirk found and handled.** Straight after the first apply, `plan` showed drift on
the bucket's `tags_all`. AWS provider 6.x sends tags inside `CreateBucket`, and LocalStack ignores
them there. That pending update also made the IAM policy document "known after apply". A second
`apply` converged, and `plan -detailed-exitcode` then returned 0 (no changes):

![drift](terraform/screenshots/08-localstack-tag-drift.png)

State and outputs, then `destroy`. The AWS CLI confirms nothing is left: 0 VPCs, 0 buckets, empty state:

![state](terraform/screenshots/09-state-and-output.png)
![destroy](terraform/screenshots/10-destroy.png)

---

## 7. Kubernetes deployment

Everything is deployed by the Helm chart (next section). This section is the Kubernetes view of the
result on the local `kind` cluster, namespace `s21-spendboard`.

Images are built locally and imported straight into each node's containerd
([`load-images.sh`](kubernetes/load-images.sh)). Pulling from Docker Hub on the nodes had hit the
anonymous rate limit earlier in the course:

![load](kubernetes/screenshots/01-load-images.png)

**Secret, created out of band.** The database password is generated on the spot and never appears in
Git, Helm values, or the rendered manifests (verified below):

![secret](kubernetes/screenshots/02-namespace-secret.png)

**Ingress** routes `/` to the frontend and `/api` straight to the backend Service:

![ingress](kubernetes/screenshots/03-ingress-routing.png)
![ui via ingress](kubernetes/screenshots/04-ui-through-ingress.png)

**ConfigMap and Secret injection.** The non-secret settings come from the ConfigMap. `DATABASE_URL`
is assembled from them plus the Secret with Kubernetes `$(VAR)` expansion. `helm get manifest` contains
only a `secretKeyRef`, never the value:

![config](kubernetes/screenshots/05-config-and-secret.png)

**Probes and migration.** An init container runs `alembic upgrade head` before uvicorn starts, retrying
until Postgres accepts connections. Concurrent Pods are serialised by a Postgres **advisory lock** in
`alembic/env.py`. The probes: startup (`/health`, up to 60 s), readiness (`/ready`, checks the DB) and
liveness (`/health`, does not check the DB, so a database blip never restarts the API):

![probes](kubernetes/screenshots/06-probes-initcontainer.png)

**Storage.** Postgres data lives on a PVC (`local-path`). Deleting the Pod keeps the data: the new Pod
still holds all 7 expenses:

![pvc](kubernetes/screenshots/07-pvc-survives-pod-delete.png)

**HPA.** An in-cluster load generator pushed the backend to ~445% of its CPU request. The HPA went
2 → 4 → 5 in about 15 seconds:

![hpa](kubernetes/screenshots/08-hpa-scale-out.png)

---

## 8. Helm

[`helm/spendboard`](helm/spendboard) contains a Deployment, Service, ConfigMap, Ingress and HPA, the
Postgres Deployment, PVC and Service, an optional ServiceMonitor, and a `helm test` smoke-test Pod.
Hardening applied to every app Pod: `runAsNonRoot`, fixed UIDs, `allowPrivilegeEscalation: false`,
`capabilities: drop [ALL]`, `seccompProfile: RuntimeDefault`, and a read-only root filesystem for the
API. The `checksum/config` annotation restarts the backend when the ConfigMap changes. `image.tag` is
`required`, so it is impossible to deploy `latest` by accident. Postgres' PVC carries
`helm.sh/resource-policy: keep`, so `helm uninstall` cannot delete the data.

| Values file | Used by |
| --- | --- |
| `values.yaml` | defaults (GHCR images, HPA 2-5 @ 70% CPU, Ingress `spendboard.local`) |
| `values-local.yaml` | local kind: locally imported images, `pullPolicy: Never`, ServiceMonitor on |
| `values-ci.yaml` | the ephemeral cluster inside GitHub Actions (no ingress controller, no Prometheus) |
| `../../gitops/environments/local/values.yaml` | what Argo CD deploys; the tag is written by CI |

Install:

![install](helm/screenshots/01-helm-install.png)

Right after `--wait` returned, the backend had 1 Pod. With the HPA enabled the chart deliberately
omits `spec.replicas` (otherwise every `helm upgrade` would fight the autoscaler), so the Deployment
starts at 1 and the HPA raises it to `minReplicas` 2 within seconds:

![after install](helm/screenshots/02-resources-right-after-install.png)
![steady](helm/screenshots/03-resources-steady.png)

`helm test` runs the in-cluster smoke test: backend `/ready`, the summary through the **frontend's**
nginx proxy, and that the SPA is served:

![helm test](helm/screenshots/04-helm-test.png)

`helm upgrade`, `history` and `rollback` are exercised for real in troubleshooting issues 1, 2 and 4
(revisions 3 → 8 of this release; it ended on revision 8, `deployed`).

---

## 9. CI/CD pipeline

[`.github/workflows/s21-final.yml`](../.github/workflows/s21-final.yml) runs on every push to `main`
that touches this project (docs, screenshots and `gitops/` excluded), and on pull requests and manual
dispatch.

| # | Job | What it does |
| --- | --- | --- |
| 1a | Backend | `ruff check` + `ruff format --check`, `pytest` with coverage, JUnit report artifact |
| 1b | Frontend | `npm ci`, `node --test`, `vite build`, `dist/` artifact |
| 2 | SAST | Bandit; full report, fails on HIGH |
| 3 | SCA | pip-audit (PyPI/OSV advisories) + `trivy fs` on `requirements.txt` and `package-lock.json` |
| 4 | Secret scan | Gitleaks over the **whole git history** of this folder |
| 5 | Docker build (matrix) | buildx, `linux/amd64` + `linux/arm64`, into an **OCI archive**: the exact bytes that are scanned and pushed |
| 6 | Image scan (matrix) | Trivy on both platforms of both images; fails on fixable HIGH/CRITICAL |
| 7 | Security gate | writes a table to the job summary; fails if any earlier job failed, was cancelled or was skipped |
| 8 | Push | `skopeo copy --all` the scanned archives to GHCR as `:<sha7>` and `:latest` |
| 9 | Deploy | ephemeral `kind` cluster, metrics-server, Secret + pull secret created in the job, `helm upgrade --install --wait` pinned to `:<sha7>`, `helm test`, end-to-end POST + summary through the frontend |
| 10 | GitOps | commits the new tag into `gitops/environments/local/values.yaml`. Argo CD takes it from there |

**Why multi-arch.** The runners are amd64 and the kind nodes on this Mac are arm64. The image Argo
CD pulls must be the same one CI scanned, so CI builds both architectures once and scans both.

Runs of this workflow (all on the public repo, so they open without signing in):

| Run | Commit | Result |
| --- | --- | --- |
| [37655615327](https://github.com/Heyy-Himanshuu/Devops-Assignment-01/actions/runs/37655615327) | first version | ❌ image scan: wrong input format for Trivy (below) |
| [37656869719](https://github.com/Heyy-Himanshuu/Devops-Assignment-01/actions/runs/37656869719) | `a1c45ef` fix | ✅ all 13 jobs, promoted `a1c45ef` |
| [37658514208](https://github.com/Heyy-Himanshuu/Devops-Assignment-01/actions/runs/37658514208) | `a40fdb0` SpendBoard 1.1.0 | ✅ the end-to-end demo in [§12](#12-gitops) |

![run list](cicd/screenshots/01-run-list.png)
![green run jobs](cicd/screenshots/02-green-run-jobs.png)
![green run](cicd/screenshots/09-actions-green-run.png)

**The first run failed, and it was a real mistake.** `trivy image --input` accepts a docker-save
tarball or an OCI **layout directory**, not an OCI archive tarball. The gate held: nothing was pushed or
deployed. The fix unpacks the archive before scanning (`a1c45ef`):

![failed run](cicd/screenshots/03-first-run-image-scan-failed.png)
![failed run web](cicd/screenshots/10-actions-failed-run.png)

Evidence from inside the green run. Tests:

![ci tests](cicd/screenshots/04-tests-in-ci.png)

Both platforms of both images scanned clean (0 fixable HIGH/CRITICAL):

![ci scan](cicd/screenshots/05-image-scan-in-ci.png)

Gate open, and pushed with both architectures. The two `unknown` entries in each index are buildx's
SBOM/provenance attestation manifests, not images:

![ci gate push](cicd/screenshots/06-gate-push-in-ci.png)

Deployed to the ephemeral cluster, `helm test` passed, the end-to-end smoke test passed, and the running
image is the SHA tag:

![ci deploy](cicd/screenshots/07-deploy-smoke-in-ci.png)

The tag promoted into `gitops/` by the pipeline itself:

![ci gitops](cicd/screenshots/08-gitops-bump-in-ci.png)

The published package. Public, multi-arch (`OS / Arch 3`), tagged `a1c45ef` + `latest`:

![ghcr](cicd/screenshots/11-ghcr-backend-package.png)

---

## 10. DevSecOps

Scanner configs and the gate rules are in [`security/`](security/README.md). Every scanner runs on every
push, and the security gate decides whether anything gets pushed.

**The first local image scan failed, with real findings:**

![before](security/screenshots/01-image-scan-before-FAIL.png)

(The full 300-line report is in [`security/trivy-first-scan-full.txt`](security/trivy-first-scan-full.txt).)

- **Backend: 8 HIGH/CRITICAL, all in `pcre2` version `10.32-3.el8_6`.** That is a RHEL 8 version
  string inside a Debian image. The library was not Debian's (Debian's own `libpcre2` was already the
  patched `10.46-1~deb13u3`). It was a copy **vendored inside the `psycopg[binary]` wheel**
  (`site-packages/psycopg_binary.libs/libpcre2-8-….so`), built on a manylinux/AlmaLinux 8 image.
  `apt-get upgrade` can never patch a library that dpkg doesn't know about.
  **Fix:** depend on plain `psycopg` and install `libpq5` from Debian, so the OS package manager owns
  every native library.
- **Frontend: 42 HIGH** in Alpine packages (`openssl`, `curl`, `pcre2`, `libxml2`, `expat`, …), each with
  a fixed version already in the Alpine repos. The upstream `nginx-unprivileged` image simply lags
  behind. **Fix:** `apk upgrade --no-cache` in the runtime stage, then drop back to UID 101.

After the fixes, both images scan clean with exit code 0. `psycopg_binary` is gone, and `libpq5` comes
from Debian:

![after](security/screenshots/02-image-scan-after-PASS.png)

What the clean result means: Trivy inspected the OS package database (dpkg/apk) **and** every Python and
npm package in the image, and found no HIGH or CRITICAL vulnerability **that has a released fix**.
Unfixable CVEs are reported but don't fail the build, because nothing can be done about them yet
(`ignore-unfixed`). Rebuilding regularly picks up new fixes.

Other controls: Bandit (no HIGH findings), pip-audit and `trivy fs` (0 known-vulnerable pinned
dependencies), Gitleaks (no secrets in history; the only password in Compose is an explicit
`local-dev-only` default that can be overridden), and the Kubernetes Pod hardening listed in
[§8](#8-helm). The namespace has the Pod Security `restricted` profile in **warn** mode. The only
warning is for Postgres, whose entrypoint has to `chown` the data directory as root on first boot.

---

## 11. Monitoring

The shared `kube-prometheus-stack` release on the cluster (installed in Session 20;
[values](monitoring/kube-prometheus-stack-values.yaml)) discovers the chart's **ServiceMonitor**
automatically. The backend exposes request and latency metrics through
`prometheus-fastapi-instrumentator`.

The raw `/metrics` output:

![metrics](monitoring/screenshots/01-backend-metrics-endpoint.png)

PromQL under live traffic: targets up, request rate by handler and status (the 4xx rows are deliberate
bad requests in the traffic mix), p95 latency, and CPU by Pod:

![promql](monitoring/screenshots/02-promql.png)

All backend Pods `UP` in Prometheus (5 at this point, because the traffic had scaled the HPA out again):

![targets](monitoring/screenshots/03-prometheus-targets.png)

The Grafana dashboard ([JSON](monitoring/grafana-dashboard-spendboard.json)) with live panels:
req/s, error ratio, p95, ready Pods, requests by handler, latency percentiles, CPU and memory per Pod:

![grafana](monitoring/screenshots/04-grafana-dashboard.png)

**Alerts** ([`prometheus-rules.yaml`](monitoring/prometheus-rules.yaml)): backend down, 4xx ratio above
25% for 2 minutes, and p95 latency above 500 ms. The traffic mix was 40% bad requests, so
`SpendBoardHighClientErrorRate` actually fired:

![alert](monitoring/screenshots/05-alert-firing.png)
![alerts ui](monitoring/screenshots/06-prometheus-alerts.png)

---

## 12. GitOps

Argo CD (3.5, namespace `argocd`) watches
[`gitops/environments/local`](gitops/environments/local) on `main` of this public repo and keeps
namespace `s21-gitops` identical to it, with `automated` sync, `prune` and `selfHeal`. How it is laid
out, and why it uses an environment chart, is in [`gitops/README.md`](gitops/README.md). The images it
runs come from GHCR at whatever SHA tag the pipeline last promoted.

**Bootstrap.** The only manual steps: the namespace, the DB Secret (deliberately not in Git), and the
Application itself:

![bootstrap](gitops/screenshots/01-bootstrap.png)

Argo CD rendered the environment chart from Git commit `43199f5` (the pipeline's own promotion commit)
and pulled `:a1c45ef` from GHCR. The app is `Synced` / `Healthy`:

![synced](gitops/screenshots/02-synced-healthy.png)

**Self-heal.** A manual `kubectl scale` (drift) was reverted to Git's value about a second later:

![self heal](gitops/screenshots/03-self-heal.png)

### The end-to-end demo: commit → pipeline → deployment updates

This is the grading rubric's "live demo", recorded. One commit changed application code: version
1.1.0 is now exposed by `/api/config` and shown in the UI header.

| Time (UTC) | What happened | Who |
| --- | --- | --- |
| 17:22:01 | `a40fdb0` pushed to `main` | me |
| 17:22:09 | [run 37658514208](https://github.com/Heyy-Himanshuu/Devops-Assignment-01/actions/runs/37658514208) starts: tests → scans → multi-arch build → image scan → gate → GHCR → kind deploy + smoke test | GitHub Actions |
| 17:30:51 | `0849553 gitops: promote spendboard to a40fdb0` committed to `gitops/` | the pipeline's job 10 |
| 17:31:56 | Argo CD sync #1 to `0849553`, rolling update to `:a40fdb0` | Argo CD |

**About 10 minutes from `git push` to the new version serving users, with no manual step in between.**

![code to cluster](gitops/screenshots/04-code-to-cluster.png)

The new version through the GitOps environment's Ingress (`spendboard-gitops.local`), with the `v1.1.0`
badge in the header:

![v1.1.0](gitops/screenshots/05-ui-v110-via-gitops.png)

**A config-only change through Git.** `monthlyBudget: "25000"` → `"30000"` in
`gitops/environments/local/values.yaml` (commit `d840328`). No image is built (the workflow ignores
`gitops/**`). Argo CD re-rendered the ConfigMap, and the chart's `checksum/config` annotation rolled the
backend so the new value took effect:

![config change](gitops/screenshots/06-config-change-synced.png)

---

## 13. Troubleshooting challenge

Six faults were introduced on purpose and taken through identify → investigate → root cause → fix →
verify. The full write-up with 20 screenshots is in
**[`kubernetes/troubleshooting/README.md`](kubernetes/troubleshooting/README.md)**.

| # | Fault | Symptom | Root cause → fix |
| --- | --- | --- | --- |
| 1 | non-existent image tag | `ImagePullBackOff`, upgrade failed | tag never built → `helm rollback` |
| 2 | hand-edited Service selector | Ingress 503 on `/api` | empty EndpointSlice → re-apply chart; **Helm 4's server-side apply refused** until `--force-conflicts` |
| 3 | DB password changed only in the Secret | `Init:0/1`, rollout stuck | Postgres keeps the password from first init → `ALTER ROLE` to match |
| 4 | readiness probe on `/readyz` | Pod `0/1`, rollout stuck | 404 → `helm rollback` |
| 5 | HPA targeting a missing Deployment | `<unknown>`, `FailedGetScale` | wrong `scaleTargetRef` → fixed name |
| 6 | the course chart's Ingress | 503 on `/api` | Service port 8080 vs 8000 → reference the port by name |

---

## 14. Lessons learned

1. **Images vendor things your OS doesn't know about.** The backend's CRITICAL CVEs were in a C
   library inside a Python wheel. `apt-get upgrade` would never have fixed them. Read *where* a scanner
   found a package, not just its name.
2. **Rolling updates plus readiness probes are the cheapest insurance there is.** Three of the six faults
   shipped broken Pods and users never saw an error, because the old ReplicaSet kept serving until a new
   Pod was Ready. The two outages were in routing (Service selector, Ingress port), where there is no
   readiness gate.
3. **"Re-run the deploy" doesn't remove drift, and Helm 4 may refuse to.** Server-side apply records who
   owns each field. A `kubectl patch` silently took ownership of the Service selector, so `helm upgrade`
   failed with a conflict. Argo CD's self-heal reverted the same kind of edit in about a second.
4. **A Secret is not the source of truth for a database password.** The database is. Rotation has to
   change both sides.
5. **Build once, scan what you ship.** Building to an OCI archive and pushing that exact archive means
   the scanned image *is* the deployed image. Multi-arch matters as soon as CI (amd64) and the cluster
   (arm64) differ.
6. **The reference project had real bugs, and each was only visible by running it:**
   - The Ingress pointed `/api` at a Service name and port that don't exist.
   - nginx proxied to a hostname `backend` that only exists in Compose.
   - The DB password sat in plaintext in `DATABASE_URL`, even though a Secret already existed.
   - The ServiceMonitor hardcoded `release: kube-prometheus-stack`, which matches nothing under any
     other release name.
   - The load-test script hit `/api/health`, which doesn't exist.
7. **Emulators have edges.** LocalStack ignores tags sent inside `CreateBucket` and doesn't emulate
   EKS. Verifying with a second tool (the AWS CLI) rather than Terraform's own state caught the first.

## Cleanup

```bash
helm uninstall spendboard -n s21-spendboard && kubectl delete ns s21-spendboard   # PVC is kept by policy; deleting the namespace removes it
kubectl delete -f gitops/argocd/spendboard-local.yaml && kubectl delete ns s21-gitops
docker compose -f docker/docker-compose.yml down -v
terraform -chdir=terraform destroy -auto-approve        # already done above
```
