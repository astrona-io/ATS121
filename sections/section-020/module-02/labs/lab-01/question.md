# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Auditing

## Scenario

The team runs a monitor against its private Rekor. The monitor saved its state at the end of the last run, in `/lab/monitor/state.json` in the workstation pod: the tree size and root hash of the log at that time. The list of artifact hashes that the release process approved is in `/lab/monitor/approved-hashes.txt`, one lower-case SHA-256 hash per line.

Since the last run, the log has grown. The team watches the key `team-a`, whose public key is `/lab/keys/team-a.pub`. Read the saved state:

```sh
kubectl -n workstation exec deploy/workstation -- cat /lab/monitor/state.json
```

## Your task

1. Find out how many entries the log gained since the saved state.
2. List the entries signed with `team-a` that were added since the saved state and whose artifact hash is not in the approved list.
3. Record your findings in a ConfigMap named `monitor-report` in the namespace `workstation`, with two keys:
   - `new-entries`: the number of entries the log gained, as a plain number.
   - `unapproved-uuids`: the entry IDs of the unapproved new `team-a` entries, one per line. 64-character UUIDs and longer entry IDs both count.

## Constraints

- Count only entries added since the saved state. An unapproved entry from before the saved state is not part of the report.
- Do not sign anything new, and do not change files in `/lab`.
- Do not restart the Rekor server pod.

## Done when

- `new-entries` equals the current tree size minus the saved tree size.
- `unapproved-uuids` holds every new `team-a` entry whose hash is not approved, and nothing else.
