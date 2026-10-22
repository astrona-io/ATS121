# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Proofs

## Scenario

Some time ago an auditor saved the state of the team's private Rekor: a tree size and a root hash. Since then two files with that state have turned up, and they disagree. One of them was forged. The log has also grown since the state was saved.

The two files are in the workstation pod:

```sh
kubectl -n workstation exec deploy/workstation -- ls /lab/checkpoints
```

Each file, `candidate-a.json` and `candidate-b.json`, holds a `treeSize` and a `rootHash`.

## Your task

1. Find out which candidate holds the root hash the log really had at that tree size. Use the log's own proofs, not the file dates.
2. Prove that the log only grew since that saved state: get a consistency proof from the saved tree size to the current tree size.
3. Record your findings in a ConfigMap named `growth-answer` in the namespace `workstation`, with three keys:
   - `genuine`: `candidate-a` or `candidate-b`.
   - `tree-size`: the log's current tree size.
   - `entries-added`: how many entries the log gained since the saved state.

## Constraints

- Do not add entries to the log while you work: it changes the current tree size.
- Do not change the files in `/lab/checkpoints/`.
- Do not restart the Rekor server pod.

## Done when

- `genuine` names the candidate whose root hash the log proves for that size.
- `tree-size` equals the log's current tree size, and `entries-added` equals the current size minus the saved size.
- A consistency proof from the saved size to the current size can be produced.
