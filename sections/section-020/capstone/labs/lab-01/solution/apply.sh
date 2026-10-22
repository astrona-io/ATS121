#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION' > /tmp/ats121-intruder.txt
set -eu
. /setup/lab-lib.sh
id="$(uuids_for_hash "$(sha256_of /lab/artifacts/inventory-2.0.0.txt)" | head -1)"
entry_json "$id" | jq -r '.body' | base64 -d | jq -r '.spec.signature.publicKey.content' | base64 -d > /tmp/intruder.pub
min=""
: > /tmp/ids.txt
for other in $(uuids_for_key /tmp/intruder.pub); do
  short_id "$other" >> /tmp/ids.txt; echo >> /tmp/ids.txt
  index="$(entry_json "$other" | jq -r '.logIndex')"
  if [ -z "$min" ] || [ "$index" -lt "$min" ]; then min="$index"; fi
done
echo "MIN=$min"
echo "IDS_BEGIN"; sort -u /tmp/ids.txt | sed '/^$/d'; echo "IDS_END"
echo "KEY_BEGIN"; cat /tmp/intruder.pub; echo "KEY_END"
IN_WORKSTATION
min="$(sed -n 's/^MIN=//p' /tmp/ats121-intruder.txt)"
sed -n '/^IDS_BEGIN$/,/^IDS_END$/p' /tmp/ats121-intruder.txt | sed '1d;$d' > /tmp/ats121-ids.txt
sed -n '/^KEY_BEGIN$/,/^KEY_END$/p' /tmp/ats121-intruder.txt | sed '1d;$d' > /tmp/ats121-key.pem
kubectl -n workstation create configmap intruder-report \
  --from-file=signer-public-key=/tmp/ats121-key.pem \
  --from-file=intruder-uuids=/tmp/ats121-ids.txt \
  --from-literal=first-intruder-index="$min" \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f /tmp/ats121-intruder.txt /tmp/ats121-ids.txt /tmp/ats121-key.pem
