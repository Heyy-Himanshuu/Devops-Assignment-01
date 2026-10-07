#!/bin/bash
# Packages the app into build/ - this directory is what CI uploads as the build artifact.
set -euo pipefail
rm -rf build && mkdir -p build
cp -r app requirements.txt build/
find build -name __pycache__ -prune -exec rm -rf {} +
cat > build/build-info.txt <<INFO
Application : Session 16 calculator
Commit      : ${GITHUB_SHA:-local}
Run         : ${GITHUB_RUN_NUMBER:-local}
Built at    : $(date -u +%Y-%m-%dT%H:%M:%SZ)
INFO
echo "Build files:"; find build -type f | sort
