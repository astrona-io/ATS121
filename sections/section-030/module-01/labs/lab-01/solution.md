# Solution: Find The Bundles That Do Not Verify

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: `failed` names exactly the artifacts that fail an offline verification of the files in `/lab`, and the other three still verify.

## Step 1: Verify every artifact

Open a shell in the workstation:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Loop over the bundles. For each one, find its artifact and verify both with the release key and the lab trust root. Print only the names that fail, and keep the errors so you can read them:

```sh
for bundle in /lab/bundles/*.sigstore.json; do
  name="$(basename "$bundle" .sigstore.json)"
  if ! cosign verify-blob --key /lab/keys/release.pub \
       --trusted-root /lab/trusted-root.json \
       --bundle "$bundle" "/lab/artifacts/$name" 2> "/tmp/$name.err" >/dev/null; then
    echo "$name" | tee -a /tmp/failed.txt
  fi
done
```

Two names are printed.

## Step 2: Read why each one failed

The two failures have different causes. Read the saved errors:

```sh
for name in $(cat /tmp/failed.txt); do echo "== $name"; cat "/tmp/$name.err"; done
```

One error is about the signature or the artifact digest: that artifact was changed after it was signed. The other is about the transparency log evidence: the bundle's inclusion proof was changed, so it no longer leads to the root hash that the log's checkpoint signs. Both must be reported, for different reasons.

## Step 3: Record the answer

Leave the shell with `exit`, copy the list to your machine and create the ConfigMap:

```sh
kubectl -n workstation exec deploy/workstation -- cat /tmp/failed.txt > failed.txt
kubectl -n workstation create configmap bundle-check --from-file=failed=failed.txt
```

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Verify with `--insecure-ignore-tlog` | The bundle with the changed inclusion proof passes, and you miss it |
| Re-sign the failing artifacts | The release gate passes, but the evidence of what went wrong is gone; the grader expects the original files |
| Check only the artifact hashes | The tampered bundle has a correct artifact; only the log check catches it |

## Common mistakes

- Verifying an artifact with the wrong bundle because of a typo in the name.
- Writing full paths into `failed`; the grader accepts them, but the file names are enough.
- Leaving out the trust root, so `cosign` checks against the public-good instance and everything fails.
