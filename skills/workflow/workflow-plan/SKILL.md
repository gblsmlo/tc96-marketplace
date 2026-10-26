---
name: workflow-plan
description: Runs phase 2 of the delivery flow v2 — turns the features of an approved PRD into one bundle each, `story.md` (who it is for and which `AC-*` it delivers), `spec.md` (what it exposes and consumes, UX section when needed) and `contract.md` (checks tagged with `AC-*`, gate type and lane, plus Surface, Size, base branch and the lane map), from the PRD and Search's repo facts, as `Draft` files the owner approves in one message, citing handoffs `H5`–`H8` and `SDD-SPEC-*`. Also writes the new item for a feature whose contract failed twice or hit a gap, and the fast-lane bundle of a fix. In a project on the delivery flow v2 (`story.md` bundles), use when an approved PRD has features with no approved bundle, when Review or Implementation hands back a failing feature or a gap, or when someone asks to spec a fix or refactor. Not for the PRD or a product change (workflow-search), running the bundle (workflow-implementation), nor a lasting technical decision (spec-adr).
type: skill
family: workflow
language: en
source: "workflow/foundations/phases.md §2 (Draft, 2026-10-26)"
tags:
  - skill
  - workflow
  - spec
---

# workflow-plan

> **Delegation (`SDD-CORE-02`).** This skill runs in the orchestrating conversation and writes nothing itself. Each bundle goes to `spec-writer`; a missing repo fact to `repo-explorer`; a lasting decision to `software-architect` with `spec-adr`. Each is called by name, as a subagent. Keep only paths, statuses and open gaps here (`SDD-CORE-04`).
> **Status.** Draft. Implements `workflow/foundations/phases.md` §2 and `workflow/foundations/handoffs.md` `H5`–`H8`. The bundle replaces `plan.md` with `story.md`; what `plan.md` held moves into `contract.md` (default D1).

## Scope

| The request is... | Mode | Go to |
| --- | --- | --- |
| features of the approved PRD with no approved bundle | **bundle** | this skill |
| a feature Review marked `split`, or one blocked on a gap (`H10`, `H14`) | **new item** | this skill |
| a fix or refactor that changes no product behavior | **fast lane** | this skill |
| a new feature or a change to what the product promises | — | `workflow-search`, as an amendment |
| a technical decision that outlives the feature | — | `spec-adr`, from Step 4 |

## Step 1: Pick what to write

1. Read only the status line of `.specs/PRD.md` and its last amendment. Not `Approved` → stop (`SDD-CORE-01`).
2. Build the list:

| Mode | Write bundles for | Folder |
| --- | --- | --- |
| bundle | every feature of the requested waves with no approved folder; with none named, every such feature in wave order | `.specs/features/F<NN>-<slug>/` |
| new item | the one feature handed back | `.specs/features/F<NN>.<n>-<slug>/`, next free `.n` |
| fast lane | the fix or refactor | `.specs/features/F<NN>.<n>-<slug>/`, under the feature it changes |

3. Order by wave. A consumer's bundle is written after its provider's `spec.md` draft exists, so its interfaces match what the provider exposes.

## Step 2: Gather inputs, no new search

| Input | From |
| --- | --- |
| the feature's PRD entry and its `AC-*` | `.specs/PRD.md` |
| repo facts | the evidence file's "Repo facts" block for this feature (`H4`) |
| each provider's `spec.md` | `.specs/features/<provider>/` |
| ADRs in force | `.specs/adr/` |

Search already read the code. Only when a fact the bundle needs is missing from the evidence file, start `repo-explorer` with one bounded question for that fact, and add the answer to the evidence file. For a new item, the question is what the failing branch already has for each failing check.

## Step 3: Write each bundle

Start `spec-writer` once per feature, in list order, with the inputs above and the three writing skills, in this order. `spec-writer` has no Skill tool, so pass each `SKILL.md` path for it to read (find with Glob `**/<skill>/SKILL.md`). They override the agent's default `plan.md`: in this flow there is no `plan.md`.

| File | Skill | Family |
| --- | --- | --- |
| `story.md` | `story-write` | design-docs |
| `spec.md` | `spec-write` | design-docs |
| `contract.md` | `contract-write` | design-docs |

Rules `spec-writer` holds to:

| # | Rule | ID |
| --- | --- | --- |
| 1 | each file answers only its question; a fact lives in one file and the others link to it | `SDD-SPEC-02` |
| 2 | `story.md` quotes the PRD's one-sentence story and lists the `AC-*` IDs; Given / When / Then stays in the PRD (default D9) | `SDD-SPEC-02` |
| 3 | `spec.md` gives each provided item a shape a consumer can code against; UX section only when the feature has an interface that needs one | `SDD-SPEC-03` |
| 4 | `contract.md` has a check for every traced `AC-*`, each with its gate type and lane, the non-functional gates, and **Met when** per `AC-*` | `SDD-SPEC-05`, `SDD-SPEC-06` |
| 5 | `contract.md` frontmatter holds base, owner role, Surface, Size and the lane map (default D1); above the 300-line budget the feature goes back as a gap: "split F<NN> in the PRD by acceptance criterion" | `SDD-SPEC-04` |
| 6 | lane map: each of the seven lanes is `none`, `small` or `large`; `large` when that lane alone is estimated above 150 changed lines (default D4); `tooling` is never `large` (default D5) | — |
| 7 | each `AC-*` and rule goes through the seven edge categories once; each applicable edge becomes a check, a gap, or a proposed Out of Scope line | `SDD-SPEC-07` |
| 8 | a new item traces the same `AC-*`, starts from the failing branch, holds only what the failing checks need | `SDD-RUN-06` |
| 9 | fast lane: `story.md` and `contract.md`; `spec.md` only when an interface changes | `SDD-SPEC-09` |
| 10 | every file is `status: Draft` | `SDD-CORE-03` |

`spec-writer` returns per feature: the folder path, one sentence, the lane map, its open gaps, and any decision it flagged as outliving the feature.

## Step 4: Amendments and lasting decisions (`H5`)

| `spec-writer` flagged... | Next |
| --- | --- |
| an edge that changes what the product promises | stop that feature; hand it to `workflow-search` as an amendment request, one sentence |
| a decision that outlives the feature | `software-architect` with `spec-adr`; the ADR is born `Proposed` and joins the owner message; `spec.md` cites `ADR-NNNN` |

## Step 5: One message to the owner (`H6`)

```
Bundles to review (Draft):
- .specs/features/F03-invitations/ — <one sentence> — lanes: backend large, frontend small, qa small — gaps: none
- .specs/features/F04-accept/ — <one sentence> — consumes F03's spec.md — gaps: <verbatim>
- .specs/adr/0004-<slug>.md — <one sentence> (Proposed)
Approve, change or reject each?
```

| The owner says | Result |
| --- | --- |
| approve (naming the folders) | each named file becomes `Approved`; the next step is `workflow-implementation` (`H7`, `H8`) |
| change one | re-draft that feature and every bundle that consumes from it |
| reject | stays `Draft`; the reason goes under its Open gaps |

Silence approves nothing (`SDD-CORE-03`).

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | no repo search repeated what the evidence file already held | `H4` |
| 2 | every folder has the files its mode requires, each answering only its question | `SDD-SPEC-02`, `SDD-SPEC-09` |
| 3 | every traced `AC-*` has a check, tagged with a lane, and **Met when** names it | `SDD-SPEC-05`, `SDD-SPEC-06` |
| 4 | every lane with a check is `small` or `large` in the lane map; every lane without one is `none` | — |
| 5 | Surface, Size and base are in `contract.md`; the feature fits the budget or went back as a gap | `SDD-SPEC-04` |
| 6 | no file of a merged feature was edited; a change is a new item | `SDD-SPEC-08` |
| 7 | every file is `Draft` until the owner answered | `SDD-CORE-03` |

## Example

PRD approved; F03 invitations consumes `requireRole` from F01 and `sendEmail` from F02. Step 2: the evidence file has "members are inserted only by `POST /members` — src/members/route.ts:22"; nothing is missing. Step 3: `spec-writer` writes `story.md` with "As an admin, I invite a teammate by email" and `AC-01`–`AC-03`; `contract.md` with C1–C4, lanes `backend: large` (estimated 180 lines), `frontend: small`, `qa: small`, the rest `none`. The repetition edge of `AC-03` becomes "C4 (AC-03) re-inviting E returns the same invitation and resends once · integration · backend". Step 5: one message; the owner approves.

**Anti-pattern.** Splitting F03 into "F03 backend" and "F03 frontend" bundles. Corrected: one bundle, one contract; the split is in the lane map, and a feature too big for one review is split in the PRD by acceptance criterion.
