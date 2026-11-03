# Signed Entry Timestamps By Hand

A signed entry timestamp (SET) is the log's promise that an entry will be in the tree. The promise is only worth something if you can check it yourself. This part rebuilds the exact bytes that the log signed for one entry, and checks the signature with `openssl` and the log's public key. After it, a SET is no longer a field you trust, but a signature you have verified.

## What the log signs

When Rekor adds an entry, it signs a small JSON document with four fields: `body`, `integratedTime`, `logID` and `logIndex`. The `body` is the Base64 text of the canonical entry. `integratedTime` is the time the log added the entry, in seconds since 1970. `logID` is the hexadecimal SHA-256 hash of the log's public key. `logIndex` is the position of the entry.

The document is written in a canonical form, which means the keys are sorted and there is no extra whitespace, so every program produces the same bytes. The signature over those bytes, Base64 encoded, is the SET. A Sigstore bundle stores it in `inclusionPromise.signedEntryTimestamp`.

## Getting a bundle

Sign a new file with the key `team-a` and keep the bundle. The flags point `cosign` at the private log.

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
printf 'set check\n' > /tmp/set-check.txt
cosign sign-blob --key /lab/keys/team-a.key \
  --signing-config /lab/signing-config.json \
  --trusted-root /lab/trusted-root.json \
  --bundle /tmp/set-check.sigstore.json \
  --yes /tmp/set-check.txt
```

## Rebuilding the signed bytes

Read the four values from the bundle. The bundle stores the log ID as Base64 of the raw hash, so convert it to hexadecimal. The time is a string in the bundle, so convert it to a number. Then print the document in canonical form with `jq -S -c`, which sorts the keys and removes whitespace:

```sh
ENTRY='.verificationMaterial.tlogEntries[0]'
LOG_ID_HEX="$(jq -r "$ENTRY.logId.keyId" /tmp/set-check.sigstore.json | base64 -d | od -An -tx1 | tr -d ' \n')"
jq -S -c --arg id "$LOG_ID_HEX" \
  "$ENTRY | {body: .canonicalizedBody, integratedTime: (.integratedTime | tonumber), logID: \$id, logIndex: (.logIndex | tonumber)}" \
  /tmp/set-check.sigstore.json | tr -d '\n' > /tmp/set-payload.json
cat /tmp/set-payload.json
```

## Checking the signature

Decode the SET into binary and verify it with the log's public key, which is in `/lab/rekor.pub`. `openssl dgst -verify` prints a short success message when the signature is valid:

```sh
jq -r "$ENTRY.inclusionPromise.signedEntryTimestamp" /tmp/set-check.sigstore.json | base64 -d > /tmp/set.sig
openssl dgst -sha256 -verify /lab/rekor.pub -signature /tmp/set.sig /tmp/set-payload.json
```

Now change the time by one second in the payload and verify again. The check fails, because the log signed a different number:

```sh
sed 's/"integratedTime":\([0-9]*\)/"integratedTime":1/' /tmp/set-payload.json > /tmp/set-payload-bad.json
openssl dgst -sha256 -verify /lab/rekor.pub -signature /tmp/set.sig /tmp/set-payload-bad.json
```

## What this proves, and what it does not

A valid SET proves that the log with this key saw this entry body at this time and promised to include it. It does not prove that the entry is in the tree today. Only an inclusion proof against a signed checkpoint proves that. A log that signs a SET and then drops the entry is caught when you ask for the proof and it cannot produce one.

You now know which four values the log signs and how to check the signature yourself. The open question is how the pieces fit when an entry is checked in full: the signature, the SET, the proof and the checkpoint.

## Common pitfalls

> [!WARNING]
> - **Rebuilding the document with other key order.** Sort the keys, or the bytes differ and the signature fails.
> - **Using the time as a string.** The signed document has a number.
> - **Reading a valid SET as proof of inclusion.** It is a promise. The proof comes from the tree.
