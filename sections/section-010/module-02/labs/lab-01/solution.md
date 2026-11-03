# Solution: Upload A Signature To The Log

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: Rekor has a verifiable entry for the notice's hash, the entry was made with `notice.pub`, and `notice-entry` holds that entry's log index and UUID.

## Step 1: Sign the notice

Open a shell in the workstation:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Sign the file with the private key. `openssl dgst -sha256 -sign` hashes the file and signs the hash:

```sh
openssl dgst -sha256 -sign /lab/keys/notice.key -out /tmp/notice.sig /lab/artifacts/security-notice.txt
```

## Step 2: Upload the entry

Send the artifact, the signature and the public key to Rekor. `--pki-format x509` tells `rekor-cli` that the key is a PEM file:

```sh
rekor-cli upload --artifact /lab/artifacts/security-notice.txt \
  --signature /tmp/notice.sig \
  --public-key /lab/keys/notice.pub \
  --pki-format x509
```

## Step 3: Verify the entry and read its index

Find the entry by the hash of the file and ask Rekor to prove it:

```sh
ENTRY_ID="$(rekor-cli search --artifact /lab/artifacts/security-notice.txt | head -1)"
rekor-cli verify --uuid "$ENTRY_ID"
curl -s "$REKOR_URL/api/v1/log/entries/$ENTRY_ID" | jq '.[] | {logIndex}'
echo "$ENTRY_ID"
```

Note the log index and the entry ID. Leave the shell with `exit`.

## Step 4: Record the answer

Create the ConfigMap with your two values. Replace the placeholders:

```sh
kubectl -n workstation create configmap notice-entry \
  --from-literal=log-index=<LOG_INDEX> \
  --from-literal=uuid=<ENTRY_ID>
```

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign the notice with `cosign` and the `team-a` key | The entry exists, but it was not made with the `notice` key |
| Upload without `--pki-format x509` | `rekor-cli` expects a PGP key and the upload fails |
| Guess the log index from the tree size | Other entries may have arrived; read the index from the entry |

## Common mistakes

- Uploading a copy of the file that has changed. The signature covers the original hash.
- Creating the ConfigMap in the wrong namespace. It must be in `workstation`.
- Putting the index in a different key name. The keys are `log-index` and `uuid`.
