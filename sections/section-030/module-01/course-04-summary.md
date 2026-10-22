# Summary

A Sigstore bundle is one JSON document with the signature, a hint or certificate for the key, and the transparency log's evidence. `cosign` v3 writes version 0.3 bundles. For a signed file the bundle holds the artifact's digest and signature under `messageSignature`, and each item in `verificationMaterial.tlogEntries` carries the log index, the log ID, the entry kind, the integrated time, the signed entry timestamp, the inclusion proof with its signed checkpoint, and the exact entry body Rekor stored.

## What you learned

Two trust files tie `cosign` to a log. The signing config says which log, certificate authority and timestamp authority to use when signing, with API versions and validity dates. The trusted root holds the public keys to trust when verifying, and the log ID in a bundle points at the right key in it. Without either file, `cosign` v3 uses the public-good instance.

`cosign verify-blob` with a bundle and a trusted root verifies offline. It checks the signature over the artifact, that the logged entry records the same signature, that the inclusion proof leads to the checkpoint's root hash, and that the log's key signed the checkpoint and the SET. A changed artifact fails the signature check; a changed inclusion proof fails the log check. Skipping the log checks with `--insecure-ignore-tlog` hides the second kind of tampering.

Rekor v2 stores the log as tiles, accepts only `hashedrekord` entries, returns no signed entry timestamp, and has no search index. The signing time then comes from an RFC 3161 timestamp in the bundle, and the bundle becomes the only practical way back to your evidence. Clients reach new Rekor v2 shards through the signing config, where `majorApiVersion` 2 selects the new protocol. The key facts to remember are these:

- Keep a bundle for every artifact you release, and the public key if you signed with a key pair.
- Read a failed verification for which check failed: the artifact or the log evidence.
- Never hard-code a log URL; let clients read the signing config.

<!-- astrona:playground:destroy -->
