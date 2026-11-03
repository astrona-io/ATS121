# Attestations And The DSSE Envelope

A release process produces facts about a file: who built it, which scanner checked it, which tests passed. A plain signature cannot carry those facts. This part defines the statement that carries them, shows the envelope that signs them, and builds both by hand so that you see the exact bytes that get signed.

## The statement

An **in-toto statement** is a JSON document with four fields. `_type` names the statement format. `subject` lists the artifacts the statement is about, each with a name and a digest. `predicateType` is a URI that says what kind of claim the predicate makes. `predicate` is the claim itself, in a shape the predicate type defines.

The predicate type is a name, not a rule that Sigstore enforces. A verifier that wants a scan result asks for the scan predicate type and rejects everything else. The playground has a predicate in `/lab/predicate.json`. Read it, and compute the digest of the artifact it describes:

<!-- astrona:playground:renew -->

```sh
cat /lab/predicate.json
sha256sum /lab/artifacts/inventory-4.1.0.txt
```

## Building a statement with jq

Combine the pieces into one statement. The shell variable holds the digest, and `jq` writes the document. The predicate type here is a URI of our own, because the lab has no standard scan format to follow:

```sh
DIGEST="$(sha256sum /lab/artifacts/inventory-4.1.0.txt | cut -d' ' -f1)"
jq -n --arg d "$DIGEST" --slurpfile p /lab/predicate.json \
  '{_type: "https://in-toto.io/Statement/v1", subject: [{name: "inventory-4.1.0.txt", digest: {sha256: $d}}], predicateType: "https://astrona.io/release-check/v1", predicate: $p[0]}' \
  | tee /tmp/statement.json
```

The subject digest ties the statement to the exact bytes of the file. If the file changes, the digest no longer matches, and a verifier rejects the statement for that file.

## The DSSE envelope

Signing the statement directly has a problem: two programs can print the same JSON with different spacing, and then the signed bytes differ. The **Dead Simple Signing Envelope (DSSE)** avoids the problem. It signs exact bytes and carries them with a label.

The envelope has three fields. `payloadType` is a label such as `application/vnd.in-toto+json`. `payload` is the statement, Base64 encoded. `signatures` is a list of signatures, each with an optional key ID. The signature does not cover the payload alone. It covers the **pre-authentication encoding (PAE)**: the string `DSSEv1`, the length and text of the payload type, and the length and bytes of the payload, joined by spaces. That ties the signature to the label as well as the bytes, so an attacker cannot move a signature to a payload with another type.

Build the envelope fields from your statement and look at them. Nothing is signed yet; `cosign` does that when it creates an attestation:

```sh
base64 < /tmp/statement.json | tr -d '\n' | head -c 80; echo
jq -n --arg p "$(base64 < /tmp/statement.json | tr -d '\n')" '{payloadType: "application/vnd.in-toto+json", payload: $p, signatures: []}' | jq 'keys'
```

The first command shows the start of the Base64 payload. The second shows that the envelope has the three field names above.

## Why logs record attestations

A signature over a file proves one thing. An attestation says why the file may be trusted, and that claim is also a fact worth recording. Recording it in the log means the signer cannot later deny that it made the claim, and anyone can find it. The log stores a hash of the envelope and a hash of the payload, plus the signature and the key, not the whole statement.

You now know the four fields of a statement, the three fields of an envelope, and what the signature covers. Next you sign this statement and watch the log record it.

## Common pitfalls

> [!WARNING]
> - **Treating the predicate type as enforced by Sigstore.** It is a label. The verifier must ask for the type it expects.
> - **Forgetting that the payload is Base64.** The envelope holds the statement encoded. Decode it before you read it.
> - **Signing the JSON text instead of the PAE.** Tools build the PAE for you. Doing it by hand is how signatures stop verifying.
