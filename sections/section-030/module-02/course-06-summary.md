# Summary

An attestation is a signed statement about an artifact. An in-toto statement has a subject, which names the artifact and holds its digest, a predicate type, which is a URI that names the kind of claim, and a predicate, which holds the claim. The statement is wrapped in a Dead Simple Signing Envelope with a payload type, the Base64 payload and a list of signatures. The signature covers the pre-authentication encoding of the type and the payload, so a signature cannot move to another label or another payload.

`cosign attest-blob` builds the statement from a predicate file and a type URI, signs it with a key, uploads an entry to the transparency log and writes a bundle with a `dsseEnvelope` where a plain signature has `messageSignature`. The bundle names the entry kind and version in `tlogEntries`. Read them from the bundle, because the entry type depends on the tools. The log holds hashes of the envelope and the payload, the signature and the key. The statement stays in the bundle.

`cosign verify-blob-attestation` checks the signature and the log evidence offline, and also checks that the subject digest equals the hash of the file and that the predicate type equals the one requested. A pass proves who signed the claim and that the log recorded it. It does not prove the claim is true. A different predicate type or a different file fails the check.

An auditor lists the entries of a key from the search index, reads the kind of each body, and ties an entry to a bundle by comparing the payload hash. The key facts to remember are these:

- Always pass `--type` when you attest and when you verify.
- Read the entry kind from the bundle or the body, never from memory.
- Keep the bundle: the log keeps only hashes of the statement.
- A valid attestation is a signed claim, not a verified fact.

<!-- astrona:playground:destroy -->
