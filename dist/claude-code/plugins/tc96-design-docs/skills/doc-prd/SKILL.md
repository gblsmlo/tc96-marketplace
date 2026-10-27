---
name: doc-prd
description: Writes or amends a product's PRD (product requirements document) from product decisions already made — summary, sourced problem, audience, objectives with metric and target, user stories with PRD-wide Given/When/Then acceptance criteria, the capabilities with the criteria each satisfies and its priority, out of scope and two-way traceability — as a `Draft` in `.specs/PRD.md`, marking every missing fact as a gap instead of inventing it. Use whenever someone asks to write, draft, revise or amend a PRD, product spec or requirements doc, to add a capability to an approved PRD, or to turn "we want X, here is what we know" into stories, criteria and capabilities. A writer only — it does not research users, read the codebase, decide scope or cut the delivery. Not for the delivery plan (layers, order, size), a technical design (doc-spec), a lasting technical decision (doc-adr), or tracker items (doc-epic, doc-feature, doc-story).
source: "[Rules of the PRD](references/rules.md)"
model: sonnet
effort: high
tags:
  - skill
  - design-docs
  - prd
---

# doc-prd

> **A writer.** It follows the [writing contract](../../docs/design-docs/writing-contract.md): it reads the request, the files the request names, `references/template.md`, `references/rules.md` and `.specs/PRD.md` when it exists — nothing else (`DD-CORE-01`, `DD-CORE-02`). A fact the PRD needs and the input does not hold becomes a gap.

## Scope

The PRD answers one question: **what are we building, and why, as which capabilities, proved by which acceptance criteria?** One per product. It carries no delivery cut: layers, order and size are the delivery plan's (`SDD-PRD-04`).

| The request is... | Go to |
| --- | --- |
| the layers, their order, size and the seams between them | the delivery plan (`spec-writer`, in `workflow-plan`) |
| a technical design written as a standalone document | `doc-spec` |
| a technical decision that outlives the delivery | `doc-adr` |
| a capability, feature or story as a tracker item | `doc-epic`, `doc-feature`, `doc-story` |
| a fix or refactor that changes no product behavior | no PRD change: `doc-bug` or `doc-tasks` |

**Anchor:** the problem, and who has it (`DD-CORE-06`). Without it, return the questions and write nothing.

## Step 1: Pick the mode

Read only the status line of `.specs/PRD.md` (or the path the caller named) and of its last amendment:

| The file... | Write |
| --- | --- |
| does not exist | the file, from `references/template.md` |
| is `Draft` or `In review` | a revision of that draft |
| is `Approved` | a dated amendment at the end; the approved text is never rewritten (`SDD-PRD-06`) |

## Step 2: Sort the input

Before writing, sort what the input says into the template's slots: problems and their evidence, audience, objectives and targets, stories, stated limits (numbers, dates, roles), the capabilities and their priority, non-goals. Anything a required slot needs and the input lacks is a gap with who decides it (`DD-CORE-05`).

## Step 3: Write

Copy the template from "Body" down. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | Every claim about users or the problem carries the source the input gave, or is labeled `(hypothesis)` | an unsourced claim is a guess (`DD-CORE-03`) |
| 2 | Every objective has a metric and a target; a target the input does not give is a gap, never a number you pick | a goal with no measure is a wish (`DOC-PRD-02`) |
| 3 | Number acceptance criteria across the PRD (`AC-01`…), each a Given / When / Then with an observable outcome | each becomes a check someone must prove (`SDD-PRD-03`) |
| 4 | Every limit the input states — a number, a duration, a role — appears in a criterion with its boundary explicit; an open side of it (inclusive? which time zone? what after?) is a gap | the question that stops a developer mid-code is the limit's edge |
| 5 | Each capability is one sentence of what a person can do, names the `AC-*` it satisfies and its priority; every `AC-*` belongs to at least one capability | the delivery plan maps checks to these (`SDD-PRD-02`) |
| 6 | A capability or priority the input did not state is yours: mark it `(proposed)` | the owner must see it was your reading (`DD-CORE-04`) |
| 7 | No delivery cut — layers, order, waves, size, what one capability provides another — even when the input offers one; an order or dependency the input states stays out of the file and is listed in the return, for the delivery plan | that is the delivery plan's (`SDD-PRD-04`) |
| 8 | Fill Traceability both ways: every `PO-*` and `OBJ-*` to its capabilities, every capability to at least one item | `SDD-PRD-05` |
| 9 | Out of Scope holds only what the input excluded, plus what you left out and say why | `DOC-PRD-01` |
| 10 | No schema, API contract or service boundary; capabilities stay in product words | that is the delivery plan's or an ADR's (`DOC-PRD-03`) |
| 11 | `status: Draft`; delete every bracketed hint | `DD-CORE-07` |

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | the sections are present and in order | `SDD-PRD-01` |
| 2 | no number, source, target or decision appears that the input did not give | `DD-CORE-03` |
| 3 | every capability names its `AC-*` and priority; every `AC-*` belongs to a capability | `SDD-PRD-02` |
| 4 | every criterion has an `AC-NN` and an observable outcome | `SDD-PRD-03` |
| 5 | no layer, order, wave, size or provides/consumes cut appears | `SDD-PRD-04` |
| 6 | traceability holds both ways | `SDD-PRD-05` |
| 7 | every gap is inline and again under Open gaps, with who decides | `DD-CORE-05` |
| 8 | no technical design leaked in; no bracketed hint survived | `DOC-PRD-03` |
| 9 | status is `Draft` (or the amendment's is) | `DD-CORE-07` |

## Step 5: Return

The return block of the [writing contract](../../docs/design-docs/writing-contract.md) §5 — outcome, path, status, one sentence, open gaps and `(proposed)` items — plus the capabilities in one line each, and any order or dependency the input stated, for the delivery plan. Not the file's content. The owner's explicit "approve" moves `Draft` to `Approved` in one field edit; "change" means a revision from the owner's words; silence moves nothing.

## Example

*"We want customers to approve quotes online. Support says approvals stall about 3 days. Quotes expire after 30 days. Sales wants to know when a quote is approved."* No PRD exists. `PO-1` "approvals stall about 3 days", source: support. `OBJ-1` "time to approval", target: `[GAP: target approval time — decides: owner]`. `US-1` with `AC-01`–`AC-04`, `US-2` (sales is told) with `AC-05`; the 30-day limit becomes `AC-04` "given a quote sent 30 days ago, when the customer opens it, then they see it expired", and its open side becomes `[GAP: is day 30 inclusive, and in whose time zone? — decides: owner]`. Capabilities, all `(proposed)`: `CAP-1` the customer approves or rejects a quote from its link (`AC-01`–`AC-04`, P0), `CAP-2` sales is notified when a quote is approved (`AC-05`, P1). No layers and no order: the delivery plan cuts those. Return: path, `Draft`, two capabilities, two gaps.
