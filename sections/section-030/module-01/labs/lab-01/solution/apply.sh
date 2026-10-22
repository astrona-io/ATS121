#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION' > /tmp/ats121-failed.txt
set -eu
. /setup/lab-lib.sh
for bundle in /lab/bundles/*.sigstore.json; do
  artifact="/lab/artifacts/$(basename "$bundle" .sigstore.json)"
  verify_with /lab/keys/release.pub "$artifact" "$bundle" || basename "$artifact"
done
IN_WORKSTATION
kubectl -n workstation create configmap bundle-check \
  --from-file=failed=/tmp/ats121-failed.txt \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f /tmp/ats121-failed.txt
