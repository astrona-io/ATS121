#!/usr/bin/env bash
# Creates the starting state for ats-121-capstone-010 in the workstation pod.
# The answer is NOT created here - finding it is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
new_key release
for version in 2.0.0 2.1.0 2.2.0 2.3.0; do
  new_artifact "/lab/artifacts/inventory-$version.txt" "inventory release $version"
  sign_with release "/lab/artifacts/inventory-$version.txt" "/lab/bundles/inventory-$version.txt.sigstore.json"
done
# Record the log state an auditor saved earlier, plus a forged copy.
sleep 5
# Read the tree size and the root hash from one response (two requests can
# see two different trees while Rekor still integrates entries), and check
# that the consistency proof endpoint reports the same root for that size.
for _ in $(seq 1 30); do
  loginfo="$(curl -sf "$REKOR_URL/api/v1/log")"
  size="$(printf '%s' "$loginfo" | jq -r '.treeSize')"
  root="$(printf '%s' "$loginfo" | jq -r '.rootHash')"
  proof_root="$(curl -sf "$REKOR_URL/api/v1/log/proof?firstSize=1&lastSize=$size" | jq -r '.rootHash')"
  [ -n "$root" ] && [ "$proof_root" = "$root" ] && break
  sleep 2
done
[ "$proof_root" = "$root" ] || { echo "ERROR: Rekor does not report a stable root hash." >&2; exit 1; }
forged="$(printf '%s' "$root" | sed 's/^\(.\)\(.\)/\2\1/')"
[ "$forged" = "$root" ] && forged="$(printf '%s' "$root" | tr '0123456789abcdef' '123456789abcdef0')"
mkdir -p /lab/checkpoints
if [ "$(( $(date +%s) % 2 ))" -eq 0 ]; then
  genuine=candidate-a; fake=candidate-b
else
  genuine=candidate-b; fake=candidate-a
fi
printf '{"treeSize": %s, "rootHash": "%s"}\n' "$size" "$root" > "/lab/checkpoints/$genuine.json"
printf '{"treeSize": %s, "rootHash": "%s"}\n' "$size" "$forged" > "/lab/checkpoints/$fake.json"
# The log keeps growing after the checkpoints were saved.
for version in 2.4.0 2.5.0 2.6.0; do
  new_artifact "/lab/artifacts/inventory-$version.txt" "inventory release $version"
  sign_with release "/lab/artifacts/inventory-$version.txt" "/lab/bundles/inventory-$version.txt.sigstore.json"
done
ls -l /lab/checkpoints
IN_WORKSTATION

echo "[lab] Starting state ready."
