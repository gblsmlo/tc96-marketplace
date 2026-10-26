---
name: doc-prd
description: Writes or amends a product's PRD (product requirements document) from product decisions already made — summary, sourced problem, audience, objectives with metric and target, user stories with PRD-wide Given/When/Then acceptance criteria, the features with what each satisfies, provides and consumes, out of scope, execution waves and two-way traceability — as a `Draft` in `.specs/PRD.md`, marking every missing fact as a gap instead of inventing it. Use whenever someone asks to write, draft, revise or amend a PRD, product spec or requirements doc, to add a feature to an approved PRD, or to turn "we want X, here is what we know" into stories, criteria and features. A writer only — it does not research users, read the codebase or decide scope. Not for one feature's technical design (doc-spec), a lasting technical decision (doc-adr), or tracker items (doc-epic, doc-feature, doc-story).
type: skill
family: design-docs
language: en
source: "[Rules of the PRD](references/rules.md)"
model: medio
effort: alto
tags:
  - skill
  - design-docs
  - prd
---

# doc-prd

> **A writer.** It follows the [writing contract](../docs/writing-contract.md): it reads the request, the files the request names, `references/template.md`, `references/rules.md` and `.specs/PRD.md` when it exists — nothing else (`DD-CORE-01`, `DD-CORE-02`). A fact the PRD needs and the input does not hold becomes a gap.

## Scope

The PRD answers one question: **what are we building, and why, in which features and in which order?** One per product.

| The request is... | Go to |
| --- | --- |
| one feature's interfaces, data shapes and design | `doc-spec` |
| a technical decision that outlives a feature | `doc-adr` |
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

Before writing, sort what the input says into the template's slots: problems and their evidence, audience, objectives and targets, stories, stated limits (numbers, dates, roles), dependencies, non-goals. Anything a required slot needs and the input lacks is a gap with who decides it (`DD-CORE-05`).

## Step 3: Write

Copy the template from "Body" down. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | Every claim about users or the problem carries the source the input gave, or is labeled `(hypothesis)` | an unsourced claim is a guess (`DD-CORE-03`) |
| 2 | Every objective has a metric and a target; a target the input does not give is a gap, never a number you pick | a goal with no measure is a wish (`DOC-PRD-02`) |
| 3 | Number acceptance criteria across the PRD (`AC-01`…), each a Given / When / Then with an observable outcome | each becomes a check someone must prove (`SDD-PRD-03`) |
| 4 | Every limit the input states — a number, a duration, a role — appears in a criterion with its boundary explicit; an open side of it (inclusive? which time zone? what after?) is a gap | the question that stops a developer mid-code is the limit's edge |
| 5 | Each feature names the `AC-*` it satisfies, what it provides and consumes, and the one provider of each consumed item | the waves and the specs are built from this (`SDD-PRD-02`) |
| 6 | A feature cut the input did not state is yours: mark it `(proposed)`; split by acceptance criterion, never by layer | the owner must see it was your reading (`DD-CORE-04`) |
| 7 | Build the waves from the consumes column: foundation first, each feature in the first wave after its providers; break a cycle by extracting a provider | `SDD-PRD-04` |
| 8 | Fill Traceability both ways: every `PO-*` and `OBJ-*` to its features, every feature to at least one item | `SDD-PRD-05` |
| 9 | Out of Scope holds only what the input excluded, plus what you left out and say why | `DOC-PRD-01` |
| 10 | No schema, API contract or service boundary; provides and consumes stay in product words | that is `doc-spec` (`DOC-PRD-03`) |
| 11 | `status: Draft`; delete every bracketed hint | `DD-CORE-07` |

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | the sections are present and in order | `SDD-PRD-01` |
| 2 | no number, source, target or decision appears that the input did not give | `DD-CORE-03` |
| 3 | every feature has satisfies, provides and consumes; every consumed item names one provider | `SDD-PRD-02` |
| 4 | every criterion has an `AC-NN` and an observable outcome | `SDD-PRD-03` |
| 5 | no feature sits in a wave at or before one of its providers; no cycle | `SDD-PRD-04` |
| 6 | traceability holds both ways | `SDD-PRD-05` |
| 7 | every gap is inline and again under Open gaps, with who decides | `DD-CORE-05` |
| 8 | no technical design leaked in; no bracketed hint survived | `DOC-PRD-03` |
| 9 | status is `Draft` (or the amendment's is) | `DD-CORE-07` |

## Step 5: Return

The return block of the [writing contract](../docs/writing-contract.md) §5 — outcome, path, status, one sentence, open gaps and `(proposed)` items — plus the waves in one line each. Not the file's content. The owner's explicit "approve" moves `Draft` to `Approved` in one field edit; "change" means a revision from the owner's words; silence moves nothing.

## Example

*"We want customers to approve quotes online. Support says approvals stall about 3 days. Quotes expire after 30 days. Sales wants to know when a quote is approved."* No PRD exists. `PO-1` "approvals stall about 3 days", source: support. `OBJ-1` "time to approval", target: `[GAP: target approval time — decides: owner]`. `US-1` with `AC-01`–`AC-04`; the 30-day limit becomes `AC-04` "given a quote sent 30 days ago, when the customer opens it, then they see it expired", and its open side becomes `[GAP: is day 30 inclusive, and in whose time zone? — decides: owner]`. Features, all `(proposed)`: `F01` quote link (consumes nothing), `F02` approval (consumes the link from `F01`, provides "approved quote event"), `F03` sales notification (consumes the event from `F02`). Waves: `W0` F01, `W1` F02, `W2` F03. Return: path, `Draft`, three waves, two gaps.
