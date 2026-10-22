# Overview: Read And Prove A Transparency Log (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private transparency log and a workstation pod, signs two example artifacts so the log has entries, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Rekor v1.5.4**, Sigstore's transparency log, in the namespace `rekor-system`, with its Trillian storage in `trillian-system` and Redis for the search index. Inside the cluster it answers at `http://rekor.localtest.me`. It uses plain HTTP and keeps its signing key in memory, which is only acceptable in a lab: restarting the Rekor server pod gives the log a new key.
- A **workstation** pod in the namespace `workstation` with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl`, `jq` and `openssl`. `rekor-cli` talks to the private log by default.
- In `/lab` in the workstation:

  | Path | What it is |
  | --- | --- |
  | `/lab/rekor.pub` | The private log's public key |
  | `/lab/signing-config.json` | Tells `cosign` to send entries to the private log |
  | `/lab/trusted-root.json` | Tells `cosign` to trust the private log's key when it verifies |
  | `/lab/keys/team-a.key`, `team-a.pub` | An example key pair; its password is `lab-only-password` (lab-only) |
  | `/lab/artifacts/` | `inventory-1.0.0.txt` and `inventory-1.1.0.txt`, both signed with `team-a` |
  | `/lab/bundles/` | The bundle `cosign` wrote for each signature |

## Helpers

Open a shell in the workstation and run the commands there:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Inside that shell, paste these helpers once. `log_state` prints the tree size and root hash. `entry_of` prints the entry ID of a file. `leaf_hash_of` computes the RFC 6962 leaf hash of an entry from its stored body.

```sh
log_state() { curl -s "$REKOR_URL/api/v1/log" | jq '{treeSize, rootHash}'; }
entry_of() { rekor-cli search --artifact "$1" | head -1; }
leaf_hash_of() {
  body="$(curl -s "$REKOR_URL/api/v1/log/entries/$1" | jq -r '.[].body')"
  { printf '\000'; printf '%s' "$body" | base64 -d; } | sha256sum
}
```

Use them like this: `log_state`, `entry_of /lab/artifacts/inventory-1.0.0.txt`, `leaf_hash_of "$(entry_of /lab/artifacts/inventory-1.0.0.txt)"`.

## Practice tasks

- Run `log_state`, sign a new file with `team-a` and the signing config, and run it again. Predict the new tree size before you look.
- Find the entry of `inventory-1.0.0.txt`, compute its leaf hash with `leaf_hash_of`, and compare it with the last 64 characters of the entry ID.
- Run `rekor-cli verify --log-index 0` and `rekor-cli verify --log-index 1`, and compare the sibling hashes in their inclusion proofs.
- Ask for a consistency proof from size 1 to the current size with `rekor-cli logproof`, and compare its root hash with `log_state`.
- Change one character in `inventory-1.1.0.txt` and search for it again. Explain why the search finds nothing.
- Read the log's checkpoint with `curl -s "$REKOR_URL/api/v1/log" | jq -r .signedTreeHead` and find the tree size and root hash in it.
