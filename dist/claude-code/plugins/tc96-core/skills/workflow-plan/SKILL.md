---
name: workflow-plan
description: Turns a triage's route into approved planning files — a PRD or dated amendment decided by product-manager and written by doc-prd, ADRs for lasting technical decisions through software-architect and doc-adr, and one delivery plan per PRD or amendment written by spec-writer from the triage's code facts, layered outside in — `plan.md` (the index that keeps progress), `plans/<layer>.md` (one per layer: seams, rules, skills, checks) and `contract.md` (which checks prove each AC-*) — every file a `Draft` the owner approves, citing `SDD-PRD-*`, `SDD-PLAN-*` and `SDD-FLOW-*` IDs. Also writes the new layer that replaces one whose checks failed twice or hit a gap, and the fast-lane delivery of a fix or refactor. Use after workflow-search, when the review hands over a new layer, or when someone asks to write the PRD or the delivery plan. Not for triaging a request (workflow-search), running layers (workflow-implementation), nor reviewing them (workflow-review).
source: "[Delivery Flow — Spec Driven Development](../../docs/workflow/delivery-flow.md)"
tags:
  - skill
  - workflow
  - plan
  - spec
---

# workflow-plan

> **Delegation (`SDD-CORE-02`).** This phase runs in the main session and writes nothing itself. The PRD goes to `product-manager`, which decides it and has `doc-prd` write it; the delivery plan goes to `spec-writer`; each lasting decision goes to `software-architect` through `doc-adr`. Each is called by name, as a subagent, so it runs on its own tier.
> **Context (`SDD-CORE-04`).** Keep only paths, statuses, one sentence per file and the open gaps. Never read a written file back into this conversation.

Rules this phase implements: [Delivery Flow — Spec Driven Development](../../docs/workflow/delivery-flow.md) §4.2–§4.5, `SDD-PRD-*`, `SDD-PLAN-*`, `SDD-FLOW-01`, `SDD-FLOW-02`.

## Scope

| The input is... | Mode | Go to |
| --- | --- | --- |
| a triage file whose route has an amendment, an ADR, the delivery plan or the fast lane | **route** | this phase |
| a layer `workflow-review` marked for a new layer after two failed rounds, or blocked on a gap | **new layer** | this phase |
| a request with no triage yet | — | `workflow-search` first |
| an approved delivery to run | — | `workflow-implementation` |

## Step 0: Read where things stand

Read only: the triage file's frontmatter and **Route**, the status line of `.specs/PRD.md` and of its last amendment, the ADR titles, and the frontmatter of each `.specs/delivery/*/plan.md`. Resume at the first stop of the route that has no `Approved` file yet.

## Step 1: PRD or amendment

Run this step when the route has an amendment, or no PRD exists. What to do depends on whether that file is already written, read from its status line in Step 0:

| The PRD, or the amendment this route asks for, is... | Do |
| --- | --- |
| not written yet | start `product-manager`, as below, then put its `Draft` in front of the owner |
| already written as `Draft` or `In review` | put it in front of the owner as it is. Do not start `product-manager` and do not rewrite it: the decisions are made and wait only for the owner |
| `Approved` | go to Step 2 |

When it is not written yet, start `product-manager` with the request, the triage path and the slice IDs that go to it. It decides the product content — problem and evidence, stories, each rule's edges, the capabilities and the acceptance criteria each satisfies — and has `doc-prd` write it into `.specs/PRD.md` or a dated amendment. The PRD carries no delivery cut: layers, order and size are the plan's (`SDD-PRD-04`). `doc-prd` only writes: what the decisions leave open comes back as gaps.

Put the `Draft` in front of the owner: path, one sentence, capabilities, open gaps, "approve, change, or reject?". A change the owner asks for is the one case that starts `product-manager` on a written draft, with the owner's words as its input.

**Gate:** the PRD or amendment is `Approved` before the delivery plan, and only the owner's reply sets it (`SDD-CORE-03`). No reply: stop here with the path and its gaps.

## Step 2: ADRs the route asks for

For each `technical-decision` slice, start `software-architect` with the slice, its facts and `doc-adr`. The ADR is born `Proposed` and goes into the same owner message as the delivery plan that cites it (Step 6). A slice whose decision the architect cannot make from the facts comes back as a gap.

## Step 3: One delivery, layered outside in

A PRD or amendment is planned as **one delivery** (`SDD-PLAN-02`). Its capabilities cross every layer, so the plan is cut by layer, outside in: contracts and the test environment, repository, backend, frontend, tests, gates (`SDD-PLAN-03`). Size is handled inside the plan, by splitting a layer into sub-layers: it never returns to the PRD (`SDD-PLAN-05`).

| Mode | Folder | Holds |
| --- | --- | --- |
| route | `.specs/delivery/<YYYY-MM-DD>-<slug>/` | `plan.md` (the index and progress), `plans/<layer>-<slug>.md` (one per layer), `contract.md` |
| route, fast lane | the same layout | only the layers the fix or refactor touches (`SDD-PLAN-10`) |
| new layer | the existing delivery folder | `plans/<layer>.<n>-<slug>.md` and its row in the index (`SDD-PLAN-09`) |

## Step 4: Facts (`SDD-PLAN-01`)

| Mode | Facts |
| --- | --- |
| route | the triage's **Facts** for the slices the delivery covers, cited by path and slice ID |
| new layer | one `repo-explorer` question about the failing branch: what it already has for each failing check. This is plan asking, not a return to search (`SDD-FLOW-02`) |
| work no triage covers | none: it is a new request, so run `workflow-search` on it first |

## Step 5: Write the delivery

Start `spec-writer` once, with:

| Input | Mode |
| --- | --- |
| the PRD path, and the amendment it plans if any | all |
| the triage path and its slice IDs, or the new layer's facts from Step 4 | all |
| the ADR paths | all |
| the absolute paths of the three templates, from this skill's base directory: `references/template-delivery-plan.md` (the index), `references/template-layer.md`, `references/template-acceptance.md` | all |
| the specialist skills implementers can load: every skill of `tc96-backend`, `tc96-frontend`, `tc96-e2e` and `tc96-core` in this session's skill listing, as `<plugin>:<name> — <one line>`. Copy them from the listing; never guess a name | all |
| the failing checks and broken rules, verbatim from the state file, and the failing branch | new layer |
| the gap, in one sentence | new layer from a gap |
| the defect or the refactor's goal, and the `AC-*` it protects | fast lane |

What `spec-writer` must hold to:

| # | Rule | ID |
| --- | --- | --- |
| 1 | the index reads from the outside in — actors and doors, vocabulary, starting point — then the layers table, the order and the branches | `SDD-PLAN-03` |
| 2 | one file per layer; a shape lives only in the **Provides** of the layer that defines it, and consumers link to it | `SDD-PLAN-02` |
| 3 | a layer file decides the seams, the rules (each with its `AC-*` or ADR source), the exact skills, what is free to decide, its checks, Surface, Size; never steps, file lists, regexes or bodies | `SDD-PLAN-04` |
| 4 | a layer above the budget splits inside itself; nothing goes back to the PRD for size | `SDD-PLAN-05` |
| 5 | every check names its `AC-*` or ADR rule and its level, and lives in one layer; G1 and G2 hold on every layer from L1, which sets them up; G3 on sensitive paths | `SDD-PLAN-06` |
| 6 | `contract.md` maps every `AC-*` to the checks that prove it, after one edge sweep per `AC-*` | `SDD-PLAN-07`, `SDD-PLAN-08` |
| 7 | the index names the trunk and the feature branch `feat/<delivery>`; every layer row starts `planned` | `SDD-PLAN-11`, `SDD-RUN-08` |
| 8 | every file is `status: Draft` | `SDD-CORE-03` |

`spec-writer` returns the folder, one sentence, the layers and their order, and the open gaps. For each decision it flags as lasting, start `software-architect` with `doc-adr`, as in Step 2.

## Step 6: One message to the owner

The delivery and its ADRs, in one message, then stop:

```
Delivery to review (Draft):
- .specs/delivery/2026-10-27-quote-approval/ — <one sentence> — layers L1a…L6, order: <one line> — gaps: <verbatim or none>
- .specs/adr/0004-<slug>.md — <one sentence> (Proposed)
Approve, change or reject?
```

| The owner says | Result |
| --- | --- |
| approve | the index, every layer file and the contract become `Approved` |
| change | re-draft what the owner named, and every layer that consumes from it |
| reject | stays `Draft`; the reason goes under the index's open gaps |

Silence approves nothing (`SDD-CORE-03`). A gap that changes what the product promises goes back to Step 1 as an amendment; a size problem never does.

## Step 7: Hand off

Report every `.specs/` path with its status, and every open gap with who decides it. Once the delivery is approved, the next phase is `workflow-implementation`: it creates the feature branch from the trunk and runs the layers in the index's order. A new layer, once approved, enters the same way. Do not load another phase from inside this one (`SDD-FLOW-04`).

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | the PRD or amendment was `Approved` before the delivery was written | `SDD-CORE-01`, `SDD-CORE-03` |
| 2 | a `Draft` amendment already written went to the owner as it was, with no `product-manager` run over it | `SDD-CORE-03` |
| 3 | the plan cites repo-search facts with `file:line`, from the triage or, for a new layer, from the failing branch | `SDD-PLAN-01` |
| 4 | one delivery folder; every index row has its layer file and every layer file a row | `SDD-PLAN-02` |
| 5 | the layer files hold seams, sourced rules and exact skill names, not steps or code | `SDD-PLAN-04` |
| 6 | every `AC-*` has a row in `contract.md`, and every check ID there exists in one layer file | `SDD-PLAN-06`, `SDD-PLAN-07` |
| 7 | no size problem was sent back to the PRD | `SDD-PLAN-05` |
| 8 | no merged layer file was edited, and no triage was reopened; a change is a new layer | `SDD-PLAN-09`, `SDD-FLOW-02` |
| 9 | every file is `Draft` (an ADR `Proposed`) until the owner answered | `SDD-CORE-03` |
| 10 | this conversation holds paths, sentences and gaps, not file content | `SDD-CORE-04` |

## Example

Triage `2026-10-26-quote-approval.md`, route: amendment (S1), then the delivery, S2 and S3 to build. Step 1: `product-manager` decides the amendment and `doc-prd` writes it: CAP-3 quote approval, `AC-01`–`AC-05`. The owner approves it. Step 3: one delivery, `.specs/delivery/2026-10-27-quote-approval/`. Step 4: the triage holds "quotes table has no status column — src/db/schema.ts:40" for S3. Step 5: `spec-writer` writes the index (actors: seller, customer through a signed link; vocabulary: `approved`, `expired`, error codes), then `L1a` contracts (the approval schema, the status column), `L2a` the repository (`approveQuote` with its result union), `L3a` the route `POST /quotes/:id/approval` → `201 | 404 | 410`, `L4a` the approval screen, `L5` the journey. The time edge of `AC-05` becomes "C7 (AC-05) approving at 23:59 on day 30 in the seller's time zone succeeds, at 00:00 on day 31 returns 410 · unit", in `L2a`. `L3a` touches a link that grants access without a session, so its file adds G3. `spec-writer` flags "approval links are signed, not stored" as lasting, and `software-architect` writes ADR 0004, `Proposed`. Step 6: one message with the delivery and the ADR. The owner answers "approve the delivery and ADR 0004". Step 7: next phase, `workflow-implementation`.
