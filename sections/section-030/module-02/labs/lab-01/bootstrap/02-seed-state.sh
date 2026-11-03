#!/usr/bin/env bash
# Creates the starting state for ats-121-lab-030-02 in the workstation pod.
# The answer is NOT created here - producing it is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
new_key release
new_artifact /lab/artifacts/inventory-5.0.0.txt inventory-5.0.0
printf '{"checked": true, "scanner": "lab-scan", "findings": 0}\n' > /lab/predicate.json
ls -l /lab/keys /lab/artifacts /lab/predicate.json
IN_WORKSTATION

echo "[lab] Starting state ready."
