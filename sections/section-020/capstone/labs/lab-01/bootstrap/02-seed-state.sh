#!/usr/bin/env bash
# Creates the starting state for ats-121-capstone-020 in the workstation pod.
# The answer is NOT created here - finding it is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
new_key release
new_key intruder
for name in inventory-1.8.0 inventory-1.9.0 inventory-2.0.0 inventory-2.0.0-hotfix helper-0.1.0; do
  new_artifact "/lab/artifacts/$name.txt" "$name"
done
sign_with release  /lab/artifacts/inventory-1.8.0.txt        /tmp/c1.json
sign_with intruder /lab/artifacts/helper-0.1.0.txt           /tmp/c2.json
sign_with release  /lab/artifacts/inventory-1.9.0.txt        /tmp/c3.json
sign_with intruder /lab/artifacts/inventory-2.0.0.txt        /tmp/c4.json
sign_with release  /lab/artifacts/inventory-2.0.0-hotfix.txt /tmp/c5.json
rm -f /tmp/c*.json
# Nobody on the team knows the intruder key.
rm -f /lab/keys/intruder.key /lab/keys/intruder.pub
rm -f /lab/artifacts/helper-0.1.0.txt
ls -l /lab/keys /lab/artifacts
IN_WORKSTATION

echo "[lab] Starting state ready."
