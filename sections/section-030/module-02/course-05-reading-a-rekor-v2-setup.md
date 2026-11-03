# Reading A Rekor v2 Setup

Rekor v2 changes how a client finds the log and how it reads it. The private lab runs Rekor v1, so you cannot send an entry to a v2 log here. You can still read and build everything a client needs: the signing config that points to the log, and the layout of the tile files an auditor reads. This part does both with files you create in the workstation.

## The signing config

A signing config tells `cosign` which services to use. The entry for the transparency log has a URL, an API version, and a validity window. Show the lab's config to see the shape:

<!-- astrona:playground:renew -->

```sh
jq '.rekorTlogUrls' /lab/signing-config.json
```

Make a copy that declares a Rekor v2 log. The URL is a placeholder, so the file is not meant to sign against anything:

```sh
jq '.rekorTlogUrls = [{"url": "https://log2026.example.com", "majorApiVersion": 2, "validFor": {"start": "2026-01-01T00:00:00Z"}, "operator": "example.com"}]' \
  /lab/signing-config.json > /tmp/signing-config-v2.json
jq '.rekorTlogUrls[0] | {url, majorApiVersion}' /tmp/signing-config-v2.json
```

The field `majorApiVersion` is what makes `cosign` use the v2 protocol. The lab config uses version 1.

## How tiles are named

A v2 log is stored as static files called tiles. A tile holds a block of hashes of one level of the Merkle tree, and a client fetches only the tiles it needs. The URL has the form `/tile/<level>/<index>`. The index is written in groups of three digits, where every group except the last gets an `x` prefix, so index 1234067 becomes `x001/x234/067`.

Write a small function that builds this path, and test it on three indexes:

```sh
tile_path() {
  n="$(printf '%d' "$1")"; out="$(printf '%03d' $((n % 1000)))"; n=$((n / 1000))
  while [ "$n" -gt 0 ]; do out="$(printf 'x%03d' $((n % 1000)))/$out"; n=$((n / 1000)); done
  echo "$out"
}
for i in 7 1234 1234067; do echo "$i -> $(tile_path "$i")"; done
```

A full tile covers 256 hashes. The last tile on a level can be partial, and its URL has a suffix with the number of hashes it holds, for example `.p/12`.

## What an auditor reads

An auditor reads the checkpoint from `/checkpoint`, picks the tiles needed for a proof, and computes the proof itself. No server code builds a proof for them. This is why tile logs scale well behind a CDN: every URL is a static file.

The entries are stored in tiles too, under `/tile/entries/<index>`. They hold the hashedrekord data in order, so an auditor can read the whole log from the start without a search index. That replaces the search you used with v1.

## What stays the same

The signed checkpoint, the inclusion proof and the consistency proof keep their meaning. A monitor still compares the checkpoint with an earlier one and watches for identities. Only the way the data is fetched changes: files by URL instead of API calls.

You now know how a client config selects v2 and how tile paths are built. For a real log, fetch `/checkpoint` first and use its size to decide which tiles to read.

## Common pitfalls

> [!WARNING]
> - **Pointing a v1 log at `majorApiVersion` 2.** The client speaks the wrong protocol.
> - **Forgetting the `x` prefix in a tile path.** The log answers not found.
> - **Looking for a search endpoint on v2.** There is none. Keep your own index.
