#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

ws sh -s <<'IN_WORKSTATION' > /tmp/ats121-monitor.txt
set -eu
. /setup/lab-lib.sh
saved="$(jq -r .treeSize /lab/monitor/state.json)"
current="$(curl -sf "$REKOR_URL/api/v1/log" | jq -r .treeSize)"
echo "NEW=$((current - saved))"
for id in $(uuids_for_key /lab/keys/team-a.pub); do
  entry="$(entry_json "$id")"
  index="$(printf '%s' "$entry" | jq -r '.logIndex')"
  [ "$index" -ge "$saved" ] || continue
  hash="$(printf '%s' "$entry" | jq -r '.body' | base64 -d | jq -r '.spec.data.hash.value')"
  grep -qx "$hash" /lab/monitor/approved-hashes.txt || short_id "$id"
done
IN_WORKSTATION
new="$(sed -n 's/^NEW=//p' /tmp/ats121-monitor.txt)"
grep -v '^NEW=' /tmp/ats121-monitor.txt > /tmp/ats121-unapproved.txt
kubectl -n workstation create configmap monitor-report \
  --from-literal=new-entries="$new" --from-file=unapproved-uuids=/tmp/ats121-unapproved.txt \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f /tmp/ats121-monitor.txt /tmp/ats121-unapproved.txt
