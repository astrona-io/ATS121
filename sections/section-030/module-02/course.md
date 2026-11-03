# Attestations In The Log

A signature over a file says that a key holder approved these bytes. It does not say what was checked, built or scanned. An **attestation** adds that: a signed statement about an artifact, such as "this file passed the release check". Sigstore signs attestations in a standard envelope and records them in the same transparency log as plain signatures.

This module follows one attestation from creation to audit. You build the statement by hand, sign and log it with `cosign attest-blob`, verify it offline, and then find attestation entries in the log. Keep one sentence in mind: **an attestation is a signed statement about an artifact, and the log records it just like a signature, with a different entry kind.**

The module has five parts. **Attestations And The DSSE Envelope** builds a statement and shows how it is wrapped. **Logging An Attestation** signs it, uploads it and reads the log entry that results. **Verifying An Attestation** checks the bundle offline and shows what a wrong predicate type does; a graded lab follows it. **Auditing Attestations In The Log** finds attestation entries for a key and compares them with the bundle. **Reading A Rekor v2 Setup** builds a v2 signing config and the tile paths an auditor reads.

## Learning objectives

After this module you can:

- Name the parts of an in-toto statement: subject, predicate type and predicate.
- Explain what a DSSE envelope is and what its payload type and signatures hold.
- Create a signed attestation bundle with `cosign attest-blob`.
- Read the entry kind and version from a bundle instead of assuming them.
- Verify an attestation offline with `cosign verify-blob-attestation`, including the predicate type.
- Compare a log entry of an attestation with the payload in the bundle.
- Build a signing config for Rekor v2 and compute tile paths.

## Before you start

You need Kubernetes basics, the idea of a transparency log with entries and inclusion proofs, and the ability to read JSON with `jq` and decode Base64 text.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Rekor (namespace `rekor-system`) | A private Rekor v1.5.4. Inside the cluster it answers at `http://rekor.localtest.me` |
| `workstation` (namespace `workstation`) | A pod with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl`, `jq` and `openssl`. You run every command here |
| `/lab/keys/` | The key pair `release`; the password is the lab-only `lab-only-password` |
| `/lab/artifacts/` | `inventory-4.0.0.txt`, signed with `release` and logged, and `inventory-4.1.0.txt`, which has no attestation yet |
| `/lab/predicate.json` | A small JSON document with the result of a release check |

Open a shell in the workstation whenever a page asks you to run a command:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
