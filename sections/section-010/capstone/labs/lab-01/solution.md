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

## Step 2: Ask the log for its root hash at the saved size

A consistency proof from size 1 to the saved size comes with the root hash of the tree at that size. Ask for it:

```sh
rekor-cli logproof --first-size 1 --last-size "$SAVED_SIZE"
```

The line `Current Root Hash` is the root of the tree at `--last-size`, here the saved size. The same answer from the API, with only the root hash:

```sh
curl -s "$REKOR_URL/api/v1/log/proof?firstSize=1&lastSize=$SAVED_SIZE" | jq -r '.rootHash'
```

Compare that root hash with the two candidates. The one that matches is genuine; the other was forged. The log's answer is trustworthy here because the proof is checked against the log's signed checkpoint, which a forger cannot produce.

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
| Pick the candidate with the newer file time | Both files were written at the same moment; only the log's proof tells them apart |
| Compare a candidate with today's root hash | Today's tree is larger, so its root hash is different from both candidates |
| Sign something to "refresh" the log | The tree size changes, and your recorded size no longer matches |

## Common mistakes

- Using size 0 as the first size: a consistency proof starts at size 1 or more.
- Recording the saved size as `tree-size` instead of the current size.
- Swapping `--first-size` and `--last-size`; the first size must be the smaller one.
