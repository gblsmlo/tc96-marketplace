---
nome: workflow-planning
descricao: Turns an accepted decision into executable work — names the perfil/layer boundary, sets the appetite, decomposes only when each unit has independent acceptance and evidence, and writes the acceptance criteria before implementation starts, citing `WF-PLAN-*` and `WF-CORE-*` IDs. Use when intent is already resolved but the work is not executable yet, or when deciding whether to split a task into multiple units. Do not use when the intent itself is still unclear — that is `workflow-research`. Do not use once a unit already has acceptance criteria and an owner — that is `workflow-implementation`.
tipo: skill
familia: workflow
idioma: en
fonte: "[Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md)"
tags:
  - skill
  - workflow
  - planning
---

# workflow-planning

> **Source of this skill:** [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md), §4.2 and the `WF-PLAN-*` / `WF-CORE-*` rules in §6.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and to whom to hand it off.

Contract this skill implements: [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §7.

> **Delegation, read first (`WF-CORE-06`, `WF-CORE-07`).** The gates, the decomposition and
> `tasks.md` go to `project-manager`; boundaries, `design.md` and ADRs go to
> `software-architect`; `user-experience.md` goes to `product-designer`. Never delegate to a
> generic agent. Every `.specs/` file goes through `workflow-spec`, which starts the owning
> agent with the template and puts the `Draft` in front of the owner (`WF-SPEC-01`,
> `WF-SPEC-06`); the orchestrating conversation keeps only the paths in the envelope's
> `artefato`.

> **Design note.** This is the **second pillar**: it turns an already-accepted decision into a unit someone can implement without reopening product questions. It writes the plan into `.specs/<feature>/` (`WF-SPEC-01`), but never invents the decision itself — if the decision is not there yet, that is a return to `workflow-research`, not something to improvise here.

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
| 1 | [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §2 | the four-pillar table, to confirm entry condition |
| 2 | Same hub, §4.2 | the five gates — the core of this skill |
| 3 | Same hub, §6 `WF-CORE-*` and `WF-PLAN-*` | the 12 rules this skill enforces |
| 4 | Same hub, §5 "Onde o artefato mora" and `WF-SPEC-*` | which `.specs/` files this scope needs |

The templates, the `DOC-*` rules and the owner's review load inside `workflow-spec`, not here.

References in this skill:

| File | What for |
| --- | --- |
| `references/portoes.md` | the five gates, one worked check each |
| `references/apetite-e-corte.md` | appetite and circuit breaker, with a worked example |

---

## Step 1 — Confirm the decision is actually resolved

If the task arrives here still carrying an open product or architecture question, it skipped
a pillar. Return it to `workflow-research` before doing anything else (`WF-CORE-03`). When the
scope is product, `.specs/<feature>/requirements.md` must be `Approved`.

---

## Step 2 — Write the design files the scope needs

Hub §5 decides which files exist for this scope (`WF-SPEC-03`); skip the ones it does not list.
Call `workflow-spec` once per file; it names the owner agent and the template, and stops for
the owner's review (`WF-SPEC-06`).

| File | Agent | When |
| --- | --- | --- |
| `design.md` | `software-architect` | architecture scope, or a product feature with a boundary or contract |
| `.specs/adr/NNNN-<slug>.md` | `software-architect` | once `design.md` is `Accepted`, one per decision that outlives the feature |
| `user-experience.md` | `product-designer` | a product feature with an interface |

Both agents start from `requirements.md` and the research envelope, never from this
conversation. Each file links the others and copies none of them (`WF-SPEC-02`). A `design.md`
in `rfc` mode waits for its decision date; it does not become `Accepted` by default.

---

## Step 3 — Pass the five gates

`references/portoes.md`, hub §4.2:

1. **Product gate** — if this touches a spec, is there an approved behavior behind it?
2. **Decomposition gate** — split into multiple units only if each has independent
   acceptance, evidence, and dependencies (`WF-PLAN-03`).
3. **Boundary gate** — name the owning perfil (`frontend-developer`, `backend-developer`,
   `devops-security`...) per unit. "Fullstack" is never an answer (`WF-PLAN-05`).
4. **Appetite gate** — decide how much this is worth spending before estimating how long it
   takes (`WF-PLAN-01`). A unit that blows its appetite stops and returns to the decision
   table — it does not quietly get more time (`WF-PLAN-02`).
5. **Acceptance gate** — every unit gets a written acceptance criterion before it is
   considered ready (`WF-PLAN-04`).

---

## Step 4 — Name what evidence will prove this unit is done

Decide now, not at validation time, what focused checks and what evidence this unit's
completion will require — the next pillar inherits this plan, it does not invent one.

**Shared contracts get a shape test in the first consumer.** When two units share a contract
(a schema and the component that emits data for it, an API and its client) and they can be
built in parallel, the consumer's acceptance criterion requires a test that feeds its **real
output** into the producer's **real validator**. Matching field or node names is not enough:
shapes drift while names still match. Put the test in the earliest unit that consumes the
contract, not in a later integration unit. Otherwise the mismatch surfaces only after both
sides are built on it. The contracts come from the "Shared contracts" table in `design.md`.

---

## Step 5 — Write `tasks.md`

Call `workflow-spec` for `.specs/<feature>/tasks.md`; `project-manager` writes it: one Task
per unit that passed the gates, with owner, dependencies, inputs, acceptance and evidence.
Every scope gets this file, including an implementation detail, and no project turns it off
(`WF-SPEC-03`, `WF-SPEC-07`). A Task whose inputs are not accepted yet is listed, but it is
not ready (`WF-SPEC-04`); the file itself is `Ready` only on the owner's answer (`WF-SPEC-06`).

---

## Step 6 — Self-check before the handoff

| # | Check | Rule |
| --- | --- | --- |
| 1 | the decision behind this unit is resolved, not open | `WF-CORE-03` |
| 2 | if split into multiple units, each has independent acceptance/evidence/dependency | `WF-PLAN-03` |
| 3 | the owning perfil is named per unit, never "fullstack" | `WF-PLAN-05` |
| 4 | appetite is decided before any time estimate | `WF-PLAN-01` |
| 5 | acceptance criteria are written, not implicit | `WF-PLAN-04` |
| 6 | the evidence plan for validation is named | — |
| 7 | every contract shared between units has a real-output-against-real-validator test in its first consumer | `WF-PLAN-04` |
| 8 | each unit names the agent that implements it, and that agent is in hub §3 | `WF-CORE-06` |
| 9 | the `.specs/` files match the scope, each written by its own agent through `workflow-spec` | `WF-SPEC-01`, `WF-SPEC-03` |
| 10 | no spec file copies another; they link | `WF-SPEC-02` |
| 11 | every status that moved past `Draft` moved on the owner's answer | `WF-SPEC-06` |

---

## Step 7 — Hand off

Return the envelope from hub §5 (`pilar: planejamento`), with the `.specs/` paths in
`artefato`:

| Situation | Continue in |
| --- | --- |
| unit ready, boundary and acceptance named | `workflow-implementation` |
| a decision is missing after all | `workflow-research` |
| cronograma/risk spans multiple units | `project-manager` |
| boundary itself is disputed, not just which perfil owns it | `software-architect` |

**Spec-only run.** When the run was started as spec generation only (the `spec` command), stop
here: return the envelope and do not start `workflow-implementation` (`WF-SPEC-05`).

**Advance without asking.** Otherwise, when the first unit is ready and `lacunas` holds nothing
that only the owner can decide, start `workflow-implementation` on it now. Do not ask whether to
continue. Stop only for an owner decision or for an action that is irreversible or visible to others
(push, PR, deleting data).

**Reset the context at the boundary.** Each unit is implemented by the agent the boundary gate
named (`frontend-developer`, `backend-developer`, `devops-security`), started with only the unit
(acceptance, owner, evidence plan) and the decisions it depends on (`WF-CORE-06`). The planning
conversation does not travel with it
([`CC-CTX-01`, `CC-CTX-03`](../../../knowledge-base/claude-code-contexto-e-cache.md)).

---

## Example

*Resolved decision: "discounts above 50% require manager approval."* Appetite: small — one
route, one check, no new service, so no `design.md` and no ADR; `user-experience.md` for the approval prompt, then `tasks.md`. Boundary: `backend-developer` owns the validation rule;
`frontend-developer` owns the approval prompt — two units, because each has its own acceptance
criterion and can be verified independently. Acceptance for the backend unit: "a request with
`discount > 0.5` and no `approvedBy` field returns a 422." Evidence plan: one `bun test` case
per unit, no E2E needed — the rule is not a user journey (`test-design` decides the level).

---

## Related

- [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) — source of this skill, §4.2, §6
- `workflow-research` · `workflow-implementation` — the neighbors
- `workflow-spec` — writes every `.specs/` file of this pillar and records the owner's approval
- `project-manager` · `software-architect` — where cronograma/risk and boundary disputes go
