# Keyless Identities In Entries

So far every entry held a bare public key, which tells you which key signed and nothing about who owns it. In keyless signing, the signer holds a short-lived certificate that names an identity, for example an email address, and the certificate goes into the log entry. Rekor indexes that identity, so an auditor can search by it. This part makes a certificate with an email identity, logs a signature made with it, and searches by that email.

## What changes in the entry

A `hashedrekord` entry with a certificate has the same shape as one with a key. The `publicKey.content` field holds the PEM certificate instead. The certificate carries a Subject Alternative Name (SAN): an extra field that lists names the certificate is valid for, such as an email address or a URL. In real keyless signing, a certificate authority checks the identity, and the certificate is valid for minutes. The lab has no certificate authority, so you make a self-signed certificate with `openssl`. The log mechanics are the same.

## Making an identity certificate

Create a key pair and a certificate for the email address `dev@example.com`. The `-addext` option adds the SAN:

<!-- astrona:playground:renew -->

```sh
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
  -keyout /tmp/dev.key -out /tmp/dev.crt -days 1 \
  -subj "/CN=dev" -addext "subjectAltName=email:dev@example.com"
openssl x509 -in /tmp/dev.crt -noout -ext subjectAltName
```

## Logging a signature with the certificate

Sign a file with the key and upload the signature with the certificate in place of a public key:

```sh
printf 'identity note\n' > /tmp/identity-note.txt
openssl dgst -sha256 -sign /tmp/dev.key -out /tmp/identity.sig /tmp/identity-note.txt
rekor-cli upload --artifact /tmp/identity-note.txt --signature /tmp/identity.sig \
  --public-key /tmp/dev.crt --pki-format x509
```

## Searching by identity

Search the index by the email address. The index holds the identities of certificates next to hashes and keys:

```sh
rekor-cli search --email dev@example.com
```

The search returns the entry you just made. Fetch its body and read the certificate field to see the same SAN inside the log:

```sh
ENTRY_ID="$(rekor-cli search --email dev@example.com | head -1)"
curl -s "$REKOR_URL/api/v1/log/entries/$ENTRY_ID" | jq -r '.[].body' | base64 -d \
  | jq -r '.spec.signature.publicKey.content' | base64 -d | openssl x509 -noout -ext subjectAltName
```

## What the auditor gains

With a bare key, the auditor must keep a list of which key belongs to whom. With a certificate, the identity is in the entry, so an auditor can ask "what did this person or workflow sign?" without any key list. In keyless signing the key itself is thrown away after signing, so an identity search is the only way to find a signer's entries later.

The identity in a real certificate is only as trustworthy as the certificate authority that issued it. A self-signed certificate like this one proves nothing about the person. The verifier must check the certificate chain against a trusted root.

You now know how an identity gets into an entry and how to search by it. What remains is to turn what you found into a report that someone else can act on.

## Common pitfalls

> [!WARNING]
> - **Trusting a self-signed identity.** Without a chain to a trusted authority, the name is only a claim.
> - **Searching by key for a keyless signer.** The key is thrown away. Search by the identity.
> - **Forgetting the certificate validity.** A keyless certificate is short-lived, so check the time of the entry, not today's time.
