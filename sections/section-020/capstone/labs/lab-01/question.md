# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Auditing

## Scenario

The `inventory` team signs its releases with the key `release`; its public key is `/lab/keys/release.pub` in the workstation pod. This morning a file called `inventory-2.0.0.txt` appeared in `/lab/artifacts/` next to the real releases, and it has an entry in the team's private Rekor. Nobody on the team signed it, and nobody has the key that did.

You are asked to write the first part of the incident report from the log alone.

## Your task

1. Find which public key signed `/lab/artifacts/inventory-2.0.0.txt`, using its Rekor entry.
2. List every entry in the log signed with that key.
3. Find the log index of that key's earliest entry.
4. Record your findings in a ConfigMap named `intruder-report` in the namespace `workstation`, with three keys:
   - `signer-public-key`: the PEM public key that signed `inventory-2.0.0.txt`, with its `BEGIN PUBLIC KEY` and `END PUBLIC KEY` lines.
   - `intruder-uuids`: the entry IDs of every entry signed with that key, one per line.
   - `first-intruder-index`: the smallest log index among those entries.

## Constraints

- Work from the log: the unknown key is not on any machine you can reach.
- Do not sign anything new, and do not change files in `/lab`.
- Do not restart the Rekor server pod.

## Done when

- `signer-public-key` is the key recorded in the log entry of `inventory-2.0.0.txt`.
- `intruder-uuids` holds every entry signed with that key, and nothing else.
- `first-intruder-index` is the log index of that key's earliest entry.
