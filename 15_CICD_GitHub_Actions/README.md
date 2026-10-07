# Session 16 — CI/CD & GitHub Actions

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

A small calculator web app taken all the way through a real pipeline on GitHub Actions. Every push
runs **CI** (lint, a 3-version test matrix, a security check, a build that uploads artifacts). When CI
passes on `main`, a separate **CD** workflow publishes the Docker image to GitHub Container Registry and
deploys it to a Kubernetes cluster created on the runner, then smoke-tests it through the Service.

Every run linked below is a real run on this repository. The screenshots are either terminal captures
of `gh run view` / `gh api` output or browser captures of the public Actions pages. Nothing is mocked.
That includes the two failures: one was a genuine bug in my first version of the workflow, and the
other is the course's own "break `add()`" scenario.

Adapted from `session-16-github-actions/10-final-cicd-pipeline` in the course repo
[`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros).

---

## Labs

| # | Lab | What it demonstrates | Submission |
| --- | --- | --- | --- |
| 1 | **CI pipeline** | Workflow → jobs → steps on hosted runners: lint, a test matrix over Python 3.11–3.13, a basic security check, secrets, and a build that uploads 4 artifacts. | [`01-ci-pipeline/submission.md`](./01-ci-pipeline/submission.md) |
| 2 | **CD pipeline** | Triggered by CI success (`workflow_run`). Builds and pushes to GHCR with `GITHUB_TOKEN`, deploys to a kind cluster, rolls out and curls the Service. | [`02-cd-pipeline/submission.md`](./02-cd-pipeline/submission.md) |
| 3 | **Failure & fix** | A real workflow bug, then a deliberately broken `add()`. Shows that `needs:` stops the build and a failed CI never reaches CD. | [`03-failure-and-fix/submission.md`](./03-failure-and-fix/submission.md) |

**Workflows:** [`.github/workflows/s16-ci.yml`](../.github/workflows/s16-ci.yml) ·
[`.github/workflows/s16-cd.yml`](../.github/workflows/s16-cd.yml)
**Runs:** [Actions → S16 CI](https://github.com/Heyy-Himanshuu/Devops-Assignment-01/actions/workflows/s16-ci.yml) ·
[Actions → S16 CD](https://github.com/Heyy-Himanshuu/Devops-Assignment-01/actions/workflows/s16-cd.yml)
**Image:** [`ghcr.io/heyy-himanshuu/s16-calculator`](https://github.com/Heyy-Himanshuu/Devops-Assignment-01/pkgs/container/s16-calculator)

---

## Concepts, mapped to this project

### CI vs CD

| | Continuous Integration | Continuous Delivery / Deployment |
| --- | --- | --- |
| **Question it answers** | "Is this commit good?" | "Get the good commit running." |
| **Runs on** | every push and pull request | only after CI passed, only on `main` |
| **Here** | `s16-ci.yml`: lint, test, security check, build, artifacts | `s16-cd.yml`: image → registry → Kubernetes → smoke test |
| **Output** | a pass/fail verdict plus artifacts | a versioned image and a running deployment |

*Delivery* means every passing commit is ready to release and a person presses the button.
*Deployment* means the release itself is automatic. This project does continuous **deployment**
(CD starts by itself when CI succeeds). Adding a required reviewer to the `dev` environment that
the deploy job uses would turn it into continuous **delivery** without changing any YAML.

### CI/CD pipeline

```
 git push ──► S16 CI ─────────────────────────────────────────┐
              ├─ Lint (flake8)                     ┐           │ workflow_run
              ├─ Test (Python 3.11 / 3.12 / 3.13)  ├─► Build ──┤ (only if CI
              ├─ Basic security check              ┘   + artifacts   succeeded)
              └─ Using secrets                                  ▼
                                                    S16 CD
                                                    ├─ Build & push image to GHCR
                                                    └─► Deploy to Kubernetes (kind) ─► smoke test
```

### GitHub Actions vocabulary

| Term | Meaning | Where it is in this repo |
| --- | --- | --- |
| **Workflow** | A YAML file in `.github/workflows/` with triggers (`on:`) and jobs. | `s16-ci.yml`, `s16-cd.yml` |
| **Event / trigger** | What starts a run. | `push` with a `paths:` filter, `pull_request`, `workflow_dispatch` (manual button), `workflow_run` (CD waits for CI) |
| **Job** | A group of steps that runs on **one** runner. Jobs run in parallel unless `needs:` orders them. | `lint`, `test`, `security-check`, `secrets-demo` run in parallel; `build` has `needs: [lint, test, security-check]` |
| **Step** | One shell command (`run:`) or one reusable action (`uses:`) inside a job. Steps share the job's filesystem. | `actions/checkout@v5`, `run: pytest ...` |
| **Runner** | The VM that executes a job. `ubuntu-latest` is a fresh GitHub-hosted VM per job, thrown away afterwards. | Every job; the test job fans out to 3 runners through `strategy.matrix` |
| **Secrets** | Encrypted values injected at runtime and masked as `***` in logs. `GITHUB_TOKEN` is created automatically for every run and its scope is set by `permissions:`. | API call in `secrets-demo`, GHCR login and the Kubernetes pull secret in CD |
| **Artifacts** | Files uploaded from a job, downloadable from the run page for N days. They are how jobs and humans get build output. | `calculator-build` (the packaged app) plus 3 × `test-report-py3.x` (JUnit XML) |
| **Build** | Turning source into something deployable. | `build.sh` → `build/`, plus `docker build` |
| **Test** | Automated checks that decide pass or fail. | 11 pytest tests (5 unit, 6 HTTP) with coverage |
| **Pipeline execution** | Order, parallelism and gating at run time. | Run graphs in the screenshots; a failed test skips `build`, and a failed CI skips CD |

---

## Repository layout

```
15_CICD_GitHub_Actions/
├── README.md                  <- this index + concepts
├── calculator-app/            <- application source code
│   ├── app/calculator.py      <- pure logic (unit-tested)
│   ├── app/web.py             <- Flask HTTP API served by gunicorn
│   ├── tests/                 <- pytest suite
│   ├── build.sh               <- packages build/ (the CI artifact)
│   ├── Dockerfile             <- non-root gunicorn image
│   └── k8s/                   <- Deployment + Service used by CD
├── 01-ci-pipeline/            <- submission.md + screenshots/
├── 02-cd-pipeline/            <- submission.md + screenshots/
└── 03-failure-and-fix/        <- submission.md + screenshots/
.github/workflows/s16-ci.yml   <- CI workflow   (repo root, where GitHub reads workflows)
.github/workflows/s16-cd.yml   <- CD workflow
```
