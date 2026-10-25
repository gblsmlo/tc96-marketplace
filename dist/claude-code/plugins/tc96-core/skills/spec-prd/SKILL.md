---
name: spec-prd
description: Writes a capability's PRD (product requirements document) — the problem, what is known versus assumed, goals with metrics, non-goals, stories with acceptance scenarios and open gaps — as a `Draft` the owner approves, then freezes it and takes later changes as dated amendments, citing `DOC-PRD-*` IDs. Use whenever someone asks to write, draft, revise or amend a PRD, product spec, requirements doc or `requirements.md`, to define what to build and why before any design or code, or to turn a vague "we should build X" into goals, non-goals and testable scenarios. Not for how to build it (spec-rfc, spec-adr), screens and states (spec-ux), or breaking work into Epics, Stories and Tasks (spec-epic, spec-story, spec-task).
source: "[Rules of the PRD](references/rules.md)"
tags:
  - skill
  - spec
  - prd
---

# spec-prd

> **Self-contained.** The template is `references/template.md`; the rule text and the status lifecycle are `references/rules.md`. Nothing here needs another skill to run.
> Owner role: `product-manager` writes the content. When this skill runs in an orchestrating conversation, start that agent with the template path and the writing rules below, and keep only its path and open gaps in the conversation.

## Scope

A PRD answers one question: **what are we building, and why?** It is born `Draft` and becomes `Approved` only on the owner's explicit answer.

| The question is... | Go to |
| --- | --- |
| how to build it: boundaries, contracts, schema | `spec-rfc`, `spec-adr` |
| how the person moves through it, every screen state | `spec-ux` |
| the capability as a tracker item | `spec-epic` |
| one story's acceptance scenarios, outside a PRD | `spec-story` |
| who implements what, in what order | `spec-task` |
| whether a document is needed at all | `DOC-CORE-02` in `references/rules.md`: no real trade-off, no document |

## Step 1: Confirm the question is open

1. Read the project's record of kept documents if one exists (a `## Specs` section in `AGENTS.md`, else `.specs/README.md`). PRD marked off: do not write the file; state the decision in one line and stop.
2. Pick the folder: `.specs/<capability>/requirements.md`. The slug is the Epic's `capability`, or the one the owner confirms. A second increment in the same capability reuses the folder.
3. Read only the status line of the file, if it exists:

| The file... | Write |
| --- | --- |
| does not exist | the file, from `references/template.md` |
| is `Draft` or `In review` | a revision of that draft |
| is `Approved` | a dated amendment at the end; the approved text is never rewritten (`DOC-PRD-04`) |

## Step 2: Write

Copy the template from "Body" down. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | Delete every bracketed hint; fill every field or write `none` | a field left as a hint is an unmade decision |
| 2 | One sentence, one claim; every fact about users cites a source (data, interview, ticket, `file:line`) | an unsourced claim is a hypothesis (`WF-RES-04`) |
| 3 | Separate fact, hypothesis, decision and gap, one row each | mixing them hides what is still a guess |
| 4 | Every goal has a metric; every story has Given/When/Then scenarios | a goal with no measure is a wish (`DOC-PRD-02`) |
| 5 | Sweep each rule and scenario through the seven edge categories (`references/rules.md`, "Edge sweep"); each edge that applies becomes a scenario, a non-goal or an open gap | the question that stops a developer mid-code is the rule's edge |
| 6 | No schema, API contract or service boundary | that is design, not product (`DOC-PRD-03`) |
| 7 | A question you cannot answer goes under **Open gaps** with who decides it and when it must close | never chosen silently |
| 8 | `status: Draft`; the writer never approves its own file | `WF-SPEC-06` |

## Step 3: Put it in front of the owner

One message, four parts, then stop: the path; the one-sentence problem; the open gaps, verbatim; "approve, change, or reject?" Not the file's content and not a summary of it: the owner reads the file.

| The owner says | Result |
| --- | --- |
| approve | `Draft` or `In review` becomes `Approved`; the file is frozen |
| change | revise from the owner's words; the status does not move |
| reject | stays `Draft`; record why under Open gaps |

Silence is not approval. On an amendment, the status that moves is the amendment's, never the file's first one. Moving a status is one field edit: make it directly.

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | the file answers only the PRD question | `DOC-CORE-01` |
| 2 | a PRD was warranted by a real trade-off | `DOC-CORE-02` |
| 3 | non-goals are written, not implied | `DOC-PRD-01` |
| 4 | every goal has a metric, every story scenarios | `DOC-PRD-02` |
| 5 | no technical design leaked in | `DOC-PRD-03` |
| 6 | every claim has a source | `WF-RES-04` |
| 7 | every applicable edge has a destination | `references/rules.md`, "Edge sweep" |
| 8 | no bracketed hint survived | Step 2, rule 1 |
| 9 | status is `Draft` until the owner answered | `WF-SPEC-06` |

## Step 5: Return

Report the path, the status, the one-sentence problem and every open gap with who decides it. When a workflow pillar called this skill, return the pillar's envelope instead: path in `artefato`, status in `resultado`, each gap in `lacunas` with `decide` and `fecha-em`.

## Example

*"We want customers to approve quotes online."* Question open: yes, what and why are undecided. Step 1: `.specs/quote-approval/requirements.md` does not exist. Step 2: the writer states the problem with the support-ticket count as source, sets one goal with a metric ("approval time from 3 days to 1"), lists "price negotiation" as a non-goal, and writes three stories. The expiry edge ("valid until when, in which time zone?") has no answer, so it goes to Open gaps with `decides: owner`. Step 3: the owner replies "approve"; the status becomes `Approved`. A month later "quotes may now be partially approved" arrives: it is appended as `## Amendment 001 — 2026-11-02 — partial approval`, born `Draft`.
