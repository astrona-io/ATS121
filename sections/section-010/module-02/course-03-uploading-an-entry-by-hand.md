# Uploading An Entry By Hand

`cosign sign-blob` does four things in one command: it hashes a file, signs the hash, uploads an entry and writes a bundle. Doing the same steps one at a time shows what a log needs from a client, and what a client must keep afterwards. This part signs a file with `openssl`, uploads the signature with `rekor-cli upload`, verifies the new entry, and then uploads it a second time to see how Rekor treats a duplicate.

## What the log needs

A `hashedrekord` entry needs three things: the SHA-256 hash of the artifact, a signature over that hash, and the public key that verifies the signature. `cosign` makes the first two with a key pair. You can make them with `openssl`. The playground has an ECDSA key pair `demo` on the P-256 curve, in `/lab/keys/demo.key` (private, PEM) and `/lab/keys/demo.pub` (public, PEM), and an artifact `/lab/artifacts/demo-note.txt` that is not in the log yet.

Check that the log does not know the file. The search finds nothing, which is the correct answer for an unlogged file:

<!-- astrona:playground:renew -->

```sh
rekor-cli search --artifact /lab/artifacts/demo-note.txt
```

## Signing with openssl

`openssl dgst -sha256 -sign` hashes the file with SHA-256 and signs the hash with the private key. For an ECDSA key it writes the signature in DER format, a binary encoding. Rekor accepts that format for ECDSA signatures.

```sh
openssl dgst -sha256 -sign /lab/keys/demo.key -out /tmp/demo-note.sig /lab/artifacts/demo-note.txt
```

Check the signature yourself before the log does. `openssl dgst -verify` uses the public key and prints a short message when the signature is valid:

```sh
openssl dgst -sha256 -verify /lab/keys/demo.pub -signature /tmp/demo-note.sig /lab/artifacts/demo-note.txt
```

## Uploading with rekor-cli

`rekor-cli upload` takes the artifact, the signature and the public key. The flag `--pki-format x509` tells it that the key is in PEM format, which is what a PEM public key or certificate from `openssl` is. `rekor-cli` hashes the file, builds the `hashedrekord` entry and sends it to the server, which checks the signature before it adds the entry.

```sh
rekor-cli upload --artifact /lab/artifacts/demo-note.txt \
  --signature /tmp/demo-note.sig \
  --public-key /lab/keys/demo.pub \
  --pki-format x509
```

On success, `rekor-cli` prints the log index of the new entry and the URL where it is available. The tree size has grown by one:

```sh
rekor-cli loginfo
```

Search again. The same command that found nothing before now finds the entry, because the index now knows the hash:

```sh
ENTRY_ID="$(rekor-cli search --artifact /lab/artifacts/demo-note.txt | head -1)"
echo "$ENTRY_ID"
```

## Verifying what you uploaded

The new entry is a normal entry, so the same verification applies. `rekor-cli verify` fetches the inclusion proof and checks it against the log's checkpoint:

```sh
rekor-cli verify --uuid "$ENTRY_ID"
```

You can also verify from the original files, without an entry ID. This recomputes the entry from the artifact, signature and key, looks it up, and checks its proof:

```sh
rekor-cli verify --artifact /lab/artifacts/demo-note.txt \
  --signature /tmp/demo-note.sig \
  --public-key /lab/keys/demo.pub \
  --pki-format x509
```

## Uploading the same entry twice

Run the upload command again. Rekor does not add a second entry. It returns a conflict error (HTTP status 409) that names the UUID of the entry that already exists. The log keeps one entry for one artifact, one signature and one key, so the log index you got the first time stays valid.

A different signature for the same artifact is a different entry. ECDSA signatures are not the same on every run, so signing the file again with the same key and uploading the new signature adds a second entry for the same hash and key. This is why a search by artifact can return more than one entry for one file.

## What you must keep

The log keeps the hash, the signature and the key. It does not keep the file. You need the file, to recompute the hash, and the entry ID or log index, to find the entry again. `cosign` writes both into a bundle for you. When you work by hand, write them down.

You now know what the log needs from a client, how to create an entry without `cosign`, and how Rekor reacts to a duplicate. What remains is how the entry ID is built and how a client reaches the log.

## Common pitfalls

> [!WARNING]
> - **Forgetting `--pki-format x509`.** Without it, `rekor-cli` expects a PGP key and the upload fails.
> - **Signing the file and uploading a changed file.** The log checks the signature over the hash of the file you upload. If the file changed after signing, the upload fails.
> - **Treating a 409 conflict as a failure of the log.** It means the entry is already there. Search for it.
> - **Using a certificate-less key and expecting an identity.** An entry with a bare public key tells you which key signed, not who owns it.

## Your mission: Upload A Signature To The Log

You can now sign a file with `openssl`, upload the signature as a `hashedrekord` entry and verify it. The graded lab gives you a security notice and a key, and asks you to get the notice into the log and record its entry.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-121-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-121-lab-010-02
astrona start ats-121-playground-010-02
```
