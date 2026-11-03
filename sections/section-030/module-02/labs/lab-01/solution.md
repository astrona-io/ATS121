# Solution: Attest A Release Artifact

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the bundle verifies offline as an attestation of the artifact with the predicate type from the task and holds the lab predicate, and `kind` and `log-index` in the ConfigMap equal the entry that the bundle names and Rekor holds.

## Step 1: Create the attestation

Open a shell in the workstation:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Sign the attestation with the release key and upload it to the private log. The flags `--signing-config` and `--trusted-root` point `cosign` at the private Rekor:

```sh
export COSIGN_PASSWORD=lab-only-password
cosign attest-blob --key /lab/keys/release.key \
  --predicate /lab/predicate.json \
  --type https://astrona.io/release-check/v1 \
  --signing-config /lab/signing-config.json \
  --trusted-root /lab/trusted-root.json \
  --bundle /lab/bundles/inventory-5.0.0.att.sigstore.json \
  --yes /lab/artifacts/inventory-5.0.0.txt
```

## Step 2: Verify it offline

Verify the bundle with the public key, the trusted root and the same predicate type:

```sh
cosign verify-blob-attestation --key /lab/keys/release.pub \
  --trusted-root /lab/trusted-root.json \
  --bundle /lab/bundles/inventory-5.0.0.att.sigstore.json \
  --type https://astrona.io/release-check/v1 \
  /lab/artifacts/inventory-5.0.0.txt
```

## Step 3: Read the kind and the log index

Read both values from the bundle. Do not guess the kind:

```sh
jq '.verificationMaterial.tlogEntries[0] | {logIndex, kindVersion}' /lab/bundles/inventory-5.0.0.att.sigstore.json
```

You can confirm the kind in Rekor by fetching the entry by index and decoding its body:

```sh
INDEX="$(jq -r '.verificationMaterial.tlogEntries[0].logIndex' /lab/bundles/inventory-5.0.0.att.sigstore.json)"
curl -s "$REKOR_URL/api/v1/log/entries?logIndex=$INDEX" | jq -r '.[].body' | base64 -d | jq -r .kind
```

## Step 4: Record the entry

Leave the workstation shell and create the ConfigMap with the two values you read:

```sh
kubectl -n workstation create configmap attestation-entry \
  --from-literal=kind='<KIND>' \
  --from-literal=log-index='<INDEX>'
```

Replace `<KIND>` and `<INDEX>` with the values from Step 3. Submit again; both checks should pass.

## Why this is the right answer

The bundle verifies only when the predicate type, the subject digest and the log evidence all match. The kind and index in the ConfigMap come from the log evidence, and the grader compares them with a fresh request to Rekor. Re-signing the file as a plain signature would create a different entry kind and fail the attestation check.
