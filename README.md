# DevOps Assignment 1

Solutions for every session of the DevOps homework: Linux, shell scripting, networking, Git, Docker,
Kubernetes (fundamentals through storage, autoscaling and troubleshooting), Helm, CI/CD with GitHub
Actions, DevSecOps, Terraform, monitoring/observability/GitOps, and a final end-to-end project.

Every command output in this repository was captured from a real run on macOS 15 (Apple Silicon)
with Docker Desktop 29.2.0 — nothing is transcribed from memory. The Kubernetes tasks were run
against a live 3-node `kind` cluster (Kubernetes v1.35.0), and every command in them is captured as
a terminal screenshot alongside its output. The Terraform sessions run against
[LocalStack](https://github.com/localstack/localstack) (an AWS API emulator in Docker), not a real AWS
account; each of those write-ups says so and lists what the emulator does not do. The CI/CD sessions
run on GitHub Actions in this repository, and every write-up links its real workflow runs — failed
ones included.

## Contents

| # | Task | Deliverable |
| --- | --- | --- |
| 1 | Linux Fundamentals | [`01_Linux_Fundamental/learning.md`](./01_Linux_Fundamental/learning.md) |
| 2 | Shell Scripting | [`02_shell_scripting/`](./02_shell_scripting) — [script](./02_shell_scripting/shellscript.sh), [output](./02_shell_scripting/output.md) |
| 3 | Networking Commands | [`03_networking/output.md`](./03_networking/output.md) |
| 4 | Git & GitHub (cherry-pick) | [`04_git/github/output.md`](./04_git/github/output.md) |
| 5 | Docker Fundamentals | [`05_Docker_Fundamental/`](./05_Docker_Fundamental) — 6 apps, [output](./05_Docker_Fundamental/output.md) |
| 6 | Dockerfiles & Images | [`06_DockerFiles_Images/submission.md`](./06_DockerFiles_Images/submission.md) |
| 7 | Docker Networking & Storage | [`07_Docker_Networking/readme.md`](./07_Docker_Networking/readme.md) |
| 8 | Kubernetes Fundamentals | [`08_Kubernetes_Fundamentals/README.md`](./08_Kubernetes_Fundamentals/README.md) |
| 9 | Kubernetes Pods, ReplicaSets & Deployments | [`09_K8s_Pods_ReplicaSets_Deployments/README.md`](./09_K8s_Pods_ReplicaSets_Deployments/README.md) |
| 10 | Kubernetes Networking & Services | [`10_K8s_Networking_Services/README.md`](./10_K8s_Networking_Services/README.md) |
| 11 | Kubernetes Ingress, ConfigMaps & Secrets | [`11_K8s_Ingress_ConfigMaps_Secrets/README.md`](./11_K8s_Ingress_ConfigMaps_Secrets/README.md) |
| 12 | Kubernetes Storage, HPA & Probes | [`12_K8s_Storage_HPA_Probes/README.md`](./12_K8s_Storage_HPA_Probes/README.md) |
| 13 | Kubernetes Troubleshooting | [`13_K8s_Troubleshooting/README.md`](./13_K8s_Troubleshooting/README.md) |
| 14 | Helm | [`14_Helm/README.md`](./14_Helm/README.md) |
| 15 | CI/CD & GitHub Actions | [`15_CICD_GitHub_Actions/README.md`](./15_CICD_GitHub_Actions/README.md) |
| 16 | Complete CI/CD & DevSecOps | [`16_DevSecOps/README.md`](./16_DevSecOps/README.md) |
| 17 | Terraform & Infrastructure as Code | [`17_Terraform_IaC/README.md`](./17_Terraform_IaC/README.md) |
| 18 | Cloud & Terraform in Action | [`18_Cloud_Terraform/README.md`](./18_Cloud_Terraform/README.md) |
| 19 | Monitoring, Observability & GitOps | [`19_Monitoring_Observability_GitOps/README.md`](./19_Monitoring_Observability_GitOps/README.md) |
| 20 | Final DevOps Project | [`20_Final_DevOps_Project/README.md`](./20_Final_DevOps_Project/README.md) |

## Task summary

**1. Linux Fundamentals** — soft vs hard links, `adduser` vs `useradd`, `journalctl`, and a command
cheat sheet.

**2. Shell Scripting** — one script covering `date`, `hostname`, `whoami`, `df -h`, `ps`, variables,
`read -p` input, `mkdir`, `touch` and `>` / `>>` redirection into
[`process.log`](./02_shell_scripting/process.log).

**3. Networking Commands** — `ping`, `traceroute`, `netstat`, `nslookup`, `dig`, `telnet` and `curl`,
each with real captured output and an explanation of what the output means.

**4. Git & GitHub** — branching, five commits on a feature branch, and cherry-picking a single
commit onto `main` including resolving the modify/delete conflict it causes.

**5. Docker Fundamentals** — six containerised "Hello World" apps (Nginx, Apache, Node.js, Python,
Java, React), all six built, run and verified with `curl`.

**6. Dockerfiles & Images** — a two-stage Node/Express build, plus a measured size comparison
against the equivalent single-stage image and an explanation of when the technique actually pays off.

**7. Docker Networking & Storage** — three custom bridge networks proving DNS-level isolation,
`host` network mode (and why it behaves differently on macOS), a bind mount updated live, and a real
overlay network with a two-replica swarm service on it.

**8. Kubernetes Fundamentals** — the control-plane/worker split, every `kube-system` component that
actually runs the cluster, namespaces and the API surface, and a first Pod created both
imperatively and declaratively — ending on why a bare Pod is not enough.

**9. Kubernetes Pods, ReplicaSets & Deployments** — all four deployment strategies (rolling update,
blue-green, canary, recreate) with live traffic sampled *during* each switchover, so the downtime
difference between them is measured rather than asserted. Plus every Pod lifecycle phase and failure
mode reproduced on purpose: Pending, Succeeded, Failed, CrashLoopBackOff, ImagePullBackOff, all
three probe types, init containers, sidecars and graceful termination.

**10. Kubernetes Networking & Services** — all five Service types (ClusterIP, NodePort,
LoadBalancer, ExternalName, headless) proven with real traffic on a 3-node cluster, including a
broken manifest found in the course repo, diagnosed and fixed.

**11. Kubernetes Ingress, ConfigMaps & Secrets** — config and credentials kept outside the image
and injected as environment variables, plus one Ingress routing by path, by hostname and over
HTTPS. Two more real bugs in the course manifests found and fixed here: an Ingress pointing at
services that do not exist, and a TLS certificate whose `CN` covers none of the hostnames it
serves — which `curl -k` hid completely.

**12. Kubernetes Storage, HPA & Probes** — emptyDir, hostPath, static and dynamically provisioned
volumes (including why the course's static PV is never used on kind), an HPA scaling 1 → 5 → 1 under
generated load with `kubectl top` evidence, all three probe types, and the PVC + HPA + probes mini
project with data surviving Pod deletion.

**13. Kubernetes Troubleshooting** — the eight core `kubectl` investigation commands, then nine
failure types (CrashLoopBackOff, ImagePullBackOff, ErrImagePull, Pending, ContainerCreating, Service,
DNS, Pod networking, configuration) each reproduced, root-caused, fixed and verified with
before/after output, plus the mini project and triage scenarios.

**14. Helm** — every Helm command from the session, a full install → upgrade → upgrade → rollback
cycle proving which revision is serving, and the notes-chart mini project, including fixes for
config changes that never reached the Pods.

**15. CI/CD & GitHub Actions** — a tested Flask app with a CI workflow (lint, test matrix, artifacts,
secrets) and a CD workflow that pushes to GHCR and deploys to a throwaway kind cluster on the runner,
plus a deliberately broken build showing CI stopping CD.

**16. Complete CI/CD & DevSecOps** — build → unit test → SAST → SCA → secret scan → image build →
image scan → security gate → push → deploy, with a vulnerable dependency and a planted fake key
blocked by the gate before the fix goes green.

**17. Terraform & IaC** — the `terraform-s3-demo` project taken through init, fmt, validate, plan,
apply, show, output and destroy, plus one write-up per AWS service (IAM, EC2, S3, VPC,
DynamoDB & RDS) with CLI demos.

**18. Cloud & Terraform in Action** — VPC, subnet, internet gateway, route table, security group, EC2
and S3 as one Terraform project, with an architecture diagram, dependency graph, state inspection
and a clean destroy.

**19. Monitoring, Observability & GitOps** — kube-prometheus-stack with a ServiceMonitor, PromQL,
Grafana dashboards and a firing alert; metrics, logs and traces explained with a Jaeger demo; and Argo
CD syncing this repository, then undoing a manual change by itself (self-heal).

**20. Final DevOps Project** — SpendBoard (FastAPI + Postgres + React) taken through Docker,
a DevSecOps GitHub Actions pipeline, Helm on Kubernetes (Ingress, HPA, probes, PVC, Secret kept out
of Git), Terraform, Prometheus/Grafana monitoring and Argo CD GitOps. A code push reaches the cluster
with no manual step. It ends with six deliberately introduced faults, each diagnosed and fixed.

## Running the Docker tasks

```bash
# Task 5 - six apps
cd 05_Docker_Fundamental
docker build -t nginx-app nginx-app && docker run -d --name nginx-app -p 8081:80 nginx-app
# ... see 05_Docker_Fundamental/output.md for all six

# Task 6 - multi-stage build
cd 06_DockerFiles_Images/multi-stage-app
docker build -t multi-stage-app .
docker run -d -p 8080:3000 --name multi-stage-container multi-stage-app
curl http://localhost:8080
```

Each task's document ends with the cleanup commands for the containers, networks and images it
creates.

## Running the Kubernetes tasks

Tasks 8–14, 19 and 20 need a running cluster. The exact cluster used for every screenshot in this repository
is one control-plane node plus two workers, with the labs' node ports published to the host:

```bash
kind create cluster --config kind-config.yaml   # see 08_Kubernetes_Fundamentals/submission.md
kubectl get nodes

# Task 11 additionally needs an ingress controller (the kind equivalent of
# `minikube addons enable ingress`):
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller --timeout=180s

# then, from any lab folder, e.g.
cd 10_K8s_Networking_Services/01-clusterip
kubectl apply -f manifests/app-deployment.yaml
kubectl apply -f manifests/service.yaml
```

Each lab's `submission.md` lists its commands in order and ends with its own cleanup step, so labs
can be run independently and in any order.

## Running the Terraform tasks

Tasks 17, 18 and the final project's `terraform/` folder target LocalStack instead of a real AWS
account:

```bash
docker run -d --name localstack -p 4566:4566 localstack/localstack:4.9   # newer tags need a paid token
cd 17_Terraform_IaC/terraform-s3-demo
terraform init && terraform apply
terraform destroy
```
