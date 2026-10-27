---
name: doc-story
description: Writes user stories from behavior already decided — "As a / I want / so that" (or a job story "When / I want to / so I can" when the input is about a situation), context, three to eight Given/When/Then acceptance criteria with observable outcomes, notes, out of scope and a definition of done — checked against INVEST, as tracker-ready bodies or a file, with every missing fact marked as a gap. Use whenever someone asks to write, rewrite, split or clean up a user story, turn a requirement, a PRD story (US-1) or a feature into stories, or add acceptance criteria to a ticket. A writer only — it does not discover needs, estimate or read the code. Not for the capability (doc-epic), a shippable slice with a benefit hypothesis (doc-feature), the implementation steps (doc-tasks), or a defect (doc-bug).
source: "[Template: Story](references/template.md)"
model: haiku
effort: medium
tags:
  - skill
  - design-docs
  - story
---

# doc-story

> **A writer.** It follows the [writing contract](../../docs/design-docs/writing-contract.md): it reads the request, the files the request names (a PRD, a feature) and `references/template.md` — nothing else (`DD-CORE-01`, `DD-CORE-02`).

## Scope

A story answers one question: **what can one user do, and how do we know it works?** It is the acceptance unit: its criteria are what a test executes.

| The request is... | Go to |
| --- | --- |
| a slice with a benefit hypothesis and dependencies | `doc-feature` |
| the steps to build a story | `doc-tasks` |
| something that worked and broke | `doc-bug` |

**Anchor:** the user, the action and the outcome (`DD-CORE-06`). An outcome the input does not give ("so that ...") is a gap, not a guess — the reason is what lets the team negotiate the solution.

## Step 1: Pick the form

| The input describes... | Form |
| --- | --- |
| a role that wants something | **user story**: As a [role], I want [action], so that [outcome] |
| a situation that triggers a need, any role | **job story**: When [situation], I want to [motivation], so I can [outcome] |

Several behaviors in one request → one story each. A behavior too large for one story (several workflow steps, several business rules, several user types) is split by workflow step, rule, data variation or happy/unhappy path — never by technical layer — and each split is `(proposed)`.

## Step 2: Write

Copy the template from "Body" down, once per story.

| # | Rule | Why |
| --- | --- | --- |
| 1 | Title is verb-first and names what the user gets; the input's ID (`US-1`) leads it | the board and the tasks cite it |
| 2 | Criteria are Given / When / Then with an outcome a test can observe ("sees", "receives", "is refused"), never an internal state | a criterion with nothing to observe cannot be proved |
| 3 | One criterion per behavior the input states, three to eight per story; reuse the PRD's `AC-NN` IDs, else number `AC-1`… | the criteria are the story's contract |
| 4 | A refusal, permission or empty case the input states becomes a criterion; one it does not state is not invented — at most a gap when the input hints at it ("only managers…" with no rule for the others) | `DD-CORE-03` |
| 5 | A limit the input states (a number, a date, a role) is written with its boundary explicit; an open side is a gap | the edge is where a developer stops |
| 6 | No screen layout, endpoint, table or component: the story says what, not how | keeps it negotiable |
| 7 | Out of this story holds what the input excluded; an exclusion you add is `(proposed)` | an unmarked exclusion reads as a decision (`DD-CORE-04`) |
| 8 | No status or estimate: the tracker and the team own them | §4 of the contract |

## Step 3: INVEST check

Read each story once against INVEST. A failure is **reported**, not fixed by inventing:

| Letter | Fails when | Then |
| --- | --- | --- |
| Independent | it only works after a later story | note the dependency under Notes |
| Valuable | the outcome is a technical step, not a user gain | gap: "what does the user get?" |
| Small | more than eight criteria, or several workflow steps | split, `(proposed)` |
| Testable | a criterion has no observable outcome | rewrite it observable, or gap |

## Step 4: Self-check

| # | Check |
| --- | --- |
| 1 | every story has role (or situation), action and outcome |
| 2 | three to eight criteria, each Given / When / Then with an observable outcome and an ID |
| 3 | no behavior, limit or rule appears that the input did not state |
| 4 | every gap is inline and again under Open questions, with who decides; no bracketed hint survived |

## Step 5: Return

The return block of the [writing contract](../../docs/design-docs/writing-contract.md) §5 — outcome (`complete`, `partial` or `blocked`), path or "inline", status, one sentence, then every gap and `(proposed)` item, one line per story. With no path named, the bodies go inline.

## Example

*"Story: a customer approves a quote from the emailed link. They can't approve an expired quote (30 days). The rep gets an email when it's approved."* One user story: "As a customer, I want to approve a quote from its link, so that [GAP: what do they get — faster delivery, a confirmed price? — decides: product owner]". Criteria: `AC-1` given a valid link, when they approve, then they see the quote marked approved; `AC-2` given a quote sent 30 days ago, when they open the link, then they see it has expired and cannot approve — `[GAP: is day 30 itself still valid? — decides: product owner]`; `AC-3` given an approval, when it is saved, then the sales rep who sent the quote receives an email. Outcome `partial`, two gaps.
