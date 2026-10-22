#!/usr/bin/env bash
# PASS when: confirms every release artifact has a bundle that verifies with the release key
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

result="$(ws sh -s <<'IN_WORKSTATION'
. /setup/lab-lib.sh
for name in inventory-4.0.0 inventory-4.0.1 inventory-4.1.0; do
  artifact="/lab/release/$name.txt"
  bundle="$artifact.sigstore.json"
  [ -f "$bundle" ] || { echo "missing $name"; continue; }
  verify_with /lab/keys/release.pub "$artifact" "$bundle" || echo "bad $name"
done
IN_WORKSTATION
)"
[ -z "$result" ] || fail "Release bundles are not complete: $(printf '%s' "$result" | tr '\n' ';')"
echo "PASS: all three release artifacts have a bundle that verifies with the release key."
