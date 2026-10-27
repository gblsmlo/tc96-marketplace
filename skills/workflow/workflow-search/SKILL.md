---
name: workflow-search
description: Opens every delivery request — splits it into one-sentence slices on five axes (product, frontend, backend, tooling, stack), reads the record before the code (PRD, ADRs, bundles, project docs, memory), sends only the slices the record did not answer to `repo-explorer`, one question each in a single round, and writes a triage file that gives each slice a verdict and a next step and the request one route into plan, citing `SDD-FLOW-*` and `SDD-SPEC-01`. Use first, whenever someone asks to build, add, change, fix or spec something, before any PRD, ADR or bundle is written. Internal only, with no web pages or library docs. Not for deciding scope or design (workflow-plan), running features (workflow-implementation), nor reviewing a diff (workflow-review).
type: skill
family: workflow
language: en
source: "[Delivery Flow — Spec Driven Development](../docs/delivery-flow.md)"
tags:
  - skill
  - workflow
  - search
  - triage
---

# workflow-search

> **Delegation (`SDD-CORE-02`).** This phase runs in the main session. It splits the request and reads the record itself — status lines, titles and the one section a slice points to — and hands every code question to `repo-explorer`, called by name as a subagent. It decides nothing: each slice leaves with a verdict and a next step, and plan decides (`SDD-FLOW-05`).
> **Context (`SDD-CORE-04`).** Keep slices, sources and one-line answers. Never paste a whole document, a diff or an explorer's full reply into this conversation; the triage file keeps the facts.

Rules this phase implements: [Delivery Flow — Spec Driven Development](../docs/delivery-flow.md) §2, §4.4 "Triage", `SDD-FLOW-01`, `SDD-FLOW-05`, `SDD-FLOW-06`, `SDD-SPEC-01`.

## Scope

| The request is... | Go to |
| --- | --- |
| anything to build, add, change, fix or spec | this phase, first |
| a triage already exists for this request and plan has not run | `workflow-plan` |
| approved bundles to run | `workflow-implementation` |
| a feature in `in-review` | `workflow-review` |
| a new item after a failed review | `workflow-plan` — never back here (`SDD-FLOW-02`) |
| research outside the codebase: a library's API, a market, users | not this flow |

## Step 1: Split

Rewrite the request as slices, one sentence each, on the five axes. Note the entities and capabilities each slice touches.

| Axis | What belongs there |
| --- | --- |
| `product` | promised behavior, rules, who uses it and what they see |
| `frontend` | screens, routes, guards, client state |
| `backend` | endpoints, data, sessions, server-side rules |
| `tooling` | tests, scripts, CI, environment variables, the harness |
| `stack` | libraries, providers, versions: the decisions that last |

1. A slice sits on one axis. A sentence that names two capabilities is two slices.
2. An axis the request does not touch has no slice.
3. A need the request implies is a slice: "when authenticated" implies a guard. Mark it `(inferred)`. A nice-to-have nobody asked for is not a slice.
4. A one-line request is still triaged: one row costs nothing, and it records where the request went.

## Step 2: Read the record first

For each slice, read these in order and stop at the first that answers it. Read titles and the one matching section, never a whole document.

| # | Source | It answers |
| --- | --- | --- |
| 1 | `.specs/PRD.md` and its amendments: Functionalities, Out of Scope, Open gaps | is it promised, excluded, or already asked? |
| 2 | `.specs/adr/`: the titles, then the one ADR whose title matches | is the lasting technical decision made? |
| 3 | `.specs/features/`: folder names, then the matching `spec.md` **Provides** | is it already specified, or built? |
| 4 | the project's docs: `CLAUDE.md`, `AGENTS.md`, `docs/`, READMEs | conventions and constraints of this codebase |
| 5 | the agent memory the project keeps | decisions recorded outside `.specs/` |

An answer found sets the slice's **Answer** and **Source** (`record: <path>`), and the slice never reaches the code (`SDD-FLOW-06`).

## Step 3: Ask the code, once

For each slice still open, start `repo-explorer` with `references/question.md`. All of them go out side by side in one message; they only read. Each reply is at most 30 lines of facts with `file:line`.

- A question the reply does not answer becomes a gap with who decides it. There is no second round and no follow-up question (`SDD-FLOW-06`).
- No web page, no library documentation, no external source.

## Step 4: Triage

Give each slice one verdict, and the verdict names its next step:

| Verdict | When | Next step |
| --- | --- | --- |
| `exists` | the record or the code already does it | nothing; cite the source |
| `product-decision` | the behavior is not promised, or a rule is open | plan · `product-manager`, PRD amendment |
| `technical-decision` | a lasting choice is not recorded (a provider, a boundary, a data model shared by features) | plan · `software-architect`, ADR |
| `build` | promised or clearly implied, and the facts say what is missing | plan · `spec-writer`, bundle |
| `no-behavior-change` | a fix or refactor of something built | plan · fast lane (`SDD-SPEC-09`) |
| `untraced` | it traces to nothing in the PRD and the request does not make it a product change | a question for the owner |

Then write the request's **route**, the order plan follows:

1. a `product-decision` amendment comes before every bundle that depends on it;
2. a `technical-decision` ADR comes before every bundle that cites it;
3. among `build` slices, a provider comes before its consumer. When one slice provides what another consumes, write it in the route as `(proposed)`: the PRD decides it.

The triage classifies and routes. Scope, feature cuts and design are plan's, and the owner's (`SDD-FLOW-05`).

## Step 5: Write and hand off

Write `.specs/triage/<YYYY-MM-DD>-<slug>.md` from `references/template-triage.md`. The file is never edited after plan reads it; a later request gets its own file.

Report, and nothing else:

```
Triage: .specs/triage/2026-10-26-login-redirect.md
Slices: 5 — exists 1 · product-decision 1 · build 3
Route: amendment (S1) → bundles (S3 provides, S4 consumes; S5 as gates)
Gaps: <each verbatim, with who decides>
Next: workflow-plan
```

When a gap decided by the owner blocks the route's first stop, ask it now, in the same message. Otherwise continue with `workflow-plan`, unless the person asked for search only. Do not load another phase from inside this one (`SDD-FLOW-04`).

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | every slice sits on one axis, in one sentence, with its entities and capabilities | `SDD-FLOW-05` |
| 2 | the record was read before the code; no slice the record answered went to `repo-explorer` | `SDD-FLOW-06` |
| 3 | one question per open slice, all in one round; nothing external was read | `SDD-FLOW-06` |
| 4 | every slice has a verdict and a next step; the route orders amendment, ADR, provider, consumer | `SDD-FLOW-05` |
| 5 | every code fact in the triage carries `file:line` | `SDD-SPEC-01` |
| 6 | nothing in the triage decides scope or design; a derived provides/consumes pair is `(proposed)` | `SDD-FLOW-05` |
| 7 | this conversation holds slices, sources and one-line answers, not file content | `SDD-CORE-04` |

## Example

Request: "a login page that takes the user to the dashboard when already authenticated".

Step 1: five slices. S1 product: an authenticated user goes to the dashboard and an anonymous one sees the login. S2 stack: the authentication provider. S3 backend: a way to ask "who am I" for the session `(inferred)`. S4 frontend: the `/login` route, the redirecting guard and the dashboard route. S5 tooling: an E2E check of the flow and the provider's variables per worktree `(inferred)`.

Step 2: the PRD promises no login flow, so S1 is answered by the record: nothing promised. `.specs/adr/0002-auth-provider.md` answers S2. `sdd.config.sh` answers half of S5: E2E runs on `bun run e2e`, and there are no auth variables.

Step 3: two `repo-explorer` calls, side by side, for S3 and S4. S3: "`authMiddleware` sets `ctx.user` — src/server/auth.ts:14; no route returns the current user". S4: "`/dashboard` has no `beforeLoad` — src/routes/dashboard.tsx:3".

Step 4: S1 `product-decision`, S2 `exists`, S3 `build`, S4 `build`, S5 `build` as gates. Route: amendment (S1), then bundles, with S3 providing "current user" and S4 consuming it `(proposed)`. Gap: "after login, back to the page first asked for, or always the dashboard? — decides: owner".

Step 5: the triage file is written. The gap does not block the amendment, which can carry it as an open gap, so the phase continues with `workflow-plan`.
