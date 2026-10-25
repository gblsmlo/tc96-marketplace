---
name: spec-rfc
description: Writes a capability's technical design as an RFC (a decision still open, with real alternatives, a decider and a decision date) or a design doc (no real alternative, only recording and review) — boundaries, contracts, verifiable invariants, cost and migration order — as a `Draft` the owner accepts, citing `DOC-RFC-*` IDs. Use whenever someone asks to write, draft or revise an RFC, design doc, technical design, `design.md`, or to decide where a responsibility lives, how a service or module boundary should look, or what contract two parts share before building it. Not for what to build (spec-prd), a single lasting decision record (spec-adr), screens and states (spec-ux), or the work breakdown (spec-task).
type: skill
family: spec
language: en
source: "[Rules of the RFC and design doc](references/rules.md)"
tags:
  - skill
  - spec
  - rfc
---

# spec-rfc

> **Self-contained.** The template is `references/template.md`; the rule text and the status lifecycle are `references/rules.md`. Nothing here needs another skill to run.
> Owner role: `software-architect` writes the content. When this skill runs in an orchestrating conversation, start that agent with the template path and the writing rules below, and keep only its path and open gaps in the conversation.

## Scope

A design answers one question: **how do we build it: which boundary owns what, and which contracts cross it?** It runs in one of two modes, declared in the header.

| Mode | When |
| --- | --- |
| `rfc` | there is a real alternative and the decision is still open |
| `design-doc` | no real alternative; the design only needs recording and review |

| The question is... | Go to |
| --- | --- |
| whether to build it, goals, non-goals | `spec-prd` |
| one decision that must outlive the increment | `spec-adr` (an RFC usually produces one per such decision) |
| flow, screen states, accessibility | `spec-ux` |
| the units, owners and evidence plan | `spec-task` |
| approving what is already built | not an RFC (`DOC-RFC-01`): record it as an ADR |

## Step 1: Confirm the question is open

1. Read the project's record of kept documents if one exists (`## Specs` in `AGENTS.md`, else `.specs/README.md`). Design marked off: do not write the file; state the decision in one line and stop.
2. The file is `.specs/<capability>/design.md`. Read only its status line:

| The file... | Write |
| --- | --- |
| does not exist | the file, from `references/template.md` |
| is `Draft` or `In review` | a revision of that draft |
| is `Accepted` or `Rejected` | a dated amendment at the end; accepted text is never rewritten |

3. Choose the mode. Name a real alternative and the reason it loses; if you cannot, the mode is `design-doc` and the file says "No real alternative" with why (`DOC-RFC-03`).

## Step 2: Write

Copy the template from "Body" down. Rules for the writer:

| # | Rule | Why |
| --- | --- | --- |
| 1 | Delete every bracketed hint; fill every field or write `none` | a field left as a hint is an unmade decision |
| 2 | One sentence, one claim; every fact about the code cites `file:line` | the owner verifies before accepting |
| 3 | Decide on one axis: state ownership, boundary, contract, distribution or operating cost | the axis is what makes two designs comparable |
| 4 | State the cost the design introduces (indirection, types, operations, migration) | a design that records only gains is a pitch |
| 5 | Every verifiable invariant names the test type that proves it, at the cheapest level that catches the defect; an invariant only an E2E proves says why | the cost repeats on every fix round |
| 6 | A contract two parts share gets a row under Shared contracts with a shape test: the consumer's real output fed into the producer's real validator | shapes drift while names still match |
| 7 | In `rfc` mode, set the decider and the decision date | an RFC with no deadline blocks the work that waits on it (`DOC-RFC-02`) |
| 8 | `status: Draft`; the writer never accepts its own file | `WF-SPEC-06` |

## Step 3: Put it in front of the owner

One message, four parts, then stop: the path; the one-sentence decision; the open questions, verbatim; "approve, change, or reject?"

| The owner says | Result |
| --- | --- |
| approve | `Accepted`, on or after the decision date |
| change | revise from the owner's words; the status does not move |
| reject | `Rejected`, or stays `Draft` |

Once resolved, fill **Decision** with what was decided, by whom, when, and the ADRs it produced (`DOC-RFC-04`). Silence is not approval.

## Step 4: Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | the file answers only the design question | `DOC-CORE-01` |
| 2 | the mode is declared; in `rfc` mode the decider and date are set | `DOC-RFC-02` |
| 3 | no RFC for a decision already built | `DOC-RFC-01` |
| 4 | every alternative is real, or the file says there is none | `DOC-RFC-03` |
| 5 | every invariant names its test type | rule 5 above |
| 6 | every shared contract has a shape test | rule 6 above |
| 7 | every lasting decision has its own ADR | `DOC-ADR-01` |
| 8 | no bracketed hint survived | rule 1 above |
| 9 | status is `Draft` until the owner answered | `WF-SPEC-06` |

## Step 5: Return

Report the path, the status, the one-sentence decision and every open question with who decides it. When a workflow pillar called this skill, return the pillar's envelope: path in `artefato`, status in `resultado`, each gap in `lacunas` with `decide` and `fecha-em`.

## Example

*"Where should quote expiry live: browser, BFF or backend?"* Real alternatives exist, so mode `rfc`, decider the tech lead, decision by Friday. Axis: boundary. Proposal: the backend owns expiry; the BFF only forwards. The alternative "BFF computes it" loses because two clients would drift. Invariant: "an expired quote is never approved" proven by a unit test on the domain function plus one `curl` against the route; no E2E needed. The owner accepts on Friday; Decision lists `ADR-0007`.
