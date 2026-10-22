#!/usr/bin/env bash
# PASS when: confirms the ConfigMap entry-answer holds a log index and a UUID
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

index="$(answer log-index entry-answer)"
uuid="$(answer uuid entry-answer)"
[ -n "$index" ] || fail "ConfigMap entry-answer has no key log-index."
[ -n "$uuid" ] || fail "ConfigMap entry-answer has no key uuid."
printf '%s' "$index" | grep -Eq '^[0-9]+$' || fail "log-index must be a number, got '$index'."
echo "PASS: entry-answer holds log-index $index and a uuid."
