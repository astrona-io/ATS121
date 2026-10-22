# Solution: Investigate An Unknown Signer

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the recorded public key is the one in the log entry of `inventory-2.0.0.txt`, and the list of entries and the earliest index match what Rekor's index returns for that key.

## Step 1: Find the entry of the suspicious file

Open a shell in the workstation and search by the artifact:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
ENTRY_ID="$(rekor-cli search --artifact /lab/artifacts/inventory-2.0.0.txt | head -1)"
echo "$ENTRY_ID"
```

## Step 2: Pull the signer's public key out of the entry

Decode the body and then the Base64 public key inside it, and save it as a PEM file:

```sh
curl -s "$REKOR_URL/api/v1/log/entries/$ENTRY_ID" | jq -r '.[].body' | base64 -d \
  | jq -r '.spec.signature.publicKey.content' | base64 -d > /tmp/intruder.pub
cat /tmp/intruder.pub
diff -q /tmp/intruder.pub /lab/keys/release.pub
```

`diff` reports that the files differ: the file was not signed with the team's `release` key.

## Step 3: List every entry of that key

Search by the key you just extracted:

```sh
rekor-cli search --public-key /tmp/intruder.pub --pki-format x509 | tee /tmp/intruder-entries.txt
```

Two entries come back: `inventory-2.0.0.txt` and one more artifact, a helper file that was deleted from `/lab` afterwards.

## Step 4: Find the earliest entry

Print the log index of each entry and sort:

```sh
for id in $(cat /tmp/intruder-entries.txt); do
  curl -s "$REKOR_URL/api/v1/log/entries/$id" | jq -r '.[].logIndex'
done | sort -n | head -1
```

The smallest index is when the key was first used in this log. It is earlier than the entry of `inventory-2.0.0.txt`: the key was used before the suspicious release appeared. Note the index, then leave the shell with `exit`.

## Step 5: Record the answer

Copy the two files to your machine and create the ConfigMap. Replace the placeholder:

```sh
kubectl -n workstation exec deploy/workstation -- cat /tmp/intruder.pub > intruder.pub
kubectl -n workstation exec deploy/workstation -- cat /tmp/intruder-entries.txt > intruder-entries.txt
kubectl -n workstation create configmap intruder-report \
  --from-file=signer-public-key=intruder.pub \
  --from-file=intruder-uuids=intruder-entries.txt \
  --from-literal=first-intruder-index=<FIRST_INDEX>
```

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Record `release.pub` as the signer | The log entry names a different key; `inventory-2.0.0.txt` was not signed by the team |
| Record only the entry of `inventory-2.0.0.txt` | The key made another entry before it; the report must list every one |
| Take the index of `inventory-2.0.0.txt` as the first one | The key was used earlier; sort the indexes of all its entries |

## Common mistakes

- Decoding the public key only once and recording Base64 instead of the PEM block.
- Sorting log indexes as text instead of numbers (`sort -n`).
- Creating the ConfigMap in the wrong namespace. It must be in `workstation`.
