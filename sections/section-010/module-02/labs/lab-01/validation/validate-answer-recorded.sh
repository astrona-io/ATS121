#!/usr/bin/env bash
# PASS when: the ConfigMap notice-entry holds the log index and UUID of the notice entry
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf "%s" "$1" | tr -d " 
" | tr "A-F" "a-f" | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

index="$(answer log-index notice-entry)"
uuid="$(answer uuid notice-entry)"
[ -n "$index" ] || fail "ConfigMap notice-entry has no key log-index."
[ -n "$uuid" ] || fail "ConfigMap notice-entry has no key uuid."
expected="$(ws sh -s <<'IN_WORKSTATION'
. /setup/lab-lib.sh
id="$(uuids_for_hash "$(sha256_of /lab/artifacts/security-notice.txt)" | head -1)"
[ -n "$id" ] || exit 0
printf '%s %s\n' "$(entry_json "$id" | jq -r '.logIndex')" "$(short_id "$id")"
IN_WORKSTATION
)"
[ -n "$expected" ] || fail "Rekor has no entry for the security notice."
[ "$index" = "${expected%% *}" ] || fail "log-index $index is not the index of the notice entry."
[ "$(short_id "$uuid")" = "${expected##* }" ] || fail "uuid does not belong to the notice entry."
echo "PASS: notice-entry holds the log index and UUID of the notice entry."
