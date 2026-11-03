# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Bundles

## Scenario

The release process checked the artifact `/lab/artifacts/inventory-5.0.0.txt` and wrote the result of the check to `/lab/predicate.json` in the workstation pod. The team's release key pair is `/lab/keys/release.key` and `/lab/keys/release.pub`. The password of the private key is `lab-only-password`.

The team wants the check result recorded as a signed attestation in its private Rekor, so that a consumer can verify it offline.

## Your task

1. Create an attestation of `inventory-5.0.0.txt` that uses `/lab/predicate.json` as its predicate and the predicate type `https://astrona.io/release-check/v1`. Sign it with the `release` key, upload it to the private Rekor, and write the bundle to `/lab/bundles/inventory-5.0.0.att.sigstore.json`.
2. Verify the bundle offline against the lab trusted root.
3. Record the log entry in a ConfigMap named `attestation-entry` in the namespace `workstation`, with two keys:
   - `kind`: the kind of the Rekor entry that holds the attestation.
   - `log-index`: the log index of that entry, as a plain number.

## Constraints

- Use the lab trust files `/lab/signing-config.json` and `/lab/trusted-root.json`. Do not verify with `--insecure-ignore-tlog`.
- Do not change `/lab/predicate.json` or the artifact.
- Do not restart the Rekor server pod.

## Done when

- The bundle verifies offline as an attestation of `inventory-5.0.0.txt` with the given predicate type.
- `kind` and `log-index` match the entry that Rekor holds.
