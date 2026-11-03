# Solution: Detect New Entries By A Watched Key

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: `new-entries` equals the current tree size minus the saved tree size, and `unapproved-uuids` is exactly the set of `team-a` entries with a log index at or above the saved size whose artifact hash is not in the approved list.

## Step 1: Count the new entries

Open a shell in the workstation:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Read the saved tree size and the current tree size, and subtract:

```sh
saved="$(jq -r .treeSize /lab/monitor/state.json)"
current="$(curl -s "$REKOR_URL/api/v1/log" | jq -r .treeSize)"
echo "$saved $current $((current - saved))"
```

The last number is the value for `new-entries`.

## Step 2: List the new entries of the watched key

Search by public key, read each entry, and keep those with a log index at or above the saved size. Print the entry ID, the index and the artifact hash:

```sh
for id in $(rekor-cli search --public-key /lab/keys/team-a.pub --pki-format x509); do
  curl -s "$REKOR_URL/api/v1/log/entries/$id" \
    | jq -r --arg id "$id" --argjson from "$saved" '.[] | select(.logIndex >= $from) | [$id, .logIndex, (.body | @base64d | fromjson | .spec.data.hash.value)] | @tsv'
done | tee /tmp/new-team-a.tsv
```

## Step 3: Remove the approved hashes

Keep only the lines whose hash is not a whole line in the approved list:

```sh
while read -r id index hash; do
  grep -qx "$hash" /lab/monitor/approved-hashes.txt || echo "$id"
done < /tmp/new-team-a.tsv | tee /tmp/unapproved.txt
```

Exactly one entry remains. The older unapproved hotfix is not in the list because its log index is below the saved size.

## Step 4: Record the report

Leave the workstation shell. Create the ConfigMap from the values on your machine. The file `/tmp/unapproved.txt` is in the pod, so print it and copy the line:

```sh
kubectl -n workstation exec deploy/workstation -- cat /tmp/unapproved.txt
```

Then create the ConfigMap with the number from Step 1 and the entry ID:

```sh
kubectl -n workstation create configmap monitor-report \
  --from-literal=new-entries=4 \
  --from-literal=unapproved-uuids='<ENTRY-ID>'
```

Replace `<ENTRY-ID>` with the printed ID. Submit again; both checks should pass.

## Why this is the right answer

The log index gives a clean cut at the saved size, so the old hotfix is out of scope. The signature of the unapproved entry is valid, and the key is the right one, so only the comparison with the approved list reveals it. Entries of `team-b` are not part of the report because the monitor watches `team-a`.
