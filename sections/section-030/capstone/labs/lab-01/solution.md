# Solution: Keep Verifiable Evidence For Rekor v2

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: every release artifact has a bundle that verifies with the release key, every bundle is a v0.3 bundle with an inclusion proof and checkpoint, and the Rekor v2 signing config has the required values.

## Step 1: Find out what is wrong today

Open a shell in the workstation and try the one bundle that exists:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
cosign verify-blob --key /lab/keys/release.pub --trusted-root /lab/trusted-root.json \
  --bundle /lab/release/inventory-4.0.0.txt.sigstore.json /lab/release/inventory-4.0.0.txt
```

The signature check fails: the bundle was made with the retired CI key, not the release key. Its log evidence is fine, but it does not prove what the team needs. Since the retired private key is gone, the only way to get a bundle the release key verifies is to sign the artifact again with the release key. The old entry stays in the log; that is expected.

## Step 2: Sign every release artifact with the release key

Sign against the private log, writing each bundle next to its artifact. The signing config sends the entry to the private Rekor, so the bundle gets its inclusion proof and checkpoint:

```sh
export COSIGN_PASSWORD=lab-only-password
for name in inventory-4.0.0 inventory-4.0.1 inventory-4.1.0; do
  cosign sign-blob --key /lab/keys/release.key \
    --signing-config /lab/signing-config.json \
    --bundle "/lab/release/$name.txt.sigstore.json" \
    --yes "/lab/release/$name.txt"
done
```

## Step 3: Verify the evidence

Verify each bundle offline, and check that it is a v0.3 bundle with an inclusion proof and checkpoint:

```sh
for name in inventory-4.0.0 inventory-4.0.1 inventory-4.1.0; do
  cosign verify-blob --key /lab/keys/release.pub --trusted-root /lab/trusted-root.json \
    --bundle "/lab/release/$name.txt.sigstore.json" "/lab/release/$name.txt"
  jq -r '.mediaType, (.verificationMaterial.tlogEntries[0].inclusionProof.checkpoint.envelope | length > 0)' \
    "/lab/release/$name.txt.sigstore.json"
done
```

Each artifact verifies, and each bundle reports the v0.3 media type and a non-empty checkpoint.

## Step 4: Write the Rekor v2 signing config

`cosign signing-config create` writes the file; `api-version=2` selects the Rekor v2 protocol:

```sh
cosign signing-config create \
  --rekor="url=http://rekor-v2.localtest.me,api-version=2,start-time=2026-10-01T00:00:00Z,operator=astrona-lab" \
  --rekor-config=ANY \
  --out /lab/signing-config-v2.json
jq '.rekorTlogUrls' /lab/signing-config-v2.json
```

The entry lists the URL, `majorApiVersion` 2, the operator and the validity start. Leave the shell with `exit`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep the old bundle of `inventory-4.0.0.txt` | It verifies only with the retired key; the release key's check fails |
| Sign without `--signing-config` | `cosign` v3 sends the entry to the public log, and the lab trust root does not trust it |
| Verify with `--insecure-ignore-tlog` | It hides missing or broken log evidence, which is exactly what Rekor v2 makes essential |
| Write `api-version=1` for the new log | `cosign` would speak the Rekor v1 protocol to a Rekor v2 log |

## Common mistakes

- Writing the bundles to `/lab/bundles/` instead of next to the artifacts in `/lab/release/`.
- Forgetting `COSIGN_PASSWORD`, so `cosign` waits for a password.
- A typo in the validity start date; it must be `2026-10-01T00:00:00Z`.
