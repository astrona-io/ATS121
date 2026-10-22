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
real="$(curl -sf "$REKOR_URL/api/v1/log/proof?firstSize=1&lastSize=$size" | jq -r '.rootHash')"
for c in candidate-a candidate-b; do
  [ "$(jq -r '.rootHash' "/lab/checkpoints/$c.json")" = "$real" ] && echo "$c"
done
IN_WORKSTATION
)"
[ -n "$expected" ] || fail "Neither checkpoint matches the log any more. Was the Rekor server restarted?"
[ "$given" = "$expected" ] || fail "genuine is '$given', but the log proves the other checkpoint."
echo "PASS: $given is the checkpoint the log is consistent with."
