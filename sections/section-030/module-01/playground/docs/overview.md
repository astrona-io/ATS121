# Overview: Verify Bundles Offline And Prepare For Rekor v2 (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private transparency log and a workstation pod, signs two example artifacts and keeps their bundles, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Rekor v1.5.4** in the namespace `rekor-system`. Inside the cluster it answers at `http://rekor.localtest.me`. Plain HTTP and an in-memory signing key: lab-only. Do not restart the Rekor server pod.
- A **workstation** pod in the namespace `workstation` with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl` and `jq`.
- In `/lab`:

  | Path | What it is |
  | --- | --- |
  | `/lab/signing-config.json`, `/lab/trusted-root.json` | The lab trust files for the private log |
  | `/lab/keys/release.key`, `release.pub` | The release key pair; password `lab-only-password` (lab-only) |
  | `/lab/artifacts/inventory-3.0.0.txt`, `inventory-3.1.0.txt` | Two artifacts signed with `release` |
  | `/lab/bundles/*.sigstore.json` | Their v0.3 bundles |

## Helpers

Open a shell in the workstation and run the commands there:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Inside that shell, paste these helpers once. `verify_release` verifies one artifact with its bundle offline. `proof_of` prints the inclusion proof of a bundle.

```sh
verify_release() {
  cosign verify-blob --key /lab/keys/release.pub --trusted-root /lab/trusted-root.json \
    --bundle "/lab/bundles/$1.sigstore.json" "/lab/artifacts/$1"
}
proof_of() { jq '.verificationMaterial.tlogEntries[0].inclusionProof' "$1"; }
```

Use them like this: `verify_release inventory-3.1.0.txt`, `proof_of /lab/bundles/inventory-3.1.0.txt.sigstore.json`.

## Practice tasks

- Verify both artifacts, then verify one artifact with the other's bundle. Read which check fails.
- Change the `checkpoint.envelope` of a copy of a bundle and verify it. Compare the error with a changed sibling hash.
- Remove `inclusionProof` from a copy of a bundle with `jq 'del(.verificationMaterial.tlogEntries[0].inclusionProof)'` and verify it. Note what `cosign` says, then explain what evidence is left.
- Sign a new file with `release`, write its bundle, and compare its log index with the output of `rekor-cli search --artifact`.
- Write a signing config for a Rekor v2 log with `cosign signing-config create` and compare it with `/lab/signing-config.json`.
