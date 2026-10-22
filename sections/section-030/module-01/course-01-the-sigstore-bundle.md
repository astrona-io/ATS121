# The Sigstore Bundle

A detached signature file says nothing about the log. To check that a signature was logged, a verifier would have to search Rekor, fetch the entry and ask for a proof. This part opens the bundle that `cosign` writes instead, finds the log evidence inside it, and explains the two trust files that decide where `cosign` signs and whom it trusts.

## One file with everything

A **Sigstore bundle** is one JSON document with the signature, the key or certificate that verifies it, and the log's evidence. Its `mediaType` names the format version; `cosign` v3 writes version 0.3, `application/vnd.dev.sigstore.bundle.v0.3+json`. The bundle has three parts:

| Part | What it holds |
| --- | --- |
| `verificationMaterial` | The key or certificate, the transparency log entries (`tlogEntries`) and any signed timestamps |
| `messageSignature` | For a signed file: the artifact's digest and the signature over it |
| `dsseEnvelope` | For a signed attestation instead: the in-toto statement and its signature |

When you sign with a key pair, `verificationMaterial` holds a `publicKey` hint, an identifier of the key, not the key itself; you supply the public key when you verify. With keyless signing it holds the short-lived certificate instead.

## The log evidence in tlogEntries

Each item in `tlogEntries` is the evidence for one log entry. It carries everything `rekor-cli verify` would fetch from the log:

| Field | What it is |
| --- | --- |
| `logIndex`, `logId.keyId` | The entry's position, and the ID of the log (the SHA-256 of the log's public key) |
| `kindVersion` | The entry's kind and version, for example `hashedrekord` and `0.0.1` |
| `integratedTime` | When Rekor accepted the entry, in Unix seconds |
| `inclusionPromise.signedEntryTimestamp` | The signed entry timestamp (SET): the log's signed promise to add the entry |
| `inclusionProof` | The log index, root hash, tree size, sibling `hashes` and the signed `checkpoint` |
| `canonicalizedBody` | The exact entry body Rekor stored, in Base64 |

Open a bundle and look for these fields. In the workstation shell, start with the top level.

<!-- astrona:playground:renew -->

Read the media type and the names of the top-level parts:

```sh
jq '{mediaType, parts: keys}' /lab/bundles/inventory-3.0.0.txt.sigstore.json
```

Now the log evidence. Print the first entry without the long body and proof fields, then the proof on its own:

```sh
jq '.verificationMaterial.tlogEntries[0] | del(.canonicalizedBody, .inclusionProof)' /lab/bundles/inventory-3.0.0.txt.sigstore.json
jq '.verificationMaterial.tlogEntries[0].inclusionProof | {logIndex, treeSize, rootHash, hashes}' /lab/bundles/inventory-3.0.0.txt.sigstore.json
```

The log index in the bundle is the same index `rekor-cli search` would give you for this artifact. The proof's root hash and tree size describe the tree at the moment `cosign` received the proof, and the checkpoint envelope next to them is the log's signed note for that tree. `cosign` can also print a short readable summary:

```sh
cosign bundle inspect /lab/bundles/inventory-3.0.0.txt.sigstore.json
```

## The two lab trust files

`cosign` v3 needs to know two things that older versions took from flags: where to send signatures, and whose keys to trust when it verifies. Both come from small JSON files, which the public-good instance distributes through The Update Framework (TUF), and which this lab writes for the private log:

| File | What it tells `cosign` | Used by |
| --- | --- | --- |
| `/lab/signing-config.json` (signing config) | Which Rekor, Fulcio and timestamp authority URLs to use, with their API version and validity dates | `cosign sign-blob --signing-config` |
| `/lab/trusted-root.json` (trusted root) | The public keys of the logs, certificate authorities and timestamp authorities to trust, with validity dates | `cosign verify-blob --trusted-root` |

Look at the Rekor part of each:

```sh
jq '.rekorTlogUrls' /lab/signing-config.json
jq '.tlogs' /lab/trusted-root.json
```

The signing config lists `http://rekor.localtest.me` with major API version 1. The trusted root lists the same URL as `baseUrl`, with the log's public key and its log ID. That ID is what `logId.keyId` in the bundle points at: when you verify, `cosign` uses it to pick the right key from the trusted root. Leave either flag out and `cosign` v3 falls back to the public-good instance, signing to the public log or trusting only the public keys.

You now know what a bundle carries, where its log evidence sits, and how the trust files tie `cosign` to a log. What remains is to see the evidence checked, and to see which check fails when something was changed.

## Common pitfalls

> [!WARNING]
> - **Expecting the public key in a key-based bundle.** A bundle made with a key pair holds only a hint. Keep the public key, or you cannot verify.
> - **Keeping only the signature.** A detached signature has no log evidence. Keep the whole bundle.
> - **Leaving out a trust file.** Without `--signing-config` or `--trusted-root`, `cosign` v3 uses the public-good instance.
> - **Treating `integratedTime` as signed by itself.** It is trustworthy only through the SET or a signed timestamp that covers it.
