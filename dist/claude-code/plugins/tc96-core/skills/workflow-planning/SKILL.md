---
name: workflow-planning
description: Turns an accepted decision into executable work — names the perfil/layer boundary, decomposes only when each unit has independent acceptance and evidence, and writes the acceptance criteria before implementation starts, citing `WF-PLAN-*` and `WF-CORE-*` IDs. Use when intent is already resolved but the work is not executable yet, or when deciding whether to split a task into multiple units. Do not use when the intent itself is still unclear — that is `workflow-research`. Do not use once a unit already has acceptance criteria and an owner — that is `workflow-implementation`.
fonte: "[Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md)"
tags:
  - skill
  - workflow
  - planning
---

# workflow-planning

> **Source of this skill:** [Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md), §4.2 and the `WF-PLAN-*` / `WF-CORE-*` rules in §6.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and to whom to hand it off.

Contract this skill implements: [Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md) §7.

> **Delegation, read first (`WF-CORE-06`, `WF-CORE-07`, `WF-CORE-08`).** The gates, the
> decomposition and the plan in `tasks/` go to `project-manager`; boundaries, `design.md` and
> ADRs go to `software-architect`; `user-experience.md` goes to `product-designer`; publishing
> to the board goes to `repo-operator`, only on the owner's answer. Never delegate to a
> generic agent. Every `.specs/` file goes through `workflow-spec`, which starts the owning
> agent with the template; the stage's drafts reach the owner together, as one planning bundle
> (`WF-SPEC-01`, `WF-SPEC-06`, hub §5); the orchestrating conversation keeps only the paths in
> the envelope's `artefato`.

> **Design note.** This is the **second pillar**: it turns an already-accepted decision into a unit someone can implement without reopening product questions. It writes the plan into `.specs/<capability>/tasks/` (`WF-SPEC-01`, `WF-SPEC-08`), but never invents the decision itself — if the decision is not there yet, that is a return to `workflow-research`, not something to improvise here.

---

## When to use

| Situation | Go to |
| --- | --- |
| intent is not resolved yet | `workflow-research` |
| the unit already has acceptance criteria, owner, and boundary | `workflow-implementation` |
| the question is cronograma, risk across many units, "does this fit the scope" | `project-manager` |
| the question is "where does this boundary belong" | `software-architect` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md) §2 | the four-pillar table, to confirm entry condition |
| 2 | Same hub, §4.2, with "Small units" and "Waves" | the four gates, the test-cost table, the review budget and the wave rule — the core of this skill |
| 3 | Same hub, §6 `WF-CORE-*` and `WF-PLAN-*` | the 16 rules this skill enforces |
| 4 | Same hub, §5 "Gaps" | which gaps this pillar must close before a unit leaves |
| 5 | Same hub, §5 "Where the artifact lives", "The planning bundle", "Delivery" and `WF-SPEC-*` | which `.specs/` files this scope needs, and how the owner reviews them |

The templates, the `DOC-*` rules and the owner's review load inside `workflow-spec`, not here.

References in this skill:

| File | What for |
| --- | --- |
| `references/portoes.md` | the four gates, one worked check each |

---

## Step 1 — Confirm the decision is actually resolved

If the task arrives here still carrying an open product or architecture question, it skipped
a pillar. Return it to `workflow-research` before doing anything else (`WF-CORE-03`). When the
scope is product, `.specs/<capability>/requirements.md` must be `Approved`, and so must the
amendment this increment depends on (`WF-SPEC-08`).

Read `lacunas` in the research envelope (`WF-CORE-09`). A gap with `fecha-em: pesquisa` still
open is the same return. Each gap with `fecha-em: planejamento` is this pillar's to close: start
the agent its `decide` names (hub §3), or ask the owner in one sentence when it is `dono`. A
unit that depends on a gap still open waits at the acceptance gate; the others go on.

---

## Step 2 — Draft the design files the scope needs, side by side

Hub §5 decides which files exist for this scope (`WF-SPEC-03`); skip the ones it does not list.
Call `workflow-spec` once per file; it names the owner agent and the template. The two agents
below run at once, each on its own file, and no draft stops for review here: the owner reads
them together in Step 5, in the planning bundle (hub §5, `WF-SPEC-06`).

| File | Agent | When |
| --- | --- | --- |
| `design.md`, or an amendment to it | `software-architect` | architecture scope, or a product change with a boundary or contract |
| `.specs/adr/NNNN-<slug>.md` | `software-architect` | drafted with `design.md`, born `Proposed`, one per decision that outlives the increment |
| `user-experience.md`, or an amendment to it | `product-designer` | a product change with an interface |

Both agents start from `requirements.md` and the research envelope, never from this
conversation, and neither waits for the other's file. Each file links the others and copies
none of them (`WF-SPEC-02`). A `design.md` in `rfc` mode waits for its decision date; it does
not become `Accepted` by default. A file the capability already has `Accepted` gets an
amendment, never a rewrite (`WF-SPEC-08`). The plan is drafted right after these drafts exist
(Step 5), citing each one as `Draft`.

**The architect fixes the cost of the proof here.** Where a rule lives decides the cheapest
test that can prove it: a rule in the backend is proved by a unit test and a `curl`; the same
rule spread across the interface only by an E2E, which costs minutes and a trace read by the
agent on every fix round. Every verifiable invariant in `design.md` and in an ADR names its
test type at the cheapest level that proves it, and an invariant only an E2E proves says why
(hub §4.2, `WF-PLAN-06`).

---

## Step 3 — Pass the four gates

`references/portoes.md`, hub §4.2:

1. **Product gate** — if this touches a spec, is there an approved behavior behind it?
2. **Decomposition gate** — split into multiple units only if each has independent
   acceptance, evidence, and dependencies (`WF-PLAN-03`); re-slice a unit above the review
   budget (`WF-PLAN-07`); land a shared contract first, as its own unit (`WF-PLAN-08`).
3. **Boundary gate** — name the owning perfil (`frontend-developer`, `backend-developer`,
   `devops-security`...) per unit. "Fullstack" is never an answer (`WF-PLAN-05`).
4. **Acceptance gate** — every unit gets a written acceptance criterion before it is
   considered ready (`WF-PLAN-04`), with a line for each edge research answered for it — a
   story scenario, or a line under `decisoes` (`WF-RES-06`). An open gap the unit depends on is
   a line nobody wrote yet: the unit waits for the answer (`WF-CORE-09`).

---

## Step 4 — Name the evidence and the test types, with their cost

Decide now, not at validation time, what focused checks and what evidence this unit's
completion will require — the next pillar inherits this plan, it does not invent one.

An execution scope arrives with its subtype, and the subtype sets the floor of the evidence
(hub §4.1): a **fix** needs the cited rule and a case that fails today; a **refactor** needs
the existing tests passing unchanged; a **technical adjustment** needs a before/after
measurement or a check of the adjustment.

For each unit, name the test types the Validation will run (`WF-PLAN-06`), from the table in
hub §4.2:

1. Write the sentence "what can go wrong here" for each acceptance criterion (`TS-CORE-01`).
2. Put each one at the cheapest level that still catches it (`TS-CORE-02`): static, unit,
   contract, integration, component, E2E, manual — in that order of cost.
3. Start from the invariants `design.md` or an ADR already typed; do not re-decide them.
4. For every integration or E2E, add the sentence of what only it catches. Without that
   sentence it goes down a level: its time and tokens repeat on every fix round, in the
   implementer and in the validator.
5. Set the unit's risk class — `contract`, `security` or `focused` — by applying the hub §4.4
   tree now (`WF-PLAN-06`). Validation reads it.

**Shared contracts land first** (`WF-PLAN-08`, hub §4.2 "Small units"). Check: the schema a
route and its client share is its own unit in an earlier wave, and the client's acceptance
feeds its real output into the route's real validator. The contracts come from the "Shared
contracts" table in `design.md`.

---

## Step 5 — Write the increment's plan, then put the bundle in front of the owner

Call `workflow-spec` for `.specs/<capability>/tasks/NNNN-<slug>.md`, numbered after the last
plan of the capability (`WF-SPEC-08`); `project-manager` writes it as soon as the Step 2
drafts exist, citing them as `Draft`: one Task per unit that passed the gates, with owner,
dependencies, inputs, acceptance, edges answered, evidence, test types and risk class. Every
scope gets this file, including execution, and no project turns it off
(`WF-SPEC-03`, `WF-SPEC-07`).

Each Task also gets its **Wave**, **Surface** and **Size** (hub §4.2 "Small units" and
"Waves", `WF-PLAN-07`, `WF-CORE-10`); the plan's `budget` field names the review budget and
wave width it was sized against, and its `delivery` field the mode and push-and-PR answer (hub
§5 "Delivery"). The fields are in `template-tasks.md`. A Task whose inputs are not accepted yet
is listed, but it is not ready (`WF-SPEC-04`).

**One planning bundle.** Planning collects the drafts — `design.md` and its ADRs,
`user-experience.md`, the plan — and sends them to the owner as one message, in the bundle
shape of `workflow-spec` Step 4 (hub §5 "The planning bundle", `WF-SPEC-06`). The plan is
`Ready` only on the owner's answer.

---

## Step 6 — Self-check before the handoff

| # | Check | Rule |
| --- | --- | --- |
| 1 | core self-check passed (hub §7, C1–C6) | `WF-CORE-*` |
| 2 | the decision behind this unit is resolved, not open | `WF-CORE-03` |
| 3 | if split into multiple units, each has independent acceptance/evidence/dependency | `WF-PLAN-03` |
| 4 | every unit declares Surface and Size and fits the plan's `budget`; one above it was re-sliced by scenario or by expand → migrate → contract step | `WF-PLAN-07` |
| 5 | a contract shared by units that would run side by side lands first as its own unit, and its first consumer has a real-output-against-real-validator test | `WF-PLAN-08`, `WF-PLAN-04` |
| 6 | the owning perfil is named per unit, never "fullstack" | `WF-PLAN-05` |
| 7 | each unit names the agent that implements it, and that agent is in hub §3 | `WF-CORE-06` |
| 8 | acceptance criteria are written, not implicit, with a line for each edge research answered | `WF-PLAN-04`, `WF-RES-06` |
| 9 | every unit names its test types at the cheapest level, every integration or E2E says what only it catches, and its risk class is set | `WF-PLAN-06` |
| 10 | every Task has a wave, and no two Tasks that can run side by side share a file in their Surface, except a landed contract | `WF-CORE-10` |
| 11 | the plan's `budget` and `delivery` fields are filled; push and PR are either quoted from the owner or "ask per wave" | `WF-PLAN-07`, hub §5 "Delivery" |
| 12 | the `.specs/` files match the scope, each written by its own agent through `workflow-spec` | `WF-SPEC-01`, `WF-SPEC-03` |
| 13 | no spec file copies another; they link | `WF-SPEC-02` |
| 14 | the owner saw one planning bundle, and every status that moved past `Draft` moved on an answer naming that file | `WF-SPEC-06` |
| 15 | the files sit in the capability's folder; approved text got an amendment; this increment has its own plan | `WF-SPEC-08` |
| 16 | no unit leaves with an open gap it depends on | `WF-CORE-09` |

---

## Step 7 — Hand off

Return the envelope from hub §5 (`pilar: planejamento`), with the `.specs/` paths in
`artefato`:

| Situation | Continue in |
| --- | --- |
| units ready, boundary and acceptance named | `workflow-implementation`, once per unit, up to the wave width |
| a decision is missing after all | `workflow-research` |
| cronograma/risk spans multiple units | `project-manager` |
| boundary itself is disputed, not just which perfil owns it | `software-architect` |

**Board, when the project keeps one.** The items' text is a planning decision: `project-manager`
writes it in the plan, under **Board items** (`template-tasks.md`). The bundle shape of
`workflow-spec` Step 4 asks for publishing, and the plan's Delivery, in the same message as the
files (Step 5, hub §5), not after it. Once the plan is `Ready` and that answer said yes,
publishing is a mechanical operation: `repo-operator` publishes that text word for
word, with the owner's answer quoted, and returns the ids in its envelope (`WF-CORE-08`).
Nothing is written back into the approved plan; each item links to the file (one-way).

**Spec-only run.** When the run was started as spec generation only (the `spec` command), stop
here: return the envelope and do not start `workflow-implementation` (`WF-SPEC-05`).

**Advance without asking, a wave at a time.** Otherwise, start `workflow-implementation` now on
every unit that meets the five conditions of hub §4.2 "Waves", up to the plan's wave width,
each writer in its own worktree and branch (`WF-CORE-10`). Execution is rolling: as a unit closes in Validation, the
next ready unit takes its slot, without waiting for the rest of its wave. Holding a ready unit
back needs a stated reason in the envelope. Do not ask whether to continue. Stop only for an
owner decision or for an action that is irreversible or visible to others (deleting or
overwriting data, a release); push and PR follow the plan's `delivery` field (hub §5).

**Reset the context at the boundary.** Each unit is implemented by the agent the boundary gate
named (`frontend-developer`, `backend-developer`, `devops-security`), started with only the unit
(acceptance, owner, evidence plan) and the decisions it depends on (`WF-CORE-06`). The planning
conversation does not travel with it
([`CC-CTX-01`, `CC-CTX-03`](../../referencias/claude-code-contexto-e-cache.md)).

Started means called as a subagent, with that agent's name as `subagent_type`: that is what
applies its `modelo` and `esforco`. When the units run in parallel sessions instead, open each
one `fresh`, with `model` and `effort` set to the orchestration tier (`agents/README.md`), and a
brief that has the session call the owner as a subagent and keep only the envelope, validation
and the PR. A brief that says "as `backend-developer`" makes the session write the code itself,
on the model it inherited from this one
([`CC-PAR-05`](../../referencias/claude-code-paralelismo-e-escala.md)).

---

## Example

*Resolved decision: "discounts above 50% require manager approval."* One route, one check, no
new service, so no `design.md` and no ADR; `user-experience.md` for the approval prompt, then
the plan `.specs/checkout-discount/tasks/0001-approval-rule.md`, both in one planning bundle.
Boundary: `backend-developer` owns the validation rule; `frontend-developer` owns the approval
prompt — two units, because each has its own acceptance criterion and can be verified
independently. Acceptance for the backend unit: "a request with `discount > 0.5` and no
`approvedBy` field returns a 422." Test types: the backend unit is proved by a unit test and a
`curl` on the route (low cost); the approval prompt by a story with `play` (medium). No E2E:
what can go wrong is the rule and the prompt's states, and both are caught below it
(`WF-PLAN-06`). The route already accepts `approvedBy`, so there is no contract unit: both sit
in wave 0, their Surfaces share no file, and they start side by side, each in its own
worktree; both are `focused`.

---

## Related

- [Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md) — source of this skill, §4.2, §6
- `workflow-research` · `workflow-implementation` — the neighbors
- `workflow-spec` — writes every `.specs/` file of this pillar and records the owner's approval
- `project-manager` · `software-architect` — where cronograma/risk and boundary disputes go
