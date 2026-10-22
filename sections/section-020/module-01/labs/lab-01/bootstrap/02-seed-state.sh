#!/usr/bin/env bash
# Creates the starting state for ats-121-lab-020-01 in the workstation pod.
# The answer is NOT created here - finding it is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
for key in team-a team-b ci-old; do new_key "$key"; done
for name in api-1.0.0 api-1.1.0 web-1.0.0 web-1.1.0 worker-1.0.0 worker-1.1.0 api-1.2.0 debug-tools; do
  new_artifact "/lab/artifacts/$name.txt" "$name"
done
sign_with team-a /lab/artifacts/api-1.0.0.txt     /tmp/b1.json
sign_with ci-old /lab/artifacts/worker-1.0.0.txt  /tmp/b2.json
sign_with team-b /lab/artifacts/web-1.0.0.txt     /tmp/b3.json
sign_with team-a /lab/artifacts/api-1.1.0.txt     /tmp/b4.json
sign_with ci-old /lab/artifacts/debug-tools.txt   /tmp/b5.json
sign_with team-b /lab/artifacts/web-1.1.0.txt     /tmp/b6.json
sign_with ci-old /lab/artifacts/worker-1.1.0.txt  /tmp/b7.json
sign_with team-a /lab/artifacts/api-1.2.0.txt     /tmp/b8.json
rm -f /tmp/b*.json
# The release manifest lists what the team really shipped.
: > /lab/release-manifest.txt
for name in api-1.0.0 api-1.1.0 api-1.2.0 web-1.0.0 web-1.1.0 worker-1.0.0 worker-1.1.0; do
  printf '%s  %s.txt\n' "$(sha256_of "/lab/artifacts/$name.txt")" "$name" >> /lab/release-manifest.txt
done
# The CI key leaked: the team only has its public key now.
rm -f /lab/keys/ci-old.key
# The unexpected artifact itself is gone; only the log remembers it.
rm -f /lab/artifacts/debug-tools.txt
ls -l /lab/keys /lab/artifacts
IN_WORKSTATION

echo "[lab] Starting state ready."
