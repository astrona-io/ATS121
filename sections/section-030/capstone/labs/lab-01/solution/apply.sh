#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
for artifact in /lab/release/inventory-4.0.0.txt /lab/release/inventory-4.0.1.txt /lab/release/inventory-4.1.0.txt; do
  sign_with release "$artifact" "$artifact.sigstore.json"
  verify_with /lab/keys/release.pub "$artifact" "$artifact.sigstore.json"
done
cosign signing-config create \
  --rekor="url=http://rekor-v2.localtest.me,api-version=2,start-time=2026-10-01T00:00:00Z,operator=astrona-lab" \
  --rekor-config=ANY \
  --out /lab/signing-config-v2.json
IN_WORKSTATION
