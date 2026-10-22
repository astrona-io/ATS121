# Searching The Log

A log with thousands of entries is useless if the only way in is the log index. An auditor starts from what they have: a file, a hash from a release page, or a public key. This part shows the search index Rekor v1 keeps, and how to query it in each of those three ways.

## What the search index covers

Rekor's tree only knows positions: entry 0, entry 1, and so on. To find entries by content, Rekor v1 keeps a **search index** in Redis next to the tree. When it accepts an entry, it adds index keys for it, for example the artifact's SHA-256 hash and the hash of the public key that signed it. A search is a lookup of one such key, and the answer is a list of entry IDs.

The table shows what you can search for and which flag of `rekor-cli search` does it:

| You have | Flag | Rekor looks up |
| --- | --- | --- |
| The artifact file | `--artifact <file>` | The file's SHA-256 hash, computed by `rekor-cli` |
| A hash from a release page | `--sha <hex>` | That hash (SHA-256, SHA-512 or SHA-1) |
| A public key | `--public-key <file> --pki-format x509` | The key |
| An e-mail address | `--email <address>` | The e-mail in a certificate (keyless signing) |
| A certificate identity | `--subject <value>` | A subject alternative name in a certificate |

The index is a convenience, not part of the log's proofs. The tree and its proofs say what is in the log; the index only helps you find it. That difference matters later, because Rekor v2 has no search index at all.

## Searching by artifact and by hash

Start with the artifact. In the workstation shell, search for one of the playground's files.

<!-- astrona:playground:renew -->

`rekor-cli` hashes the file and looks the hash up:

```sh
rekor-cli search --artifact /lab/artifacts/api-1.0.0.txt
```

The answer is one entry ID, because the file was signed once. Hash the file yourself and search by the hash, the way you would with a hash copied from a release page:

```sh
API_HASH="$(sha256sum /lab/artifacts/api-1.0.0.txt | cut -d' ' -f1)"
rekor-cli search --sha "$API_HASH"
```

The same entry ID comes back. A search by hash finds every signature over the same bytes, so if two keys had signed this exact file, you would get two IDs.

## Searching by public key

The question an auditor asks most often is "what did this key sign?". A public key search answers it. The keys `cosign` generates are PEM-encoded public keys in the X.509 format, so tell `rekor-cli` that with `--pki-format x509`:

```sh
rekor-cli search --public-key /lab/keys/team-a.pub --pki-format x509
```

Two entry IDs come back: `api-1.0.0.txt` and `api-1.1.0.txt` were signed with `team-a`. Search for `team-b` and count again:

```sh
rekor-cli search --public-key /lab/keys/team-b.pub --pki-format x509
```

One entry, `web-1.0.0.txt`. With `--operator and` you can combine conditions, for example a key and a hash, and get only the entries that match both.

## Searching through the API

Scripts usually skip `rekor-cli` and call the index directly. The endpoint `/api/v1/index/retrieve` takes a JSON body with a `hash` or a `publicKey`, and returns the list of entry IDs:

```sh
curl -s -X POST -H 'Content-Type: application/json' \
  -d "{\"hash\":\"sha256:$API_HASH\"}" \
  "$REKOR_URL/api/v1/index/retrieve" | jq .
```

For a public key, the body holds the key file in Base64 and its format, the same information as the `rekor-cli` flags:

```sh
TEAM_A_KEY="$(base64 < /lab/keys/team-a.pub | tr -d '\n')"
curl -s -X POST -H 'Content-Type: application/json' \
  -d "{\"publicKey\":{\"format\":\"x509\",\"content\":\"$TEAM_A_KEY\"}}" \
  "$REKOR_URL/api/v1/index/retrieve" | jq .
```

The IDs in these answers can be 80 characters long: 16 characters that name the tree, then the 64-character UUID. When you compare IDs from different commands, compare the last 64 characters.

You can now go from a file, a hash or a key to the entries that record it. What an entry actually says, and how to tell a good entry from a suspicious one, is the next step.

## Common pitfalls

> [!WARNING]
> - **Forgetting `--pki-format x509`.** Without it, `rekor-cli` does not know how to read the key file and the search fails.
> - **Expecting a search for a changed file to find the old entry.** The search uses the hash of the file as it is now.
> - **Treating an empty search as proof that nothing was signed.** It proves the index has no such key on this log. Signatures sent to another log, or never logged, do not show up.
> - **Searching the public log by accident.** `rekor-cli` uses the public log unless `--rekor_server` or `REKOR_REKOR_SERVER` points elsewhere. In the workstation it points at the private log.
