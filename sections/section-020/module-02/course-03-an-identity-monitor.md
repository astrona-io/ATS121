# An Identity Monitor

The consistency check says the log is honest. It does not say whether the signatures in it belong there. The identity check answers that. It lists the entries a watched key made since the last run, compares each artifact hash with the list of approved hashes, and reports the rest. This part writes that check and runs it on a log that contains one unapproved signature.

## Finding what is new

Everything at or above the saved tree size is new. An entry's log index tells you whether it is: the first new entry has the index equal to the saved size. The monitor therefore needs the entries of the watched key, and then it keeps those whose log index is at or above the saved size.

`rekor-cli search --public-key` lists the entries of a key, but it does not say when each one was added. So the monitor reads each entry and filters by its log index. Paste this function into the workstation shell. It prints the log index and the artifact hash of every new entry of the key in the first argument:

<!-- astrona:playground:renew -->

```sh
new_entries_of_key() {
  saved_size="$(jq -r '.treeSize' /lab/monitor/state.json)"
  for id in $(rekor-cli search --public-key "$1" --pki-format x509); do
    curl -s "$REKOR_URL/api/v1/log/entries/$id" \
      | jq -r --argjson from "$saved_size" '.[] | select(.logIndex >= $from) | [.logIndex, (.body | @base64d | fromjson | .spec.data.hash.value)] | @tsv'
  done
}
```

The `select` in the jq program keeps only entries whose `logIndex` is at or above the saved size. The body is decoded in place, and the output has two columns, the index and the hash.

Run it for the key `team-a`:

```sh
new_entries_of_key /lab/keys/team-a.pub
```

If you saved the state before you signed the hotfix file, the saved state is from before it, so one line appears: the index and the hash of `api-hotfix.txt`.

## Comparing with the approved list

The second step compares each hash with the approved list. A hash is approved when it appears as a whole line in the list. `grep -x` matches whole lines, and `-q` makes it silent. Paste the second function:

```sh
report_unapproved() {
  new_entries_of_key "$1" | while read -r index hash; do
    if ! grep -qx "$hash" /lab/monitor/approved-hashes.txt; then
      echo "ALERT: index $index, hash $hash is not approved"
    fi
  done
}
```

Run it:

```sh
report_unapproved /lab/keys/team-a.pub
```

The hotfix was signed by `team-a` and nobody put its hash on the approved list, so the monitor reports it. That is the whole identity check: the signature is valid and the key is the right one, and the artifact is still unexpected.

## Approving an entry

If the hotfix was real, the owner adds its hash to the approved list and the alert stops. The monitor does not decide what is legitimate. A person does, and records the decision in the list:

```sh
sha256sum /lab/artifacts/api-hotfix.txt | cut -d' ' -f1 >> /lab/monitor/approved-hashes.txt
report_unapproved /lab/keys/team-a.pub
```

The second command prints nothing, since every new entry is approved. Remove the line from the list again if you want to see the alert once more.

## Moving the state forward

After a run with no unexplained entries, the monitor saves the new state so that the next run starts from here. Without that step, every run would report the same entries again:

```sh
curl -s "$REKOR_URL/api/v1/log" | jq '{treeSize, rootHash}' > /lab/monitor/state.json
```

Save the state only after both checks pass or after the owner has reviewed the alerts. If you save the state at the start of a run, an entry that raised an alert is never reported a second time.

## Watching more than one identity

The watched key does not have to be a key you own. A monitor can watch the keys of the projects you depend on, and the identities of the people who may sign them. The function takes the key file as its first argument, so one run can loop over a list. In keyless signing the watched value is an identity inside a certificate, such as an email address or a workflow, which Rekor v1 also indexes. The principle is the same: list the new entries for the identity and compare each one with what you expect.

You now know how to list the new entries of a key by log index, how to compare their hashes with an approved list, and when to move the state. The graded lab gives you a log with a saved state and asks for a monitor report.

## Common pitfalls

> [!WARNING]
> - **Filtering by time instead of index.** The log index gives a clean cut at the saved size. Times can overlap between runs.
> - **Moving the state before the alerts are reviewed.** The alert is lost on the next run.
> - **Comparing hashes in different formats.** The entry holds lower-case hexadecimal. Use the same form in the approved list.
> - **Trusting the search index to be complete.** A thorough monitor also walks the new index range and decodes every body.

## Your mission: Detect New Entries By A Watched Key

You can now list what a key signed since a saved state and compare it with an approved list. The graded lab gives you a saved monitor state and an approved list, and asks you to report how many entries the log gained and which entries of the watched key are not approved.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-121-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-121-lab-020-02
astrona start ats-121-playground-020-02
```
