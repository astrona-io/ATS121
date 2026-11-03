# Handling An Alert

A monitor that finds something unexpected has done half of its job. The other half is what a person does in the first hour. The wrong first move, such as deleting a key or restarting a service, can destroy the evidence. This part sorts alerts into the ones a monitor can raise, says what each one means, and lists the first steps for a signing event nobody expected.

## Two kinds of alert

The two checks raise two very different alerts, and they need different responses.

| Alert | What it means | First step |
| --- | --- | --- |
| Consistency failed, or the tree shrank | The log changed history, or the monitor's state is wrong | Check the monitor's own state and checkpoint first, then ask for the log operator's explanation |
| Unapproved entry by a watched key | Someone signed with the key outside the release process | Treat the key as possibly stolen, and keep the evidence |

A consistency alert is rare, and on a public log it is serious. The most common cause is a mistake in the monitor: a state file from another log, a restored backup, or a log that moved to a new shard with a new tree. Rule out those causes before you report a failure of the log.

## False alarms

An alert is not proof of an attack. Several ordinary events look the same to a monitor.

A release that was signed correctly but never added to the approved list produces an unapproved entry. A developer who signs a test artifact with the shared key produces one too. A second copy of the log state, restored from a backup, makes the tree look smaller.

Each false alarm has a cost: people stop reading alerts. Keep the approved list current, and keep keys that people use for tests apart from keys that sign releases.

## What to do with an unexpected entry

Treat an unapproved entry by a release key as a possible theft until you can explain it. Work in this order.

First, record the entry: its log index, its UUID, the artifact hash and the integrated time. Save the full JSON of the entry and its proof. The log keeps the entry forever, but your report must not depend on a later search.

Second, find out whether the artifact exists. A hash that matches a file in your build system points to a legitimate build that skipped the approved list. A hash that matches nothing you have points to a stranger's artifact.

Third, list every entry the key made since the last time you reviewed it. One unexpected entry is rarely the only one. The timeline of the key shows when the first one appeared.

Fourth, stop the key. Remove it from the systems that sign, publish the new public key to the verifiers, and tell the users of the artifact which versions are affected. Verifiers that pin a public key must stop accepting the old one.

## What the log does for the response

The log helps the response in two ways. It proves what the key signed, so that you know the real scope of the problem. It also gives you a time boundary: an entry has a log index, and every entry before the first unexpected one is older. Artifacts signed before the first bad entry stay trustworthy, if the key was not stolen earlier. Artifacts signed after it are suspect.

It cannot tell you who used the key or how the thief got it. Those answers come from your own systems.

## The published monitor

You do not have to maintain shell functions forever. Sigstore publishes `rekor-monitor`, which does both checks: it verifies the consistency of the log and searches for new entries that match identities or keys you list in a configuration file. It can run as a scheduled GitHub Actions workflow, and a failed run opens an issue. Check the tool's current documentation for its flags and its configuration format before you rely on it, because they change between versions.

The shell versions in this module show what the tool has to do: save a state, prove consistency, filter new entries and compare them with what you expect.

You now know what each alert means, what a false alarm looks like, and the first four steps for an unexpected entry. Together with the two checks you wrote, that is a complete monitor and a plan for its alerts.

## Common pitfalls

> [!WARNING]
> - **Deleting a key before saving the evidence.** Save the entries, their proofs and the timeline first.
> - **Reporting a log failure first.** Rule out your own state file and backups before you blame the log.
> - **Treating every entry before the alert as safe.** Check when the first unexpected entry appeared. The key may have been used earlier.
