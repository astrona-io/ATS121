#!/usr/bin/env bash
# PASS when: confirms tree-size and entries-added match the log
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

size="$(answer tree-size growth-answer)"
added="$(answer entries-added growth-answer)"
[ -n "$size" ] && [ -n "$added" ] || fail "growth-answer needs the keys tree-size and entries-added."
facts="$(ws sh -c 'printf "%s %s\n" "$(curl -sf "$REKOR_URL/api/v1/log" | jq -r .treeSize)" "$(jq -r .treeSize /lab/checkpoints/candidate-a.json)"')"
now="${facts%% *}"; old="${facts##* }"
[ "$size" = "$now" ] || fail "tree-size is $size, but the log has $now entries."
[ "$added" = "$(( now - old ))" ] || fail "entries-added is $added, but the log grew by $(( now - old ))."
echo "PASS: the log has $now entries, $added more than the saved checkpoint."
