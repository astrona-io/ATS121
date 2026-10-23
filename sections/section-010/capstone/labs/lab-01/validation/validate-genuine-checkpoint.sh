#!/usr/bin/env bash
# PASS when: confirms the answer names the checkpoint whose root hash the log proves
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

given="$(answer genuine growth-answer)"
[ -n "$given" ] || fail "ConfigMap growth-answer has no key genuine."
expected="$(ws sh -s <<'IN_WORKSTATION'
size="$(jq -r '.treeSize' /lab/checkpoints/candidate-a.json)"
# The proof endpoint reports the current root, so read the root at the saved
# size from the checkpoint kept in the bundle whose inclusion proof has that size.
bundle=""
for file in /lab/bundles/*.sigstore.json; do
  if [ "$(jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.treeSize' "$file")" = "$size" ]; then
    bundle="$file"
  fi
done
[ -n "$bundle" ] || { echo "NO_BUNDLE $size"; exit 0; }
# The bundle stores the root hash in Base64; the candidates hold it in hex.
real="$(jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.rootHash' "$bundle" | base64 -d | od -An -tx1 | tr -d ' \n')"
for c in candidate-a candidate-b; do
  [ "$(jq -r '.rootHash' "/lab/checkpoints/$c.json")" = "$real" ] && echo "$c"
done
IN_WORKSTATION
)"
case "$expected" in
  NO_BUNDLE*) fail "No bundle in /lab/bundles has an inclusion proof for the saved tree size ${expected#NO_BUNDLE }." ;;
esac
[ -n "$expected" ] || fail "Neither checkpoint matches the root hash the log signed for that tree size. Were the files in /lab/checkpoints changed?"
[ "$given" = "$expected" ] || fail "genuine is '$given', but the log proves the other checkpoint."
echo "PASS: $given is the checkpoint the log is consistent with."
