# Logging An Attestation

An envelope that only you hold proves nothing to anyone else. To make the claim public, the signer uploads the signed envelope to the transparency log and keeps the log's evidence in a bundle. This part signs a statement like the one you built by hand with `cosign attest-blob`, reads the bundle that comes back, and finds the same entry in Rekor.

## Signing and uploading

`cosign attest-blob` builds the statement for you, signs it with a key, uploads an entry to the log and writes a bundle. The flags `--predicate` and `--type` set the predicate and its type URI. `--signing-config` and `--trusted-root` point it at the private log. `--bundle` is the output file. The key password is the lab-only one:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
cosign attest-blob --key /lab/keys/release.key \
  --predicate /lab/predicate.json \
  --type https://astrona.io/release-check/v1 \
  --signing-config /lab/signing-config.json \
  --trusted-root /lab/trusted-root.json \
  --bundle /tmp/inventory-4.1.0.att.sigstore.json \
  --yes /lab/artifacts/inventory-4.1.0.txt
```

`cosign` computes the subject digest from the file you pass, so you do not build the statement by hand. The result is a bundle with the same structure as before, but with an envelope inside instead of a plain signature.

## Reading the bundle

A bundle for a plain signature has a `messageSignature` field. A bundle for an attestation has a `dsseEnvelope` field instead. Check which fields the new bundle has:

```sh
jq 'keys' /tmp/inventory-4.1.0.att.sigstore.json
jq '.dsseEnvelope | {payloadType, signatures: (.signatures | length)}' /tmp/inventory-4.1.0.att.sigstore.json
```

Decode the payload to see the statement `cosign` built. It has the subject digest of your file and the predicate type you gave:

```sh
jq -r '.dsseEnvelope.payload' /tmp/inventory-4.1.0.att.sigstore.json | base64 -d | jq .
```

## Reading the entry kind

Now look at the log evidence. Every item in `tlogEntries` names the kind of entry and its version. Read them from the bundle. Do not assume which kind a tool writes, because the answer depends on the tool version and can change:

```sh
jq '.verificationMaterial.tlogEntries[0] | {logIndex, kindVersion}' /tmp/inventory-4.1.0.att.sigstore.json
```

The `kindVersion` tells you the type of the Rekor entry. Rekor v1 has two types for attestations, `dsse` and `intoto`, and the bundle states which one this entry is. Keep the log index; you need it next.

## Finding the entry in Rekor

Fetch the entry by log index and decode its body. The body has the same `kind` as the bundle claimed:

```sh
INDEX="$(jq -r '.verificationMaterial.tlogEntries[0].logIndex' /tmp/inventory-4.1.0.att.sigstore.json)"
curl -s "$REKOR_URL/api/v1/log/entries?logIndex=$INDEX" | jq -r '.[].body' | base64 -d | jq .
```

For a `dsse` entry the `spec` holds hashes of the envelope and the payload, plus the signatures with their verifying keys. It does not hold the statement. To tie the entry to your bundle, compute the SHA-256 hash of the decoded payload and compare it with the payload hash in the entry. You do that comparison when you audit the log.

## What the log gained

The tree size grew by one. The attestation entry has its own log index, and the log signed a new checkpoint that covers it. The earlier signature of `inventory-4.0.0.txt` is a separate entry. One artifact can have many entries: a signature, a scan attestation and a build attestation are three entries, each with its own index.

You now know how to sign and log an attestation, how to read its kind from the bundle, and how to find the entry in Rekor. The open question is how a consumer checks it.

## Common pitfalls

> [!WARNING]
> - **Asserting the entry kind from memory.** Read `kindVersion` from the bundle and the `kind` from the entry body.
> - **Expecting the statement in the log.** The log holds hashes of the envelope and payload. The statement lives in the bundle.
> - **Leaving out `--type`.** The predicate type then defaults to a generic one, and a verifier that asks for yours rejects it.
