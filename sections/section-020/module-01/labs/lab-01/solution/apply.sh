#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION' > /tmp/ats121-leak.txt
set -eu
. /setup/lab-lib.sh
for id in $(uuids_for_key /lab/keys/ci-old.pub); do short_id "$id"; echo; done | sort -u > /tmp/uuids.txt
cut -d' ' -f1 /lab/release-manifest.txt | sort -u > /tmp/shipped.txt
unexpected=""
for id in $(cat /tmp/uuids.txt); do
  hash="$(entry_json "$id" | jq -r '.body' | base64 -d | jq -r '.spec.data.hash.value')"
  grep -qx "$hash" /tmp/shipped.txt || unexpected="$hash"
done
echo "UNEXPECTED=$unexpected"
cat /tmp/uuids.txt
IN_WORKSTATION
unexpected="$(sed -n 's/^UNEXPECTED=//p' /tmp/ats121-leak.txt)"
grep -v '^UNEXPECTED=' /tmp/ats121-leak.txt > /tmp/ats121-uuids.txt
kubectl -n workstation create configmap leak-audit \
  --from-file=uuids=/tmp/ats121-uuids.txt --from-literal=unexpected-sha256="$unexpected" \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f /tmp/ats121-leak.txt /tmp/ats121-uuids.txt
