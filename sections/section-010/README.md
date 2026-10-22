# Section 010: Transparency Logs And Merkle Trees

A signature tells you that the holder of a key signed an artifact. It does not tell you when, it does not tell anyone else that it happened, and it cannot show that a stolen key was used. A transparency log closes that gap: every signing event is written to a public, append-only record that anyone can check.

This section explains how Rekor, the Sigstore transparency log, can be checked by people who do not trust it. Rekor keeps its entries in a Merkle tree, a tree of hashes whose top hash, the root hash, changes if any entry changes. Two short proofs then answer the two questions an auditor asks: is this entry in the log, and did the log only grow since I last looked?

## What you will learn

- Why a signature alone is not enough, and what an append-only log adds.
- How a Merkle tree is built from leaf hashes and node hashes, as RFC 6962 defines them.
- Following an inclusion proof from one leaf to the root hash, and verifying one with `rekor-cli verify`.
- Following a consistency proof between two tree sizes, and asking Rekor for one with `rekor-cli logproof`.
- What a checkpoint and a signed entry timestamp (SET) are, and what each one promises.
- What monitors and witnesses do with checkpoints.

## The learning path

The module has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster with a private Rekor and a workstation pod, and the landing page starts it for you.

### 1. Read And Prove A Transparency Log

The playground holds a private Rekor with two entries, signed with the key `team-a` from the workstation.

1. Why Signing Needs A Transparency Log
2. Merkle Trees And Inclusion Proofs, followed by the lab **Find And Prove A Release Entry**
3. Consistency Proofs, Checkpoints And Monitors
4. Summary

## Section capstone: Prove The Log Only Grew

An auditor saved the log's state some time ago: a tree size and a root hash. Two copies of that saved state exist, and one was forged. The capstone asks you to find out which copy the log can prove, to show that the log only grew since then, and to report how much it grew. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-121-capstone-010
```
