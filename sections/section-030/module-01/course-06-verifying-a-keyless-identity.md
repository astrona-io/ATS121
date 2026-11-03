# Verifying A Keyless Identity

In keyless signing the signer proves who they are to a certificate authority, which issues a certificate valid for a few minutes. The certificate names the identity and the system that vouched for it. A verifier then asks two questions: who signed, and who vouched. This part reads those two fields in a certificate and shows the matching `cosign` options. The private lab has no certificate authority, so you make a certificate yourself and read it, and the verify command is shown but not run.

## The two fields

A Fulcio certificate holds the identity in the Subject Alternative Name: an email address for a person, or a URL for a workflow. The system that vouched is recorded in a certificate extension called the OIDC issuer, which holds the URL of the identity provider, for example the address of a CI system.

Both fields matter. A person can have the same email at two providers, and only one of them may be the one you trust. A verifier that checks only the name accepts a signature from the wrong provider.

## Making a sample certificate

Create a certificate with a URL identity, the way a CI workflow would have one:

<!-- astrona:playground:renew -->

```sh
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
  -keyout /tmp/wf.key -out /tmp/wf.crt -days 1 \
  -subj "/CN=workflow" \
  -addext "subjectAltName=URI:https://ci.example.com/team/repo/.workflow@refs/heads/main"
```

Read the identity back, as a verifier would:

```sh
openssl x509 -in /tmp/wf.crt -noout -ext subjectAltName
```

Print the validity period. A real keyless certificate lasts minutes, and the verifier must check the time of signing against it, not the time of verifying:

```sh
openssl x509 -in /tmp/wf.crt -noout -dates
```

## The verify options

To verify a keyless bundle, `cosign` needs the identity and the issuer to expect. The command has this shape. It is shown for reading and is not run in the lab, because the lab has no certificate authority to match:

```text
cosign verify-blob \
  --bundle artifact.sigstore.json \
  --certificate-identity "https://ci.example.com/team/repo/.workflow@refs/heads/main" \
  --certificate-oidc-issuer "https://ci.example.com" \
  artifact.bin
```

With the options `--certificate-identity-regexp` and `--certificate-oidc-issuer-regexp`, a pattern replaces the exact value. A wide pattern accepts more signers than you meant, so keep the pattern as tight as the exact value would be.

## What the log adds

The bundle holds the certificate and the log entry. The log entry has a time, and the verifier checks that this time falls inside the certificate validity. That is why a short-lived certificate stays useful: it was valid when the log saw the signature, and the log timestamp proves it. Without a log, an expired certificate would make every old signature unverifiable.

You now know the two fields a keyless verifier checks, how to read them, and which options set the expected values. The last open question is how a client is pointed at a different log version.

## Common pitfalls

> [!WARNING]
> - **Checking the identity without the issuer.** The same name can come from different providers.
> - **Using a wide regular expression.** It accepts signers you did not mean.
> - **Checking the certificate against today's date.** Check it against the log time.
