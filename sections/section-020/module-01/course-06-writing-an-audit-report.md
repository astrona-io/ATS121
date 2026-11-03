# Writing An Audit Report

An audit that ends in a terminal is not finished. The finding has to reach the person who decides, in a form they can check. This part turns the entries of one key into a short report with a count, a table and a list of questions, using only the log.

## What a report holds

A report names its scope first: which log, which key, and the tree size at the time of reading. It then lists the facts, one row per entry, with the log index, the integrated time and the artifact hash. Finally it lists what the log cannot say, so nobody reads more into it than it holds.

Fix the scope first. Record the log tree size and the key:

<!-- astrona:playground:renew -->

```sh
curl -s "$REKOR_URL/api/v1/log" | jq '{treeSize, rootHash}'
```

## One row per entry

For each entry of `team-a`, print the log index, the integrated time as a date, and the artifact hash. The time field is in seconds since 1970, and `todate` turns it into a readable date:

```sh
for id in $(rekor-cli search --public-key /lab/keys/team-a.pub --pki-format x509); do
  curl -s "$REKOR_URL/api/v1/log/entries/$id" \
    | jq -r '.[] | [.logIndex, (.integratedTime | todate), (.body | @base64d | fromjson | .spec.data.hash.value)] | @tsv'
done | sort -n | tee /tmp/report-rows.tsv
```

Count the rows and note the first and last time:

```sh
wc -l < /tmp/report-rows.tsv
head -1 /tmp/report-rows.tsv | cut -f2
tail -1 /tmp/report-rows.tsv | cut -f2
```

## The questions the log leaves open

Under the table, list what the report cannot answer. For any key the list is the same: who held the key at each time, whether each artifact was meant to be signed, and whether the index was complete. For the last point, walk the log by index as in the bulk retrieval and compare the count of entries with the search.

Add one line for each open question and who can answer it. The release owner can answer which artifacts were intended. The key custodian can answer who held the key.

## Making the report checkable

A reader should be able to repeat your numbers. State the commands you used, and the tree size at the time, because the tree grows and later counts differ. Save the rows file with the report. For a stronger record, keep the bundles of the artifacts: each bundle holds a signed checkpoint, so a reader can verify an entry without trusting your copy of the log.

You now know the parts of a report and how to produce them from the log. A report is complete when another person can rerun it and get the same table up to the tree size you recorded.

## Common pitfalls

> [!WARNING]
> - **Leaving out the tree size.** Counts change as the log grows. Record the size with the numbers.
> - **Mixing UTC and local time.** `todate` prints UTC. State it.
> - **Writing conclusions the log cannot support.** The log shows what was signed, not who or why.
