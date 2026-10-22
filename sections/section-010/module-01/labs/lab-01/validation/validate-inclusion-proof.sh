#!/usr/bin/env bash
# PASS when: confirms rekor-cli verifies the inclusion proof of the recorded entry
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

index="$(answer log-index entry-answer)"
[ -n "$index" ] || fail "ConfigMap entry-answer has no key log-index."
ws rekor-cli verify --log-index "$index" >/dev/null 2>&1 || fail "rekor-cli verify --log-index $index failed."
echo "PASS: the inclusion proof of entry $index verifies."
