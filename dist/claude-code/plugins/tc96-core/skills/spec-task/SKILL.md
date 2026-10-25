---
name: spec-task
description: Writes a Task — the executable cut an implementer reads, with scope, surface (files touched), size, risk class, acceptance, evidence, test types and why it ships alone safely — and the increment plan that orders Tasks into dependency waves with a review budget and delivery mode, as `tasks/NNNN-<slug>.md` a `Draft` the owner marks `Ready`. Use whenever someone asks to write, split or re-slice a Task or ticket, to plan an increment, break a Story into work items, order work into waves, size work for review, name owners and evidence, or says a unit is too big to review. Not for the capability (spec-epic), acceptance scenarios (spec-story), or deciding what to build (spec-prd).
source: "[Rules of the Task and the plan](references/rules.md)"
tags:
  - skill
  - spec
  - task
---

# spec-task

> **Self-contained.** The Task template is `references/template-task.md`, the plan template is `references/template-plan.md`, and the rules, review budget and wave rule are `references/rules.md`. Nothing here needs another skill to run.
> Owner role: `project-manager` writes the content. When this skill runs in an orchestrating conversation, start that agent with the templates' paths and keep only the plan's path and open gaps in the conversation.

## Scope

Two artifacts, one decision: **what is the smallest unit someone can implement and prove alone, and in what order do the units run?**

| Artifact | File | Holds |
| --- | --- | --- |
| Task | an item in the tracker, or a section of the plan | the executable cut (`template-task.md`) |
| Plan | `.specs/<capability>/tasks/NNNN-<slug>.md` | one increment's Tasks, inputs, waves and delivery (`template-plan.md`) |

| The question is... | Go to |
| --- | --- |
| why and what, goals, non-goals | `spec-prd` |
| the acceptance scenarios a Task enables | `spec-story` |
| boundaries and contracts the Tasks implement | `spec-rfc`, `spec-adr` |
| screens and states a frontend Task cites | `spec-ux` |

## Step 1: Confirm the unit is ready to plan

1. Read the project's record of kept documents if one exists (`## Specs` in `AGENTS.md`, else `.specs/README.md`). The plan is always kept; board items may be off. The record may also hold the project's review budget and wave width; use them in place of the defaults.
2. Confirm the inputs exist and their status: PRD `Approved`, design `Accepted`, UX `accepted`, ADRs `Accepted`, as the increment needs. A Task that cites an input not yet accepted waits; the others start (`WF-SPEC-04`).
3. Confirm no open gap blocks a Task's acceptance. A Task never carries an open product question.
4. Number the plan: highest number in `.specs/<capability>/tasks/` plus one, four digits, slug the increment in kebab-case (`0002-approval-expiry.md`). A new increment gets a new plan; a `Ready` plan is never extended.

## Step 2: Pass the four gates, then write

| Gate | Question |
| --- | --- |
| Product | is there approved behavior behind this change? If not, it returns to the PRD |
| Decomposition | does each unit have its own acceptance, evidence and dependency? Split only along those lines; a unit above the review budget is re-sliced by acceptance scenario or by expand-migrate-contract step, never by layer or file |
| Boundary | which owner (frontend, backend, devops-security) owns the unit? "Fullstack" is never an answer |
| Acceptance | acceptance criteria written, one line per edge the PRD answered; an open gap the unit depends on makes it wait |

Copy `references/template-task.md` per Task and `references/template-plan.md` for the plan. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | Name Surface (files touched) and Size (changed lines, tests included, review families) on every Task | two Tasks run side by side only when their Surfaces share no file |
| 2 | Fit the review budget: by default at most 300 changed lines, two review families, one owner | a review is as long as the diff it reads and repeats each fix round |
| 3 | A contract two units share lands first as its own Task: the schema or type and its validator, nothing else | building both sides on an unlanded contract drifts the shapes |
| 4 | Name each Task's test types at the cheapest level that catches the defect; integration or E2E adds the sentence of what only it catches | the cost repeats on every fix round |
| 5 | Assign the risk class: `contract` (alters a public contract), `security` (auth or sensitive data) or `focused` | validation reads it instead of deciding again |
| 6 | Group Tasks into waves by dependency: wave 0 holds contract Tasks and Tasks with no dependency | waves are how the plan reads |
| 7 | Write "Ships alone safely because" for every Task | each PR merges on its own |
| 8 | Delete every bracketed hint; `status: Draft`; the writer never marks it `Ready` | `WF-SPEC-06` |

## Step 3: Put it in front of the owner

One message, four parts, then stop: the plan's path; the one-sentence goal of the increment; the open gaps, verbatim; "approve, change, or reject?". Include whether to publish board items, the delivery mode and whether push and PR are authorized.

| The owner says | Result |
| --- | --- |
| approve | `Draft` becomes `Ready`; each Task starts once its own inputs are accepted |
| change | revise from the owner's words; the status does not move |
| reject | stays `Draft` |

Silence is not approval. Authorization to push and PR covers this plan only and never covers merging.

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | every Task has one owner, dependencies and inputs | `WF-PLAN-05` |
| 2 | every Task has written acceptance and an evidence plan | `WF-PLAN-04` |
| 3 | test types are at the cheapest level, with a risk class | `WF-PLAN-06` |
| 4 | every Task has wave, Surface, Size and fits the budget | `WF-PLAN-07` |
| 5 | no two side-by-side Tasks share a file in Surface, except a landed contract | `WF-PLAN-08` |
| 6 | decomposition follows acceptance, evidence and dependency | `WF-PLAN-03` |
| 7 | every input is accepted or its Task waits | `WF-SPEC-04` |
| 8 | Delivery names the mode and the authorization, or says "ask per wave" | `template-plan.md` |
| 9 | no bracketed hint survived; status is `Draft` | Step 2, rule 8 |

## Step 5: Return

Report the plan's path, its status and every open gap with who decides it. When a workflow pillar called this skill, return the pillar's envelope: path in `artefato`, status in `resultado`, each gap in `lacunas`.

## Example

*Increment: approval expiry.* Plan `0002-approval-expiry.md`. T1 (wave 0, backend): the `expiresAt` field and its validator only; Surface two files, Size 60 lines, risk `contract`, test type contract. T2 (wave 1, backend): reject expired approval; depends on T1; unit test plus one `curl`. T3 (wave 1, frontend): the expired-state screen; depends on T1; cites the UX file; component test. T2 and T3 run side by side because their Surfaces share no file. The owner replies "approve, push and PR authorized, per task"; the plan becomes `Ready`.
