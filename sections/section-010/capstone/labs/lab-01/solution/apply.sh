#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

answer="$(ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
size="$(jq -r '.treeSize' /lab/checkpoints/candidate-a.json)"
real="$(curl -sf "$REKOR_URL/api/v1/log/proof?firstSize=1&lastSize=$size" | jq -r '.rootHash')"
genuine=""
for c in candidate-a candidate-b; do
  [ "$(jq -r '.rootHash' "/lab/checkpoints/$c.json")" = "$real" ] && genuine="$c"
done
now="$(curl -sf "$REKOR_URL/api/v1/log" | jq -r '.treeSize')"
printf '%s %s %s\n' "$genuine" "$now" "$(( now - size ))"
IN_WORKSTATION
)"
set -- $answer
kubectl -n workstation create configmap growth-answer \
  --from-literal=genuine="$1" --from-literal=tree-size="$2" --from-literal=entries-added="$3" \
  --dry-run=client -o yaml | kubectl apply -f -
