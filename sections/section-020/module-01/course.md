# Search And Audit Rekor Entries

On Monday morning the security team reports that the private key of the old CI system, `ci-old`, was found in a public repository. The key is revoked, but the damage may be done. Which artifacts did `ci-old` sign? Were all of them real releases? Without a transparency log, nobody can answer that. With Rekor, the answer is a few commands away.

This module is about reading the log as an auditor. **Rekor**, Sigstore's transparency log, stores for every `hashedrekord` entry the SHA-256 hash of the artifact, the signature and the public key, and Rekor v1 keeps a **search index**, a Redis index that maps hashes and public keys to entries. Keep one sentence in mind: **the log tells you what a key signed; only your release records tell you what it should have signed.**

The module has two parts. **Searching The Log** covers the search index and the ways to query it: by artifact, by hash and by public key. **Reading And Auditing Entries** decodes what an entry records and walks through a full audit of one key; a graded lab follows it.

## Learning objectives

After this module you can:

- Say what the Rekor v1 search index covers.
- Find entries by artifact file, by SHA-256 hash and by public key.
- Read an entry with `rekor-cli get` and decode its body.
- Pull the artifact hash and the public key out of a `hashedrekord` entry.
- List every entry made by one key and compare it with a release manifest.
- Use the log index and the integrated time to place an entry in time.

## Before you start

You need Kubernetes basics: namespaces, pods, `kubectl exec` and `kubectl create configmap`. You should know that a Rekor entry has a log index and a UUID, and that a `hashedrekord` entry records an artifact hash, a signature and a public key. You need `jq` for reading JSON; it runs in the workstation.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Rekor (namespace `rekor-system`) | A private Rekor v1.5.4 with Redis for the search index. Inside the cluster it answers at `http://rekor.localtest.me` |
| `workstation` (namespace `workstation`) | A pod with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl` and `jq`. You run every command here |
| `/lab/keys/` | The key pairs `team-a` and `team-b`; the password is the lab-only `lab-only-password` |
| `/lab/artifacts/` | `api-1.0.0.txt` and `api-1.1.0.txt`, signed with `team-a`, and `web-1.0.0.txt`, signed with `team-b` |

Open a shell in the workstation whenever a page asks you to run a command:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
