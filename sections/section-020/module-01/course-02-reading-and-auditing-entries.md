# Reading And Auditing Entries

A list of entry IDs tells you how many signatures a key made. It does not tell you what was signed, or when. This part opens an entry, pulls out the artifact hash, the signature and the public key it records, and then walks through a full audit of one key against the list of what your team really shipped.

## What a hashedrekord entry holds

Every entry stores a **body**: the exact JSON that Rekor accepted, in a canonical form, so its hash never changes. For a `hashedrekord` entry the body has a kind, an API version and a `spec` with two parts: `data.hash`, the algorithm and value of the artifact's hash, and `signature`, the signature in Base64 and the public key that verifies it, also in Base64. Next to the body, Rekor keeps the log index, the log ID and the **integrated time**, the moment Rekor accepted the entry, in Unix seconds.

Start with an entry you know. In the workstation shell, find the entry of `api-1.1.0.txt`.

<!-- astrona:playground:renew -->

Keep its ID in a variable:

```sh
ENTRY_ID="$(rekor-cli search --artifact /lab/artifacts/api-1.1.0.txt | head -1)"
```

`rekor-cli get` shows the entry with the body already decoded, together with `LogIndex`, `IntegratedTime` and `UUID`:

```sh
rekor-cli get --uuid "$ENTRY_ID" --format json | jq .
```

## Decoding the body yourself

For a script, the stored body is more useful, because it is exactly what Rekor hashed. The API returns it in Base64; decode it and read it with `jq`:

```sh
curl -s "$REKOR_URL/api/v1/log/entries/$ENTRY_ID" | jq -r '.[].body' | base64 -d | jq .
```

The JSON has `kind` set to `hashedrekord` and the `spec` described above. Pull out the two values an auditor needs most, the artifact hash and the public key. The key is Base64 of a PEM file, so decode it once more:

```sh
BODY="$(curl -s "$REKOR_URL/api/v1/log/entries/$ENTRY_ID" | jq -r '.[].body' | base64 -d)"
printf '%s' "$BODY" | jq -r '.spec.data.hash.value'
printf '%s' "$BODY" | jq -r '.spec.signature.publicKey.content' | base64 -d
```

The first line is the SHA-256 of `api-1.1.0.txt`; compare it with `sha256sum /lab/artifacts/api-1.1.0.txt`. The second is the PEM public key of `team-a`, the same text as `/lab/keys/team-a.pub`. This is how you find a signer you do not know: the log hands you its public key.

## Placing an entry in time

The log index orders entries: a smaller index was added earlier. The integrated time gives the clock time. Convert it to a date with the `date` command in the workstation:

```sh
WHEN="$(rekor-cli get --uuid "$ENTRY_ID" --format json | jq -r '.IntegratedTime')"
date -u -d "@$WHEN"
```

The first entry of a key is the entry with the smallest log index among its search results. That is when the key was first used, as far as this log knows.

## Auditing one key

An audit compares two lists: what the log says a key signed, and what your team says it shipped. Your team's list is a **release manifest**, a file with the SHA-256 hash of every artifact it released. The audit has four steps:

1. List every entry ID for the key with a public key search.
2. For each entry, decode the body and read the artifact hash.
3. Look each hash up in the release manifest.
4. Every hash that is not in the manifest is a signing event nobody expected.

A short loop does the whole audit for `team-a` in the playground. Make a manifest with the two `api` files first, then compare:

```sh
sha256sum /lab/artifacts/api-1.0.0.txt /lab/artifacts/api-1.1.0.txt | cut -d' ' -f1 > /tmp/manifest.txt
for id in $(rekor-cli search --public-key /lab/keys/team-a.pub --pki-format x509); do
  hash="$(curl -s "$REKOR_URL/api/v1/log/entries/$id" | jq -r '.[].body' | base64 -d | jq -r '.spec.data.hash.value')"
  grep -qx "$hash" /tmp/manifest.txt && echo "expected   $id" || echo "UNEXPECTED $id $hash"
done
```

Both entries are expected here. In a real incident, an `UNEXPECTED` line is a hash you then try to match with a file, a build log or a registry. The entry ID and the log index are your evidence: they point at a record the log cannot remove.

You can now read every field of an entry, find a signer from the log alone, and audit one key against a release manifest. That is the core of incident response with a transparency log.

## Common pitfalls

> [!WARNING]
> - **Decoding the public key only once.** The body holds the PEM file in Base64. Decode it to get the readable `BEGIN PUBLIC KEY` block.
> - **Comparing hashes with different letter case or spaces.** Compare the lower-case hexadecimal value, without spaces or file names.
> - **Taking the first search result as the first entry.** Search results are not ordered by time. Sort by log index to find the earliest.
> - **Treating "not in the manifest" as proof of an attack.** It is a lead. Check build logs and registries before you call it an incident.

## Your mission: Find Every Entry Signed By A Leaked Key

You can now list every entry made by one key and compare it with a release manifest. The graded lab gives you a leaked CI key, the team's release manifest and a log with several keys in it, and asks you to list every entry the leaked key made and name the artifact it signed outside the release.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-121-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-121-lab-020-01
astrona start ats-121-playground-020-01
```
