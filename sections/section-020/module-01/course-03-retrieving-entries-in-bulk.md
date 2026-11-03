# Retrieving Entries In Bulk

A search answers "which entries match this hash or this key?". An audit often asks a different question: "what is in the log between these two points?". The search index cannot answer that, because it only knows hashes and keys. This part reads entries by log index, singly and in batches, and builds a table of the whole playground log from the entries themselves.

## Reading one entry by index

Every entry has a log index, and the index is the one thing you can always enumerate: the first entry is 0 and the last is the tree size minus one. `rekor-cli get --log-index` reads one entry. In the workstation shell, read the first entry of the playground log:

<!-- astrona:playground:renew -->

```sh
rekor-cli get --log-index 0 --format json | jq '{LogIndex, IntegratedTime, UUID}'
```

The answer holds the index, the integrated time in Unix seconds and the UUID. The decoded entry body is in the same JSON under `Body`. Reading by index needs no search index, so it works even if Redis lost its data.

## Reading a range in a loop

The tree size tells you how far to read. Ask for it, then read every index below it and print one line per entry with the integrated time converted to a date:

```sh
SIZE="$(curl -s "$REKOR_URL/api/v1/log" | jq -r '.treeSize')"
echo "tree size: $SIZE"
i=0
while [ "$i" -lt "$SIZE" ]; do
  rekor-cli get --log-index "$i" --format json | jq -r '[.LogIndex, (.IntegratedTime | todate), .UUID] | @tsv'
  i=$((i + 1))
done
```

The loop makes one request per entry, which is fine for a small log and slow for a large one. The public log holds many millions of entries, so nobody reads it this way. An auditor reads a range, or asks for a batch.

## Reading a batch with one request

The API can return several entries in one request. `POST /api/v1/log/entries/retrieve` takes a JSON body with a list of log indexes, or a list of entry UUIDs, and returns the entries:

```sh
curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"logIndexes":[0,1,2]}' \
  "$REKOR_URL/api/v1/log/entries/retrieve" | jq 'length'
```

The answer is a list with one object per entry. Each object has one key, the entry UUID, and the entry as its value. The count is the number of indexes that exist, so a list that reaches past the end of the log returns fewer entries than you asked for, not an error. The server limits how many entries one request may carry, so a long range needs several requests.

## Building a table from the bodies

The index alone is not much use. What you want in an audit is the artifact hash and the signer of each entry. Fetch the batch, decode every body and print a table of index, artifact hash and the first characters of the public key:

```sh
curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"logIndexes":[0,1,2]}' \
  "$REKOR_URL/api/v1/log/entries/retrieve" \
  | jq -r '.[] | to_entries[] | .value | [.logIndex, (.body | @base64d | fromjson | .spec.data.hash.value), (.body | @base64d | fromjson | .spec.signature.publicKey.content | .[0:12])] | @tsv'
```

The first column is the log index, the second the SHA-256 hash recorded in the entry, and the third the beginning of the Base64 public key. Entries signed with the same key share the same third column. That is the quickest way to see how many signers a log has.

## Why walking by index matters

A search by key asks the index. A walk by index asks the tree. The two give the same answer when the index is complete. When they differ, the walk is the one to trust, because the tree is the record. An auditor who suspects the index of missing something walks the range and decodes every body.

You now know how to read one entry, a range and a batch by index, and how to turn the bodies into a table. The next question is what the table tells you about when things happened.

## Common pitfalls

> [!WARNING]
> - **Reading past the end.** Index values start at 0, so the last entry has the index tree size minus one.
> - **Trusting a search for completeness.** The index can miss entries. Walk the range when a missing entry matters.
> - **Sending a very long range in one request.** The server limits the batch size. Send several requests.
