# gitops/

Git is the source of truth for what runs in namespace `s21-gitops` on the local kind cluster. Argo CD
(3.5, namespace `argocd`) polls this public repo and makes the cluster match it.

```
gitops/
├── argocd/spendboard-local.yaml      the Argo CD Application (applied once, by hand)
└── environments/local/
    ├── Chart.yaml                    environment chart: depends on file://../../../helm/spendboard
    └── values.yaml                   per-environment values - spendboard.image.tag is written by CI
```

**Why an environment chart.** The app chart in `helm/spendboard` is shared by every environment. This
folder only says *which* version and *which* settings run here. Argo CD renders it with
`helm dependency build` + `helm template`, so promoting a release is a one-line diff in Git.

**The Application** (`syncPolicy.automated` with `prune: true` and `selfHeal: true`):

- `prune` means a resource deleted from Git is deleted from the cluster.
- `selfHeal` means a manual change to the cluster (`kubectl scale`, `kubectl edit`) is reverted to what
  Git says.
- `CreateNamespace=true` creates the target namespace if it doesn't exist.

**What is deliberately not in Git:** the database password. It is created once per cluster with
`kubectl -n s21-gitops create secret generic spendboard-db --from-literal=password=...`. In a real setup
this would be Sealed Secrets or External Secrets.

**Promotion flow.** Push app code → `s21-final.yml` tests, scans, pushes `:<sha7>` to GHCR, deploys it
to a throwaway cluster → job 10 commits `tag: "<sha7>"` here → Argo CD sees the new commit → rolling
update in `s21-gitops`.

The evidence (bootstrap, self-heal, and the full code-to-cluster demo) is in
[section 12 of the project README](../README.md#12-gitops).
