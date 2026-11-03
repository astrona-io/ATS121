# Summary

A monitor reads a transparency log on a schedule and compares it with what it saw last time. It makes two checks. The consistency check asks whether the log today extends the log it saw before. The identity check asks whether a key or identity it watches signed anything it does not recognise. A monitor needs both, because an honest log still records a thief's signature, and a careful owner can still be shown an altered log.

The monitor keeps a small state between runs: the tree size and the root hash at the end of the last run. The tree size is the dividing line for new entries, since every entry with a log index at or above it was added since. The approved list of artifact hashes comes from the release process, never from the log, and the monitor saves its state only after the checks pass or the alerts are reviewed.

The consistency check sorts three cases. A smaller tree is an alert. An equal tree means nothing was added. A larger tree needs a consistency proof, which `rekor-cli loginfo` checks against the state it saved. The identity check lists the entries of a key with `rekor-cli search --public-key`, keeps those at or above the saved size, decodes the artifact hash from each body and reports the hashes that are not approved.

An alert is not proof of an attack. Ordinary events, such as an unlisted release or a restored backup, look the same to a monitor. For an unexpected entry by a release key, record the entry and its proof first, check whether the artifact exists, list everything else the key signed, and then stop the key. The log proves what was signed and when it was added. It does not say who used the key.

The key facts to remember are these:

- A log index at or above the saved tree size marks an entry as new.
- A consistency alert is most often a fault in the monitor's own state.
- Keep the saved state and the approved list where the watched key cannot write.
- Test an alert by breaking an input on purpose.

<!-- astrona:playground:destroy -->
