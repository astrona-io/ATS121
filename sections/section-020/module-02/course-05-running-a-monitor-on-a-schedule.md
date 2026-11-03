# Running A Monitor On A Schedule

A monitor that someone must remember to run is not a monitor. The two checks must run by themselves, keep their state between runs, and make noise only when something is wrong. This part puts the two checks into one script with clear exit codes, runs it twice, and shows how a scheduler would call it.

## The shape of the script

The script has four steps: read the saved state, run the consistency check, run the identity check, and save the new state only if both pass. Its exit code tells the scheduler the result. Zero means no alert, and any other value means an alert. A scheduler such as `cron` or a CI job then raises the alarm on a non-zero exit code.

Save this as `run-monitor.sh`. It assumes the state file and the approved list from the earlier steps of this module, and a watched key file as its first argument:

<!-- astrona:playground:renew -->

```sh
cat > /lab/monitor/run-monitor.sh <<'SCRIPT'
#!/bin/sh
set -u
KEY="$1"
STATE=/lab/monitor/state.json
saved="$(jq -r .treeSize "$STATE")"
current="$(curl -s "$REKOR_URL/api/v1/log" | jq -r .treeSize)"
if [ "$current" -lt "$saved" ]; then echo "ALERT: tree shrank"; exit 2; fi
if [ "$current" -gt "$saved" ]; then
  rekor-cli loginfo >/dev/null 2>&1 || { echo "ALERT: consistency check failed"; exit 2; }
fi
alerts=0
for id in $(rekor-cli search --public-key "$KEY" --pki-format x509); do
  curl -s "$REKOR_URL/api/v1/log/entries/$id" \
    | jq -r --argjson from "$saved" '.[] | select(.logIndex >= $from) | [.logIndex, (.body | @base64d | fromjson | .spec.data.hash.value)] | @tsv' \
    | while read -r index hash; do
        grep -qx "$hash" /lab/monitor/approved-hashes.txt || echo "ALERT: index $index hash $hash is not approved"
      done
done > /tmp/monitor-alerts.txt
cat /tmp/monitor-alerts.txt
[ -s /tmp/monitor-alerts.txt ] && exit 1
curl -s "$REKOR_URL/api/v1/log" | jq '{treeSize, rootHash}' > "$STATE"
echo "OK: state saved at tree size $current"
SCRIPT
chmod +x /lab/monitor/run-monitor.sh
```

The script writes the alerts to a file first, because a `while` loop in a pipe cannot change the shell's variables. It saves the state last, so an alert is repeated on the next run until a person reviews it.

## Running it twice

Run it for `team-a`. If the log has grown since the state was saved and an entry is not approved, the first run prints an alert and exits with 1. Check the exit code:

```sh
/lab/monitor/run-monitor.sh /lab/keys/team-a.pub; echo "exit code: $?"
```

Approve the reported hash by appending it to the approved list, run again, and read the exit code. The second run saves the state and exits with 0. A third run finds no new entries and also exits with 0.

## Calling it from a scheduler

A scheduler runs the script at a fixed interval and reacts to the exit code. A `cron` line that runs every ten minutes looks like `*/10 * * * * /lab/monitor/run-monitor.sh /lab/keys/team-a.pub || notify`, where `notify` is your own alert command. A CI job does the same with a scheduled trigger, and a failed job raises the alert.

Two things matter in production. The state file must live on storage that survives restarts, and no process that signs may be able to write it. The script must also alert when it cannot run at all: a monitor that silently stops looks the same as a quiet log. A common solution is a second check that fires when the state file is older than expected.

The published `rekor-monitor` tool does the same job with a configuration file instead of a shell script. Check its current documentation for the exact options.

You now have a monitor that runs without a person, keeps its state, and reports through an exit code. The last question is what happens when the monitor itself fails, and the answer is another alert on its silence.

## Common pitfalls

> [!WARNING]
> - **Saving the state before the checks.** An alert is then lost.
> - **Ignoring the exit code in the scheduler.** The alert never reaches a person.
> - **Letting the monitor fail silently.** Alert on a stale state file too.
