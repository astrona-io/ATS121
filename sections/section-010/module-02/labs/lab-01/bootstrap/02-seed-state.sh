#!/usr/bin/env bash
# Creates the starting state for ats-121-lab-010-02 in the workstation pod.
# The answer is NOT created here - uploading the entry is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
# An ECDSA P-256 key pair made with openssl, not cosign.
openssl ecparam -name prime256v1 -genkey -noout -out /lab/keys/notice.key
openssl ec -in /lab/keys/notice.key -pubout -out /lab/keys/notice.pub 2>/dev/null
new_artifact /lab/artifacts/security-notice.txt "security notice 2026-11"
# Another artifact, signed and logged, so the log is not empty.
new_key team-a
new_artifact /lab/artifacts/release-2.0.0.txt "release 2.0.0"
sign_with team-a /lab/artifacts/release-2.0.0.txt /tmp/release.sigstore.json
rm -f /tmp/release.sigstore.json
ls -l /lab/keys /lab/artifacts
IN_WORKSTATION

echo "[lab] Starting state ready."
