# Summary

A signature proves who signed an artifact, but not when, not to anyone else, and not whether a stolen key was used. A transparency log fills that gap: an append-only public record of signing events that anyone can check. Rekor is Sigstore's transparency log. For a `hashedrekord` entry it records the artifact's SHA-256 hash, the signature and the public key, never the artifact itself, and gives each entry a log index and a UUID.

## What you learned

Rekor keeps its entries in a Merkle tree, hashed the way RFC 6962 defines it: a leaf hash is SHA-256 over a zero byte and the entry, and a node hash is SHA-256 over a one byte and its two children. The root hash at the top changes if any entry changes. An inclusion proof is the list of sibling hashes from one leaf up to the root; a verifier who recomputes the signed root from the entry knows the entry is in the tree. In Rekor v1 the entry's 64-character UUID is its leaf hash, and search results may add 16 characters in front that name the tree.

A consistency proof shows that a smaller tree is the start of a larger one, so the log only grew and never changed or dropped an entry. Asking for a proof from size 1 to some size also reveals the root hash the tree had at that size, which is how an auditor checks a saved root. The log stands behind its hashes with two signed statements: a checkpoint, which signs a tree size and root hash, and a signed entry timestamp, which promises that one accepted entry will be added. Monitors and witnesses are the programs and parties that check those statements over time.

The key facts to remember are these:

- `rekor-cli search --artifact` finds entries by hash, `rekor-cli get` shows one, and `rekor-cli verify` checks its inclusion proof, checkpoint and SET.
- `rekor-cli loginfo` checks the log's signed state and, once it saved a state, its consistency with that state.
- `rekor-cli logproof --first-size --last-size` asks for a consistency proof; the API answers the same at `/api/v1/log/proof`.
- Every signing command in a private setup needs a signing config, or `cosign` v3 uses the public log.

<!-- astrona:playground:destroy -->
