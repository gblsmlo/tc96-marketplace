---
name: workflow-search
description: Runs phase 1 of the delivery flow v2 — breaks the owner's prompt into claims (problems, hypotheses, objectives), checks each against the codebase, the web, the product docs and the decision memory, marks it confirmed, refuted or unverified with its evidence, and has `product-manager` write the PRD from the confirmed claims only, as a `Draft` the owner approves together with the evidence file, citing handoffs `H1`–`H4` and `SDD-PRD-*`. Also gathers the repo facts per feature that Plan needs, so Plan does not search again. In a project on the delivery flow v2 (`story.md` bundles), use when someone brings a new product, a new capability or a change to what the product promises, says "research this before we build it", or asks to validate a problem or hypothesis before the PRD. Not for writing a feature's bundle (workflow-plan), a fix or refactor that changes no product behavior (workflow-plan, fast lane), nor a lasting technical decision (spec-adr).
type: skill
family: workflow
language: en
source: "workflow/foundations/phases.md §1 (Draft, 2026-10-26)"
tags:
  - skill
  - workflow
  - prd
  - research
---

# workflow-search

> **Delegation (`SDD-CORE-02`).** This skill runs in the orchestrating conversation and writes only the evidence file. Code questions go to `repo-explorer`, web questions to `web-researcher`, the PRD to `product-manager` with `spec-prd`. Each is called by name, as a subagent. Keep claims, verdicts and paths in this conversation, never file contents or page text (`SDD-CORE-04`).
> **Status.** Draft. Implements `workflow/foundations/phases.md` §1 and `workflow/foundations/handoffs.md` `H1`–`H4`.

## Scope

| The request is... | Go to |
| --- | --- |
| a new product, a new capability, or a change to what the product promises | this skill |
| an approved PRD that needs a feature added or a promise changed | this skill, amendment mode |
| a fix or refactor that changes no product behavior | `workflow-plan`, fast lane |
| a feature already in an approved PRD | `workflow-plan` |
| a technical decision that outlives a feature | `spec-adr` |

## Step 1: Read the starting point (`H1`)

1. Read only the status line of `.specs/PRD.md` and of its last amendment.

| `.specs/PRD.md` | Mode |
| --- | --- |
| missing | new PRD |
| `Draft` or `In review` | revision of that draft |
| `Approved` | amendment: the approved text is never rewritten (`SDD-PRD-06`) |

2. Restate the prompt as a numbered claim list, one claim per line, before any search:

| Kind | ID | Example |
| --- | --- | --- |
| problem | `CL-P1` | "admins add teammates by hand, one at a time" |
| hypothesis | `CL-H1` | "an invite link cuts the time to a full team" |
| objective | `CL-O1` | "a new workspace has three members within a day" |

A sentence that holds two claims becomes two lines. A claim with no observable consequence is sent back to the owner as a question, not searched.

## Step 2: Check each claim against four sources (`H2a`–`H2d`)

Send the questions out side by side; they only read. One bounded question per agent call.

| Source | Agent | Question shape | Evidence kept |
| --- | --- | --- | --- |
| Codebase | `repo-explorer` | "Does `<claim>` hold in the code? Return what exists, its callers and its tests, with file:line, at most 30 lines." | `file:line` |
| Web | `web-researcher` | "How do products like this solve `<claim>`? Return at most 5 sources with URL and access date." | URL and date |
| Docs | read here, by path | earlier PRDs and amendments, merged bundles in `.specs/features/` | path and section |
| Decision memory | read here, by path | ADRs in `.specs/adr/`, decisions recorded in `AGENTS.md` | ADR ID or decision date |

Skip a source that cannot answer the claim, and write `n/a` with the reason. A claim checked against no source is `unverified`.

## Step 3: Decide each claim

| Verdict | When | Goes to |
| --- | --- | --- |
| confirmed | at least one source supports it and none contradicts it | the PRD |
| refuted | a source contradicts it | out of the PRD; listed in the evidence file with the source |
| unverified | no source answers it, or sources disagree | the PRD's Open gaps, with who decides |

The verdict cites the evidence that decided it. Inference is labeled as such and never makes a claim `confirmed`.

## Step 4: Repo facts per feature, for Plan (`H4`)

Once the claims point to features, ask `repo-explorer` one question per likely feature:

```
Feature <name> would provide <items> and consume <items>.
Return, with file:line: what already exists for each item; every caller of anything it would
change; the tests around it; the conventions of that layer. Facts only, at most 30 lines.
```

These facts are what Plan cites in `spec.md` (`SDD-SPEC-01`). Plan only searches again for a fact missing here.

## Step 5: Write the evidence file

Default D6 (open in `workflow/README.md`): `.specs/search/<YYYY-MM-DD>-<slug>.md`, from `references/template-evidence.md`, `status: Draft`. It holds the claim list, each verdict with its evidence, and the repo facts per feature.

## Step 6: Write the PRD

Start `product-manager` with the skill `spec-prd` and only:

| Input | Value |
| --- | --- |
| mode | new, revision or amendment, from Step 1 |
| confirmed claims | the `CL-*` lines marked confirmed, each with its evidence |
| unverified claims | as Open gaps, each with who decides |
| repo facts | the evidence file path, section "Repo facts" |

The PRD premises the agent must hold, beyond `spec-prd`'s own rules:

| # | Premise | Rule |
| --- | --- | --- |
| 1 | every feature states what it provides and what it consumes; every consumed item has exactly one provider | `SDD-PRD-02` |
| 2 | each `AC-NN` is observable in Given / When / Then | `SDD-PRD-03` |
| 3 | the Dependency Graph has no cycle; `W0` consumes nothing | `SDD-PRD-04` |
| 4 | each `PO-*` and `OBJ-*` comes from a confirmed claim and names its `CL-*` | — |
| 5 | Traceability and Open gaps stay, after the Dependency Graph (default D7) | `SDD-PRD-01` |
| 6 | the file is `status: Draft` | `SDD-CORE-03` |

## Step 7: One message to the owner (`H3`)

```
Search done (Draft):
- .specs/PRD.md — <features count> features in <waves count> waves
- .specs/search/<date>-<slug>.md — <n> confirmed, <n> refuted, <n> unverified
Refuted: <CL-* and one-line reason each>
Open gaps: <verbatim, each with who decides>
Approve, change or reject the PRD?
```

Silence approves nothing. On approval, the PRD becomes `Approved` and the next step is `workflow-plan` (`H4`).

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | every claim has a verdict and the evidence that decided it | — |
| 2 | no refuted claim reached the PRD; every unverified one is an Open gap | — |
| 3 | every feature in the PRD has repo facts, or a line saying none exist | `SDD-SPEC-01` |
| 4 | every consumed item has exactly one provider; the graph has no cycle | `SDD-PRD-02`, `SDD-PRD-04` |
| 5 | the PRD and the evidence file are `Draft` until the owner answered | `SDD-CORE-03` |
| 6 | this conversation holds claims, verdicts and paths, not page text or code | `SDD-CORE-04` |

## Example

Prompt: "admins waste time adding people; an invite link would fix it; we want full teams in a day". Step 1: no PRD; claims `CL-P1`, `CL-H1`, `CL-O1`. Step 2: `repo-explorer` returns "members are inserted only by `POST /members`, admin-only — src/members/route.ts:22"; `web-researcher` returns three products with invite links. Step 3: `CL-P1` confirmed, `CL-H1` confirmed, `CL-O1` unverified (no usage data). Step 4: facts for F01 session, F02 email, F03 invitations. Step 6: `product-manager` writes six features in four waves; `CL-O1` becomes Open gap "target for full team: owner decides". Step 7: one message; the owner approves.

**Anti-pattern.** Writing "users want invite links" into the PRD from the prompt alone. Corrected: the claim is `CL-H1`, checked against the web and the code, and enters the PRD only as confirmed, with its sources.
