# Entry Types And Their Fields

A log that stores only one kind of record would need a new log for every new use. Rekor v1 solves this with entry types: each type says which fields an entry has and what the server checks before it accepts it. An auditor reads the type first, because the type tells which fields to look for. This part lists the types, compares the two that record a plain signature, and reads the body of a real entry field by field.

## The kinds Rekor v1 accepts

Every entry has a **kind**, the name of its type, and an **apiVersion**, the version of that type's schema. The kind and version together decide the shape of the `spec` field, which holds the type-specific data. Rekor v1 supports these kinds:

| Kind | What it records |
| --- | --- |
| `hashedrekord` | The hash of an artifact, a signature over it and the public key or certificate |
| `rekord` | An artifact (or a link to it), a signature and a public key; the older, general type |
| `dsse` | A signed in-toto attestation in a DSSE envelope, stored as hashes of the envelope and payload |
| `intoto` | An in-toto attestation, in an older entry format |
| `rfc3161` | A timestamp response from a timestamp authority |
| `cose` | A signed COSE message |
| `helm` | A signed Helm chart and its provenance file |
| `jar` | A signed Java archive |
| `rpm` | An RPM package with its signature |
| `alpine` | An Alpine Linux package |

You will meet `hashedrekord` in almost every audit, because `cosign sign-blob` and `cosign sign` write it. The next module reads `dsse` entries. The other kinds exist for tools that sign a package format directly.

## hashedrekord against rekord

Both types record a signature over an artifact, but they differ in what Rekor sees. With `rekord`, the client can send the artifact itself, and the server computes the hash. With `hashedrekord`, the client hashes the artifact and sends only the hash. The server never sees the content.

`hashedrekord` is the better choice for two reasons. A private file stays private, because only its SHA-256 hash goes into a public log. The request is also small, because the hash has a fixed size. Sigstore tools use `hashedrekord` by default. Rekor v2 keeps only this kind.

The trade-off is that the log cannot check the content. It checks that the signature is valid over the hash the client sent. Whether that hash is the hash of the file you hold is a check you make, by hashing your file and comparing.

## Reading a body field by field

Now read a real entry. In the workstation shell, find the entry of a signed artifact and decode its body. The Rekor API returns the body in Base64, so the commands decode it and print the result with `jq`.

<!-- astrona:playground:renew -->

```sh
ENTRY_ID="$(rekor-cli search --artifact /lab/artifacts/release-1.0.0.txt | head -1)"
curl -s "$REKOR_URL/api/v1/log/entries/$ENTRY_ID" | jq -r '.[].body' | base64 -d | jq .
```

The top-level fields are `apiVersion`, `kind` and `spec`. Read the three of them in turn. `kind` is `hashedrekord`. `apiVersion` is the schema version of that type. `spec` holds `data.hash`, with the algorithm and the lower-case hexadecimal value, and `signature`, with the Base64 signature and the `publicKey` that verifies it.

Compare the hash in the entry with the hash of the file:

```sh
curl -s "$REKOR_URL/api/v1/log/entries/$ENTRY_ID" | jq -r '.[].body' | base64 -d | jq -r '.spec.data.hash.value'
sha256sum /lab/artifacts/release-1.0.0.txt
```

The two values are the same. That is the whole link between a file and its entry: the log holds a hash, and you recompute it.

## The public key field

The `publicKey` in the body holds a `content` field, which is itself Base64. Decode it twice, once for the body and once for the key, and you get the PEM text of the public key that `cosign` used:

```sh
curl -s "$REKOR_URL/api/v1/log/entries/$ENTRY_ID" | jq -r '.[].body' | base64 -d \
  | jq -r '.spec.signature.publicKey.content' | base64 -d
```

Compare the result with `/lab/keys/team-a.pub`. They are the same key. An entry signed with a certificate (the keyless flow) holds a certificate in this field instead, and an auditor reads the identity from the certificate.

## Versions of a type

A type changes over time, and the version number says which fields exist. The playground log accepts the versions its server was built with. When you read an entry, always read `apiVersion` together with `kind`. The Rekor v2 type `hashedrekord` has version `0.0.2`, with a different layout for the signature and the key, so a script that works on version `0.0.1` bodies breaks on version `0.0.2` bodies.

You now know the kinds Rekor v1 supports, why `hashedrekord` records a hash and not the file, and how to read an entry body down to the key. What you have not done yet is create an entry without `cosign`, which shows exactly which pieces a log needs.

## Common pitfalls

> [!WARNING]
> - **Reading only the kind.** The kind and the apiVersion together decide the fields. Check both before you write a script.
> - **Comparing the hash with the wrong file.** The entry holds the hash from signing time. If the file changed after signing, the hashes differ, and that is a correct result.
> - **Decoding the body once.** The body is Base64 JSON, and the key and signature inside it are Base64 too. Decode each layer.
