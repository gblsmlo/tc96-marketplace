---
name: doc-adr
description: Records one architecture decision that was already made as an ADR (architecture decision record) — context, the decision in active voice, the axis that decided it, the real alternatives and why each lost, consequences with their cost, and verifiable invariants — numbered in sequence in `.specs/adr/NNNN-<slug>.md`, born `Proposed`, and superseded by a new ADR instead of edited once `Accepted`. Use whenever someone asks to write, record, log, supersede or revise an ADR, to "document why we chose X", or when a spec or review settles a choice other work will depend on. A writer only — it does not weigh options, read the code or recommend; the decision comes in the input. Not for a decision still being debated, one feature's design (doc-spec), or what to build (doc-prd).
type: skill
family: design-docs
language: en
source: "[Rules of the ADR](references/rules.md)"
model: rapido
effort: medio
tags:
  - skill
  - design-docs
  - adr
---

# doc-adr

> **A writer.** It follows the [writing contract](../docs/writing-contract.md): it reads the request, the files the request names, `references/template.md`, `references/rules.md`, and the listing of the ADR folder to number the file — nothing else (`DD-CORE-01`, `DD-CORE-02`).

## Scope

An ADR answers one question: **what did we decide, and why, in a way that outlives this change?** One ADR, one decision; three choices are three ADRs.

| The request is... | Go to |
| --- | --- |
| a choice still open, or a request to recommend one | not a writer's job: the decision comes first, then this skill |
| one feature's interfaces, data shapes and steps | `doc-spec` |
| what to build | `doc-prd` |
| a choice with no real trade-off, easy to reverse | no document (`DOC-CORE-02`); say so and stop |

**Anchor:** the decision that was made (`DD-CORE-06`). A request that lists options without a choice is `blocked`: return "which option was chosen, and by whom?" and write nothing.

## Step 1: Number and place

1. List `.specs/adr/` (or the folder the caller named). The number is the highest plus one, four digits, `0001` first; a number the caller gives wins. The slug is the decision in kebab-case: `0005-keep-sessions-in-postgres.md`.
2. Several decisions in one request → one ADR each, numbered in the order given.
3. The decision replaces an earlier one → a superseding ADR (Step 3), never an edit.

## Step 2: Write

Copy the template from "Body" down. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | One decision, in active voice: "We will ..." | `DOC-ADR-01` |
| 2 | Name the axis that decided it — state ownership, boundary, contract, distribution or operating cost — from the input's reason | makes decisions comparable years later |
| 3 | Alternatives are the ones the input weighed, each with the reason it lost; an obvious alternative the input does not mention becomes a gap ("was X considered?"), not a straw man you write | `DOC-ADR-04`, `DD-CORE-03` |
| 4 | Consequences include a cost; a cost the input states is copied, an evident one it does not state is written `(proposed)` | recording only the gain is not allowed (`DOC-ADR-04`) |
| 5 | Each invariant the input gives names the test type that proves it at the cheapest level; an invariant with no test type is a gap | the owner must be able to check the decision holds |
| 6 | `file:line` and links only when the input gives them; delete every bracketed hint | `DD-CORE-02` |
| 7 | `status: Proposed`; the writer never accepts its own ADR | `DD-CORE-07` |

## Step 3: Superseding, not editing

An `Accepted` ADR is never edited (`DOC-ADR-02`). When the decision changes:

1. Write a new ADR with `Supersedes: ADR-NNNN` in its header.
2. In the old ADR, change only the status line to `Superseded by ADR-NNNN`.
3. Keep the old file: deleting it erases why the first decision was made.

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | exactly one decision per file, in active voice | `DOC-ADR-01` |
| 2 | named `NNNN-<slug>.md`, next in sequence | `DOC-ADR-03` |
| 3 | every alternative came from the input; consequences include a cost | `DOC-ADR-04`, `DD-CORE-03` |
| 4 | an `Accepted` ADR was not edited beyond its status line | `DOC-ADR-02` |
| 5 | every gap is inline and again under Open questions, with who decides | `DD-CORE-05` |
| 6 | no bracketed hint survived; status is `Proposed` | `DD-CORE-07` |

## Step 5: Return

The return block of the [writing contract](../docs/writing-contract.md) §5 — outcome (`complete`, `partial` or `blocked`), path or "inline", status, one sentence, then every gap and `(proposed)` item, with the one-sentence decision as the summary. The owner's explicit "accept" moves `Proposed` to `Accepted`; silence moves nothing.

## Example

*"Record it: sessions stay in PostgreSQL, not Redis, because ops does not want another service. Highest ADR is 0004."* File `0005-keep-sessions-in-postgres.md`, `Proposed`. Decision: "We will store sessions in PostgreSQL." Axis: operating cost. Alternative: Redis, lost on "one more service to run" (the input's reason). Costs: none stated, so "(proposed) one extra query per authenticated request". Invariants: none given → `[GAP: what must stay true, and which test proves it? — decides: software-architect]`. Outcome `partial`.
