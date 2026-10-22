# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Auditing

## Scenario

The private key of the old CI system, `ci-old`, was found in a public repository. The security team removed the private key from the team's machines; only the public key is left, at `/lab/keys/ci-old.pub` in the workstation pod. Three keys have signed artifacts into the team's private Rekor: `team-a`, `team-b` and `ci-old`.

The team's release manifest, `/lab/release-manifest.txt`, lists the SHA-256 hash and name of every artifact the team really released:

```sh
kubectl -n workstation exec deploy/workstation -- cat /lab/release-manifest.txt
```

## Your task

1. List every Rekor entry that was signed with the `ci-old` key.
2. Find the one artifact that `ci-old` signed which is **not** in the release manifest. The file itself was deleted, so only the log knows its hash.
3. Record your findings in a ConfigMap named `leak-audit` in the namespace `workstation`, with two keys:
   - `uuids`: the entry IDs of every `ci-old` entry, one per line. 64-character UUIDs and longer entry IDs both count.
   - `unexpected-sha256`: the SHA-256 hash, in lower-case hexadecimal, of the artifact `ci-old` signed outside the release.

## Constraints

- List exactly the `ci-old` entries: no entries of other keys, and none left out.
- Do not sign anything new, and do not change files in `/lab`.
- Do not restart the Rekor server pod.

## Done when

- `uuids` holds every entry signed with `ci-old`, and nothing else.
- `unexpected-sha256` is the hash of the `ci-old` artifact that is not in the release manifest.
