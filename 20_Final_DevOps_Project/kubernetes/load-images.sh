#!/usr/bin/env bash
# Import locally built images straight into every kind node's containerd.
# (`kind load docker-image` fails on multi-platform images from buildx, and pulling on the
#  nodes hit Docker Hub's anonymous rate limit - 429 Too Many Requests - earlier in the course.)
set -euo pipefail
CLUSTER="${CLUSTER:-devops-hw}"
for img in "$@"; do
  for node in $(kind get nodes --name "$CLUSTER"); do
    docker save --platform linux/arm64 "$img" | docker exec -i "$node" ctr -n k8s.io images import --all-platforms - >/dev/null
    echo "imported $img -> $node"
  done
done
