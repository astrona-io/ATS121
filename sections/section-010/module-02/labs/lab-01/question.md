# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Proofs

## Scenario

The security team wrote a notice, `/lab/artifacts/security-notice.txt`, and wants a public record that it exists in this exact form. Its signing key is an ECDSA P-256 key pair made with `openssl`, not with `cosign`: the private key is `/lab/keys/notice.key` and the public key is `/lab/keys/notice.pub`, both in PEM format. Both are in the workstation pod. The notice is not in the team's private Rekor yet:

```sh
kubectl -n workstation exec deploy/workstation -- ls -l /lab/artifacts /lab/keys
```

## Your task

1. Sign the notice with `/lab/keys/notice.key` and upload the signature to Rekor as a `hashedrekord` entry that uses `/lab/keys/notice.pub`.
2. Check that Rekor can prove the new entry with `rekor-cli verify`.
3. Record the entry in a ConfigMap named `notice-entry` in the namespace `workstation`, with two keys:
   - `log-index`: the log index of the entry, as a number.
   - `uuid`: the UUID of the entry. A 64-character UUID and a longer entry ID both count.

## Constraints

- Do not change `/lab/artifacts/security-notice.txt` or the keys.
- Use the key `notice`. An entry signed with another key does not count.
- Do not restart the Rekor server pod.

## Done when

- Rekor holds an entry for the notice, made with the `notice` key, with a verified inclusion proof.
- `notice-entry` holds that entry's log index and UUID.
