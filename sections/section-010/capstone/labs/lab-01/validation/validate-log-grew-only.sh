#!/usr/bin/env bash
# PASS when: confirms a consistency proof from the saved size to the current size exists
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

ws sh -c 'old="$(jq -r .treeSize /lab/checkpoints/candidate-a.json)"; now="$(curl -sf "$REKOR_URL/api/v1/log" | jq -r .treeSize)"; rekor-cli logproof --first-size "$old" --last-size "$now" >/dev/null' 2>/dev/null \
  || fail "rekor-cli logproof could not prove consistency from the saved size to now."
echo "PASS: the log can prove it only grew since the saved checkpoint."
