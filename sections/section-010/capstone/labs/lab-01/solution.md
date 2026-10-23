# Solution: Prove The Log Only Grew

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the genuine candidate, the current tree size with the number of entries added, and that a consistency proof between the two sizes exists.

## Step 1: Read the two candidates

Open a shell in the workstation and look at both files:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
cat /lab/checkpoints/candidate-a.json /lab/checkpoints/candidate-b.json
```

Both name the same tree size and different root hashes. Only one root hash can be right, because a tree of a given size has exactly one root hash. Keep the saved size in a variable:

```sh
SAVED_SIZE="$(jq -r '.treeSize' /lab/checkpoints/candidate-a.json)"
```

## Step 2: Read the log's root hash at the saved size from a bundle

A consistency proof does not give you the old root: `rekor-cli logproof` and `/api/v1/log/proof` always report the log's current root hash, whatever `--last-size` you ask for. The log's root at the saved size is in a checkpoint for that size. Every Sigstore bundle in `/lab/bundles/` keeps one: when `cosign` uploaded the entry, Rekor returned an inclusion proof for the tree right after it added the entry, with the signed checkpoint for that tree size.

List the tree size each bundle's inclusion proof was made for, and keep the bundle whose size is the saved size:

```sh
for file in /lab/bundles/*.sigstore.json; do
  size="$(jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.treeSize' "$file")"
  echo "$size $file"
  [ "$size" = "$SAVED_SIZE" ] && BUNDLE="$file"
done
echo "bundle for size $SAVED_SIZE: $BUNDLE"
```

The bundle stores the root hash in Base64, a text encoding of binary data, while the candidates hold it in hexadecimal. Convert it, then print both candidates next to it:

```sh
jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.rootHash' "$BUNDLE" | base64 -d | od -An -tx1 | tr -d ' \n'; echo
jq -r '.rootHash' /lab/checkpoints/candidate-a.json /lab/checkpoints/candidate-b.json
```

The candidate that matches the converted root hash is genuine; the other was forged. You can trust the bundle's root hash because the log signed it in the checkpoint. `cosign verify-blob` checks that signature against the log's key in the trusted root, together with the inclusion proof, without network access:

```sh
cosign verify-blob --key /lab/keys/release.pub \
  --trusted-root /lab/trusted-root.json \
  --bundle "$BUNDLE" "/lab/artifacts/$(basename "$BUNDLE" .sigstore.json)"
```

A forger can write any hash into a file, but cannot produce a checkpoint the log's key signed.

## Step 3: Prove the log only grew

Read the current tree size, then ask for a consistency proof from the saved size to it:

```sh
CURRENT_SIZE="$(curl -s "$REKOR_URL/api/v1/log" | jq -r '.treeSize')"
rekor-cli logproof --first-size "$SAVED_SIZE" --last-size "$CURRENT_SIZE"
echo "current: $CURRENT_SIZE added: $((CURRENT_SIZE - SAVED_SIZE))"
```

The proof's hashes tie the saved tree to the current one: the first `SAVED_SIZE` entries are unchanged. Note the current size and the number of entries added, then leave the shell with `exit`.

## Step 4: Record the answer

From your own machine, with your values in place of the placeholders:

```sh
kubectl -n workstation create configmap growth-answer \
  --from-literal=genuine=<candidate-a-or-candidate-b> \
  --from-literal=tree-size=<CURRENT_SIZE> \
  --from-literal=entries-added=<ADDED>
```

## Step 5: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Pick the candidate with the newer file time | Both files were written at the same moment; only the log's signed checkpoint tells them apart |
| Compare a candidate with today's root hash | Today's tree is larger, so its root hash is different from both candidates |
| Ask `rekor-cli logproof` with the saved size as `--last-size` for the root | The answer's root hash is the current root, not the root at the saved size, so it matches neither candidate |
| Sign something to "refresh" the log | The tree size changes, and your recorded size no longer matches |

## Common mistakes

- Comparing the Base64 root hash from the bundle with the hexadecimal root hash in a candidate without converting it first.
- Picking a bundle by its file name: use the bundle whose `inclusionProof.treeSize` is the saved size.
- Using size 0 as the first size: a consistency proof starts at size 1 or more.
- Recording the saved size as `tree-size` instead of the current size.
- Swapping `--first-size` and `--last-size`; the first size must be the smaller one.
