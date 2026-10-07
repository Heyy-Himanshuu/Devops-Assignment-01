# Session 13 — Kubernetes Storage, HPA & Probes

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

Data that outlives its container, Pods that scale with load, and health checks that decide when a container gets restarted or gets traffic. Each one was run on a real cluster and pushed until it broke, so the docs below show where each mechanism stops working as well as where it works.

Every command in every lab below was run against a live 3-node Kubernetes cluster (`kind`, Kubernetes v1.35.0) on macOS. Each screenshot is the real terminal output of the command shown directly above it. Nothing is mocked or transcribed from memory.

Labs are adapted from the course repo [`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros) (`session-13-storage-hpa-probes`).

---

## Labs

| # | Lab | What it demonstrates | Submission |
| --- | --- | --- | --- |
| 1 | **Kubernetes Volumes** | emptyDir, hostPath, PV, PVC, StorageClass and dynamic provisioning, each run for real. Includes a bug in the course PVC: it never binds to the PV written for it. | [`01-kubernetes-volumes/README.md`](./01-kubernetes-volumes/README.md) |
| 2 | **HPA hands-on** | `hpa.yaml` + a load generator: scale-out 1 → 2 → 5 and back to 1, recorded as a timestamped timeline. Shows why the course load generator alone plateaus at 2. | [`02-hpa/submission.md`](./02-hpa/submission.md) |
| 3 | **Probes** | Liveness restarts, readiness removing a Pod from its Service, and a startup probe saving a slow-booting app that liveness alone kills forever. | [`03-probes/submission.md`](./03-probes/submission.md) |
| 4 | **Mini project** | PVC + 2–5 replicas + all three probes: data survives Pod deletion, HPA scales out and in, and both bonus challenges are broken on purpose. | [`04-mini-project/submission.md`](./04-mini-project/submission.md) |

---

## Findings worth knowing

1. **The course's static PV is never used.** `student-pvc.yaml` has no `storageClassName`, so on any cluster with a default StorageClass (kind, minikube, every cloud) it gets dynamically provisioned a *new* volume, and `student-pv` sits `Available` forever. Fixed with `storageClassName: ""`. See [lab 1](./01-kubernetes-volumes/README.md#4-the-static-pv-that-never-gets-used-bug-in-the-course-manifests).
2. **The course load generator saturates itself, not nginx.** One `wget` loop uses ~0.8 CPU in busybox but only pushes ~90m into nginx, so the HPA settles at exactly 2 replicas and never reaches 5. Four more copies were needed. See [lab 2](./02-hpa/submission.md).
3. **A liveness probe alone kills a slow-starting app on every attempt.** The restart cycle measured 45 s, not 15 s. The `sh` wrapper ignores SIGTERM, so every kill waits out the full 30 s grace period. See [lab 3](./03-probes/submission.md).
4. **An RWO PVC pins all HPA replicas to one node.** The mini project scales to 5 Pods, but the local-path volume has node affinity, so all 5 land on the same worker. See [lab 4](./04-mini-project/submission.md).

---

## Environment notes

- `metrics-server` v0.9.0 was installed from its release manifest with `--kubelet-insecure-tls` (kind's kubelets use self-signed serving certs). This is the kind equivalent of `minikube addons enable metrics-server`.
- kind's default StorageClass is `standard` → `rancher.io/local-path`, the same idea as minikube's `k8s.io/minikube-hostpath`.
- Early in the run, Docker Hub answered the kind nodes' anonymous pulls with `429 Too Many Requests`, so the images these labs use were pulled once on the host and imported into each node (`ctr images import`). That is why events say `already present on machine`.

---

## Repository layout

```
12_K8s_Storage_HPA_Probes/
├── README.md                  <- this index
├── 01-kubernetes-volumes/
│   ├── README.md              <- volume concepts + every command, screenshot and explanation
│   ├── screenshots/
│   └── manifests/             <- course YAML + the two fixed versions
├── 02-hpa/
│   ├── submission.md
│   ├── hpa-watch.log          <- raw `kubectl get hpa -w` recording (timestamped)
│   ├── pods-watch.log         <- raw `kubectl get pods -w` recording (timestamped)
│   ├── screenshots/
│   └── manifests/             <- deployment, service, hpa, load generators
├── 03-probes/
│   ├── submission.md
│   ├── screenshots/
│   └── manifests/
└── 04-mini-project/
    ├── submission.md
    ├── screenshots/
    └── manifests/
```
