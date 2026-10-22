#!/usr/bin/env bash
# PASS when: confirms the other three bundles still verify with the release key and the lab trust root
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

ok="$(ws sh -s <<'IN_WORKSTATION'
. /setup/lab-lib.sh
n=0
for bundle in /lab/bundles/*.sigstore.json; do
  artifact="/lab/artifacts/$(basename "$bundle" .sigstore.json)"
  verify_with /lab/keys/release.pub "$artifact" "$bundle" && n=$((n + 1))
done
echo "$n"
IN_WORKSTATION
)"
[ "$ok" = 3 ] || fail "Expected three bundles that verify, found $ok. Do not re-sign or edit the files."
echo "PASS: the three good bundles verify offline."
