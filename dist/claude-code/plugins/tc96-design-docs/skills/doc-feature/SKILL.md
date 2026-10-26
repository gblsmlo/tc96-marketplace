---
name: doc-feature
description: Writes a feature — the smallest slice that ships and can be proved alone — from what was already decided — what it delivers, its benefit hypothesis, acceptance criteria in Given/When/Then, what it provides to and consumes from other features, what is out of it, and its dependencies — as a tracker-ready body or a file, marking every missing fact as a gap. Use whenever someone asks to write or rewrite a feature, a feature brief or a feature card, to break an epic's line into a feature, or to turn a PRD row (F01, F02…) into a standalone item for the board or for an implementer. A writer only — it does not size, prioritize or design the solution. Not for the capability above it (doc-epic), a single user story (doc-story), the technical design (doc-spec), or the implementation steps (doc-tasks).
source: "[Template: Feature](references/template.md)"
model: haiku
effort: medium
tags:
  - skill
  - design-docs
  - feature
---

# doc-feature

> **A writer.** It follows the [writing contract](../../docs/design-docs/writing-contract.md): it reads the request, the files the request names (a PRD, an epic) and `references/template.md` — nothing else (`DD-CORE-01`, `DD-CORE-02`).

## Scope

A feature answers one question: **what slice ships next, what does it deliver, and how do we know it works?** It sits between the epic (the capability) and its stories or tasks, and it fits one release and one review.

| The request is... | Go to |
| --- | --- |
| the capability that groups several features | `doc-epic` |
| one user-facing behavior, written as a story | `doc-story` |
| the shapes, interfaces and design of the feature | `doc-spec` |
| the ordered steps to build it | `doc-tasks` |

**Anchor:** what it delivers, and the benefit expected (`DD-CORE-06`).

## Step 1: Sort the input

From a PRD row, copy what the PRD already says — `F<NN>`, the `AC-*` it satisfies, provides, consumes — and cite it instead of rewording it. From free input, sort into: what it delivers, who benefits and how, the stated behaviors, the dependencies, the exclusions.

## Step 2: Write

Copy the template from "Body" down.

| # | Rule | Why |
| --- | --- | --- |
| 1 | Title is verb-first and names the outcome; when the input gives an ID (`F02`), it leads the title | the board and the PR cite it |
| 2 | Benefit hypothesis: "We believe [this feature] will [outcome] for [who]; we will know when [measure]"; a measure the input lacks is a gap | a feature with no measurable benefit cannot be judged |
| 3 | Acceptance criteria are Given / When / Then with an observable outcome, one per stated behavior; reuse the PRD's `AC-NN` IDs when they exist, else number `AC-1`… locally | each becomes a check (`DD-CORE-03`) |
| 4 | Provides and consumes are in product words, and each consumed item names its provider; when the input states no dependency, write `none` | a consumer without a provider cannot be scheduled |
| 5 | A behavior you split out to keep the slice small is `(proposed)` under Out of this feature | the owner sees your cut (`DD-CORE-04`) |
| 6 | No schema, endpoint, file or component name: that is `doc-spec` | a feature describes behavior, not design |
| 7 | No status field: the tracker owns it | §4 of the contract |

## Step 3: Self-check

| # | Check |
| --- | --- |
| 1 | every criterion has an ID and an observable outcome |
| 2 | every consumed item names one provider, or dependencies say `none` |
| 3 | no metric, target, ID or dependency appears that the input did not give |
| 4 | no technical design leaked in |
| 5 | every gap is inline and again under Open questions, with who decides; no bracketed hint survived |

## Step 4: Return

The return block of the [writing contract](../../docs/design-docs/writing-contract.md) §5 — outcome (`complete`, `partial` or `blocked`), path or "inline", status, one sentence, then every gap and `(proposed)` item. With no path named, the body goes inline.

## Example

*"Turn F02 from the PRD into a feature card."* The PRD says `F02` approval satisfies `AC-01`–`AC-03`, consumes "a signed link to one quote" (F01), provides "approved quote event". Title: `F02 · Customers approve or reject a quote from its link`. Benefit: "We believe online approval will shorten approval time for customers; we will know when median time from send to approval drops" — the PRD's `OBJ-1` gives the measure, so no gap. Criteria: `AC-01`–`AC-03`, copied by ID with their text. Consumes: the link (F01). Provides: the event. Outcome `complete`.
