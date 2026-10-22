#!/usr/bin/env bash
# PASS when: confirms uuids lists exactly the entries signed by the leaked ci-old key
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

given="$(answer uuids leak-audit)"
[ -n "$given" ] || fail "ConfigMap leak-audit has no key uuids."
printf '%s\n' "$given" | sed '/^[[:space:]]*$/d' | while read -r id; do short_id "$id"; echo; done | sed '/^$/d' | sort -u > /tmp/ats121-given.txt
ws sh -s <<'IN_WORKSTATION' | sed '/^$/d' | sort -u > /tmp/ats121-expected.txt
. /setup/lab-lib.sh
for id in $(uuids_for_key /lab/keys/ci-old.pub); do short_id "$id"; echo; done
IN_WORKSTATION
[ -s /tmp/ats121-expected.txt ] || fail "Rekor returned no entries for ci-old.pub; is the search index up?"
if ! diff -q /tmp/ats121-given.txt /tmp/ats121-expected.txt >/dev/null; then
  missing="$(comm -13 /tmp/ats121-given.txt /tmp/ats121-expected.txt | wc -l | tr -d ' ')"
  extra="$(comm -23 /tmp/ats121-given.txt /tmp/ats121-expected.txt | wc -l | tr -d ' ')"
  rm -f /tmp/ats121-given.txt /tmp/ats121-expected.txt
  fail "uuids is not the set of ci-old entries ($missing missing, $extra not signed by ci-old)."
fi
count="$(wc -l < /tmp/ats121-expected.txt | tr -d ' ')"
rm -f /tmp/ats121-given.txt /tmp/ats121-expected.txt
echo "PASS: all $count entries signed by ci-old are listed, and nothing else."
