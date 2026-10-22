#!/usr/bin/env bash
# PASS when: confirms /lab/signing-config-v2.json points cosign at a Rekor v2 log
set -uo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }

# answer KEY CONFIGMAP: prints one key of an answer ConfigMap in workstation.
answer() { kubectl -n workstation get configmap "$2" -o jsonpath="{.data.$1}" 2>/dev/null; }

# short_id ID: the last 64 hex characters of an entry ID, lower case.
short_id() { printf '%s' "$1" | tr -d ' \r\n' | tr 'A-F' 'a-f' | rev | cut -c1-64 | rev; }

fail() { echo "FAIL: $*"; exit 1; }

ws jq -e '
  (.rekorTlogUrls | length) >= 1
  and .rekorTlogUrls[0].url == "http://rekor-v2.localtest.me"
  and .rekorTlogUrls[0].majorApiVersion == 2
  and .rekorTlogUrls[0].operator == "astrona-lab"
  and (.rekorTlogUrls[0].validFor.start | startswith("2026-10-01"))' /lab/signing-config-v2.json >/dev/null 2>&1 \
  || fail "/lab/signing-config-v2.json does not list http://rekor-v2.localtest.me with API version 2, operator astrona-lab, start 2026-10-01."
echo "PASS: the signing config for Rekor v2 is correct."
