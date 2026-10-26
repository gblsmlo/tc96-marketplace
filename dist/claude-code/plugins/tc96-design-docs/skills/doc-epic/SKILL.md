---
name: doc-epic
description: Writes an epic — a capability that spans several features or releases — from what the team already decided — who uses it, the problem it solves, the epic hypothesis with its leading indicators, what a person can do once it is ready, what is out of it, and its children — as a tracker-ready body or a file, with every missing fact marked as a gap. Use whenever someone asks to write, draft or rewrite an epic, "open an epic for X", turn a PRD theme or roadmap item into an epic, or describe a large capability for the board, in any tracker (GitHub, Linear, Jira, ClickUp). A writer only — it does not prioritize, size or research. Not for one shippable slice (doc-feature), a user story (doc-story), or the product's full requirements (doc-prd).
source: "[Template: Epic](references/template.md)"
model: haiku
effort: medium
tags:
  - skill
  - design-docs
  - epic
---

# doc-epic

> **A writer.** It follows the [writing contract](../../docs/design-docs/writing-contract.md): it reads the request, the files the request names and `references/template.md` — nothing else (`DD-CORE-01`, `DD-CORE-02`).

## Scope

An epic answers one question: **which capability are we building, for whom, and how will we know it paid off?** It is the parent level: it closes when its children close, and it never carries implementation detail.

| The request is... | Go to |
| --- | --- |
| one slice that ships alone, with a benefit and acceptance | `doc-feature` |
| one user-facing behavior with Given / When / Then | `doc-story` |
| the whole product's problem, stories, features and waves | `doc-prd` |

**Anchor:** the capability, and who uses it (`DD-CORE-06`).

## Step 1: Sort the input

Sort the input into the template's slots: users and what they do, the problem and its evidence, the expected outcome and how it is measured, the capabilities listed, the exclusions, the children (features or stories already named, with their IDs). A slot the input leaves empty is a gap or, for an optional section, deleted.

## Step 2: Write

Copy the template from "Body" down.

| # | Rule | Why |
| --- | --- | --- |
| 1 | Title `EPIC-<slug> · <capability name>`; the slug is the capability in kebab-case | children and PRs cite it by ID |
| 2 | The problem is in the user's words: no screen, table or component name | an epic outlives any one implementation |
| 3 | The hypothesis is "If we deliver …, then … will …, measured by … within …"; a measure or a window the input lacks is a gap, never a number you pick | an epic with no measure cannot be judged done or wrong (`DD-CORE-03`) |
| 4 | "What a person can do" lists one verb-first line per capability the input names; a child the input does not name is not invented | each line becomes a feature or story later |
| 5 | Out of this epic holds what the input excluded; a neighboring capability you excluded to keep scope clear is `(proposed)` | the owner sees your reading (`DD-CORE-04`) |
| 6 | Children: the IDs the input gives; otherwise "none yet" | IDs are cited, never invented |
| 7 | No status field: the tracker owns it | §4 of the contract |

## Step 3: Self-check

| # | Check |
| --- | --- |
| 1 | every section of the template is present or deliberately deleted (optional ones only) |
| 2 | no target, metric, date or child ID appears that the input did not give |
| 3 | the problem section names no screen, table, endpoint or component |
| 4 | every gap is inline and again under Open questions, with who decides |
| 5 | no bracketed hint survived |

## Step 4: Return

The return block of the [writing contract](../../docs/design-docs/writing-contract.md) §5 — outcome (`complete`, `partial` or `blocked`), path or "inline", status, one sentence, then every gap and `(proposed)` item. With no path named, the body goes inline, ready to paste into the tracker.

## Example

*"Epic for online quote approval: customers approve quotes without email, sales stops chasing. We'd call it a win if median approval time drops. Excludes partial approval and e-signature."* Title `EPIC-quote-approval · Online quote approval`. Users: customers who receive quotes; sales reps who send them. Hypothesis: "If customers can approve quotes online, then median approval time will drop, measured by time from send to approval, within `[GAP: by how much, and by when? — decides: owner]`." Capabilities: open a quote from a link; approve or reject it; notify sales on approval. Out: partial approval, e-signature. Children: none yet. Outcome `partial`, one gap.
