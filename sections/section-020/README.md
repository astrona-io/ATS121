# Section 020: Searching And Auditing Rekor

A transparency log only protects you if someone reads it. When a signing key leaks, the first question is: what did this key sign, and was every one of those signatures expected? Rekor can answer that, because it records the public key and the artifact hash of every `hashedrekord` entry and keeps a search index over them.

This section turns you into the person who reads the log. You search Rekor by artifact and by public key, decode what an entry records, and compare the log with what your team says it shipped. The difference between the two is where an incident starts.

## What you will learn

- What Rekor v1's search index covers, and what it does not.
- Searching by artifact file, by SHA-256 hash and by public key with `rekor-cli search`.
- Reading an entry with `rekor-cli get` and decoding its stored body with `base64` and `jq`.
- Pulling the artifact hash, the signature and the public key out of a `hashedrekord` entry.
- Auditing one key: listing every entry it made and finding the ones nobody expected.
- Using the integrated time and the log index to tell when a key was first and last used.

## The learning path

The module has a landing page, two short parts, a graded lab right after the part it tests, and a summary. The module's playground holds a private Rekor with entries from two team keys.

### 1. Search And Audit Rekor Entries

The playground's start script signed three artifacts: two with the key `team-a`, one with `team-b`.

1. Searching The Log
2. Reading And Auditing Entries, followed by the lab **Find Every Entry Signed By A Leaked Key**
3. Summary

## Section capstone: Investigate An Unknown Signer

A file called `inventory-2.0.0.txt` showed up next to the real releases, and it is in the log. Nobody on the team signed it. The capstone asks you to find which key did, every entry that key made, and when it first appeared. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-121-capstone-020
```
