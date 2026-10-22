#!/usr/bin/env bash
# PASS when: confirms intruder-uuids lists every entry made by that key and first-intruder-index is the earliest
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

given="$(answer intruder-uuids intruder-report)"
first="$(answer first-intruder-index intruder-report)"
[ -n "$given" ] && [ -n "$first" ] || fail "intruder-report needs the keys intruder-uuids and first-intruder-index."
printf '%s\n' "$given" | sed '/^[[:space:]]*$/d' | while read -r id; do short_id "$id"; echo; done | sed '/^$/d' | sort -u > /tmp/ats121-given.txt
ws sh -s <<'IN_WORKSTATION' > /tmp/ats121-facts.txt
. /setup/lab-lib.sh
id="$(uuids_for_hash "$(sha256_of /lab/artifacts/inventory-2.0.0.txt)" | head -1)"
entry_json "$id" | jq -r '.body' | base64 -d | jq -r '.spec.signature.publicKey.content' | base64 -d > /tmp/intruder.pub
for other in $(uuids_for_key /tmp/intruder.pub); do
  printf '%s %s\n' "$(short_id "$other")" "$(entry_json "$other" | jq -r '.logIndex')"
done
IN_WORKSTATION
cut -d' ' -f1 /tmp/ats121-facts.txt | sort -u > /tmp/ats121-expected.txt
min="$(cut -d' ' -f2 /tmp/ats121-facts.txt | sort -n | head -1)"
same=0; diff -q /tmp/ats121-given.txt /tmp/ats121-expected.txt >/dev/null && same=1
rm -f /tmp/ats121-given.txt /tmp/ats121-expected.txt /tmp/ats121-facts.txt
[ "$same" = 1 ] || fail "intruder-uuids is not the set of entries signed by that key."
[ "$first" = "$min" ] || fail "first-intruder-index is $first, but the earliest entry of that key is $min."
echo "PASS: every entry of the unknown key is listed; the first is at index $min."
