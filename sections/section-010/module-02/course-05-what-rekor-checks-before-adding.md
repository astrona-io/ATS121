# What Rekor Checks Before Adding

A log that accepts anything is a log you cannot trust to mean anything. Rekor therefore checks every upload before it adds a leaf to the tree. This part sends three bad uploads and reads how the server rejects each, so you know which claims in an entry the log has verified and which it has not.

## The checks

For a `hashedrekord` entry the server checks that the public key can be parsed, that the signature is valid over the hash for that key, and that the fields have the right form. It then builds the canonical body and the leaf hash. If the same leaf already exists, it answers with a conflict.

The server does not check who owns the key, whether the artifact is safe, or whether a release was approved. Those questions belong to the verifier and to the monitor.

## A good entry first

Sign the demo note with the `demo` key, as in the manual upload, and keep the pieces. You need the signature file in the next steps.

<!-- astrona:playground:renew -->

```sh
printf 'checked note\n' > /tmp/checked-note.txt
openssl dgst -sha256 -sign /lab/keys/demo.key -out /tmp/checked.sig /tmp/checked-note.txt
openssl dgst -sha256 -verify /lab/keys/demo.pub -signature /tmp/checked.sig /tmp/checked-note.txt
```

## A signature that does not match the file

Change the file after signing and upload it with the old signature. The server computes the hash of the file you send, checks the signature against it, and refuses:

```sh
printf 'changed after signing\n' > /tmp/checked-note.txt
rekor-cli upload --artifact /tmp/checked-note.txt --signature /tmp/checked.sig \
  --public-key /lab/keys/demo.pub --pki-format x509
```

The command fails with an error about the signature. The tree size has not changed. Check that with `rekor-cli loginfo`.

## The wrong public key

Restore the file and upload it with a public key that did not make the signature:

```sh
printf 'checked note\n' > /tmp/checked-note.txt
rekor-cli upload --artifact /tmp/checked-note.txt --signature /tmp/checked.sig \
  --public-key /lab/keys/team-a.pub --pki-format x509
```

This fails for the same reason: the signature does not verify with that key. A signature always binds to one key.

## A broken signature

Flip the first byte of the signature file and upload again:

```sh
{ printf '\000'; tail -c +2 /tmp/checked.sig; } > /tmp/broken.sig
rekor-cli upload --artifact /tmp/checked-note.txt --signature /tmp/broken.sig \
  --public-key /lab/keys/demo.pub --pki-format x509
```

The server rejects the upload, usually with a message that the signature could not be parsed or verified. Either way, nothing was added.

## What the rejections tell an auditor

Every entry in the log passed these checks when it was added. So when you read an entry and see a key and a signature, you know they matched the hash at that time. You do not need to check the signature again to know it was valid, though a careful auditor may do it. What you must still check is the meaning: who holds the key, and whether the artifact was meant to be signed.

You now know what Rekor verifies on upload, what it leaves to you, and how a bad upload looks. Now the good upload can be completed, and that closes the loop from the file to the log.

## Common pitfalls

> [!WARNING]
> - **Reading "it is in the log" as "it is approved".** The log only checks that the signature matches.
> - **Retrying a rejected upload with `--insecure` flags.** A rejection is information. Find the mismatch.
> - **Assuming a failed upload left a partial entry.** The tree size does not change on failure.
