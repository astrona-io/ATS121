#!/usr/bin/env bash
# Creates the starting state for ats-121-lab-030-01 in the workstation pod.
# The answer is NOT created here - finding it is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
new_key release
for name in inventory-3.0.0 inventory-3.1.0 inventory-3.2.0 inventory-3.3.0 inventory-3.4.0; do
  new_artifact "/lab/artifacts/$name.txt" "$name"
  sign_with release "/lab/artifacts/$name.txt" "/lab/bundles/$name.txt.sigstore.json"
done
# Two of the five do not verify any more, for two different reasons. Which
# two is chosen at random, so the answer cannot be copied.
set -- 3.0.0 3.1.0 3.2.0 3.3.0 3.4.0
pick_one="$(( $(date +%s) % 5 + 1 ))"
pick_two="$(( (pick_one % 5) + 1 ))"
eval "proof_victim=\${$pick_one}"
eval "artifact_victim=\${$pick_two}"
# 1. A changed hash in the inclusion proof of one bundle.
bundle="/lab/bundles/inventory-$proof_victim.txt.sigstore.json"
first="$(jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.hashes[0]' "$bundle")"
changed="$(printf '%s' "$first" | tr 'ABCDEFabcdef' 'BCDEFAbcdefa')"
jq --arg h "$changed" '.verificationMaterial.tlogEntries[0].inclusionProof.hashes[0] = $h' "$bundle" > /tmp/t.json
mv /tmp/t.json "$bundle"
# 2. One artifact changed after it was signed.
printf 'patched after release\n' >> "/lab/artifacts/inventory-$artifact_victim.txt"
ls -l /lab/artifacts /lab/bundles
IN_WORKSTATION

echo "[lab] Starting state ready."
