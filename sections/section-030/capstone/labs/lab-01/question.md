# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Rekor v2

## Scenario

The `inventory` team is moving to a Rekor v2 log. Rekor v2 has no search index, so the team decided that every release artifact must have a bundle with its full log evidence, kept next to the artifact. Today that is not true for the current release in `/lab/release/` in the workstation pod:

```sh
kubectl -n workstation exec deploy/workstation -- ls -l /lab/release
```

`inventory-4.0.0.txt` has a bundle, but it was signed with the retired CI key, whose private key was destroyed. `inventory-4.0.1.txt` and `inventory-4.1.0.txt` have no bundle. The team's current signing key is `/lab/keys/release.key` (password `lab-only-password`, lab-only), and its public key is `/lab/keys/release.pub`.

## Your task

1. Make sure each of the three release artifacts in `/lab/release/` has a bundle `/lab/release/<name>.sigstore.json` that verifies offline with `/lab/keys/release.pub` and `/lab/trusted-root.json`.
2. Each bundle must be a v0.3 bundle that carries an inclusion proof with its checkpoint. Sign against the team's private log with `/lab/signing-config.json`.
3. Write the signing config the team will use for Rekor v2 to `/lab/signing-config-v2.json`. It must list one Rekor log with:
   - URL `http://rekor-v2.localtest.me`
   - major API version 2
   - operator `astrona-lab`
   - validity start `2026-10-01T00:00:00Z`

## Constraints

- Do not change the artifacts in `/lab/release/`.
- Do not verify with `--insecure-ignore-tlog`.
- Do not restart the Rekor server pod. No Rekor v2 runs in this lab; do not sign with the Rekor v2 signing config.

## Done when

- All three release artifacts have bundles that verify with the release key and the lab trust root.
- Each bundle is a v0.3 bundle with an inclusion proof and a checkpoint.
- `/lab/signing-config-v2.json` lists the Rekor v2 log with the values above.
