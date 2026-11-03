#!/usr/bin/env bash
# PASS when: attestation-entry records the log index and the entry kind that the bundle and Rekor show
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }
fail() { echo "FAIL: $*"; exit 1; }

bundle=/lab/bundles/inventory-5.0.0.att.sigstore.json
kind="$(answer kind attestation-entry | tr -d ' \r\n')"
index="$(answer log-index attestation-entry | tr -d ' \r\n')"
[ -n "$kind" ] || fail "ConfigMap attestation-entry has no key kind."
[ -n "$index" ] || fail "ConfigMap attestation-entry has no key log-index."
bundle_index="$(ws sh -c 'jq -r ".verificationMaterial.tlogEntries[0].logIndex" '"$bundle")"
[ "$index" = "$bundle_index" ] || fail "log-index does not match the log entry in the bundle."
entry_kind="$(ws sh -c 'curl -sf "$REKOR_URL/api/v1/log/entries?logIndex='"$index"'" | jq -r ".[].body" | base64 -d | jq -r .kind')"
[ -n "$entry_kind" ] || fail "Rekor has no entry at log index $index."
[ "$kind" = "$entry_kind" ] || fail "kind is not the kind of the entry Rekor holds at that index."
echo "PASS: kind and log-index match the entry in Rekor."
