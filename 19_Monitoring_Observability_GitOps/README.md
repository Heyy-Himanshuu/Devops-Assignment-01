# Session 20 — Monitoring, Observability & GitOps

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

This session covers seeing what a running system is doing and keeping it in the state Git describes. An in-cluster Prometheus/Grafana/Alertmanager stack watches a real app through metrics, logs, CPU, memory and health, with two alerts driven from healthy to firing and back to resolved. Distributed tracing is shown with OpenTelemetry and Jaeger. Argo CD reconciles the cluster against **this repository**, picking up a pushed change and reverting manual drift.

Every command in every lab was run against a live 3-node Kubernetes cluster (`kind`, Kubernetes v1.35.0) on macOS. Terminal screenshots are the real output of the command shown above them. UI screenshots are headless-Chrome captures of the real Prometheus, Alertmanager, Grafana, Jaeger and Argo CD UIs. Nothing is mocked.

Labs are adapted from the course repo [`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros) (`session20-monitoring-observability-gitops`).

---

## Labs

| # | Lab | What it demonstrates | Submission |
| --- | --- | --- | --- |
| 1 | **Monitoring** | kube-prometheus-stack on kind, with false-positive control-plane alerts traced to loopback-bound metrics and fixed. Then metrics (req/s, p95), CPU and memory utilisation, application health, logs (including those of a crashed container), and two alerts that fire, reach Alertmanager and resolve. Includes a custom Grafana dashboard and a label bug in my own alert rule, found and fixed. | [`01-monitoring/submission.md`](./01-monitoring/submission.md) |
| 2 | **Observability** | Monitoring vs observability, the three pillars, why they matter, tools, and observability on Kubernetes. Live **distributed tracing**: one request across two services in Jaeger, showing even connection reuse. | [`02-observability/README.md`](./02-observability/README.md) |
| 3 | **GitOps (mini project)** | Argo CD watching this repo: a Git push reaches the cluster in 21 s, and a manual scale and a deleted Service are self-healed. Two course bugs are fixed, an Application kept inside its own watched path and a cleanup that orphans the workload. Also covers GitOps concepts and the viva questions. | [`03-gitops/submission.md`](./03-gitops/submission.md) |

## Deliverables checklist

| Deliverable | Where |
| --- | --- |
| Monitoring demo | [`01-monitoring/`](./01-monitoring), with [`monitoring-values.yaml`](./01-monitoring/monitoring-values.yaml), [`manifests/`](./01-monitoring/manifests) (app, ServiceMonitor, PrometheusRule, load generator, Grafana dashboard) |
| Observability documentation | [`02-observability/README.md`](./02-observability/README.md) |
| GitOps demo | [`03-gitops/`](./03-gitops), with [`app/`](./03-gitops/app) (watched by Argo CD), [`argocd-application.yaml`](./03-gitops/argocd-application.yaml), [`argocd-values.yaml`](./03-gitops/argocd-values.yaml) |
| Screenshots | `screenshots/` in each lab: 24 + 6 + 13 |
| README.md | this file, plus one per lab |

---

## Repository layout

```
19_Monitoring_Observability_GitOps/
├── README.md                      <- this index
├── 01-monitoring/
│   ├── submission.md
│   ├── monitoring-values.yaml     <- kube-prometheus-stack values (kind fixes, Grafana anonymous viewer)
│   ├── promql.sh                  <- run a PromQL query from the terminal
│   ├── manifests/                 <- podinfo app + ServiceMonitor, alert rules, load generator, dashboard
│   └── screenshots/
├── 02-observability/
│   ├── README.md                  <- the documentation + tracing demo
│   ├── trace.sh                   <- print one trace's spans from Jaeger's API
│   ├── manifests/tracing.yaml     <- Jaeger + frontend/backend podinfo with OpenTelemetry
│   └── screenshots/
└── 03-gitops/
    ├── submission.md
    ├── app/                       <- desired state, watched by Argo CD on main
    ├── argocd-application.yaml    <- applied once, by hand; lives outside app/
    ├── argocd-values.yaml
    ├── wait-for-replicas.sh
    └── screenshots/
```

## What is still running

The `kps` monitoring stack (`monitoring` namespace) and Argo CD (`argocd` namespace, auth re-enabled) are left installed on the cluster, so the final project can use them. Every per-lab namespace (`s20-app`, `s20-tracing`, `s20-gitops`) was deleted.
