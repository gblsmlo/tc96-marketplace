---
name: workflow-plan
description: Turns a triage's route into approved planning files — a PRD or dated amendment decided by product-manager and written by doc-prd, ADRs for lasting technical decisions through software-architect and doc-adr, and one bundle per feature (`spec.md`, `plan.md`, `contract.md`) written by spec-writer from the triage's code facts — every file a `Draft` the owner approves, citing `SDD-PRD-*`, `SDD-SPEC-*` and `SDD-FLOW-*` IDs. Also writes the new item that replaces a feature whose contract failed twice or hit a gap, and the fast-lane bundle of a fix or refactor. Use after workflow-search, when the review hands over a new item, or when someone asks to write the PRD, a spec or a bundle. Not for triaging a request (workflow-search), running features (workflow-implementation), nor reviewing them (workflow-review).
type: skill
family: workflow
language: en
source: "[Delivery Flow — Spec Driven Development](../docs/delivery-flow.md)"
tags:
  - skill
  - workflow
  - plan
  - spec
---

# workflow-plan

> **Delegation (`SDD-CORE-02`).** This phase runs in the main session and writes nothing itself. The PRD goes to `product-manager`, which decides it and has `doc-prd` write it; each bundle goes to `spec-writer`; each lasting decision goes to `software-architect` through `doc-adr`. Each is called by name, as a subagent, so it runs on its own tier.
> **Context (`SDD-CORE-04`).** Keep only paths, statuses, one sentence per file and the open gaps. Never read a written file back into this conversation.

Rules this phase implements: [Delivery Flow — Spec Driven Development](../docs/delivery-flow.md) §4.2–§4.5, `SDD-PRD-*`, `SDD-SPEC-*`, `SDD-FLOW-01`, `SDD-FLOW-02`.

## Scope

| The input is... | Mode | Go to |
| --- | --- | --- |
| a triage file whose route has an amendment, an ADR, bundles or the fast lane | **route** | this phase |
| a feature `workflow-review` marked for a new item after two failed rounds, or blocked on a gap | **new item** | this phase |
| a request with no triage yet | — | `workflow-search` first |
| approved bundles to run | — | `workflow-implementation` |

## Step 0: Read where things stand

Read only: the triage file's frontmatter and **Route**, the status line of `.specs/PRD.md` and of its last amendment, the ADR titles, and the folder names in `.specs/features/`. Resume at the first stop of the route that has no `Approved` file yet.

## Step 1: PRD or amendment

When the route has an amendment, or no PRD exists: start `product-manager` with the request, the triage path and the slice IDs that go to it. It decides the product content — problem and evidence, stories, each rule's edges, the feature cut, what each feature provides and consumes, the waves — and has `doc-prd` write it into `.specs/PRD.md` or a dated amendment. `doc-prd` only writes: what the decisions leave open comes back as gaps.

Put the `Draft` in front of the owner: path, one sentence, waves, open gaps, "approve, change, or reject?".

**Gate:** the PRD or amendment is `Approved` before any bundle, and only the owner's reply sets it (`SDD-CORE-03`). No reply: stop here with the path and its gaps.

## Step 2: ADRs the route asks for

For each `technical-decision` slice, start `software-architect` with the slice, its facts and `doc-adr`. The ADR is born `Proposed` and goes into the same owner message as the bundles that cite it (Step 6). A slice whose decision the architect cannot make from the facts comes back as a gap.

## Step 3: Pick the bundles

Read only the PRD's **Functionalities** and **Dependency Graph**.

| Mode | Write bundles for | ID and folder |
| --- | --- | --- |
| route | every feature the route's `build` slices map to, with no approved folder; in wave order | `.specs/features/F<NN>-<slug>/`, the `F` number from the PRD |
| route, fast lane | the fix or refactor of a `no-behavior-change` slice | `.specs/features/F<NN>.<n>-<slug>/`, under the feature it changes |
| new item | the one feature `workflow-review` named | `.specs/features/F<NN>.<n>-<slug>/`, the next free `.n` |

A consumer's bundle is written after its provider's draft exists, so it codes against the provider's `spec.md`, not a guess. Bundles start from an approved PRD (`SDD-CORE-01`); the fast lane needs no amendment, but it needs an approved PRD to trace to.

## Step 4: Facts for each bundle (`SDD-SPEC-01`)

| Mode | Facts |
| --- | --- |
| route | the triage's **Facts** for the slices this feature maps to, cited by path and slice ID |
| new item | one `repo-explorer` question about the failing branch: what it already has for each failing check. This is plan asking, not a return to search (`SDD-FLOW-02`) |
| a feature no triage covers | none: it is a new request, so run `workflow-search` on it first |

## Step 5: Write each bundle

Start `spec-writer` once per feature, in list order, with:

| Input | Mode |
| --- | --- |
| the PRD path and the feature's `F` number | all |
| the triage path and slice IDs, or the new item's facts from Step 4 | all |
| the paths of the providers' `spec.md` | route, new item |
| the absolute paths of the three templates, from this skill's base directory: `references/template-spec.md`, `references/template-plan.md`, `references/template-contract.md` | all |
| the failing checks and unmet `AC-*`, verbatim from the state file, and the failing branch | new item |
| the gap, in one sentence | new item from a gap |
| the defect or the refactor's goal, and the `AC-*` it protects | fast lane |

What `spec-writer` must hold to, as it writes:

| # | Rule | ID |
| --- | --- | --- |
| 1 | each file answers only its question; a fact lives in one file and the others link to it | `SDD-SPEC-02` |
| 2 | `spec.md` gives each provided item a shape a consumer can code against; UX section only when the feature has an interface that needs one | `SDD-SPEC-03` |
| 3 | `plan.md` names the Surface, Size and base branch, one owner role, and fits the review budget; a feature above it goes back as a gap: "split F<NN> in the PRD" | `SDD-SPEC-04` |
| 4 | `contract.md` has a check for every `AC-*` the feature traces, each with its gate type, plus the non-functional gates, and closes with **Met when** per `AC-*` | `SDD-SPEC-05`, `SDD-SPEC-06` |
| 5 | each `AC-*` and rule goes through the seven edge categories once; each applicable edge becomes a check, a gap, or a proposed Out of Scope line for the PRD | `SDD-SPEC-07` |
| 6 | a new item traces the same `AC-*`, starts from the failing branch, and holds only what the failing checks need | `SDD-RUN-06` |
| 7 | fast lane: `plan.md` and `contract.md`; `spec.md` only when an interface changes | `SDD-SPEC-09` |
| 8 | every file is `status: Draft` | `SDD-CORE-03` |

`spec-writer` returns per feature: the folder path, one sentence, its open gaps, and any decision it flagged as outliving the feature. For each flagged decision, start `software-architect` with `doc-adr`, as in Step 2.

## Step 6: One message to the owner

All bundles of this run, and their ADRs, in one message, then stop:

```
Bundles to review (Draft):
- .specs/features/F01-quote-link/ — <one sentence> — gaps: none
- .specs/features/F02-approval/ — <one sentence> — depends on F01's spec.md — gaps: <verbatim>
- .specs/adr/0004-<slug>.md — <one sentence> (Proposed)
Approve, change or reject each?
```

| The owner says | Result |
| --- | --- |
| approve (naming the folders) | each named file becomes `Approved` |
| change one | re-draft that feature, and every bundle that consumes from it |
| reject | stays `Draft`; the reason goes under its Open gaps |

Silence approves nothing (`SDD-CORE-03`). An Out of Scope line or a gap that changes what the product promises is not answered here: it goes back to Step 1 as an amendment.

## Step 7: Hand off

Report every `.specs/` path with its status, and every open gap with who decides it. When every bundle of a wave is approved, the next phase is `workflow-implementation`. A new item, once approved, enters the same way. Do not load another phase from inside this one (`SDD-FLOW-04`).

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | the PRD or amendment was `Approved` before any bundle | `SDD-CORE-01`, `SDD-CORE-03` |
| 2 | every bundle cites repo-search facts with `file:line`, from the triage or, for a new item, from the failing branch | `SDD-SPEC-01` |
| 3 | every folder has the files its mode requires, each answering only its question | `SDD-SPEC-02`, `SDD-SPEC-09` |
| 4 | every `AC-*` the feature traces has a check, and **Met when** names them | `SDD-SPEC-05`, `SDD-SPEC-06` |
| 5 | the non-functional gates are listed; `risk: security` adds the security gate | `SDD-SPEC-05` |
| 6 | every bundle fits the review budget, or went back as a gap | `SDD-SPEC-04` |
| 7 | no file of a merged feature was edited, and no triage was reopened; a change is a new item | `SDD-SPEC-08`, `SDD-FLOW-02` |
| 8 | every file is `Draft` (an ADR `Proposed`) until the owner answered | `SDD-CORE-03` |
| 9 | this conversation holds paths, sentences and gaps, not file content | `SDD-CORE-04` |

## Example

Triage `2026-10-26-quote-approval.md`, route: amendment (S1), then bundles, S2 providing the signed quote link and S3 consuming it. Step 1: `product-manager` decides the amendment and `doc-prd` writes it: F01 quote link in `W0`, F02 approval in `W1`, `AC-01`–`AC-05`. The owner approves it. Step 3: F01, then F02. Step 4: the triage holds "quotes table has no status column — src/db/schema.ts:40" for S3. Step 5: `spec-writer` writes F01, then F02 against F01's `spec.md`. The time edge of `AC-05` becomes "C5 (AC-05) approving at 23:59 on day 30 in the seller's time zone succeeds, at 00:00 on day 31 returns 410 · unit". The risk is `security`, because the link grants access without a session, so G3 is listed. `spec-writer` flags "approval links are signed, not stored" as lasting, and `software-architect` writes ADR 0004, `Proposed`. Step 6: one message with both folders and the ADR. The owner answers "approve F01, F02 and ADR 0004". Step 7: next phase, `workflow-implementation`.
