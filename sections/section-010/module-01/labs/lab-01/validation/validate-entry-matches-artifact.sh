#!/usr/bin/env bash
# PASS when: confirms the recorded entry is the log entry for inventory-1.2.0.tar.gz.txt
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

index="$(answer log-index entry-answer)"
uuid="$(short_id "$(answer uuid entry-answer)")"
expected="$(ws sh -s <<'IN_WORKSTATION'
. /setup/lab-lib.sh
id="$(uuids_for_hash "$(sha256_of /lab/artifacts/inventory-1.2.0.tar.gz.txt)" | head -1)"
printf '%s %s\n' "$(entry_json "$id" | jq -r '.logIndex')" "$(short_id "$id")"
IN_WORKSTATION
)"
[ -n "$expected" ] || fail "Could not find the entry for inventory-1.2.0.tar.gz.txt in Rekor."
[ "$index" = "${expected%% *}" ] || fail "log-index $index is not the entry for inventory-1.2.0.tar.gz.txt."
[ "$uuid" = "${expected##* }" ] || fail "uuid does not belong to the entry for inventory-1.2.0.tar.gz.txt."
echo "PASS: the recorded entry is the one for inventory-1.2.0.tar.gz.txt."
