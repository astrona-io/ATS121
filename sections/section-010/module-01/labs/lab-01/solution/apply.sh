#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

answer="$(ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
id="$(uuids_for_hash "$(sha256_of /lab/artifacts/inventory-1.2.0.tar.gz.txt)" | head -1)"
index="$(entry_json "$id" | jq -r '.logIndex')"
rekor-cli verify --log-index "$index" >/dev/null
printf '%s %s\n' "$index" "$(short_id "$id")"
IN_WORKSTATION
)"
index="${answer%% *}"
uuid="${answer##* }"
kubectl -n workstation create configmap entry-answer \
  --from-literal=log-index="$index" --from-literal=uuid="$uuid" \
  --dry-run=client -o yaml | kubectl apply -f -
