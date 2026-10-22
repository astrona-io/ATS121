---
estimated_duration: 30m
---

# Prove The Log Only Grew

- **ID:** LAB
- **Slug:** ats-121-capstone-010
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab against a private Rekor v1 in the namespace `rekor-system`. Read
`question.md` for the task; `solution.md` is the walkthrough. Built from the
documentation and source, and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-121-capstone-010
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-121-capstone-010`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/01-install-rekor.sh` | Helm, CoreDNS rewrite, workstation, private Rekor, trust files |
| `bootstrap/02-seed-state.sh` | The starting state of the task |
| `manifests/` | Helm values for Rekor and the workstation pod |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/wait-for-rekor.sh` | Waits until Rekor answers |
| `validation/` | Grading scripts, one per check |
