#!/usr/bin/env bash
# PASS when: confirms signer-public-key is the key that signed inventory-2.0.0.txt
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

kubectl -n workstation get configmap intruder-report -o jsonpath='{.data.signer-public-key}' > /tmp/ats121-given.pem 2>/dev/null
[ -s /tmp/ats121-given.pem ] || fail "ConfigMap intruder-report has no key signer-public-key."
expected="$(ws sh -s <<'IN_WORKSTATION'
. /setup/lab-lib.sh
id="$(uuids_for_hash "$(sha256_of /lab/artifacts/inventory-2.0.0.txt)" | head -1)"
entry_json "$id" | jq -r '.body' | base64 -d | jq -r '.spec.signature.publicKey.content' | base64 -d
IN_WORKSTATION
)"
given_flat="$(tr -d ' \r\n' < /tmp/ats121-given.pem)"
expected_flat="$(printf '%s' "$expected" | tr -d ' \r\n')"
rm -f /tmp/ats121-given.pem
[ -n "$expected_flat" ] || fail "Could not read the signer of inventory-2.0.0.txt from the log."
[ "$given_flat" = "$expected_flat" ] || fail "signer-public-key is not the key in the log entry of inventory-2.0.0.txt."
echo "PASS: the signer of inventory-2.0.0.txt is identified."
