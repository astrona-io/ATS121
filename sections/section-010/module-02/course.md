# Create And Read Rekor Entries

Every proof in a transparency log starts with an entry, and every entry starts with a client that sends a request to the log. Most of the time that client is `cosign`, which hides the request. To audit a log you need to know what the log does with the request: which programs run, what type of entry it accepts, what it stores, and how it names the result.

This module opens the Rekor server and looks at its parts. It then shows the entry types that Rekor v1 accepts, uploads an entry by hand with `rekor-cli` and `openssl` instead of `cosign`, and ends with the log's tree ID, its shards and the REST API that every client uses. Keep one sentence in mind: **an entry is a signed statement about a hash, and Rekor checks that statement before it adds it to the tree.**

The module has five parts. **How Rekor Is Built** names the programs and the storage behind the API. **Entry Types And Their Fields** compares the entry types and reads the body of two of them. **Uploading An Entry By Hand** signs a file with `openssl` and uploads it with `rekor-cli`; a graded lab follows it. **Shards, Tree IDs And The API** explains how an entry ID is made and which API calls an auditor uses. **What Rekor Checks Before Adding** sends three bad uploads and shows which claims the log verifies and which it leaves to you.

## Learning objectives

After this module you can:

- Name the programs that make up a Rekor v1 deployment and say what each one stores.
- Explain why the search index is separate from the Merkle tree.
- Name the entry kinds that Rekor v1 supports and say what a `hashedrekord` entry and a `rekord` entry record.
- Read the `kind`, `apiVersion` and `spec` of an entry body.
- Sign a file with `openssl`, upload it with `rekor-cli upload` and verify the new entry.
- Explain what Rekor does when you upload the same entry twice.
- Split an entry ID into a tree ID and a leaf hash.
- Explain what a shard is and read `treeID` and `inactiveShards` from the log.
- Name the checks Rekor runs on upload and what a rejected upload leaves behind.

## Before you start

You need Kubernetes basics, an idea of what a Merkle tree and an inclusion proof are, and a working knowledge of `rekor-cli search` and `rekor-cli get`. You should know what an ECDSA key pair is and what it means to sign a hash.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Rekor (namespace `rekor-system`) | A private Rekor v1.5.4 transparency log. Inside the cluster it answers at `http://rekor.localtest.me` |
| Trillian (namespace `trillian-system`) | The storage behind the Merkle tree |
| `workstation` (namespace `workstation`) | A pod with `cosign` v3.1.4, `rekor-cli` v1.5.5, `openssl`, `curl` and `jq`. You run every command here |
| `/lab` in the workstation | The lab trust files, the key `team-a`, an `openssl` key `demo`, two artifacts signed with `team-a` and one artifact that is not in the log |

Open a shell in the workstation whenever a page asks you to run a command:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
