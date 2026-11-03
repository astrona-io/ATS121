# Summary

A transparency log protects you only when someone reads it. Rekor records, for every `hashedrekord` entry, the artifact's SHA-256 hash, the signature and the public key, together with a log index and an integrated time. Rekor v1 also keeps a search index in Redis, which maps artifact hashes, public keys and certificate identities to entries. The index is a convenience for finding entries; the tree and its proofs are what make them trustworthy.

## What you learned

You can search the log in three ways. A search by artifact hashes the file for you, a search by hash takes a value from a release page, and a search by public key, with the X.509 format, lists every entry a key made. Scripts call the same index through `/api/v1/index/retrieve`. Entry IDs from a search can be 80 characters long, with a tree identifier in front of the 64-character UUID, so you compare the last 64 characters.

An entry's body is the canonical JSON Rekor accepted. Decoded, it gives you the artifact hash under `spec.data.hash.value` and the signer's PEM public key, Base64-encoded, under `spec.signature.publicKey.content`. The log index orders entries, and the integrated time says when Rekor accepted each one, so the earliest entry of a key is the one with the smallest index.

An audit of one key compares what the log says it signed with what the team says it shipped. You list the key's entries, decode each artifact hash, and look it up in the release manifest. A hash that is not there is a signing event nobody expected, and its entry is evidence the log cannot remove. The key facts to remember are these:

- `rekor-cli search --public-key <file> --pki-format x509` answers "what did this key sign?".
- The log hands you the public key of any signer, even one you have never seen.
- An empty search proves only that this log has no matching entry.

<!-- astrona:playground:destroy -->
