#!/usr/bin/env bash
# Creates the starting state for ats-121-capstone-030 in the workstation pod.
# The answer is NOT created here - finding it is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
new_key release
new_key old-ci
mkdir -p /lab/release
for name in inventory-4.0.0 inventory-4.0.1 inventory-4.1.0; do
  new_artifact "/lab/release/$name.txt" "$name"
done
# A bundle from before the key change: signed with the retired CI key.
sign_with old-ci /lab/release/inventory-4.0.0.txt /lab/release/inventory-4.0.0.txt.sigstore.json
# The retired key is gone.
rm -f /lab/keys/old-ci.key
ls -l /lab/release /lab/keys
IN_WORKSTATION

echo "[lab] Starting state ready."
