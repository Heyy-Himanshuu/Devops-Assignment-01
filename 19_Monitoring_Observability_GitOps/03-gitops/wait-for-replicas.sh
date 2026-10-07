#!/bin/sh
# Poll the GitOps-managed Deployment every 2s until it has N ready replicas, then report how long it
# took and which Git commit Argo CD has synced. Nothing here applies anything to the cluster.
N=${1:?usage: wait-for-replicas.sh N}
T0=$(date +%s)
until [ "$(kubectl get deploy session20-mini -n s20-gitops -o jsonpath='{.status.readyReplicas}')" = "$N" ]; do sleep 2; done
echo "cluster reached $N/$N $(( $(date +%s) - T0 ))s after git push, with no kubectl apply:"
kubectl get deploy session20-mini -n s20-gitops
kubectl get application session20-mini -n argocd -o jsonpath='synced to {.status.sync.revision}{"\n"}'
