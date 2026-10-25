---
name: spec-story
description: Writes a Story — the acceptance unit of a backlog — as "As a role, I want an action, so that an outcome" with three to eight Given/When/Then scenarios a test can execute (main path, a refusal, who cannot do it, what changes when data changes), a done-when, and a parent Epic, in a tool-neutral body for any tracker. Use whenever someone asks to write, refine or split a user story, acceptance criteria, acceptance scenarios, Given/When/Then, a definition of ready, or to turn an Epic or PRD line into something a developer can be held to. Not for the capability itself (spec-epic), the executable cut (spec-task), or the full PRD (spec-prd).
type: skill
family: spec
language: en
source: "[Rules of the Story](references/rules.md)"
tags:
  - skill
  - spec
  - story
---

# spec-story

> **Self-contained.** The template is `references/template.md`; the rules and the edge sweep are `references/rules.md`. Nothing here needs another skill to run.
> Owner role: `project-manager` writes the content, with the PRD's wording as source. When this skill runs in an orchestrating conversation, start that agent with the template path and keep only the item's text and open gaps in the conversation.

## Scope

A Story answers one question: **what can a role do, and how will we know it works?** It is the acceptance unit: a Story without a written, checkable criterion is not ready.

| The question is... | Go to |
| --- | --- |
| the permanent capability it belongs to | `spec-epic` |
| the executable cut that delivers part of it | `spec-task` |
| goals, metrics, non-goals around it | `spec-prd` |

## Step 1: Confirm it is a Story

1. Read the project's record of kept documents if one exists (`## Specs` in `AGENTS.md`, else `.specs/README.md`). Board items off: do not publish the item; the scenarios still live in the PRD.
2. Find the parent Epic and inherit its `capability`. No parent: stop and link one, or ask the owner; an orphan is a divergence to resolve, never a case to guess at.
3. Confirm it is one role, one action, one outcome. Two actions are two Stories.

## Step 2: Write

Copy the template from "Body" down into the tracker item. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | Title: `<what this delivers, verb-first> [STORY-<capability>-NNN]` | stable reference |
| 2 | Three to eight scenarios: the main path, a refusal, who cannot do it, what changes when the data changes | coverage of the cases that break |
| 3 | A scenario describes a starting situation reachable in a real environment and an observable result; it never restates the rule's text | a scenario a test can execute |
| 4 | Run each scenario through the seven edge categories (`references/rules.md`); each edge that applies becomes a scenario, is declared out, or is an open gap | the question that stops a developer mid-code is the edge |
| 5 | "Done when" requires an executable, green, reviewed test with the run linked; no scenario is accepted by hand-checking | proportional evidence for a Story means the scenarios, executed |
| 6 | No automation closes the Story just because its Tasks closed; the scenarios are the gate | Tasks can all close and the behavior still be wrong |
| 7 | Delete every bracketed hint | a hint left in is an unmade decision |

## Step 3: Put it in front of the owner

Show the owner the text before publishing it: the parent, the one-sentence story, the scenarios, the open gaps and "publish, change, or reject?". Publishing is outward-facing: it needs the owner's explicit yes. Silence is not approval.

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | it has a parent Epic and inherits `capability` | `SPEC-STORY-01` |
| 2 | 3 to 8 scenarios, each executable | `SPEC-STORY-02` |
| 3 | main path, refusal, who cannot, data change covered | Step 2, rule 2 |
| 4 | applicable edges have a destination | `SPEC-STORY-04` |
| 5 | "Done when" demands an executable test | `SPEC-STORY-03` |
| 6 | no bracketed hint survived | Step 2, rule 7 |

## Step 5: Return

Report the item text (or its tracker id once published), the parent and any gap. When a workflow pillar called this skill, return the pillar's envelope: path or id in `artefato`.

## Example

*Epic: quote approval.* `Approve a quote online [STORY-quote-approval-001]`. As a customer, I want to approve a quote from its link, so that I do not wait for the rep. Scenarios: (1) Given a valid quote, when the customer approves, then they see a confirmation with a reference number. (2) Given an expired quote, when they try to approve, then they see the expiry date and "Request a new quote", and nothing is approved. (3) Given a visitor with no link token, when they open the page, then they see "Quote not found". (4) Given the customer approves twice, when the second request lands, then the quote stays approved once. Edge "expires at midnight in which time zone?" had no answer, so it is an open gap decided by the owner.
