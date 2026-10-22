# What Changes With Rekor v2

Everything so far used Rekor v1: a log stored in Trillian and MySQL, with a Redis search index next to it. Sigstore has redesigned the log as Rekor v2, and the redesign removes things an auditor got used to. This part compares the two versions, shows what that means for the evidence you keep, and shows how a client is pointed at a Rekor v2 log.

## A log made of tiles

**Rekor v2**, also called `rekor-tiles`, is a tile-based transparency log built on Tessera, a library from the transparency.dev project. Instead of a database that answers queries, the log is published as static files called tiles: fixed-size pieces of the Merkle tree and of the entry data that anyone can download and cache. That makes the log cheaper to run and simpler to mirror. Rekor v2 ships separate server binaries for different storage, for example Google Cloud, AWS, or a plain POSIX file system.

The table compares what an auditor or a client sees:

| Topic | Rekor v1 | Rekor v2 |
| --- | --- | --- |
| Storage | Trillian with MySQL, Redis for search | Tiles on object storage or a file system |
| Write API | `/api/v1/log/entries` | `/api/v2/log/entries`, the only write API |
| Search index | Yes: by hash, key, e-mail or identity | None |
| Entry kinds | Many, including `hashedrekord`, `dsse`, `intoto` | Only `hashedrekord` (version `0.0.2`); attestations are logged as a `hashedrekord` over their signed bytes |
| Key types | Several, including PGP and SSH | Only certificates and public keys |
| Signed entry timestamp | Returned with every entry | Not returned; `integratedTime` is always 0 |
| Signing time | From the SET's integrated time | From an RFC 3161 timestamp by a timestamp authority (TSA), stored in the bundle |
| Shards | A new tree now and then, same URL | A new log with its own URL, about every six months |

## What it means for your evidence

Two rows in that table change how you work. First, there is no search index. You cannot later ask the log "which entries record this hash?" or "what did this key sign?". A monitor that reads every new entry can still build its own index, but a team that threw away its bundles has no direct way back to its evidence. In Rekor v2, **the bundle is the evidence**: keep a bundle for every artifact you release.

Second, there is no signed entry timestamp. The time of signing must come from a **timestamp authority (TSA)**, a service that signs a timestamp for the signature following RFC 3161. The bundle stores that signed timestamp in `verificationMaterial.timestampVerificationData`, and the trusted root must hold the TSA's certificate chain. Sigstore runs a public TSA at `timestamp.sigstore.dev`. A bundle from Rekor v2 therefore carries an inclusion proof with its checkpoint, but no `inclusionPromise`.

## How a client finds a Rekor v2 log

A client does not hard-code a log URL. It reads the signing config, which lists log URLs with their major API version and a validity window. When a shard closes, the operator adds the next one with a new start date, and clients that refresh their signing config move to it. The trusted root keeps the keys of old shards, so old bundles still verify.

You can write such a signing config yourself. In the workstation shell, create one that points at a Rekor v2 log. No Rekor v2 runs in this playground, so you will not sign with it; the point is to see the shape.

<!-- astrona:playground:renew -->

`api-version=2` is what tells `cosign` to speak the Rekor v2 protocol:

```sh
cosign signing-config create \
  --rekor="url=http://rekor-v2.localtest.me,api-version=2,start-time=2026-10-01T00:00:00Z,operator=astrona-lab" \
  --rekor-config=ANY \
  --out /tmp/signing-config-v2.json
jq '.rekorTlogUrls' /tmp/signing-config-v2.json
```

The entry has the URL, `majorApiVersion` 2, the validity start and the operator. Compare it with the lab's working signing config, which has the same fields with version 1:

```sh
jq '.rekorTlogUrls' /lab/signing-config.json
```

## The public-good instance

The Sigstore community runs a public Rekor v2 with yearly shards; the `rekor-tiles` project names `https://log2025-1.rekor.sigstore.dev` as its 2025 shard and warns that shard URLs change. At the time of writing, in October 2026, the trusted root that Sigstore distributes through TUF already lists the key of `https://log2025-1.rekor.sigstore.dev` (Rekor v2) next to `https://rekor.sigstore.dev` (Rekor v1), so clients can verify entries from both. The signing config distributed the same way still lists only the Rekor v1 log, so clients sign to Rekor v1 by default. Whether your clients sign to v1 or v2 therefore depends on the signing config they read, not on the client version alone. Check the current signing config before you plan around either.

You now know what Rekor v2 removes, why that makes keeping bundles essential, where the signing time comes from instead, and how a signing config moves clients from one log to another.

## Common pitfalls

> [!WARNING]
> - **Planning to search the log later.** Rekor v2 has no search index. Keep a bundle for every artifact.
> - **Hard-coding a log URL.** Rekor v2 shards get new URLs. Let clients read the signing config.
> - **Expecting a SET from Rekor v2.** There is none; the signing time comes from a signed RFC 3161 timestamp.
> - **Logging attestations as `dsse` or `intoto` entries in Rekor v2.** Rekor v2 accepts only `hashedrekord`; clients log the signed bytes of the envelope instead.
