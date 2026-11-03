# Overview: Create And Read Rekor Entries (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private transparency log and a workstation pod, signs two example artifacts so the log has entries, and leaves one artifact unsigned so you can upload an entry by hand, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Rekor v1.5.4**, Sigstore's transparency log, in the namespace `rekor-system`, with its Trillian storage in `trillian-system` and Redis for the search index. Inside the cluster it answers at `http://rekor.localtest.me`. It uses plain HTTP and keeps its signing key in memory, which is only acceptable in a lab: restarting the Rekor server pod gives the log a new key.
- A **workstation** pod in the namespace `workstation` with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl`, `jq` and `openssl`. `rekor-cli` talks to the private log by default.
- In `/lab` in the workstation:

  | Path | What it is |
  | --- | --- |
  | `/lab/rekor.pub`, `/lab/signing-config.json`, `/lab/trusted-root.json` | The lab trust files |
  | `/lab/keys/team-a.key`, `team-a.pub` | A `cosign` key pair; its password is `lab-only-password` (lab-only) |
  | `/lab/keys/demo.key`, `demo.pub` | An ECDSA P-256 key pair made with `openssl`, in PEM format |
  | `/lab/artifacts/release-1.0.0.txt`, `release-1.1.0.txt` | Signed with `team-a`; they have entries |
  | `/lab/artifacts/demo-note.txt` | Not in the log yet |

## Helpers

Open a shell in the workstation and run the commands there:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Inside that shell, paste these helpers once. `body_of` prints the decoded body of an entry. `entry_of` prints the entry ID of a file.

```sh
body_of() { curl -s "$REKOR_URL/api/v1/log/entries/$1" | jq -r '.[].body' | base64 -d | jq .; }
entry_of() { rekor-cli search --artifact "$1" | head -1; }
```

## Practice tasks

- Run `kubectl -n rekor-system get pods` and `kubectl -n trillian-system get pods` on your machine, and name what each pod does.
- Use `body_of` on the entry of `release-1.0.0.txt` and find the kind, the apiVersion, the hash and the public key. Compare the key with `/lab/keys/team-a.pub`.
- Sign `demo-note.txt` with `openssl dgst -sha256 -sign`, upload it with `rekor-cli upload --pki-format x509`, and verify it with `rekor-cli verify --uuid`.
- Upload the same entry again and read the error. Then sign the file again, upload the new signature and count the entries `rekor-cli search --artifact` returns.
- Convert `treeID` from `curl -s "$REKOR_URL/api/v1/log"` to 16 hexadecimal characters with `printf '%016x\n'` and compare it with the start of an 80-character entry ID.
- Read the entry at index 0 with `curl -s "$REKOR_URL/api/v1/log/entries?logIndex=0"` and compare its key with the entry ID from a search.
