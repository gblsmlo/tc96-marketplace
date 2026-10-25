---
name: spec-epic
description: Writes an Epic — the permanent capability level of a backlog — stating who it is for, the problem it solves, what a person can do once it is ready, what is explicitly out, and how it is accepted, in a tool-neutral body that fits any tracker (GitHub Issues, Linear, Multica). Use whenever someone asks to write, create, split off or rewrite an Epic, to turn a PRD or capability idea into the top-level backlog item, to define a capability's scope for a tracker, or when a Story has no parent and needs one. Not for the PRD itself (spec-prd), for a single acceptance unit (spec-story), or for an executable work item (spec-task).
source: "[Rules of the Epic](references/rules.md)"
tags:
  - skill
  - spec
  - epic
---

# spec-epic

> **Self-contained.** The template is `references/template.md`; the rules and the hierarchy are `references/rules.md`. Nothing here needs another skill to run.
> Owner role: `project-manager` writes the content. When this skill runs in an orchestrating conversation, start that agent with the template path and keep only the item's text and open gaps in the conversation.

## Scope

An Epic answers one question: **what permanent capability does this backlog item represent?** It is the top of the hierarchy (Epic, Story, Task). Milestone has no template: it is a roadmap-block property on Epic, Story and Task. The Epic does not close on delivery; it closes when every child Story closes, and reopens when its governing rule set gains a new rule.

| The question is... | Go to |
| --- | --- |
| why and what, with goals and non-goals | `spec-prd` (an Epic is typically the resolved output of one) |
| what a role can do, with scenarios a test can run | `spec-story` |
| the executable cut an implementer reads | `spec-task` |

## Step 1: Confirm the capability is real

1. Read the project's record of kept documents if one exists (`## Specs` in `AGENTS.md`, else `.specs/README.md`). Board items off: do not write the item; state the decision in one line and stop.
2. Pick the `capability` slug: kebab-case, stable, the value every child groups by. A capability that already has an Epic gets no second one; update the existing item.
3. Confirm the Epic is capability-level. If it names a screen, table or component, it is a Story or Task.

## Step 2: Write

Copy the template from "Body" down into the tracker item. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | Title: `EPIC-<capability> · <capability name>` | one grep finds the whole tree |
| 2 | Describe the problem at capability level: what goes wrong today without it. No screen, table or component names | implementation detail belongs to Stories and Tasks |
| 3 | "What a person can do" has one verb-first line per Story or group of Stories; a line with no Story behind it is a gap | the review checks the list against the children |
| 4 | "Out of this Epic" names what someone might expect and is another capability | scope creep starts as an unspoken expectation |
| 5 | Acceptance is the children's: every Story's scenarios pass, with evidence linked. No separate acceptance round for the Epic itself | business acceptance of the whole capability is a later, separate step |
| 6 | Cite the PRD or decision record that authorized the capability | traceability |
| 7 | Delete every bracketed hint | a hint left in is an unmade decision |

## Step 3: Put it in front of the owner

Show the owner the text before publishing it to a tracker: the capability slug, the one-sentence problem, the "what a person can do" list, and "publish, change, or reject?". Publishing is outward-facing: it needs the owner's explicit yes. Silence is not approval.

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | the Epic is capability-level, with no implementation names | Step 2, rule 2 |
| 2 | `capability` is set and unique | `SPEC-EPIC-01` |
| 3 | every "what a person can do" line has a Story, or is flagged as a gap | `SPEC-EPIC-03` |
| 4 | out-of-scope items are named | `SPEC-EPIC-04` |
| 5 | acceptance defers to the children | `SPEC-EPIC-05` |
| 6 | no bracketed hint survived | Step 2, rule 7 |

## Step 5: Return

Report the item text (or its tracker id once published), the `capability` slug and any gap. When a workflow pillar called this skill, return the pillar's envelope: path or id in `artefato`.

## Example

*Capability: quote approval.* Title `EPIC-quote-approval · Quote approval`. Who: sales reps send quotes; customers approve them. Problem: approvals travel by email and stall for days. A person can: approve a quote online; see its expiry; download a signed PDF. Out: price negotiation (its own capability). Accepted when all three Stories' scenarios pass with evidence.
