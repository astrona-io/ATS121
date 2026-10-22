# Verify Bundles Offline And Prepare For Rekor v2

A deployment system checks the signature of every artifact it installs. If each check had to ask Rekor for an inclusion proof, every deployment would depend on the log being up and reachable. The **Sigstore bundle** solves that: one JSON document with the signature, a hint or certificate for the key, and the log's evidence, so the verifier needs nothing but the bundle, the artifact and a trusted root.

This module is about that evidence and how to check it. Keep one sentence in mind: **a bundle lets you verify offline, so the bundle is the evidence you must keep.** That sentence matters even more with **Rekor v2**, the redesigned Sigstore log, which no longer offers a search index to find entries again.

The module has three parts. **The Sigstore Bundle** opens a bundle field by field and explains the two trust files the lab uses. **Verifying A Bundle Offline** runs `cosign verify-blob` against good and tampered bundles; a graded lab follows it. **What Changes With Rekor v2** compares the two log versions and shows how a client is pointed at a new log.

## Learning objectives

After this module you can:

- Name the parts of a v0.3 Sigstore bundle and find the inclusion proof and checkpoint in it.
- Explain what a signing config and a trusted root each tell `cosign`.
- Verify a bundle offline with `cosign verify-blob`.
- Tell from a failing verification whether the artifact or the log evidence changed.
- Explain what Rekor v2 changes for searching, entry types and timestamps.
- Write a signing config that points `cosign` at a Rekor v2 log.

## Before you start

You need Kubernetes basics and the idea of a transparency log: Rekor records an entry for each signature, and an inclusion proof with a signed checkpoint proves that the entry is in the log. You should be able to read JSON with `jq`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Rekor (namespace `rekor-system`) | A private Rekor v1.5.4. Inside the cluster it answers at `http://rekor.localtest.me` |
| `workstation` (namespace `workstation`) | A pod with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl` and `jq`. You run every command here |
| `/lab/keys/` | The key pair `release`; the password is the lab-only `lab-only-password` |
| `/lab/artifacts/`, `/lab/bundles/` | `inventory-3.0.0.txt` and `inventory-3.1.0.txt`, signed with `release`, and their bundles |

Open a shell in the workstation whenever a page asks you to run a command:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
