#!/usr/bin/env bash
# PASS when: confirms each release bundle is a v0.3 bundle with an inclusion proof and a checkpoint
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

result="$(ws sh -s <<'IN_WORKSTATION'
for name in inventory-4.0.0 inventory-4.0.1 inventory-4.1.0; do
  bundle="/lab/release/$name.txt.sigstore.json"
  jq -e '.mediaType == "application/vnd.dev.sigstore.bundle.v0.3+json"
         and (.verificationMaterial.tlogEntries[0].inclusionProof.hashes != null)
         and (.verificationMaterial.tlogEntries[0].inclusionProof.checkpoint.envelope | length > 0)' "$bundle" >/dev/null 2>&1 \
    || echo "$name"
done
IN_WORKSTATION
)"
[ -z "$result" ] || fail "These bundles lack v0.3 log evidence: $(printf '%s' "$result" | tr '\n' ' ')"
echo "PASS: every release bundle carries its inclusion proof and checkpoint."
