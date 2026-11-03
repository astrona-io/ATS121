#!/usr/bin/env bash
# PASS when: the security notice has an entry in Rekor that Rekor can prove
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf "%s" "$1" | tr -d " 
" | tr "A-F" "a-f" | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

result="$(ws sh -s <<'IN_WORKSTATION'
. /setup/lab-lib.sh
ids="$(uuids_for_hash "$(sha256_of /lab/artifacts/security-notice.txt)")"
[ -n "$ids" ] || { echo NONE; exit 0; }
id="$(printf '%s\n' "$ids" | head -1)"
if rekor-cli verify --uuid "$id" >/dev/null 2>&1; then echo OK; else echo BADPROOF; fi
IN_WORKSTATION
)"
case "$result" in
  *NONE*) fail "Rekor has no entry for /lab/artifacts/security-notice.txt." ;;
  *BADPROOF*) fail "The entry exists, but its inclusion proof does not verify." ;;
esac
echo "PASS: security-notice.txt has a verified entry in Rekor."
