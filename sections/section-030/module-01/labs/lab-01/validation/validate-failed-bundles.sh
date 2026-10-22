#!/usr/bin/env bash
# PASS when: confirms failed lists exactly the artifacts whose bundles do not verify offline
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

given="$(answer failed bundle-check)"
[ -n "$given" ] || fail "ConfigMap bundle-check has no key failed."
printf '%s\n' "$given" | sed 's/[[:space:]]//g; /^$/d' | xargs -n1 basename | sort -u > /tmp/ats121-given.txt
ws sh -s <<'IN_WORKSTATION' | sort -u > /tmp/ats121-expected.txt
. /setup/lab-lib.sh
for bundle in /lab/bundles/*.sigstore.json; do
  artifact="/lab/artifacts/$(basename "$bundle" .sigstore.json)"
  verify_with /lab/keys/release.pub "$artifact" "$bundle" || basename "$artifact"
done
IN_WORKSTATION
count="$(wc -l < /tmp/ats121-expected.txt | tr -d ' ')"
same=0; diff -q /tmp/ats121-given.txt /tmp/ats121-expected.txt >/dev/null && same=1
rm -f /tmp/ats121-given.txt /tmp/ats121-expected.txt
[ "$count" = 2 ] || fail "Expected two failing bundles in /lab, found $count. Were the files in /lab changed?"
[ "$same" = 1 ] || fail "failed does not name exactly the two artifacts that do not verify."
echo "PASS: both failing artifacts are named, and no others."
