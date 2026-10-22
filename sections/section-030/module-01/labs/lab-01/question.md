# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Bundles

## Scenario

The `inventory` team keeps a Sigstore bundle next to every release artifact. Before a release goes to customers, a gate verifies each bundle offline. Today the gate stopped the release: some bundles do not verify, and nobody knows which ones or why.

The artifacts and bundles are in the workstation pod:

```sh
kubectl -n workstation exec deploy/workstation -- ls /lab/artifacts /lab/bundles
```

Every bundle `/lab/bundles/<name>.sigstore.json` belongs to the artifact `/lab/artifacts/<name>`. The release key's public key is `/lab/keys/release.pub`, and the lab trust root is `/lab/trusted-root.json`.

## Your task

1. Verify every artifact against its bundle, offline, with the release public key and the lab trust root.
2. Record the artifacts that do **not** verify in a ConfigMap named `bundle-check` in the namespace `workstation`, with one key:
   - `failed`: the file names of the failing artifacts (for example `inventory-3.0.0.txt`), one per line.

## Constraints

- Keep every log check: do not use `--insecure-ignore-tlog`.
- Do not re-sign artifacts, edit bundles or change artifacts. The grader verifies the files in `/lab` again and expects exactly two failures and three passes.
- Do not restart the Rekor server pod.

## Done when

- `failed` names exactly the artifacts whose bundles do not verify, and no others.
- The other bundles still verify with the release key and the lab trust root.
