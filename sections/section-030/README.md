# Section 030: Bundles, Offline Verification And Rekor v2

Asking the log every time you verify a signature is slow, needs a network, and puts the log in the path of every deployment. The Sigstore bundle removes that need. It is one JSON document that carries the signature together with the log's evidence: the entry, its inclusion proof and the checkpoint that signs the root hash. With the log's public key in a trusted root, a verifier checks everything offline.

This section shows what a bundle holds, how `cosign` verifies one without contacting Rekor, and which check catches which kind of tampering. It ends with Rekor v2, the redesigned log that has no search index. With Rekor v2, the bundle you keep is often the only practical way back to your evidence.

## What you will learn

- The fields of a v0.3 Sigstore bundle and the log evidence in `tlogEntries`.
- The two lab trust files: a signing config, which says where to sign, and a trusted root, which says whom to trust.
- Verifying a bundle offline with `cosign verify-blob --bundle --trusted-root`.
- Telling a changed artifact from a changed inclusion proof by the failing check.
- What changes with Rekor v2: tiles, one entry type, no search index, no signed entry timestamps, and yearly shards.
- Writing a signing config that points `cosign` at a Rekor v2 log.

## The learning path

The module has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module's playground holds two artifacts signed with the key `release`, and their bundles.

### 1. Verify Bundles Offline And Prepare For Rekor v2

1. The Sigstore Bundle
2. Verifying A Bundle Offline, followed by the lab **Find The Bundles That Do Not Verify**
3. What Changes With Rekor v2
4. Summary

## Section capstone: Keep Verifiable Evidence For Rekor v2

The team is preparing to move to a log without a search index, where a lost bundle means lost evidence. One release artifact has a bundle signed with a retired key, and two have none. The capstone asks you to make sure every release artifact has a verifiable bundle with its full log evidence, and to write the signing config the team will use for Rekor v2. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-121-capstone-030
```
