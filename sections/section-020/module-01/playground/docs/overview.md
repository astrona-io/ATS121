# Overview: Search And Audit Rekor Entries (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private transparency log and a workstation pod, signs three example artifacts with two keys, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Rekor v1.5.4** in the namespace `rekor-system`, with Redis for the search index. Inside the cluster it answers at `http://rekor.localtest.me`. Plain HTTP and an in-memory signing key: lab-only. Do not restart the Rekor server pod.
- A **workstation** pod in the namespace `workstation` with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl` and `jq`.
- In `/lab`: the lab trust files (`rekor.pub`, `signing-config.json`, `trusted-root.json`), the key pairs `team-a` and `team-b` (password `lab-only-password`, lab-only), and three artifacts:

  | Artifact | Signed with |
  | --- | --- |
  | `/lab/artifacts/api-1.0.0.txt` | `team-a` |
  | `/lab/artifacts/api-1.1.0.txt` | `team-a` |
  | `/lab/artifacts/web-1.0.0.txt` | `team-b` |

## Helpers

Open a shell in the workstation and run the commands there:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Inside that shell, paste these helpers once. `entries_of_key` lists the entry IDs signed by a public key file. `body_of` prints the decoded body of an entry. `signer_of` prints the PEM public key that signed an entry.

```sh
entries_of_key() { rekor-cli search --public-key "$1" --pki-format x509; }
body_of() { curl -s "$REKOR_URL/api/v1/log/entries/$1" | jq -r '.[].body' | base64 -d; }
signer_of() { body_of "$1" | jq -r '.spec.signature.publicKey.content' | base64 -d; }
```

Use them like this: `entries_of_key /lab/keys/team-a.pub`, `body_of <ID> | jq .`, `signer_of <ID>`.

## Practice tasks

- Count the entries of `team-a` and `team-b`. Then sign a new file with `team-b` (remember `--signing-config /lab/signing-config.json` and `COSIGN_PASSWORD=lab-only-password`) and count again.
- Sign the same file with both keys and search for it by hash. Explain why you get two entries.
- For every entry of `team-a`, print the artifact hash and the log index, and sort them by index.
- Use `signer_of` on the entry of `web-1.0.0.txt` and compare the result with `/lab/keys/team-b.pub` using `diff`.
- Combine a key and a hash in one search with `--operator and`, and compare it with each search on its own.
