#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

answer="$(ws sh -s <<'IN_WORKSTATION'
set -eu
. /setup/lab-lib.sh
openssl dgst -sha256 -sign /lab/keys/notice.key -out /tmp/notice.sig /lab/artifacts/security-notice.txt
rekor-cli upload --artifact /lab/artifacts/security-notice.txt \
  --signature /tmp/notice.sig --public-key /lab/keys/notice.pub --pki-format x509 >/dev/null
id="$(uuids_for_hash "$(sha256_of /lab/artifacts/security-notice.txt)" | head -1)"
printf '%s %s\n' "$(entry_json "$id" | jq -r '.logIndex')" "$(short_id "$id")"
IN_WORKSTATION
)"
index="${answer%% *}"
uuid="${answer##* }"
kubectl -n workstation create configmap notice-entry \
  --from-literal=log-index="$index" --from-literal=uuid="$uuid" \
  --dry-run=client -o yaml | kubectl apply -f -
