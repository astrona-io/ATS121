#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION' > /tmp/ats121-att.txt
set -eu
export COSIGN_PASSWORD=lab-only-password
cosign attest-blob --key /lab/keys/release.key \
  --predicate /lab/predicate.json \
  --type https://astrona.io/release-check/v1 \
  --signing-config /lab/signing-config.json \
  --trusted-root /lab/trusted-root.json \
  --bundle /lab/bundles/inventory-5.0.0.att.sigstore.json \
  --yes /lab/artifacts/inventory-5.0.0.txt >/dev/null 2>&1
cosign verify-blob-attestation --key /lab/keys/release.pub \
  --trusted-root /lab/trusted-root.json \
  --bundle /lab/bundles/inventory-5.0.0.att.sigstore.json \
  --type https://astrona.io/release-check/v1 \
  /lab/artifacts/inventory-5.0.0.txt >/dev/null 2>&1
echo "KIND=$(jq -r '.verificationMaterial.tlogEntries[0].kindVersion.kind' /lab/bundles/inventory-5.0.0.att.sigstore.json)"
echo "INDEX=$(jq -r '.verificationMaterial.tlogEntries[0].logIndex' /lab/bundles/inventory-5.0.0.att.sigstore.json)"
IN_WORKSTATION
kubectl -n workstation create configmap attestation-entry \
  --from-literal=kind="$(sed -n 's/^KIND=//p' /tmp/ats121-att.txt)" \
  --from-literal=log-index="$(sed -n 's/^INDEX=//p' /tmp/ats121-att.txt)" \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f /tmp/ats121-att.txt
