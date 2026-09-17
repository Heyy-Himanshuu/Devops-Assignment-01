# Session 11 — Kubernetes Networking & Services

## Name

Himanshu Rathi

## Roll No

`24BCS10365`

---

All five Service types, each deployed against a live 3-node cluster and proven with real traffic — including a broken manifest found in the upstream repo, diagnosed and fixed.

Every command in every lab below was run against a live 3-node Kubernetes cluster (`kind`, Kubernetes v1.35.0) on macOS. Each screenshot is the real terminal output of the command shown directly above it — nothing is mocked or transcribed from memory.

Labs are adapted from the course repo [`Nency-Ravaliya/devops-heros`](https://github.com/Nency-Ravaliya/devops-heros).

---

## Labs

| # | Lab | What it demonstrates | Submission |
| --- | --- | --- | --- |
| 1 | **ClusterIP** | The default internal-only virtual IP; reached by short name, raw IP and FQDN. | [`01-clusterip/submission.md`](./01-clusterip/submission.md) |
| 2 | **NodePort** | A static port opened on every node — proven by curling all three node IPs. | [`02-nodeport/submission.md`](./02-nodeport/submission.md) |
| 3 | **LoadBalancer** | Cloud-provisioned external access, and why EXTERNAL-IP stays <pending> locally. | [`03-loadbalancer/submission.md`](./03-loadbalancer/submission.md) |
| 4 | **ExternalName** | A pure CNAME alias — plus a real NXDOMAIN bug in the committed manifest, diagnosed and fixed. | [`04-externalname/submission.md`](./04-externalname/submission.md) |
| 5 | **Headless** | clusterIP: None — DNS returns every Pod IP, giving StatefulSet members stable identities. | [`05-headless/submission.md`](./05-headless/submission.md) |

---

## Repository layout

```
10_K8s_Networking_Services/
├── README.md              <- this index
├── 01-clusterip/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 02-nodeport/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 03-loadbalancer/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 04-externalname/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
├── 05-headless/
│   ├── submission.md      <- commands, explanations and screenshots
│   ├── screenshots/       <- terminal captures of every command and its output
│   └── manifests/         <- the YAML applied in that lab
```
