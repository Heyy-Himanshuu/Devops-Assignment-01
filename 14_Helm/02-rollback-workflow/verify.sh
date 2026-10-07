#!/bin/sh
# Prints what is actually live: Helm's view, the Deployment's image, and what the Service answers in-cluster.
NS=s15-rollback; REL=web
echo "helm  : revision $(helm status $REL -n $NS -o json | jq -r '.version') ($(helm status $REL -n $NS -o json | jq -r '.info.description'))"
echo "deploy: $(kubectl get deploy $REL -n $NS -o jsonpath='{.spec.template.spec.containers[0].image}  ready={.status.readyReplicas}/{.spec.replicas}')"
kubectl run probe-$$ -n $NS --rm -i --restart=Never --image=curlimages/curl:8.6.0 --quiet -- \
  sh -c "for i in 1 2 3 4; do curl -s -D - http://$REL/ | grep -E '^Server|<h1|revision' | tr -d '\r' | tr '\n' ' '; echo; done"
