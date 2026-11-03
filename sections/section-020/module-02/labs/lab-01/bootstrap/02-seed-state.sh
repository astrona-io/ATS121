#!/usr/bin/env bash
# Creates the starting state for ats-121-lab-020-02 in the workstation pod.
# The answer is NOT created here - finding it is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
for key in team-a team-b; do new_key "$key"; done
for name in api-1.0.0 api-1.1.0 api-old-hotfix web-1.0.0 api-1.2.0 api-debug web-1.1.0 web-debug; do
  new_artifact "/lab/artifacts/$name.txt" "$name"
done
# The log as the monitor last saw it.
sign_with team-a /lab/artifacts/api-1.0.0.txt      /tmp/b1.json
sign_with team-a /lab/artifacts/api-1.1.0.txt      /tmp/b2.json
sign_with team-a /lab/artifacts/api-old-hotfix.txt /tmp/b3.json
sign_with team-b /lab/artifacts/web-1.0.0.txt      /tmp/b4.json
mkdir -p /lab/monitor
curl -sf "$REKOR_URL/api/v1/log" | jq '{treeSize, rootHash}' > /lab/monitor/state.json
# The hashes the release process approved.
: > /lab/monitor/approved-hashes.txt
for name in api-1.0.0 api-1.1.0 api-1.2.0 web-1.0.0 web-1.1.0; do
  sha256_of "/lab/artifacts/$name.txt" >> /lab/monitor/approved-hashes.txt
done
# What happened since the last run.
sign_with team-a /lab/artifacts/api-1.2.0.txt  /tmp/b5.json
sign_with team-a /lab/artifacts/api-debug.txt  /tmp/b6.json
sign_with team-b /lab/artifacts/web-1.1.0.txt  /tmp/b7.json
sign_with team-b /lab/artifacts/web-debug.txt  /tmp/b8.json
rm -f /tmp/b*.json
ls -l /lab/keys /lab/monitor
IN_WORKSTATION

echo "[lab] Starting state ready."
