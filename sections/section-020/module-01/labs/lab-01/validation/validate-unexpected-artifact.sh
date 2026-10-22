#!/usr/bin/env bash
# PASS when: confirms unexpected-sha256 is the hash of the ci-old artifact that is not in the release manifest
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

given="$(answer unexpected-sha256 leak-audit | tr -d ' \r\n' | tr 'A-F' 'a-f')"
[ -n "$given" ] || fail "ConfigMap leak-audit has no key unexpected-sha256."
expected="$(ws sh -s <<'IN_WORKSTATION'
. /setup/lab-lib.sh
cut -d' ' -f1 /lab/release-manifest.txt > /tmp/shipped.txt
for id in $(uuids_for_key /lab/keys/ci-old.pub); do
  hash="$(entry_json "$id" | jq -r '.body' | base64 -d | jq -r '.spec.data.hash.value')"
  grep -qx "$hash" /tmp/shipped.txt || echo "$hash"
done
IN_WORKSTATION
)"
[ -n "$expected" ] || fail "Could not compute the unexpected artifact from the log."
[ "$given" = "$expected" ] || fail "unexpected-sha256 is not the hash of the artifact ci-old signed outside the release."
echo "PASS: the unexpected artifact is identified by its hash."
