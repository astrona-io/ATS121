# Witnesses And Cosigned Checkpoints

A log signs its own checkpoints, so a log that wants to lie can sign two different histories, one for each audience. A **witness** closes that gap. A witness is an independent party that keeps the last checkpoint it saw for a log, checks that each new checkpoint is consistent with it, and only then adds its own signature. A verifier that requires witness signatures cannot be shown a forked history unless the witnesses are fooled too.

## What a checkpoint note looks like

A checkpoint is a signed note: a few lines of text, an empty line, and one or more signature lines. The text holds the log origin, the tree size and the root hash. Each signature line starts with a dash, a name, and a Base64 value.

The lab log has one signer, itself. Read the checkpoint from a bundle and look at its structure. Take the bundle for `inventory-3.0.0` that the playground made:

<!-- astrona:playground:renew -->

```sh
jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.checkpoint.envelope' \
  /lab/bundles/inventory-3.0.0.txt.sigstore.json
```

The first three lines are the origin, the size and the root hash. Count the signature lines, which start with an em dash:

```sh
jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.checkpoint.envelope' \
  /lab/bundles/inventory-3.0.0.txt.sigstore.json | grep -c '^—'
```

The count is the number of parties that signed this checkpoint. For the private lab the count is one.

## What a witness does

When the log publishes a new checkpoint, it sends the checkpoint and a consistency proof from the old size to the witness. The witness checks the proof against the last checkpoint it stored. If the proof holds, the witness stores the new checkpoint and returns a signature over the same note text. If the proof fails, it refuses. A witness never trusts the log's word: it only trusts the math and its own memory.

The log then attaches the witness signatures to the checkpoint. The result is a **cosigned checkpoint**: the same text with several signature lines, one from the log and one from each witness. A witness signature usually carries a timestamp, so the line also tells when the witness saw the checkpoint.

## How a verifier uses witnesses

A verifier holds a policy that names the witnesses it trusts and how many must have signed, for example two out of three. It checks the log signature, then counts the valid witness signatures, and accepts the checkpoint only if the count reaches the threshold. This policy lives in the verifier, not in the log, so the log cannot lower it.

Here is the check you can do by hand: take a checkpoint, count the signature lines, and compare with a threshold you set.

```sh
SIGS="$(jq -r '.verificationMaterial.tlogEntries[0].inclusionProof.checkpoint.envelope' \
  /lab/bundles/inventory-3.0.0.txt.sigstore.json | grep -c '^—')"
THRESHOLD=2
if [ "$SIGS" -ge "$THRESHOLD" ]; then echo "enough signatures"; else echo "need $THRESHOLD, found $SIGS"; fi
```

Against the private lab this prints that more signatures are needed, because the lab has no witnesses. This counts lines only. A real verifier checks each signature with the witness public key and ignores lines from unknown names.

## What a witness does not prove

A witness proves that the log showed it one consistent history. It does not prove that the entries are honest, and it does not look at what is signed. Witnesses also need to be independent: three witnesses run by the same party count as one.

You now know what a cosigned checkpoint is, how a witness decides to sign, and how a verifier turns signature lines into a policy. What remains is the signer side: the identity inside a certificate.

## Common pitfalls

> [!WARNING]
> - **Counting signature lines as valid signatures.** Check each one with the witness key.
> - **Trusting witnesses from one operator.** Independence is the point.
> - **Expecting witnesses in the private lab.** It has none, so the count is one.
