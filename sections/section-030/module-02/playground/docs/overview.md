# Overview: Attestations In The Log (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private transparency log and a workstation pod, signs one example artifact and prepares a second one for attestation, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Rekor v1.5.4** in the namespace `rekor-system`. Inside the cluster it answers at `http://rekor.localtest.me`. Plain HTTP and an in-memory signing key: lab-only. Do not restart the Rekor server pod.
- A **workstation** pod in the namespace `workstation` with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl` and `jq`.
- In `/lab`:

  | Path | What it is |
  | --- | --- |
  | `/lab/signing-config.json`, `/lab/trusted-root.json` | The lab trust files for the private log |
  | `/lab/keys/release.key`, `release.pub` | The release key pair; password `lab-only-password` (lab-only) |
  | `/lab/artifacts/inventory-4.0.0.txt` | An artifact signed with `release`; its bundle is in `/lab/bundles` |
  | `/lab/artifacts/inventory-4.1.0.txt` | An artifact with no signature or attestation yet |
  | `/lab/predicate.json` | A small check result to use as an attestation predicate |

## Helpers

Open a shell in the workstation and run the commands there:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Inside that shell, paste these helpers once. `payload_of` prints the decoded statement of an attestation bundle. `entry_kind_of` prints the entry kind and log index recorded in a bundle.

```sh
payload_of() { jq -r '.dsseEnvelope.payload' "$1" | base64 -d | jq .; }
entry_kind_of() { jq '.verificationMaterial.tlogEntries[0] | {logIndex, kindVersion}' "$1"; }
```

## Practice tasks

- Attest `inventory-4.1.0.txt` with `cosign attest-blob`, then run `payload_of` and `entry_kind_of` on the bundle.
- Verify the attestation with `cosign verify-blob-attestation`, then repeat with a wrong `--type` and read the error.
- Attest the same file with a second predicate type and list the entries of `release` with `rekor-cli search --public-key`.
- Compare the SHA-256 hash of the decoded payload with `spec.payloadHash.value` in the log entry.
