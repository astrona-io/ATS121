#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

answer="$(ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
size="$(jq -r '.treeSize' /lab/checkpoints/candidate-a.json)"
# The proof endpoint reports the current root, so read the root at the saved
# size from the checkpoint kept in the bundle whose inclusion proof has that size.
bundle=""
for file in /lab/bundles/*.sigstore.json; do
  if [ "$(jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.treeSize' "$file")" = "$size" ]; then
    bundle="$file"
  fi
done
if [ -z "$bundle" ]; then
  echo "ERROR: no bundle in /lab/bundles has an inclusion proof for tree size $size." >&2
  exit 1
fi
# The bundle stores the root hash in Base64; the candidates hold it in hex.
real="$(jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.rootHash' "$bundle" | base64 -d | od -An -tx1 | tr -d ' \n')"
genuine=""
for c in candidate-a candidate-b; do
  if [ "$(jq -r '.rootHash' "/lab/checkpoints/$c.json")" = "$real" ]; then
    genuine="$c"
  fi
done
now="$(curl -sf "$REKOR_URL/api/v1/log" | jq -r '.treeSize')"
printf '%s %s %s\n' "$genuine" "$now" "$(( now - size ))"
IN_WORKSTATION
)"
set -- $answer
kubectl -n workstation create configmap growth-answer \
  --from-literal=genuine="$1" --from-literal=tree-size="$2" --from-literal=entries-added="$3" \
  --dry-run=client -o yaml | kubectl apply -f -
