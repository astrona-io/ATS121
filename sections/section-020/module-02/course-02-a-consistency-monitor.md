# A Consistency Monitor

The first check of a monitor asks whether the log only grew. If it did not, nothing else the log says can be trusted. This part writes the check as a shell function, runs it on a log that grew and on a saved state that claims a larger log, and reads what each result means.

## What the check compares

The monitor has the tree size it saved at the end of its last run. It asks the log for the current tree size and sorts the result into three cases:

| Case | Meaning | Action |
| --- | --- | --- |
| Current size is smaller than the saved size | The log lost entries | Alert |
| Current size equals the saved size | Nothing was added | Stop, no alert |
| Current size is larger | The log grew | Ask for a consistency proof and check it |

The third case is where the real check happens. A consistency proof is the list of hashes that shows the small tree is the first part of the large tree. Without a proof, a log could hand out a larger tree that has a different history.

## Using rekor-cli for the proof

`rekor-cli loginfo` does the proof for you. It remembers the last log state it saw in `~/.rekor/state.json`. On the next call it asks the log for a consistency proof between the remembered state and the current one, checks the proof, and fails when it does not hold. It also checks the log's signature on the state. The command exits with an error when a check fails, which is exactly what a monitor needs.

In the workstation shell, run it once so that it remembers the current state:

<!-- astrona:playground:renew -->

```sh
rekor-cli loginfo
```

Wrap the checks in a function. The function reads the saved tree size from the state file you saved, compares it with the current size, and then lets `rekor-cli loginfo` check the proof. Paste it into the shell:

```sh
check_consistency() {
  saved_size="$(jq -r '.treeSize' /lab/monitor/state.json)"
  current_size="$(curl -s "$REKOR_URL/api/v1/log" | jq -r '.treeSize')"
  if [ "$current_size" -lt "$saved_size" ]; then
    echo "ALERT: the tree shrank from $saved_size to $current_size"
    return 1
  fi
  if [ "$current_size" -eq "$saved_size" ]; then
    echo "OK: no new entries, tree size is $current_size"
    return 0
  fi
  if rekor-cli loginfo >/dev/null 2>&1; then
    echo "OK: the log grew from $saved_size to $current_size and is consistent"
  else
    echo "ALERT: the consistency check failed"
    return 1
  fi
}
```

Run it right away. If the state file you made earlier holds the current size, the log has not grown, and the function says so:

```sh
check_consistency
```

## Making the log grow

Sign a new file so that the tree gets one more entry. The flags `--signing-config` and `--trusted-root` send the entry to the private log and check it. The key `team-a` uses the lab-only password:

```sh
export COSIGN_PASSWORD=lab-only-password
printf 'api hotfix\n' > /lab/artifacts/api-hotfix.txt
cosign sign-blob --key /lab/keys/team-a.key \
  --signing-config /lab/signing-config.json \
  --trusted-root /lab/trusted-root.json \
  --bundle /tmp/api-hotfix.sigstore.json \
  --yes /lab/artifacts/api-hotfix.txt
```

Now run the check again:

```sh
check_consistency
```

This time the current size is larger than the saved one, so the function lets `rekor-cli loginfo` check the proof, and it reports that the log grew and is consistent.

## Testing the alert

A check that never alerts is not proven to work. Test the shrink case on purpose. Write a saved state that claims a tree larger than the real one, and run the check:

```sh
cp /lab/monitor/state.json /tmp/state-real.json
jq '.treeSize = 1000000' /tmp/state-real.json > /lab/monitor/state.json
check_consistency
cp /tmp/state-real.json /lab/monitor/state.json
```

The function prints the alert for a shrunken tree and returns an error. The last line puts the real state back. A real monitor would stop here and page a person.

## What the check does not prove

The size comparison and the proof show that the log grew from the size you saved. They do not show what the root hash was at the old size, unless the monitor also keeps the signed checkpoint it received then and compares the proof's start with that root. `rekor-cli loginfo` does this with the state it saves itself. A monitor that must survive a restart of the machine keeps both the state file and the signed checkpoint in a place the signers cannot write.

You now know how a monitor sorts the three cases, how `rekor-cli loginfo` checks the proof, and how to test an alert. The consistency check says the log is honest. It says nothing about what was signed.

## Common pitfalls

> [!WARNING]
> - **Overwriting the saved state before the check passes.** Save the new state only after the check succeeds. Otherwise a bad run hides the change.
> - **Treating an equal size as consistent without more.** Equal sizes mean nothing was added. Compare the root hash with the saved one too.
> - **Never testing the alert.** Break the input on purpose, as above, and check that the alert fires.
