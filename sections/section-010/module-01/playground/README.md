# Read And Prove A Transparency Log — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-121-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment with a private Rekor v1 (chart `rekor` 1.8.7)
and a workstation pod with `cosign` v3.1.4 and `rekor-cli` v1.5.5, plus a few
example log entries. Nothing to submit. Built from the documentation and not
yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-121-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-121-playground-010-01`), not
the config path. `astrona submit` and `astrona test` do not apply.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/prepare.sh` | Helm, CoreDNS rewrite, workstation, private Rekor, trust files, example entries |
| `manifests/rekor-values.yaml` | Helm values for Rekor and Trillian |
| `manifests/lab-start.yaml` | The workstation pod and its setup scripts |
| `docs/overview.md` | What the environment contains and ideas to try |
