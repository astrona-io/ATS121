#!/usr/bin/env bash
# PASS when: unapproved-uuids lists exactly the team-a entries added since the saved state whose hash is not approved
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }
fail() { echo "FAIL: $*"; exit 1; }

given="$(answer unapproved-uuids monitor-report)"
[ -n "$given" ] || fail "ConfigMap monitor-report has no key unapproved-uuids."
printf '%s\n' "$given" | sed '/^[[:space:]]*$/d' | while read -r id; do short_id "$id"; echo; done | sed '/^$/d' | sort -u > /tmp/ats121-given.txt
ws sh -s <<'IN_WORKSTATION' | sed '/^$/d' | sort -u > /tmp/ats121-expected.txt
. /setup/lab-lib.sh
saved="$(jq -r .treeSize /lab/monitor/state.json)"
for id in $(uuids_for_key /lab/keys/team-a.pub); do
  entry="$(entry_json "$id")"
  index="$(printf '%s' "$entry" | jq -r '.logIndex')"
  [ "$index" -ge "$saved" ] || continue
  hash="$(printf '%s' "$entry" | jq -r '.body' | base64 -d | jq -r '.spec.data.hash.value')"
  grep -qx "$hash" /lab/monitor/approved-hashes.txt || { short_id "$id"; echo; }
done
IN_WORKSTATION
[ -s /tmp/ats121-expected.txt ] || { rm -f /tmp/ats121-given.txt /tmp/ats121-expected.txt; fail "The grader found no unapproved entry; is the search index up?"; }
if ! diff -q /tmp/ats121-given.txt /tmp/ats121-expected.txt >/dev/null; then
  missing="$(comm -13 /tmp/ats121-given.txt /tmp/ats121-expected.txt | wc -l | tr -d ' ')"
  extra="$(comm -23 /tmp/ats121-given.txt /tmp/ats121-expected.txt | wc -l | tr -d ' ')"
  rm -f /tmp/ats121-given.txt /tmp/ats121-expected.txt
  fail "unapproved-uuids is not the expected set ($missing missing, $extra wrong)."
fi
count="$(wc -l < /tmp/ats121-expected.txt | tr -d ' ')"
rm -f /tmp/ats121-given.txt /tmp/ats121-expected.txt
echo "PASS: the $count unapproved new entry of team-a is listed, and nothing else."
