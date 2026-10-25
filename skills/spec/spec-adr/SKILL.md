---
name: spec-adr
description: Records one architecture decision as an ADR (architecture decision record) — context, the decision, real alternatives, consequences with their cost, and verifiable invariants — numbered in sequence, born `Proposed`, never edited once `Accepted` and superseded by a new ADR when the decision changes, citing `DOC-ADR-*` IDs. Use whenever someone asks to write, record, supersede or revise an ADR, to "document why we chose X", to log a decision that must outlive the current increment, or when an RFC or design reaches acceptance and its lasting decisions need their own record. Not for deciding what to build (spec-prd), for an open design discussion (spec-rfc), or for a decision with no real trade-off (`DOC-CORE-02`).
type: skill
family: spec
language: en
source: "[Rules of the ADR](references/rules.md)"
tags:
  - skill
  - spec
  - adr
---

# spec-adr

> **Self-contained.** The template is `references/template.md`; the rule text, numbering and superseding procedure are `references/rules.md`. Nothing here needs another skill to run.
> Owner role: `software-architect` writes the content. When this skill runs in an orchestrating conversation, start that agent with the template path and the writing rules below, and keep only its path and open gaps in the conversation.

## Scope

An ADR answers one question: **what did we decide, and why, in a way that outlives this increment?** One ADR, one decision; three choices are three ADRs.

| The question is... | Go to |
| --- | --- |
| a decision still open, with alternatives under discussion | `spec-rfc` |
| what to build | `spec-prd` |
| a choice with no real trade-off, easy to reverse | no document (`DOC-CORE-02`) |

## Step 1: Confirm the decision is made and lasting

1. Read the project's record of kept documents if one exists (`## Specs` in `AGENTS.md`, else `.specs/README.md`). ADR marked off: do not write the file; state the decision in one line (it goes to the plan's origin) and stop.
2. Confirm the decision is made: a decision still being debated is an RFC. Confirm it outlives the increment: a local choice that dies with the PR is not an ADR.
3. Number it: highest number in `.specs/adr/` plus one, four digits, `0001` first. Slug the decision in kebab-case: `0003-keep-sessions-in-postgres.md`. Other files cite it as `ADR-0003`. The ADR lives in the code repository, never in a wiki.
4. If this decision replaces an earlier one, this is a superseding ADR (Step 3), not an edit.

## Step 2: Write

Copy the template from "Body" down. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | One decision, in active voice: "We will ..." | `DOC-ADR-01` |
| 2 | Name the axis that decided it: state ownership, boundary, contract, distribution or operating cost | makes decisions comparable years later |
| 3 | List real alternatives and why each lost | `DOC-ADR-04`; no straw men |
| 4 | Consequences include the cost (indirection, types, operations, migration); recording only the gain is not allowed | `DOC-ADR-04` |
| 5 | Each verifiable invariant names the test type that proves it at the cheapest level; an E2E-only invariant says why | the test cost repeats on every fix round |
| 6 | Facts cite `file:line`; delete every bracketed hint | the owner verifies before accepting |
| 7 | `status: Proposed`; the writer never accepts its own ADR | `WF-SPEC-06` |

## Step 3: Superseding, not editing

An `Accepted` ADR is never edited (`DOC-ADR-02`). When the decision changes:

1. Write a new ADR with `Supersedes: ADR-NNNN` in its header.
2. In the old ADR, change only the status line to `Superseded by ADR-NNNN`.
3. Keep the old file: deleting it erases why the first decision was made.

## Step 4: Put it in front of the owner

One message, four parts, then stop: the path; the one-sentence decision; the open questions, verbatim; "approve, change, or reject?"

| The owner says | Result |
| --- | --- |
| approve | `Proposed` becomes `Accepted` |
| change | revise from the owner's words; the status does not move |
| reject | the file is removed; it recorded nothing |

Silence is not approval.

## Step 5: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | exactly one decision | `DOC-ADR-01` |
| 2 | it lives in `.specs/adr/NNNN-<slug>.md`, numbered in sequence | `DOC-ADR-03` |
| 3 | consequences include cost; alternatives are real | `DOC-ADR-04` |
| 4 | an `Accepted` ADR was not edited; a change is a new ADR | `DOC-ADR-02` |
| 5 | every invariant names its test type | Step 2, rule 5 |
| 6 | no bracketed hint survived | Step 2, rule 6 |
| 7 | status is `Proposed` until the owner answered | `WF-SPEC-06` |

## Step 6: Return

Report the path, the status and the one-sentence decision. When a workflow pillar called this skill, return the pillar's envelope: path in `artefato`, status in `resultado`.

## Example

*"Sessions stay in PostgreSQL, not Redis."* Highest ADR is `0003`, so the file is `.specs/adr/0004-keep-sessions-in-postgres.md`, `Proposed`. Axis: operating cost. Alternative "Redis" loses on one more service to run for a load the database handles. Consequences list the cost: session reads add a query per request. Invariant: "a revoked session is rejected on the next request", proven by an integration test against the local database. The owner replies "approve"; the status becomes `Accepted`.
