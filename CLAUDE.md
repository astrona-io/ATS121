# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS121 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Immutable Auditing With The Rekor Transparency
  Log** domain of the **Sigstore** training path (`ATP023`). It is 15% of the
  path. There is no official Sigstore certification exam; the path's domains
  and weights are Astrona's own, set in `ATP023/path.yaml`.
- **What the domain really tests:** reading a transparency log and proving
  things with it: find the entry for an artifact, verify that an entry is in
  the log (inclusion proof), verify that the log only grew (consistency
  proof), find every entry made by one key, and verify a Sigstore bundle
  offline. Every explanation should lead to a command the reader can run, and
  every answer is proved by a `rekor-cli` or `cosign` verification or by the
  Rekor API.
- **The three topics:** transparency logs and Merkle trees, searching and
  auditing Rekor, and bundles with offline verification (including what
  changes with Rekor v2).
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Transparency Logs And Merkle Trees | Proofs |
  | 020 | Searching And Auditing Rekor | Auditing |
  | 030 | Bundles, Offline Verification And Rekor v2 | Bundles |

- **The versions:** `cosign` **v3.1.4**, `rekor-cli` **v1.5.5**, `regctl`
  0.11.7 in the workstation pod; a private **Rekor v1** installed with the
  `rekor` Helm chart **1.8.7** (`appVersion` 1.5.4; the image is
  `ghcr.io/sigstore/rekor/rekor-server:v1.5.4`), with its Trillian
  dependency chart (log server, log signer, MySQL 8.4) and Redis for the
  search index; Helm **3.22.1**; a single-node `kind` cluster. Rekor v2
  (`rekor-tiles`, chart 1.2.6, `appVersion` 2.3.0) is taught in prose only.
- **The main sources:** <https://docs.sigstore.dev/logging/overview/>,
  <https://docs.sigstore.dev/about/bundle/>, the `sigstore/rekor` source at
  `v1.5.5` (for `rekor-cli` flags and the API), the `sigstore/rekor-tiles`
  `README.md` and `CLIENTS.md` (for Rekor v2), the `sigstore/cosign` docs at
  `v3.1.4` (`doc/cosign_*.md`), and RFC 6962 / RFC 9162 for Merkle tree
  hashing. Sigstore is an OpenSSF project; it is not a CNCF project.

### Status: built, not yet run

The first version of this repository was written from the documentation and
source **without a live run**. No playground or lab has been started, and no
`astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The riskiest assumptions, in order (check these first on the first run):

1. **Key-based signing against the private Rekor.** cosign v3.1.4 has no
   `--rekor-url` on `sign-blob`; every environment writes
   `/lab/signing-config.json` with `cosign signing-config create --rekor=...`
   and `/lab/trusted-root.json` with `cosign trusted-root create --rekor=...`
   from the log's public key (`GET /api/v1/log/publicKey`); in those files the
   log URL is `rekorTlogUrls[].url` (signing config) and `tlogs[].baseUrl`
   (trusted root). `--tlog-upload` is deprecated in v3 and `--bundle` is
   required for `sign-blob`. It is assumed that
   `cosign sign-blob --key ... --signing-config ... --bundle ...` uploads a
   `hashedrekord` entry to `http://rekor.localtest.me` over plain HTTP and
   writes a v0.3 bundle with an inclusion proof, and that `cosign verify-blob
   --key ... --trusted-root ... --bundle ...` verifies it without network
   access.
2. **The Rekor chart on `kind`.** Values follow the chart's own
   `ci/ci-values.yaml` (MySQL 8.4 image digest, no `--ignore-db-dir`). The
   server uses `signer: memory`: **a restart of the Rekor server pod creates
   a new log key**, and every trusted root made before it stops matching new
   checkpoints. Graders and seeds never restart it; pages say so.
3. **The search index.** `rekor-cli search` and `POST /api/v1/index/retrieve`
   need Redis; it is enabled. Search results may be 80-character entry IDs
   (tree ID + UUID) while `rekor-cli get` prints 64-character UUIDs; graders
   compare the last 64 hex characters.
4. **`rekor-cli logproof` output.** Pages describe it in words only: it
   prints the hashes of the consistency proof and the root hash at
   `--last-size`.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Transparency log | A public list of records that can only be appended to, where anyone can check that nothing was changed or removed |
| Append-only | New entries are added at the end; existing entries are never edited or deleted |
| Merkle tree | A binary tree of hashes: each leaf is the hash of one entry, each inner node the hash of its two children, and the top is the root hash |
| Leaf hash | `SHA-256(0x00 || entry)`, the hash of one entry with a one-byte prefix (RFC 6962) |
| Node hash | `SHA-256(0x01 || left || right)`, the hash of two child hashes |
| Log index / tree size / root hash | The position of an entry (from 0) / the number of entries / the hash at the top of the tree for that size |
| Inclusion proof | The list of sibling hashes that lets a verifier recompute the root hash from one leaf, proving the entry is in the tree |
| Consistency proof | The hashes that prove a tree of size N is the first N entries of a larger tree, so nothing was changed or removed |
| Checkpoint (signed tree head) | A note signed by the log with its origin, tree size and root hash |
| Signed entry timestamp (SET) | The log's signature over an entry's body, integrated time, log ID and log index: a promise that the entry will be in the log |
| Entry types | The kind of record: `hashedrekord` (an artifact hash and its signature), `dsse` and `intoto` (attestations) in Rekor v1 |
| Search index | A Redis index in Rekor v1 that maps artifact hashes, public keys and identities to entry UUIDs |
| Shard | A separate log instance; Rekor rotates to a new tree when one gets too large |
| Monitor / witness | A program that watches the log for an identity or for consistency / a third party that co-signs checkpoints it has checked |
| Sigstore bundle | One JSON document with the signature, the key or certificate hint, and the log evidence (`tlogEntries`) and timestamps |
| Rekor v2 | `rekor-tiles`: a tile-based log with one write API (`/api/v2/log/entries`), only `hashedrekord` entries and no search index |

### The example workloads

| Name | What it is |
| --- | --- |
| Rekor (namespace `rekor-system`, Helm release `rekor`) | `rekor-server` v1.5.4, Service `rekor-server` on port `80`, reached in the cluster as `http://rekor.localtest.me` through a CoreDNS `rewrite stop` block. Trillian (namespace `trillian-system`), Redis for search. Plain HTTP, in-memory signer: lab-only |
| `workstation` (namespace `workstation`) | `alpine:3.22` with `cosign`, `rekor-cli`, `regctl`, `curl`, `jq`, `git` and `openssl`. `REKOR_URL` and `REKOR_REKOR_SERVER` are set to `http://rekor.localtest.me`, so `rekor-cli` uses the private log by default |
| `/lab` in the workstation | An `emptyDir`: `rekor.pub`, `signing-config.json`, `trusted-root.json` (made by `/setup/lab-init.sh`), `keys/`, `artifacts/`, `bundles/` |
| Keys | Generated in the environment with the lab-only `COSIGN_PASSWORD=lab-only-password`. No key material is in this repository |

Pages run tools through a helper, defined once per page that needs it:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
```

Interactive work uses a shell in the pod:
`kubectl -n workstation exec -it deploy/workstation -- sh`.

### Environment facts the text must respect

- **Always pass the lab trust files.** Without `--signing-config
  /lab/signing-config.json`, cosign v3 signs against the public-good
  instance; without `--trusted-root /lab/trusted-root.json` it verifies
  against the public-good trust root. Every signing and verifying command on
  a page passes both, and the page says why once.
- **The public-good Rekor is for reading only.** Pages may show `rekor-cli
  loginfo --rekor_server https://rekor.sigstore.dev` or a search there as an
  optional step (needs internet). Nothing is graded against it, and nothing is
  ever uploaded to it.
- **Rekor v2 status (checked 2026-10-22):** the TUF-distributed signing
  config on `sigstore/root-signing` `main` (`signing_config.v0.2.json`) lists
  only `https://rekor.sigstore.dev` (API version 1), while the TUF trusted
  root (`trusted_root.json`) lists the keys of both `https://rekor.sigstore.dev`
  and `https://log2025-1.rekor.sigstore.dev` (Rekor v2, valid from
  2025-09-23). Pages say "at the time of writing". The `rekor-tiles` README
  names `https://log2025-1.rekor.sigstore.dev` as the public Rekor v2 shard to
  add by hand, and says shard URLs change about every six months. Teach the
  mechanism (signing config, yearly shards), not a URL to hard-code.
- **CoreDNS:** copy the `rewrite stop` block with the answer name rewritten
  back (see `add_coredns_rewrite` in every bootstrap script); never the
  one-line `rewrite name` form.
- **Answers are ConfigMaps.** Labs that ask for a finding (a UUID, a log
  index, a file name) have the reader store it in a ConfigMap in the namespace
  `workstation`; the question names the ConfigMap and its keys exactly.
- **Many environments start broken on purpose** (a tampered bundle, an
  artifact signed by an unknown key, a fake checkpoint). The fault is the
  material. Never "fix" it in the bootstrap.

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/prepare.sh`, `manifests/rekor-values.yaml`,
`manifests/lab-start.yaml`, `docs/overview.md`), labs (`config.yaml`,
`README.md`, `prerequisites.md`, `question.md`, `solution.md`,
`bootstrap/01-install-rekor.sh`, `bootstrap/02-seed-state.sh`,
`manifests/`, `solution/apply.sh`, `testing/wait-for-rekor.sh`,
`validation/validate-*.sh`) and one capstone per section.

The shared plumbing of all nine environments (install and seed scripts,
manifests, reference solutions, graders, `config.yaml` files, author
READMEs and `prerequisites.md`) was generated from one script that is not in
this repository. When you change a shared piece (the install function, the
workstation manifest, `lab-init.sh`), change it in every environment.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS121`, domain `Immutable Auditing With The Rekor
Transparency Log`, weight `15`. Lab entries carry `title`, `path`,
`difficulty`, `estimated_duration`, `topic`, `task_kind`, `tags`,
`learning_goals`, `resources`, in that order, as in ATS016.

- `topic`: exactly one of `merkle-trees`, `proofs`, `search`, `auditing`,
  `bundles`, `rekor-v2`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `rekor`, `rekor-cli`,
  `transparency-log`, `merkle-tree`, `inclusion-proof`, `consistency-proof`,
  `checkpoint`, `set`, `log-index`, `entry-uuid`, `hashedrekord`,
  `search-index`, `public-key-search`, `artifact-search`, `audit`,
  `sigstore-bundle`, `offline-verification`, `trusted-root`,
  `signing-config`, `cosign`, `rekor-v2`.
- `resources`: 1 to 4 pages on `docs.sigstore.dev`, `github.com/sigstore`
  or `datatracker.ietf.org`. The only place outside links are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/section-010/module-01/playground
astrona destroy ats-121-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS121.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-121-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-121-playground-<section>-<module>`, `ats-121-lab-<section>-<module>`,
`ats-121-capstone-<section>`. Graders check **behaviour** (the answer matches
what the Rekor API and a fresh verification say) and reject the plausible but
wrong fix (verifying with `--insecure-ignore-tlog`, re-signing an artifact to
get a new entry instead of finding the old one, listing entries of the wrong
key). A lab's `question.md` and `solution.md` must match what its
`validation/` scripts check.

### Where to find trusted sources

- **Rekor and logs:** <https://docs.sigstore.dev/logging/overview/>,
  `sigstore/rekor` (`openapi.yaml`, `cmd/rekor-cli/app/`)
- **Bundles:** <https://docs.sigstore.dev/about/bundle/>
- **Rekor v2:** `sigstore/rekor-tiles` `README.md` and `CLIENTS.md`
- **cosign:** `sigstore/cosign` `doc/cosign_sign-blob.md`,
  `doc/cosign_verify-blob.md`, `doc/cosign_signing-config_create.md`,
  `doc/cosign_trusted-root_create.md` at `v3.1.4`
- **Merkle trees:** RFC 6962 section 2 and RFC 9162
