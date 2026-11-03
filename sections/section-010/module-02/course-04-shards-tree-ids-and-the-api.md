# Shards, Tree IDs And The API

Every command in this module so far called the same HTTP API, either directly with `curl` or through `rekor-cli`. A log also has to survive growth: one Merkle tree cannot grow without limit. This part explains how an entry ID is built, what a shard is, and which API calls an auditor uses most.

## How an entry ID is built

Search results in Rekor v1 may print an 80-character hexadecimal ID. It has two parts. The first 16 characters are the **tree ID** in hexadecimal: the number of the Trillian tree that holds the entry. The last 64 characters are the **UUID**, which is the leaf hash of the entry.

You can prove it with the playground log. The API reports the tree ID as a decimal number. Convert it to 16 hexadecimal characters and compare it with the start of an entry ID.

<!-- astrona:playground:renew -->

```sh
TREE_ID="$(curl -s "$REKOR_URL/api/v1/log" | jq -r '.treeID')"
printf '%016x\n' "$TREE_ID"
rekor-cli search --artifact /lab/artifacts/release-1.0.0.txt | head -1
```

If the search prints an 80-character ID, its first 16 characters equal the converted tree ID. If it prints 64 characters, the client has removed the tree ID, and the 64 characters are the same UUID.

## Why a log has shards

A Merkle tree in a database grows with every entry, and a very large tree is slow and costly to run. Rekor handles this with **sharding**: when a tree gets too large, the operator starts a new Trillian tree and makes it the active one. New entries go to the active tree. The old tree stays, frozen, and keeps answering reads. Each tree is a **shard**.

From the outside the log is still one URL. The server knows all its shards. The tree ID in the entry ID tells it which shard holds an entry, so a lookup by full entry ID finds the right tree. The log index, in contrast, counts across shards: the first entry of a new shard continues the numbering of the old one.

## Reading the shards from the API

The state endpoint lists the shards. The playground log is new, so it has only one tree and no inactive shards:

```sh
curl -s "$REKOR_URL/api/v1/log" | jq '{treeID, treeSize, inactiveShards}'
```

`treeID` is the active tree. `inactiveShards` is a list with one object per frozen tree, each with its own tree ID, tree size, root hash and signed tree head. On the public log it is not empty.

For an auditor, shards add a rule: a root hash and a tree size belong to one tree. A consistency check runs inside one shard. When a log rotates, the checkpoint of the old shard stays as the final word on that shard, and the checkpoint of the new shard starts from size zero in its own tree.

## The calls an auditor uses

Four API calls cover most audit work. Each one has a `rekor-cli` command that calls it:

| API call | What it returns | `rekor-cli` command |
| --- | --- | --- |
| `GET /api/v1/log` | Tree size, root hash, tree ID, signed tree head, inactive shards | `loginfo` |
| `GET /api/v1/log/entries?logIndex=N` | The entry at index N, with its proof | `get --log-index N` |
| `GET /api/v1/log/entries/{id}` | The entry with that ID or UUID | `get --uuid ID` |
| `GET /api/v1/log/proof?firstSize=A&lastSize=B` | A consistency proof | `logproof` |

The index search is a `POST` to `/api/v1/index/retrieve` with a hash or a public key in the body; `rekor-cli search` calls it. Read an entry by index with `curl` and print its UUID, which is the key of the returned object:

```sh
curl -s "$REKOR_URL/api/v1/log/entries?logIndex=0" | jq 'keys'
```

The key of the returned object is the entry ID. Use the index when you walk the log in order, and the UUID when you follow a result from a search.

## Errors an auditor should recognise

A request for an index beyond the tree size returns an error with status 404, not an empty answer. An upload of an existing entry returns 409 with the existing UUID in the message. A malformed body returns 400, and the message says which field failed. A response in the 500 range means the server or Trillian failed, and says nothing about whether an entry exists.

You now know how an entry ID is built, what a shard is, and which calls and errors an auditor sees. Together with the entry types and the upload, that is the full path of an entry: a client signs a hash, the server checks and canonicalizes it, Trillian adds a leaf, and the ID names the tree and the leaf.

## Common pitfalls

> [!WARNING]
> - **Passing the 80-character ID where a UUID is expected.** Some flags accept both. Compare entries by the last 64 characters.
> - **Mixing log indexes with tree positions.** The log index counts across shards. The tree size of one shard does not.
> - **Reading an empty search result as "not in the log".** The search index is separate from the tree. Check by hash with a proof when it matters.
