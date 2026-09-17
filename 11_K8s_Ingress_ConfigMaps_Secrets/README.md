# Session 12 — Kubernetes Ingress, ConfigMaps & Secrets

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

Config and credentials kept outside the container image, and a single layer-7 entry point routing by path, by hostname and over TLS — including two real bugs in the committed lab manifests, each diagnosed from the evidence and fixed.

Every command in every lab below was run against a live 3-node Kubernetes cluster (`kind`, Kubernetes v1.35.0) on macOS. Each screenshot is the real terminal output of the command shown directly above it — nothing is mocked or transcribed from memory.

Labs are adapted from the course repo [`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros).

---

## Labs

| # | Lab | What it demonstrates | Submission |
| --- | --- | --- | --- |
| 1 | **ConfigMaps** | External key/value app config; values printed in full by describe. | [`01-configmap/submission.md`](./01-configmap/submission.md) |
| 2 | **Secrets** | Credentials hidden from describe — and a demonstration that base64 is encoding, not encryption. | [`02-secret/submission.md`](./02-secret/submission.md) |
| 3 | **Ingress & TLS** | Path and host routing plus HTTPS termination; two committed bugs found and fixed (dangling backends, and a certificate with no SAN). | [`03-ingress/submission.md`](./03-ingress/submission.md) |
| 4 | **Full Demo** | ConfigMap + Secret feeding a backend and frontend behind one Ingress, end to end. | [`04-full-demo/submission.md`](./04-full-demo/submission.md) |

---

## Repository layout

```
11_K8s_Ingress_ConfigMaps_Secrets/
├── README.md              <- this index
├── 01-configmap/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 02-secret/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 03-ingress/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 04-full-demo/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
```
