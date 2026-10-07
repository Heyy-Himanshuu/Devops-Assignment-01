#!/usr/bin/env bash
# Load generator used in this lab (from the course's 04-hpa README):
# one busybox Pod requesting the Service in a tight loop.
set -euo pipefail
NS="${1:-s13-hpa}"
kubectl run load-generator -n "$NS" \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://hpa-demo-service >/dev/null; done"
