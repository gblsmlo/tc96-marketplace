---
name: spec-prd
description: Writes the product's PRD (product requirements document), the single source of truth of the Spec Driven Development flow — summary, problem and opportunity, audience, objectives with metrics, user stories with numbered acceptance criteria, the features with what each provides and consumes, out of scope, the dependency graph in waves and the traceability from each problem to its features — as a `Draft` the owner approves, then freezes it and takes later changes as dated amendments, citing `SDD-PRD-*` and `DOC-PRD-*` IDs. Use whenever someone asks to write, draft, revise or amend a PRD, product spec or `PRD.md`, to add a feature to the product, or to turn "we should build X" into features, acceptance criteria and waves. Not for a feature's interfaces, steps or checks (sdd-spec-writer), nor for a lasting technical decision (spec-adr).
type: skill
family: spec
language: en
source: "[Rules of the PRD](references/rules.md)"
tags:
  - skill
  - spec
  - prd
---

# spec-prd

> **Self-contained.** The template is `references/template.md`; the rule text, the lifecycle and the edge sweep are `references/rules.md`. Nothing here needs another skill to run.
> Owner role: `product-manager` writes the content. When this skill runs in an orchestrating conversation, start that agent as a subagent with the template path and the writing rules below, and keep only its path and open gaps in the conversation (`SDD-CORE-02`).

## Scope

The PRD answers one question: **what are we building, and why, in which features and in which order?** It is born `Draft` and becomes `Approved` only on the owner's explicit answer.

| The question is... | Go to |
| --- | --- |
| a feature's interfaces, steps and checks | `sdd-spec-writer` |
| a technical decision that outlives a feature | `spec-adr` |
| running the approved features | `sdd-orchestrator` |
| a fix or refactor that changes no product behavior | `sdd-spec-writer`, fast lane: no PRD amendment |

## Step 1: Confirm the question is open

1. The file is `.specs/PRD.md`, one per product. Read only its status line and the status of its last amendment, if it exists:

| The file... | Write |
| --- | --- |
| does not exist | the file, from `references/template.md` |
| is `Draft` or `In review` | a revision of that draft |
| is `Approved` | a dated amendment at the end; the approved text is never rewritten (`SDD-PRD-06`) |

2. A request that changes no product behavior (a fix, a refactor) does not open an amendment: send it to `sdd-spec-writer` and stop.

## Step 2: Write

Copy the template from "Body" down. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | Delete every bracketed hint; fill every field or write `none` | a field left as a hint is an unmade decision |
| 2 | Every claim about users cites a source, or is labeled `hypothesis` | an unsourced claim is a guess |
| 3 | Every objective has a metric and a target | a goal with no measure is a wish (`DOC-PRD-02`) |
| 4 | Number acceptance criteria across the PRD (`AC-01`…), each a Given / When / Then with an observable outcome | each one becomes a check a contract must prove (`SDD-PRD-03`) |
| 5 | Each feature names the `AC-*` it satisfies, what it provides and what it consumes, with the provider of each consumed item | the graph and the contracts are built from this (`SDD-PRD-02`) |
| 6 | Cut features so each fits one review (default 300 changed lines); split by acceptance criterion, never by layer | a feature above the budget reviews badly, one far below it costs a full cycle for little |
| 7 | Build the waves from the consumes column: foundation first, each feature in the first wave after its providers; break a cycle by extracting a provider | `SDD-PRD-04` |
| 8 | Fill Traceability both ways: every `PO-*` and `OBJ-*` to its features, every feature to at least one item | `SDD-PRD-05` |
| 9 | Sweep each acceptance criterion through the seven edge categories (`references/rules.md`); each applicable edge becomes an `AC-*`, an Out of Scope line or an open gap | the question that stops a developer mid-code is the rule's edge |
| 10 | No schema, API contract or service boundary; provides and consumes stay in product words | that is the feature's `spec.md` (`DOC-PRD-03`) |
| 11 | `status: Draft`; the writer never approves its own file | `SDD-CORE-03` |

## Step 3: Put it in front of the owner

One message, four parts, then stop: the path; the summary's first sentence; the waves in one line each; the open gaps, verbatim; "approve, change, or reject?" Not the file's content: the owner reads the file.

| The owner says | Result |
| --- | --- |
| approve | `Draft` or `In review` becomes `Approved`; the file is frozen |
| change | revise from the owner's words; the status does not move |
| reject | stays `Draft`; record why under Open gaps |

Silence is not approval. On an amendment, the status that moves is the amendment's. Moving a status is one field edit: make it directly.

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | the sections are present and in order | `SDD-PRD-01` |
| 2 | every feature has satisfies, provides and consumes; every consumed item names one provider | `SDD-PRD-02` |
| 3 | every acceptance criterion has an `AC-NN` and an observable outcome | `SDD-PRD-03` |
| 4 | no feature sits in a wave at or before one of its providers; no cycle | `SDD-PRD-04` |
| 5 | traceability holds both ways | `SDD-PRD-05` |
| 6 | out of scope is written, not implied | `DOC-PRD-01` |
| 7 | no technical design leaked in | `DOC-PRD-03` |
| 8 | every applicable edge has a destination | `references/rules.md`, "Edge sweep" |
| 9 | no bracketed hint survived | Step 2, rule 1 |
| 10 | status is `Draft` until the owner answered | `SDD-CORE-03` |

## Step 5: Return

Report the path, the status, the waves and every open gap with who decides it. Nothing else goes back to the orchestrating conversation.

## Example

*"We want customers to approve quotes online."* `.specs/PRD.md` does not exist. The writer states `PO-1` ("quote approvals stall for about 3 days", source: support tickets), sets `OBJ-1` ("approval time from 3 days to 1"), and writes `US-1` with `AC-01` to `AC-05`. Features: `F01` quote link (provides "a signed link to one quote", consumes nothing), `F02` approval (satisfies `AC-01`–`AC-04`, consumes the link from `F01`, provides "approved quote event"), `F03` sales notification (consumes the event from `F02`). Waves: `W0` F01, `W1` F02, `W2` F03. The expiry edge ("valid until when, in which time zone?") has no answer, so it goes to Open gaps with `decided by: owner`. The owner answers "30 days, in the seller's time zone"; the writer adds `AC-05` and the owner approves. A month later "partial approval" arrives: it enters as `## Amendment 001 — 2026-11-02 — partial approval`, adding `F04` and `AC-06`, born `Draft`.
