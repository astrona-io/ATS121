# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Proofs

## Scenario

The `inventory` team signed four releases with its `release` key, one after the other but not in version order, and every signature went to the team's private Rekor. An auditor now asks for proof that release 1.2.0 was recorded in the log. The bundles were not kept, so the evidence has to come from the log itself.

The artifacts are in the workstation pod, in `/lab/artifacts/`:

```sh
kubectl -n workstation exec deploy/workstation -- ls /lab/artifacts
```

## Your task

1. Find the Rekor entry that records `/lab/artifacts/inventory-1.2.0.tar.gz.txt`.
2. Verify that entry's inclusion proof with `rekor-cli`.
3. Record the entry for the auditor in a ConfigMap named `entry-answer` in the namespace `workstation`, with two keys:
   - `log-index`: the entry's log index, a number.
   - `uuid`: the entry's UUID (the 64-character UUID or the longer entry ID both count).

## Constraints

- Find the existing entry. Do not sign the artifact again: a new signature creates a new entry with a different index, and it is graded as wrong.
- Do not change the files in `/lab/artifacts/`.
- Do not restart the Rekor server pod.

## Done when

- The ConfigMap `entry-answer` exists in `workstation` with the keys `log-index` and `uuid`.
- The recorded index and UUID belong to the entry of `inventory-1.2.0.tar.gz.txt`.
- `rekor-cli verify --log-index <your index>` verifies the inclusion proof.
