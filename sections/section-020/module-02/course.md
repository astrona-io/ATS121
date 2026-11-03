# Monitor The Log

A transparency log protects you only if somebody looks at it. The proofs in the log are checked when a verifier asks for them, and an attacker who signs with a stolen key does not ask. A monitor is the program that looks without being asked. It reads the log on a schedule, checks that the log only grew, and reports every entry made by a key or identity it watches.

This module builds the two checks of a monitor by hand with `rekor-cli`, `curl` and `jq`, so you see what every monitor does underneath. Keep one sentence in mind: **a monitor compares the log today with what it saw last time, and anything it cannot explain is an alert.**

The module has five parts. **What A Monitor Checks** names the two checks and the state a monitor keeps. **A Consistency Monitor** checks that the log only grew since the last run. **An Identity Monitor** lists the entries a watched key made since the last run and flags the ones nobody approved; a graded lab follows it. **Handling An Alert** says what to do when a check fails, and how to tell a real incident from a false alarm. **Running A Monitor On A Schedule** puts both checks into one script with exit codes and shows how a scheduler calls it.

## Learning objectives

After this module you can:

- Name the two checks of a log monitor and the state it must keep between runs.
- Write a shell check that detects a log that shrank or that failed a consistency check.
- List the entries a key made since a saved tree size.
- Compare those entries with a list of approved artifact hashes and report the rest.
- Explain what each kind of alert means and what to do first.
- Run the checks from a script that reports through its exit code.

## Before you start

You need Kubernetes basics, `rekor-cli search`, `rekor-cli get` and `jq`. You should know that a Rekor entry has a log index, and what a tree size and a root hash are.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Rekor (namespace `rekor-system`) | A private Rekor v1.5.4 transparency log. Inside the cluster it answers at `http://rekor.localtest.me` |
| `workstation` (namespace `workstation`) | A pod with `cosign` v3.1.4, `rekor-cli` v1.5.5, `curl` and `jq`. You run every command here |
| `/lab` in the workstation | The lab trust files, the keys `team-a` and `team-b`, and four artifacts, three of them already signed |

Open a shell in the workstation whenever a page asks you to run a command:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
