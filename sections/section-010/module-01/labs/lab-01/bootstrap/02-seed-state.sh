#!/usr/bin/env bash
# Creates the starting state for ats-121-lab-010-01 in the workstation pod.
# The answer is NOT created here - finding it is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
new_key release
for version in 1.0.0 1.1.0 1.2.0 1.3.0; do
  new_artifact "/lab/artifacts/inventory-$version.tar.gz.txt" "inventory release $version"
done
# Signed out of order on purpose: the log index does not follow the version.
for version in 1.1.0 1.3.0 1.2.0 1.0.0; do
  sign_with release "/lab/artifacts/inventory-$version.tar.gz.txt" "/lab/bundles/inventory-$version.tar.gz.txt.sigstore.json"
done
# The task is to find the entry in the log, not to read it from a bundle.
rm -f /lab/bundles/*
ls -l /lab/artifacts
IN_WORKSTATION

echo "[lab] Starting state ready."
