# Summary

A Rekor v1 deployment has four parts. The Rekor server exposes the API, checks every entry and signs checkpoints and signed entry timestamps. Trillian stores the Merkle tree in MySQL, with a log server and a log signer. Redis holds the search index. The tree is the source of truth. The index is a convenience, and an empty search result does not prove that an entry is missing.

Every entry has a kind, an apiVersion and a spec. Rekor v1 supports `hashedrekord`, `rekord`, `dsse`, `intoto`, `rfc3161`, `cose`, `helm`, `jar`, `rpm` and `alpine`. A `hashedrekord` entry records the SHA-256 hash of an artifact, a signature over it and the public key or certificate. It never records the file, so you recompute the hash from your own copy to link the file to its entry.

An entry can be made without `cosign`. A client needs a hash, a signature over it and the public key. `openssl dgst -sha256 -sign` makes the signature, and `rekor-cli upload` with `--pki-format x509` sends the entry. The server checks the signature before it adds anything. Uploading the same entry again returns a conflict that names the existing UUID, while a new signature over the same file makes a new entry.

An entry ID of 80 characters is a 16-character tree ID in hexadecimal followed by the 64-character UUID, which is the leaf hash. A shard is one Trillian tree. When a tree gets too large, the operator starts a new one and freezes the old one, and the log index keeps counting across shards. Proofs and root hashes belong to one tree.

The key facts to remember are these:

- `rekor-cli upload --artifact --signature --public-key --pki-format x509` creates a `hashedrekord` entry.
- `GET /api/v1/log` returns the tree size, root hash, tree ID and inactive shards.
- `GET /api/v1/log/entries?logIndex=N` returns the entry at index N.
- Always read `kind` and `apiVersion` before parsing a body.

<!-- astrona:playground:destroy -->
