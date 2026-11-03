# Auditing Attestations In The Log

The consumer of an attestation holds a bundle. An auditor often holds nothing but the log, and wants to know what a key attested. This part lists the entries of the `release` key, tells signature entries from attestation entries by their kind, and ties one entry to the payload in a bundle by its hash.

## Listing the entries of a key

The private log now holds entries for the `release` key from the playground and from your own signing. Search the index by public key and count the results:

<!-- astrona:playground:renew -->

```sh
rekor-cli search --public-key /lab/keys/release.pub --pki-format x509 | tee /tmp/release-entries.txt | wc -l
```

The search index maps a public key to entries. Whether it lists attestation entries next to signature entries depends on the entry type and the Rekor version. Compare the count with the number of entries you know you made, and treat a gap as a reason to read the log by index, as the search is only a convenience.

## Telling the kinds apart

Each result is an entry ID. Fetch each body and print its `kind` next to the ID. A signature has the kind `hashedrekord`. An attestation has one of the attestation kinds:

```sh
for id in $(cat /tmp/release-entries.txt); do
  kind="$(curl -s "$REKOR_URL/api/v1/log/entries/$id" | jq -r '.[].body' | base64 -d | jq -r '.kind')"
  echo "$kind $id"
done
```

Read the kinds before you parse the bodies. The fields of a `hashedrekord` body and a `dsse` body are different, and a script written for one fails on the other.

## Tying an entry to a bundle

An attestation entry holds the SHA-256 hash of the payload. Compute that hash from the payload in your bundle and compare it with the entry. If the two are equal, this entry is the log record of that exact statement:

```sh
jq -r '.dsseEnvelope.payload' /tmp/inventory-4.1.0.att.sigstore.json | base64 -d | sha256sum
INDEX="$(jq -r '.verificationMaterial.tlogEntries[0].logIndex' /tmp/inventory-4.1.0.att.sigstore.json)"
curl -s "$REKOR_URL/api/v1/log/entries?logIndex=$INDEX" | jq -r '.[].body' | base64 -d | jq -r '.spec.payloadHash.value'
```

If the bundle `/tmp/inventory-4.1.0.att.sigstore.json` exists from an earlier `cosign attest-blob` run, the two values are the same. This check works without the original file and without the key, so an auditor can run it with only the bundle and the log.

## What an audit asks

An audit of attestations asks three questions. Which attestations did this key sign? For each, which artifact is the subject and what is the predicate type? Is each one expected? The log answers the first from its entries, and the second only with the bundle, because the log keeps hashes and not the statement. This is another reason to keep bundles.

You now know how to list the entries of a key, tell signature entries from attestation entries by kind, and tie an entry to a bundle by its payload hash.

## Common pitfalls

> [!WARNING]
> - **Assuming every entry of a key is a signature.** Read the kind first.
> - **Expecting predicate details from the log.** The log holds hashes. The statement is in the bundle.
> - **Trusting the search count as complete.** Walk the log by index when completeness matters.
