# Overview: Monitor The Log (Playground)

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

- Save the current log state to `/lab/monitor/state.json` with `curl -s "$REKOR_URL/api/v1/log" | jq '{treeSize, rootHash}'`, sign a new file with `team-b` (remember `--signing-config /lab/signing-config.json` and `COSIGN_PASSWORD=lab-only-password`), and compute how many entries the log gained.
- Run `rekor-cli loginfo` twice, with an entry added between the runs, and explain why the second run can check consistency.
- Write a state file with a tree size larger than the log and check that your consistency function raises an alert.
- List the entries of `team-b` with a log index at or above a saved size, and compare their hashes with an approved list you write yourself.
