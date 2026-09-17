# Session 10 — Kubernetes Pods, ReplicaSets & Deployments

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

The four Deployment strategies, each executed end to end with live traffic measured during the switchover, plus every Pod lifecycle phase and probe type reproduced deliberately.

Every command in every lab below was run against a live 3-node Kubernetes cluster (`kind`, Kubernetes v1.35.0) on macOS. Each screenshot is the real terminal output of the command shown directly above it — nothing is mocked or transcribed from memory.

Labs are adapted from the course repo [`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros).

---

## Labs

| # | Lab | What it demonstrates | Submission |
| --- | --- | --- | --- |
| 1 | **Rolling Update** | Zero-downtime replacement, one Pod at a time, with traffic sampled throughout the rollout. | [`01-rolling-update/submission.md`](./01-rolling-update/submission.md) |
| 2 | **Blue-Green** | Two full environments side by side; cut over by flipping only the Service selector. | [`02-blue-green/submission.md`](./02-blue-green/submission.md) |
| 3 | **Canary** | 10% → 30% → 100% traffic shift driven purely by replica counts, plus the abort path. | [`03-canary/submission.md`](./03-canary/submission.md) |
| 4 | **Recreate** | The deliberate-downtime strategy, with the outage window measured request by request. | [`04-recreate/submission.md`](./04-recreate/submission.md) |
| 5 | **Pod Lifecycle & Probes** | Running, Pending, Succeeded, Failed, CrashLoopBackOff, ImagePullBackOff, all three probes, init containers, sidecars and graceful termination. | [`05-pod-lifecycle/submission.md`](./05-pod-lifecycle/submission.md) |

---

## Repository layout

```
09_K8s_Pods_ReplicaSets_Deployments/
├── README.md              <- this index
├── 01-rolling-update/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 02-blue-green/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 03-canary/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 04-recreate/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 05-pod-lifecycle/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
```
