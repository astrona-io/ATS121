#!/usr/bin/env bash
# Runs before the reference solution: waits until the workstation reaches
# Rekor and the lab trust files exist.
set -eu

for _ in $(seq 1 90); do
  if kubectl -n workstation exec deploy/workstation -- sh -c \
       'curl -sf "$REKOR_URL/api/v1/log" >/dev/null && test -s /lab/trusted-root.json' 2>/dev/null; then
    exit 0
  fi
  sleep 5
done
echo "Rekor did not answer in time." >&2
exit 1
