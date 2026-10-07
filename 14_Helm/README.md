# Session 15 — Helm

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

Helm used as a package manager for Kubernetes. The labs cover every core CLI command, a complete install → upgrade → upgrade → rollback workflow verified with live traffic at every step, and the Notes App mini project. The run turned up three real bugs: one in the chart scaffolded by `helm create` and two in the course's mini-project chart. A fourth issue was in the ConfigMap pattern most charts use, where a *failed* upgrade could change what *healthy* Pods serve. Each one was diagnosed from the evidence and fixed.

Every command in every lab below was run against a live 3-node Kubernetes cluster (`kind`, Kubernetes v1.35.0) using **Helm v4.1.3** on macOS. Each screenshot is the real terminal output of the command shown directly above it. Nothing is mocked or transcribed from memory.

Labs are adapted from the course repo [`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros) (`session-15-helm`).

---

## Labs

| # | Lab | What it demonstrates | Submission |
| --- | --- | --- | --- |
| 1 | **Helm Commands** | `repo`, `search`, `create`, `lint`, `template`, `install`, `list`, `status`, `get`, `test`, `upgrade`, `history`, `rollback`, `uninstall`, each run for real. Includes recovering a failed release, and a `helm create` test hook whose untagged image makes every test run depend on the rate-limited registry. | [`01-helm-commands/submission.md`](./01-helm-commands/submission.md) |
| 2 | **Rollback Workflow** | Install → Upgrade → Verify → Upgrade → Verify → Rollback → Verify, proven with the nginx binary and page actually being served. Also automatic rollback (`--rollback-on-failure`), plus a bug where a shared ConfigMap leaks a failed release into healthy Pods, fixed with per-revision immutable ConfigMaps. | [`02-rollback-workflow/submission.md`](./02-rollback-workflow/submission.md) |
| 3 | **Mini Project — Notes App** | A chart with dev/prod values, lint, template, install, a prod upgrade, a bad upgrade and a rollback. Two course chart bugs were fixed: config-only upgrades never reached the Pods, and a hard-coded NodePort blocked a second release. | [`03-mini-project/submission.md`](./03-mini-project/submission.md) |

## Deliverables checklist

| Deliverable | Where |
| --- | --- |
| Helm chart | [`03-mini-project/notes-chart/`](./03-mini-project/notes-chart), [`02-rollback-workflow/versioned-web-fixed/`](./02-rollback-workflow/versioned-web-fixed), [`01-helm-commands/mychart/`](./01-helm-commands/mychart) |
| values.yaml | `notes-chart/values.yaml` + `values-prod.yaml`; `versioned-web` + `values-v2.yaml` / `values-v3.yaml` |
| Templates | `templates/` in each chart, including `_helpers.tpl` named templates in `versioned-web-fixed` |
| Installation | Lab 1 steps 9–12, Lab 2 step 2, Lab 3 step 4 |
| Upgrade | Lab 1 step 18, Lab 2 steps 4 and 6, Lab 3 step 6 |
| Rollback | Lab 1 step 20, Lab 2 steps 9–19, Lab 3 step 9 |
| Screenshots | `screenshots/` in each lab (61 terminal captures) |

---

## Repository layout

```
14_Helm/
├── README.md                    <- this index
├── 01-helm-commands/
│   ├── submission.md            <- commands, explanations and screenshots
│   ├── screenshots/
│   └── mychart/                 <- `helm create` scaffold (test hook image pinned)
├── 02-rollback-workflow/
│   ├── submission.md
│   ├── screenshots/
│   ├── versioned-web/           <- chart whose page shows the live release
│   ├── versioned-web-fixed/     <- same chart with per-revision immutable ConfigMaps
│   ├── values-v2.yaml, values-v3.yaml
│   └── verify.sh                <- helm view + deployment view + 4 real in-cluster requests
└── 03-mini-project/
    ├── submission.md
    ├── screenshots/
    ├── notes-chart/             <- the Notes App chart (0.1.1, fixed)
    ├── chart-fixes.diff         <- course chart 0.1.0 → 0.1.1
    └── show-pods.sh             <- per-Pod ENVIRONMENT and nginx version
```

## Note on image pulls

During this run Docker Hub rate-limited the kind nodes' anonymous pulls (`429 Too Many Requests`, Lab 1 step 11). The images were pulled once on the host and imported into each node's containerd:

```bash
docker pull nginx:1.25
for n in $(kind get nodes --name devops-hw); do
  docker save nginx:1.25 | docker exec -i $n ctr -n k8s.io images import -
done
```

That only works for images with a fixed tag. `:latest` forces `imagePullPolicy: Always`, so the node goes back to the registry anyway (Lab 1 step 16b).
