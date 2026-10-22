# Read And Prove A Transparency Log

A release team signs `inventory-1.2.0.tar.gz` with its private key and publishes the signature. A month later the key is stolen, and the thief signs a release of their own. Both signatures are valid. Nothing in a signature says when it was made, and nobody outside the thief's machine knows the second one exists.

A **transparency log** is the answer Sigstore gives to that problem. It is a public list of records that can only be appended to, where anyone can check that nothing was changed or removed. **Rekor** is Sigstore's transparency log: every time a tool such as `cosign` signs an artifact, it can record the artifact's hash, the signature and the public key in Rekor, and get back proof that the record is there.

This module is about how you check such a log without trusting the people who run it. Keep one sentence in mind: **Rekor's proofs let you check its answers with hashes, so you never have to take its word for anything.**

The module has three parts. **Why Signing Needs A Transparency Log** shows what a log adds to a signature, what Rekor records, and how to read the log's current state. **Merkle Trees And Inclusion Proofs** builds a small Merkle tree by hand and verifies a real inclusion proof; a graded lab follows it. **Consistency Proofs, Checkpoints And Monitors** shows how you prove that a log only grew, and who does that checking in practice.

## Learning objectives

After this module you can:

- Explain what a transparency log adds to a signature.
- Name what a `hashedrekord` entry in Rekor records.
- Compute a leaf hash and a node hash the way RFC 6962 defines them.
- Follow an inclusion proof from a leaf to the root hash.
- Find the log entry of an artifact and verify its inclusion proof with `rekor-cli`.
- Ask Rekor for a consistency proof and explain what it proves.
- Tell a checkpoint from a signed entry timestamp (SET).

## Before you start

You need Kubernetes basics: namespaces, pods, `kubectl exec` and `kubectl create configmap`. You should know what a SHA-256 hash is and what a digital signature proves. This module does not teach how to sign; it teaches what happens to a signature after it is made.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Rekor (namespace `rekor-system`) | A private Rekor v1.5.4 transparency log. Inside the cluster it answers at `http://rekor.localtest.me` |
| `workstation` (namespace `workstation`) | A pod with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl` and `jq`. You run every command here |
| `/lab` in the workstation | The lab trust files, the key pair `team-a`, two artifacts and their bundles |

The playground's start script already signed two artifacts, `inventory-1.0.0.txt` and `inventory-1.1.0.txt`, with the key `team-a`, so the log has entries for you to read. Open a shell in the workstation whenever a page asks you to run a command:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
