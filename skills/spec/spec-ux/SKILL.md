---
name: spec-ux
description: Writes a capability's user-experience contract — persona and journey, flow, every screen in all four states (loading, empty, success, failure), usability checks and accessibility with exact roles and accessible names — as a `draft` the owner accepts, so frontend work and tests can start from it. Use whenever someone asks to write, draft or review a UX spec, user flow, journey, screen states, wireframe description, accessibility spec or `user-experience.md`, or asks "how should this work for the user" before any component is built. Not for deciding what to build (spec-prd), technical boundaries (spec-rfc), or how the React code is structured (the implementer decides while executing the Task).
type: skill
family: spec
language: en
source: "[Rules of the UX contract](references/rules.md)"
tags:
  - skill
  - spec
  - ux
---

# spec-ux

> **Self-contained.** The template is `references/template.md`; the rules and the status lifecycle are `references/rules.md`. Nothing here needs another skill to run.
> Owner role: `product-designer` writes the content. When this skill runs in an orchestrating conversation, start that agent with the template path and the writing rules below, and keep only its path and open gaps in the conversation.

## Scope

A UX file answers one question: **how does the person move through this capability, and what does each screen show in every state?** It is the experience contract that frontend work and tests cite.

| The question is... | Go to |
| --- | --- |
| whether to build it, priority, acceptance scenarios | `spec-prd`, `spec-story` |
| boundaries (BFF versus backend, feature), contracts, schemas | `spec-rfc` |
| where the code lives, who owns each piece of state, which React API | decided by the implementer, not written here |
| the level of each test | not written here |

## Step 1: Confirm the question is open

1. Read the project's record of kept documents if one exists (`## Specs` in `AGENTS.md`, else `.specs/README.md`). UX marked off: do not write the file; state the decision in one line and stop.
2. The file is `.specs/<capability>/user-experience.md`. List the stories it covers by ID; a UX file with no story behind it has no reason to exist.
3. Read only its status line:

| The file... | Write |
| --- | --- |
| does not exist | the file, from `references/template.md` |
| is `draft` or `reviewed` | a revision of that draft |
| is `accepted` | a dated amendment at the end; accepted text is never rewritten |

## Step 2: Write

Copy the template from "Body" down. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | Delete every bracketed hint; fill every field or write `none` | a field left as a hint is an unmade decision |
| 2 | Every claim about the user cites a source (data, interview, ticket); an unsourced claim is listed as "Not validated with a user" | `SPEC-UX-01` |
| 3 | Every screen has all four states: loading, empty, success, failure with what to do next | `SPEC-UX-02` |
| 4 | Every expected failure has a recovery path; every destructive action says confirm or undo | `SPEC-UX-03` |
| 5 | Every control in the flow is in the accessibility table with its role and exact accessible name | the table is the contract tests locate by (`SPEC-UX-04`) |
| 6 | Say what lives in the URL (filter, tab, page) so reload and shared links keep state | `SPEC-UX-05` |
| 7 | Place each component by vocabulary, not by how many consumers it has | `SPEC-UX-06` |
| 8 | No code structure, no schema, no test level | out of this file |
| 9 | `status: draft`; the writer never accepts its own file | `WF-SPEC-06` |

## Step 3: Put it in front of the owner

One message, four parts, then stop: the path; the one-sentence problem the experience solves; the open gaps and unvalidated assumptions, verbatim; "approve, change, or reject?"

| The owner says | Result |
| --- | --- |
| approve | `draft` or `reviewed` becomes `accepted`; frontend work may start |
| change | revise from the owner's words; the status does not move |
| reject | stays `draft` |

Silence is not approval. Frontend work does not start on a `draft`.

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | every screen has all four states | `SPEC-UX-02` |
| 2 | every expected failure has a recovery path | `SPEC-UX-03` |
| 3 | every control has role and accessible name | `SPEC-UX-04` |
| 4 | every user claim has a source or is listed as unvalidated | `SPEC-UX-01` |
| 5 | URL state is stated | `SPEC-UX-05` |
| 6 | nothing about code structure leaked in | Step 2, rule 8 |
| 7 | no bracketed hint survived | Step 2, rule 1 |
| 8 | status is `draft` until the owner answered | `WF-SPEC-06` |

## Step 5: Return

Report the path, the status and every open gap with who decides it. When a workflow pillar called this skill, return the pillar's envelope: path in `artefato`, status in `resultado`, each gap in `lacunas`.

## Example

*Stories: approve a quote online.* The approval screen gets: loading (skeleton of the line items), empty (not possible, the screen requires a quote; says so), success (confirmation with a reference number), failure (expired quote: explains it expired on the date and offers "Request a new quote"). Accessibility table: `button` named "Approve quote", `link` named "Download PDF". The filter "status" lives in the URL. "Customers prefer one-click approval" has no source, so it lands under "Not validated with a user" with a test plan.
