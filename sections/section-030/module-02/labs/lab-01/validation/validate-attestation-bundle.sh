#!/usr/bin/env bash
# PASS when: the attestation bundle verifies offline with the requested predicate type and is about inventory-5.0.0.txt
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
fail() { echo "FAIL: $*"; exit 1; }

bundle=/lab/bundles/inventory-5.0.0.att.sigstore.json
ws test -s "$bundle" || fail "The bundle $bundle does not exist."
ws cosign verify-blob-attestation --key /lab/keys/release.pub \
  --trusted-root /lab/trusted-root.json --bundle "$bundle" \
  --type https://astrona.io/release-check/v1 \
  /lab/artifacts/inventory-5.0.0.txt >/dev/null 2>&1 \
  || fail "The bundle does not verify as an attestation of inventory-5.0.0.txt with the type https://astrona.io/release-check/v1."
ws sh -c 'jq -e ".verificationMaterial.tlogEntries | length >= 1" '"$bundle"' >/dev/null' \
  || fail "The bundle has no log entry."
predicate="$(ws sh -c 'jq -r ".dsseEnvelope.payload" '"$bundle"' | base64 -d | jq -c .predicate')"
expected="$(ws sh -c 'jq -c . /lab/predicate.json')"
[ "$predicate" = "$expected" ] || fail "The predicate in the bundle is not the content of /lab/predicate.json."
echo "PASS: the attestation bundle verifies offline and carries the lab predicate."
