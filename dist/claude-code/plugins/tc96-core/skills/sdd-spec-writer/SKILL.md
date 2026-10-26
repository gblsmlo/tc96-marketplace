---
name: sdd-spec-writer
description: Turns features of an approved PRD into their bundles — `spec.md` (what the feature exposes and consumes, UX as a section when needed), `plan.md` (steps, Surface, Size, local scripts when needed) and `contract.md` (one check per acceptance criterion; met only when it proves every criterion it traces was met) — after a repo search, as `Draft` files the owner approves in one message, citing `SDD-SPEC-*` IDs. Also writes the new item that replaces a feature whose contract failed twice or that hit a gap, and the fast-lane bundle for a fix or refactor. Use when a PRD feature has no approved bundle, when the orchestrator reports a feature as split or blocked on a gap, or when someone asks to spec a fix. Not for the PRD itself (doc-prd), a lasting technical decision (doc-adr), nor running the features (sdd-orchestrator).
source: "[Delivery Flow — Spec Driven Development](../../referencias/fluxo-de-entrega-sdd.md)"
tags:
  - skill
  - sdd
  - spec
---

# sdd-spec-writer

> **Delegation (`SDD-CORE-02`).** This skill runs in the orchestrating conversation and writes nothing itself. The repo search goes to `repo-explorer`; each bundle goes to `spec-writer`; a lasting decision goes to `software-architect` through `doc-adr`. Each is called by name, as a subagent, so it runs on its own tier. Keep only paths, statuses and open gaps in this conversation (`SDD-CORE-04`).

Contract this skill implements: [Delivery Flow — Spec Driven Development](../../referencias/fluxo-de-entrega-sdd.md) §4.3–§4.5 and `SDD-SPEC-*`.

## Scope

| The request is... | Mode | Go to |
| --- | --- | --- |
| features of the approved PRD with no approved bundle | **bundle** | this skill |
| a feature the orchestrator marked `split`, or blocked on a gap | **new item** | this skill |
| a fix or refactor that changes no product behavior | **fast lane** | this skill |
| a new feature, or a change to what the product promises | — | `doc-prd`, as an amendment, first |
| a technical decision that outlives the feature | — | `doc-adr`, called from Step 4 |
| running an approved bundle | — | `sdd-orchestrator` |

## Step 1: Pick what to write

1. Read only the status line of `.specs/PRD.md` and of its last amendment. Not `Approved` → stop: bundles start from an approved PRD (`SDD-CORE-01`). The fast lane does not need an amendment, but it needs an approved PRD to trace to.
2. Build the list:

| Mode | Write bundles for | ID and folder |
| --- | --- | --- |
| bundle | every feature of the requested waves with no approved folder in `.specs/features/`; with no wave named, every such feature, in wave order | `.specs/features/F<NN>-<slug>/`, the `F` number from the PRD |
| new item | the one feature the orchestrator named | `.specs/features/F<NN>.<n>-<slug>/`, the next free `.n` |
| fast lane | the fix or refactor requested | `.specs/features/F<NN>.<n>-<slug>/`, under the feature it changes |

3. Order the list by wave. A consumer's bundle is written after its provider's draft exists, so it codes against the provider's `spec.md`, not a guess.

## Step 2: Repo search, before writing (`SDD-SPEC-01`)

For each feature, start `repo-explorer` with one bounded question. Features of the same wave go out side by side; they only read.

```
Feature <ID> provides <items> and consumes <items> (from <providers>).
Its likely Surface: <paths from the PRD's wording, or "unknown">.
Return, with file:line: what already exists for each provided item; every caller of anything
it would change; the tests around it; the conventions of that layer (naming, folder, error
shape). Facts only, at most 30 lines.
```

For a new item, the question is about the failing branch: what the branch already has for each failing check. For the fast lane, about the defect: where it happens and what calls it.

## Step 3: Write each bundle

Start `spec-writer` once per feature, in list order, with:

| Input | Mode |
| --- | --- |
| the PRD path and the feature's `F` number | all |
| the repo-search facts from Step 2 | all |
| the paths of the providers' `spec.md` | bundle, new item |
| the three template paths: `references/template-spec.md`, `references/template-plan.md`, `references/template-contract.md` | all |
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

`spec-writer` returns per feature: the folder path, one sentence, its open gaps, and any decision it flagged as outliving the feature.

## Step 4: Lasting decisions

For each decision `spec-writer` flagged as outliving the feature, start `software-architect` with `doc-adr`. The ADR is born `Proposed` and goes into the same owner message as the bundle; the `spec.md` that depends on it cites `ADR-NNNN`.

## Step 5: One message to the owner

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

Silence approves nothing (`SDD-CORE-03`). An Out of Scope line or a gap that changes what the product promises is not answered here: it goes to `doc-prd` as an amendment.

## Step 6: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | a repo search ran for every feature before its bundle | `SDD-SPEC-01` |
| 2 | every folder has the files its mode requires, each answering only its question | `SDD-SPEC-02`, `SDD-SPEC-09` |
| 3 | every `AC-*` the feature traces has a check, and **Met when** names them | `SDD-SPEC-05`, `SDD-SPEC-06` |
| 4 | the non-functional gates are listed; `risk: security` adds the security gate | `SDD-SPEC-05` |
| 5 | every bundle fits the review budget, or went back as a gap | `SDD-SPEC-04` |
| 6 | no file of a merged feature was edited; a change is a new item | `SDD-SPEC-08` |
| 7 | every file is `Draft` until the owner answered | `SDD-CORE-03` |
| 8 | this conversation holds paths, sentences and gaps, not file content | `SDD-CORE-04` |

## Step 7: Return

The folder paths, their statuses, and the open gaps with who decides each. When every bundle of a wave is approved, the next step is `sdd-orchestrator`.

## Example

PRD `Approved`; no folders yet. Waves: `W0` F01 quote link, `W1` F02 approval. Step 2: two `repo-explorer` calls in parallel; F02's comes back with "quotes table has no status column — src/db/schema.ts:40" and "the only reader of quotes is GET /quotes/:id — src/server/quotes.route.ts:12". Step 3: `spec-writer` writes F01, then F02 against F01's `spec.md`. F02's contract traces `AC-01`–`AC-05`; the time edge of `AC-05` becomes "C5 (AC-05) approving at 23:59 on day 30 in the seller's time zone succeeds, at 00:00 on day 31 returns 410 · unit"; risk `security`, because the link grants access without a session, so G3 is listed. `spec-writer` flags "approval links are signed, not stored" as lasting: Step 4 writes ADR 0004, `Proposed`. Step 5: one message with both folders and the ADR. The owner answers "approve F01, F02 and ADR 0004".
