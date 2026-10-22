# Welcome To The Course

This course trains you for the **Immutable Auditing With The Rekor Transparency Log** part of the Astrona **Sigstore** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, pods, ConfigMaps, `kubectl exec` and `kubectl create configmap`. You know what a SHA-256 hash is and that a digital signature proves who signed some data with a private key. You can read JSON with `jq`. You do not need to know Rekor, Merkle trees or Sigstore bundles yet. Each new idea is explained the first time it appears.

## What you can do at the end

Rekor is the transparency log of Sigstore: a public record of signing events. This course does not ask you to remember words about it. It asks you to find records in the log, prove things with them, and catch the record that should not be there. The course has three topics.

The first topic is **transparency logs and Merkle trees**. You will learn to:

- Explain why a signature alone is not enough, and what an append-only log adds.
- Build a small Merkle tree by hand and follow an inclusion proof from a leaf to the root hash.
- Verify that an entry is in the log, and that the log only grew, with `rekor-cli`.
- Tell a checkpoint from a signed entry timestamp, and say what each one promises.

The second topic is **searching and auditing Rekor**. You will learn to:

- Search the log by artifact hash and by public key.
- Decode an entry and read which hash and which key it records.
- List every entry made by one key, and find the signing event nobody expected.

The third topic is **bundles and offline verification**. You will learn to:

- Read a Sigstore bundle and find its log evidence.
- Verify a bundle with `cosign` without asking the log, and tell why one fails.
- Explain what changes with Rekor v2, and why that makes keeping bundles essential.

Everything is written for **cosign v3.1.4**, **rekor-cli v1.5.5** and a private **Rekor v1.5.4**.

## The words this course uses

The pages use Sigstore's own terms, because those are the words you meet in the tools, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **transparency log** is a public list of records that can only be appended to, where anyone can check that nothing was changed or removed. **Rekor** is Sigstore's transparency log. One record in it is an **entry**, and every entry has a **log index** (its position, starting at 0) and a **UUID** (a long hexadecimal identifier). A **Merkle tree** is the tree of hashes Rekor builds over all its entries; the hash at its top is the **root hash**.

Three pieces of evidence come back again and again:

| Evidence | What it proves |
| --- | --- |
| Inclusion proof | One entry is in the tree with a given root hash |
| Consistency proof | A smaller tree is the start of a larger tree, so the log only grew |
| Signed entry timestamp (SET) | The log promised, with its signature, to add the entry |

## The example setup in your playground

Every playground and lab runs the same small setup. A private Rekor runs in the namespace `rekor-system`. A **workstation** pod in the namespace `workstation` holds the client tools: `cosign`, which signs and verifies, and `rekor-cli`, which talks to Rekor. You run every command in the workstation.

The workstation's folder `/lab` holds the trust files that tie the tools to the private Rekor, and the keys, artifacts and bundles each module creates. The artifacts are small text files named like software releases, for example `inventory-1.2.0.txt`. Many labs start with something wrong on purpose, such as a forged checkpoint or a tampered bundle. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections. It starts with how the log can be trusted, then what an auditor does with it, and ends with the evidence a verifier keeps.

| Section | What it covers |
| --- | --- |
| 010 | Transparency Logs And Merkle Trees |
| 020 | Searching And Auditing Rekor |
| 030 | Bundles, Offline Verification And Rekor v2 |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, combining its skills in one scenario | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
