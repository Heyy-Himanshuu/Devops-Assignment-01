#!/bin/sh
# Prints each running notes-dev Pod's ENVIRONMENT (from the ConfigMap) and the nginx version it actually runs.
for p in $(kubectl get pod -n s15-notes -l app=notes-dev --field-selector=status.phase=Running -o name); do
  kubectl exec -n s15-notes $p -- sh -c 'echo $HOSTNAME ENVIRONMENT=$ENVIRONMENT $(nginx -v 2>&1)'
done
