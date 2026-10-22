# Solution: Find And Prove A Release Entry

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the ConfigMap holds a log index and a UUID, they belong to the entry of `inventory-1.2.0.tar.gz.txt`, and that entry's inclusion proof verifies.

## Step 1: Open a shell in the workstation

Every Rekor command runs in the workstation pod, where `rekor-cli` already points at the private log:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Step 2: Find the entry by the artifact's hash

Search the log's index with the artifact file. `rekor-cli` computes the file's SHA-256 hash and asks Rekor which entries record it:

```sh
rekor-cli search --artifact /lab/artifacts/inventory-1.2.0.tar.gz.txt
```

The answer is one entry ID. The artifacts were signed out of order, so do not guess the index from the version number. Keep the ID in a variable:

```sh
ENTRY_ID="$(rekor-cli search --artifact /lab/artifacts/inventory-1.2.0.tar.gz.txt | head -1)"
```

You can search by hash too, which gives the same result: `rekor-cli search --sha "$(sha256sum /lab/artifacts/inventory-1.2.0.tar.gz.txt | cut -d' ' -f1)"`.

## Step 3: Read the entry and its log index

Ask for the entry and pick out its log index:

```sh
rekor-cli get --uuid "$ENTRY_ID" --format json | jq '.LogIndex, .UUID'
```

The JSON output of `rekor-cli get` has the fields `LogIndex` and `UUID`. The API gives the same index, keyed by the entry ID:

```sh
curl -s "$REKOR_URL/api/v1/log/entries/$ENTRY_ID" | jq '.[] | .logIndex'
```

Note the log index and the UUID. The UUID is the last 64 characters of the entry ID.

## Step 4: Verify the inclusion proof

Let `rekor-cli` recompute the root hash from the entry's leaf and check the log's checkpoint and signed entry timestamp:

```sh
rekor-cli verify --uuid "$ENTRY_ID"
```

It reports the index and says that the inclusion proof verified. Leave the workstation shell with `exit`.

## Step 5: Record the answer

Create the ConfigMap from your own machine, with the values you noted. Replace the placeholders:

```sh
kubectl -n workstation create configmap entry-answer \
  --from-literal=log-index=<LOG_INDEX> \
  --from-literal=uuid=<UUID>
```

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign the artifact again and record the new entry | The new entry has a new index and UUID; the auditor asked for the original record |
| Guess the index from the version order | The releases were signed out of order, so 1.2.0 is not the third entry |
| Copy the ID of another release | The grader compares the entry with the hash of `inventory-1.2.0.tar.gz.txt` |

## Common mistakes

- Searching with a path that has a typo: `rekor-cli` then hashes nothing useful and finds no entry.
- Writing the log index with extra spaces or text; the key must hold only the number.
- Creating the ConfigMap in the wrong namespace. It must be in `workstation`.
