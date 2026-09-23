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

> **Design note.** This is the **second pillar**: it turns an already-accepted decision into a unit someone can implement without reopening product questions. It never writes a plan file into the repository or invents the decision itself — if the decision is not there yet, that is a return to `workflow-research`, not something to improvise here.

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
| 3 | Same hub, §6 `WF-CORE-*` and `WF-PLAN-*` | the 10 rules this skill enforces |

References in this skill:

| File | What for |
| --- | --- |
| `references/portoes.md` | the five gates, one worked check each |
| `references/apetite-e-corte.md` | appetite and circuit breaker, with a worked example |

---

## Step 1 — Confirm the decision is actually resolved

If the task arrives here still carrying an open product or architecture question, it skipped
a pillar. Return it to `workflow-research` before doing anything else (`WF-CORE-03`).

---

## Step 2 — Pass the five gates

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

## Step 3 — Name what evidence will prove this unit is done

Decide now, not at validation time, what focused checks and what evidence this unit's
completion will require — the next pillar inherits this plan, it does not invent one.

---

## Step 4 — Self-check before the handoff

| # | Check | Rule |
| --- | --- | --- |
| 1 | the decision behind this unit is resolved, not open | `WF-CORE-03` |
| 2 | if split into multiple units, each has independent acceptance/evidence/dependency | `WF-PLAN-03` |
| 3 | the owning perfil is named per unit, never "fullstack" | `WF-PLAN-05` |
| 4 | appetite is decided before any time estimate | `WF-PLAN-01` |
| 5 | acceptance criteria are written, not implicit | `WF-PLAN-04` |
| 6 | the evidence plan for validation is named | — |

---

## Step 5 — Hand off

Return the envelope from hub §5 (`pilar: planejamento`):

| Situation | Continue in |
| --- | --- |
| unit ready, boundary and acceptance named | `workflow-implementation` |
| a decision is missing after all | `workflow-research` |
| cronograma/risk spans multiple units | `project-manager` |
| boundary itself is disputed, not just which perfil owns it | `software-architect` |

---

## Example

*Resolved decision: "discounts above 50% require manager approval."* Appetite: small — one
route, one check, no new service. Boundary: `backend-developer` owns the validation rule;
`frontend-developer` owns the approval prompt — two units, because each has its own acceptance
criterion and can be verified independently. Acceptance for the backend unit: "a request with
`discount > 0.5` and no `approvedBy` field returns a 422." Evidence plan: one `bun test` case
per unit, no E2E needed — the rule is not a user journey (`test-design` decides the level).

---

## Related

- [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) — source of this skill, §4.2, §6
- `workflow-research` · `workflow-implementation` — the neighbors
- `project-manager` · `software-architect` — where cronograma/risk and boundary disputes go
