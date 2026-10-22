# ATS121 — Immutable Auditing With The Rekor Transparency Log (Sigstore)

Course material for the **Immutable Auditing With The Rekor Transparency Log**
domain of the Astrona Sigstore training path
([ATP023](https://github.com/astrona-io/ATP023)), which is **15% of the
path**. Written for **cosign v3.1.4**, **rekor-cli v1.5.5** and a private
**Rekor v1.5.4** (Helm chart `rekor` 1.8.7).

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Sigstore documentation and the source of `rekor`, `rekor-tiles` and
> `cosign`. None has been started on a cluster, and no lab has passed
> `astrona test` yet. See `CLAUDE.md`, which ranks the riskiest assumptions.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's module into a
  single scenario.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Transparency Logs And Merkle Trees | 1 | 1 + capstone | Proofs |
| [020](sections/section-020) | Searching And Auditing Rekor | 1 | 1 + capstone | Auditing |
| [030](sections/section-030) | Bundles, Offline Verification And Rekor v2 | 1 | 1 + capstone | Bundles |

The order goes from how the log can be trusted, to what an auditor does with
it, to the evidence a verifier keeps. Section 010 builds the Merkle tree and
its two proofs. Section 020 searches the log and audits one key. Section 030
verifies bundles offline and explains why Rekor v2 makes keeping bundles a
must.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Read And Prove A Transparency Log](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Search And Audit Rekor Entries](sections/section-020/module-01/course.md) | 2 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Verify Bundles Offline And Prepare For Rekor v2](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | What the learner proves |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Prove The Log Only Grew | which of two saved checkpoints is genuine, and that the log only grew since |
| [020](sections/section-020/capstone/labs/lab-01) | Investigate An Unknown Signer | which key signed a release, every entry it made, and when it first appeared |
| [030](sections/section-030/capstone/labs/lab-01) | Keep Verifiable Evidence For Rekor v2 | a verifiable v0.3 bundle for every release artifact, and a Rekor v2 signing config |

---

## The lab environment

Every playground and lab is a **kind** cluster with a private **Rekor v1**
(namespace `rekor-system`, with Trillian and Redis) and a **workstation** pod
(namespace `workstation`) that holds `cosign`, `rekor-cli`, `curl` and `jq`.
Inside the cluster the log answers at `http://rekor.localtest.me` (a CoreDNS
`rewrite stop` block). The workstation's `/lab` folder holds the lab trust
files: the log's public key, a signing config that sends cosign to the
private log, and a trusted root that trusts it. Keys are generated in the
environment; none is stored in this repository.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Labs record their findings in a ConfigMap the task names. Graders compare the
answer with what the Rekor API and a fresh verification say, so an answer
copied from the wrong entry, the wrong key or an unverified bundle fails.
