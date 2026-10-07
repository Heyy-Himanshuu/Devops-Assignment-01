# Session 14 — Kubernetes Troubleshooting

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

"My application isn't working. How do I find out why?" Every failure below was produced for real and then worked through the same way: **identify → investigate → root cause → fix → verify**, with before and after output for each.

Every command in every lab below was run against a live 3-node Kubernetes cluster (`kind`, Kubernetes v1.35.0) on macOS. Each screenshot is the real terminal output of the command shown directly above it. Nothing is mocked or transcribed from memory.

Labs are adapted from the course repo [`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros) (`session-14-kubernetes-troubleshooting`).

---

## Labs

| # | Lab | What it demonstrates | Submission |
| --- | --- | --- | --- |
| 1 | **Troubleshooting commands** | `get`, `get -o wide`, `describe`, `logs`, `exec`, `events`, `explain`, `top`: what each one is for, run on real Pods. | [`01-kubectl-commands/submission.md`](./01-kubectl-commands/submission.md) |
| 2 | **Common issues** | CrashLoopBackOff, ImagePullBackOff, ErrImagePull, Pending, ContainerCreating, configuration errors, Service connectivity, DNS and Pod networking. Each one reproduced, diagnosed, fixed and verified. | [`02-common-issues/submission.md`](./02-common-issues/submission.md) |
| 3 | **Mini project** | The course's troubleshooting challenge: broken image, broken Service selector, the Q&A, the troubleshooting table and the README questions. | [`03-mini-project/submission.md`](./03-mini-project/submission.md) |
| 4 | **Triage gauntlet** | `scenarios/triage_all.sh`: 5 broken production Pods, all fixed. One of them needed two fixes, and one looked healthy while broken. | [`04-triage-scenarios/submission.md`](./04-triage-scenarios/submission.md) |

---

## Issue index

| Issue | Status you see | Root cause found | Where |
|---|---|---|---|
| CrashLoopBackOff | `Error` ↔ `CrashLoopBackOff`, restarts climbing | process exits non-zero (and in scenario 1, also exits **zero**) | [lab 2](./02-common-issues/submission.md#1-crashloopbackoff), [lab 4](./04-triage-scenarios/submission.md#scenario-1--crashloop) |
| ErrImagePull / ImagePullBackOff | `ErrImagePull` → `ImagePullBackOff` | tag doesn't exist, repo doesn't exist, **registry rate limit (429)** | [lab 2](./02-common-issues/submission.md#2-errimagepull--imagepullbackoff), [lab 4](./04-triage-scenarios/submission.md#scenario-2--imagepull) |
| Pending | `Pending`, no node, no IP | nodeSelector matches no node, or requests bigger than any node | [lab 2](./02-common-issues/submission.md#3-pending), [lab 4](./04-triage-scenarios/submission.md#scenario-3--pending) |
| ContainerCreating (stuck) | `ContainerCreating` forever | volume source (ConfigMap) doesn't exist → `FailedMount` | [lab 2](./02-common-issues/submission.md#4-stuck-in-containercreating) |
| Configuration | `CreateContainerConfigError` | env var refers to a ConfigMap key that isn't there (case mismatch) | [lab 2](./02-common-issues/submission.md#5-configuration-issue--createcontainerconfigerror) |
| OOMKilled | `OOMKilled`, exit 137 | memory limit far below what the process needs | [lab 4](./04-triage-scenarios/submission.md#scenario-5--oomkilled) |
| Service connectivity | Pods fine, Service fails | selector ≠ Pod labels (no endpoints), **or** wrong `targetPort` | [lab 2](./02-common-issues/submission.md#6-service-connectivity), [lab 3](./03-mini-project/submission.md) |
| DNS | `NXDOMAIN` | typo, wrong namespace, short name used across namespaces | [lab 2](./02-common-issues/submission.md#7-dns), [lab 4](./04-triage-scenarios/submission.md#scenario-4--dns-failure) |
| Pod networking | everything green, curl times out | a default-deny NetworkPolicy | [lab 2](./02-common-issues/submission.md#8-pod-networking--networkpolicy) |

---

## Bugs found in the course material

1. **`09-service-dns-troubleshooting/dns-test-pod.yaml` can never start.** It uses `registry.k8s.io/e2e-test-images/dnsutils:1.3`, and that repository has **no tags at all**. The image from the Kubernetes DNS-debugging docs is `jessie-dnsutils:1.3`. Proven by querying the registry and fixed in [`dns-test-pod-fixed.yaml`](02-common-issues/manifests/dns-test-pod-fixed.yaml).
2. **`09-service-dns-troubleshooting/service.yaml`** (the "good" file, not `broken-service.yaml`) has `selector: app: web-ahsgdf`, so it matches nothing. Treated as an exercise and fixed in [`service-fixed.yaml`](02-common-issues/manifests/service-fixed.yaml).
3. **Scenario 1's obvious fix doesn't work.** Adding `DATABASE_URL` makes the script print "started successfully" and then **exit 0**. A bare Pod restarts on any exit, so it goes straight back into `CrashLoopBackOff` (as `Completed`).

---

## Repository layout

```
13_K8s_Troubleshooting/
├── README.md                <- this index
├── 01-kubectl-commands/     <- submission.md, screenshots/, manifests/
├── 02-common-issues/        <- submission.md, screenshots/, manifests/ (broken + fixed, course + own)
├── 03-mini-project/         <- submission.md, screenshots/, manifests/
└── 04-triage-scenarios/     <- submission.md, screenshots/, manifests/ (5 scenarios + fixed.yaml each)
```
