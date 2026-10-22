# Prerequisites

Before starting this lab you should be able to:

- Search Rekor by artifact hash and by public key.
- Extract the public key from a `hashedrekord` entry.
- Create a ConfigMap from files and literals.

## What the environment gives you

The environment builds itself before the task begins. It takes several
minutes, because it installs a whole transparency log:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- A private **Rekor v1** transparency log in the namespace `rekor-system`
  (Helm chart `rekor` 1.8.7, with Trillian and Redis). Inside the cluster it
  answers at `http://rekor.localtest.me`. It uses plain HTTP and keeps its
  signing key in memory, which is only acceptable in a lab.
- A **workstation** pod in the namespace `workstation` with `cosign` v3.1.4,
  `rekor-cli` v1.5.5, `curl`, `jq` and `openssl`. Every command runs there:
  open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh`.
- The lab trust files in `/lab` in the workstation: `rekor.pub` (the log's
  public key), `signing-config.json` (sign against the private log) and
  `trusted-root.json` (trust the private log's key).

## Working rules

- Everything is graded on the **final state**: the answer ConfigMap the task
  names, and the files in `/lab` in the workstation.
- Do not restart the Rekor server pod. It keeps its key in memory, so a
  restart gives the log a new key.
- Keys use the lab-only password `lab-only-password` (`COSIGN_PASSWORD`).
