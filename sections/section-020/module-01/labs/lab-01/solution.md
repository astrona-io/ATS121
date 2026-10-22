# Solution: Find Every Entry Signed By A Leaked Key

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: `uuids` is exactly the set of entries Rekor's index returns for `ci-old.pub`, and `unexpected-sha256` is the hash of the one `ci-old` artifact that is not in the release manifest.

## Step 1: List the entries of the leaked key

Open a shell in the workstation:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Search the index by the public key. The key is a PEM public key in the X.509 format:

```sh
rekor-cli search --public-key /lab/keys/ci-old.pub --pki-format x509 | tee /tmp/ci-old-entries.txt
```

The answer has three entry IDs. Keep the file: it is the `uuids` answer.

## Step 2: Read the artifact hash of each entry

Decode each entry's body and print the artifact hash next to its ID:

```sh
for id in $(cat /tmp/ci-old-entries.txt); do
  hash="$(curl -s "$REKOR_URL/api/v1/log/entries/$id" | jq -r '.[].body' | base64 -d | jq -r '.spec.data.hash.value')"
  echo "$hash $id"
done
```

## Step 3: Compare with the release manifest

Look each hash up in the first column of the manifest:

```sh
cut -d' ' -f1 /lab/release-manifest.txt > /tmp/shipped.txt
for id in $(cat /tmp/ci-old-entries.txt); do
  hash="$(curl -s "$REKOR_URL/api/v1/log/entries/$id" | jq -r '.[].body' | base64 -d | jq -r '.spec.data.hash.value')"
  grep -qx "$hash" /tmp/shipped.txt || echo "unexpected: $hash"
done
```

Two of the three hashes are the `worker` releases in the manifest. The third is printed as unexpected: an artifact signed with the CI key that the team never released. Note that hash.

## Step 4: Copy the entry list out of the pod

Leave the shell with `exit`, then copy the list to your machine:

```sh
kubectl -n workstation exec deploy/workstation -- cat /tmp/ci-old-entries.txt > ci-old-entries.txt
```

## Step 5: Record the answer

Create the ConfigMap with the file and the hash you noted. Replace the placeholder:

```sh
kubectl -n workstation create configmap leak-audit \
  --from-file=uuids=ci-old-entries.txt \
  --from-literal=unexpected-sha256=<UNEXPECTED_HASH>
```

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Search by the names of the `worker` files | You only find the artifacts you already know; the unexpected one has no file any more |
| List every entry in the log | Entries of `team-a` and `team-b` are not part of the leak |
| Hash the files in `/lab/artifacts` | The unexpected artifact was deleted; only its hash in the log is left |

## Common mistakes

- Forgetting `--pki-format x509`, so the search fails.
- Recording the hash with the file name or in upper case; the key must hold only the lower-case hash.
- Creating the ConfigMap in the wrong namespace. It must be in `workstation`.
