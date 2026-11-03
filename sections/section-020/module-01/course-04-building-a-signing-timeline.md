# Building A Signing Timeline

An incident report needs an order of events: when did the key sign its first artifact, when did it sign the odd one, how long was the gap between them? The log holds that order twice, once as the log index and once as the integrated time. They do not mean the same thing, and an auditor must know which one to use. This part builds a timeline for one key, shows the two orderings side by side, and explains what each one proves.

## Two orderings, two meanings

The **log index** is the position of the entry in the tree. It is assigned in the order the log added entries, and nothing can change it. The **integrated time** is the time, in Unix seconds, that the Rekor server wrote into the entry when it accepted it. The server signs that time into the signed entry timestamp (SET).

In a single log both orderings normally agree: a higher index has a later or equal time. They are different kinds of evidence. The index order is fixed by the Merkle tree, so it is the order everyone can check with proofs. The time comes from the server's clock and is only as trustworthy as that clock. For an incident timeline, use the index for "before" and "after", and the time for "about when".

## A timeline for one key

Build the timeline of the key `team-a`. In the workstation shell, list its entries, read each one and print index and date, sorted by index. First paste a helper that prints the line for one entry ID:

<!-- astrona:playground:renew -->

```sh
entry_line() {
  curl -s "$REKOR_URL/api/v1/log/entries/$1" \
    | jq -r '.[] | [.logIndex, (.integratedTime | todate), (.body | @base64d | fromjson | .spec.data.hash.value[0:12])] | @tsv'
}
```

Then run it for every entry the index knows for the key, and sort by the first column:

```sh
for id in $(rekor-cli search --public-key /lab/keys/team-a.pub --pki-format x509); do
  entry_line "$id"
done | sort -n
```

The output has one line per entry: the log index, the date and time, and the first twelve characters of the artifact hash. The first line is the first time the key signed anything in this log. The last line is the most recent.

## Gaps and bursts

A timeline shows two patterns that matter in an investigation. A **gap** is a long stretch with no entries. A **burst** is many entries in a short time. A key that signs one release every few weeks and then signs twenty artifacts in a minute has a burst, and a burst needs an explanation: a legitimate release job, or someone using a stolen key.

Compute the time between consecutive entries of the key to find them. The command below prints the number of seconds between each entry and the one before it:

```sh
for id in $(rekor-cli search --public-key /lab/keys/team-a.pub --pki-format x509); do
  curl -s "$REKOR_URL/api/v1/log/entries/$id" | jq -r '.[] | [.logIndex, .integratedTime] | @tsv'
done | sort -n | awk 'NR > 1 { print $1, $2 - previous } { previous = $2 }'
```

Each line shows an index and the seconds since the previous entry of the same key. The playground signed its entries one after another, so expect small values here. In a real incident, a very small value among large ones is the burst.

## Comparing two keys

The same walk works for any key. A timeline for the key you suspect, placed next to the timeline of the key you trust, shows whether the suspect key was active before the incident or only after it. The log index orders the two lists against each other even when the clocks of two signers disagree, because both lists come from the same tree.

## What the timeline cannot show

The log records when an entry was added, not when the signature was made. A signature made months ago and uploaded today has today's integrated time. The log also cannot tell you who held the key. It only tells you which key signed. A timeline is evidence for an investigation, not a verdict.

You now know the difference between the log index and the integrated time, how to build a timeline for a key, and what a gap or a burst can mean. The summary that follows sets this beside the rest of the module.

## Common pitfalls

> [!WARNING]
> - **Using the integrated time as the signing time.** It is the time of upload. A signature can be older than its entry.
> - **Sorting by time and ignoring the index.** For before and after, the index is the order the tree proves.
> - **Reading a burst as proof of misuse.** It can be a normal release job. Compare it with the release plan before you decide.
