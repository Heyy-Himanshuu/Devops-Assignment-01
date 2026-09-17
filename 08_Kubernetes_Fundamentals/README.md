# Session 9 — Kubernetes Fundamentals

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

Cluster architecture from the inside out — the control-plane/worker split, the control plane
components that actually run it, namespaces, the API surface, and creating a first Pod both
imperatively and declaratively.

Every command was run against a live 3-node Kubernetes cluster (`kind`, Kubernetes v1.35.0) on
macOS. Each screenshot is the real terminal output of the command shown directly above it —
nothing is mocked or transcribed from memory.

The upstream `session9-k8s` folder in
[`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros) contains reading
links rather than a command list, so this lab was built to cover what the session taught.

---

## Submission

**[`submission.md`](./submission.md)** — 22 commands, each with its captured terminal output.

| Part | Covers |
| --- | --- |
| Tooling & cluster | `kubectl version`, the kind cluster definition, `kubectl cluster-info` |
| Nodes | `kubectl get nodes -o wide`, node Conditions and Capacity |
| Control plane | every `kube-system` Pod, which node each runs on, `/readyz?verbose` |
| API surface | `kubectl get namespaces`, `kubectl api-resources`, `kubectl explain` |
| First Pod | `kubectl run` (imperative) vs `kubectl apply` (declarative) |
| Debugging | `kubectl describe`, `kubectl logs`, `kubectl exec` |
| The gap | deleting a bare Pod — nothing recreates it, which is why Deployments exist |

---

## Repository layout

```
08_Kubernetes_Fundamentals/
├── README.md         <- this index
├── submission.md     <- commands, explanations and screenshots
└── screenshots/      <- terminal captures of every command and its output
```
