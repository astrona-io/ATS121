#!/usr/bin/env bash
# PASS when: new-entries equals the current tree size minus the saved tree size
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

given="$(answer new-entries monitor-report | tr -d ' \r\n')"
[ -n "$given" ] || fail "ConfigMap monitor-report has no key new-entries."
expected="$(ws sh -c 'saved="$(jq -r .treeSize /lab/monitor/state.json)"; current="$(curl -sf "$REKOR_URL/api/v1/log" | jq -r .treeSize)"; echo $((current - saved))' | tr -d ' \r\n')"
[ -n "$expected" ] || fail "Could not read the tree size from Rekor."
[ "$given" = "$expected" ] || fail "new-entries is $given, but the log gained a different number of entries since the saved state."
echo "PASS: new-entries is $expected."
