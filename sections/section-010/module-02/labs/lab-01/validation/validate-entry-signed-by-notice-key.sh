#!/usr/bin/env bash
# PASS when: the entry for the security notice was made with the notice key
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf "%s" "$1" | tr -d " 
" | tr "A-F" "a-f" | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

count="$(ws sh -s <<'IN_WORKSTATION'
. /setup/lab-lib.sh
for id in $(uuids_for_hash "$(sha256_of /lab/artifacts/security-notice.txt)"); do short_id "$id"; echo; done | sed '/^$/d' | sort -u > /tmp/by-hash.txt
for id in $(uuids_for_key /lab/keys/notice.pub); do short_id "$id"; echo; done | sed '/^$/d' | sort -u > /tmp/by-key.txt
comm -12 /tmp/by-hash.txt /tmp/by-key.txt | wc -l | tr -d ' '
IN_WORKSTATION
)"
[ "${count:-0}" -ge 1 ] || fail "No entry for the notice was signed with /lab/keys/notice.pub."
echo "PASS: the notice entry was made with the notice key."
