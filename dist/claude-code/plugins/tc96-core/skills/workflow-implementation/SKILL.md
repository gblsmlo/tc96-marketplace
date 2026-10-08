---
name: workflow-implementation
description: Executes a ready work unit without reopening product decisions — confirms readiness, keeps scope to what the unit decided, preserves explicit contracts, and decides when to stop and return a pillar instead of deciding ad-hoc, citing `WF-IMPL-*` and `WF-CORE-*` IDs. Use once a unit has acceptance criteria and an owning perfil from `workflow-planning`. Do not use to decide what to build — that is `workflow-research` or `workflow-planning`. Do not use to prove the change is correct — that is `workflow-validation`.
fonte: "[Fluxo de Entrega — Quatro Pilares](../../referencias/fluxo-de-entrega-quatro-pilares.md)"
tags:
  - skill
  - workflow
  - implementation
---

# workflow-implementation

> **Source of this skill:** [Fluxo de Entrega — Quatro Pilares](../../referencias/fluxo-de-entrega-quatro-pilares.md), §4.3 and the `WF-IMPL-*` / `WF-CORE-*` rules in §6.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and to whom to hand it off.

Contract this skill implements: [Fluxo de Entrega — Quatro Pilares](../../referencias/fluxo-de-entrega-quatro-pilares.md) §7.

> **Delegation, read first (`WF-CORE-06`, `WF-CORE-07`).** The unit runs in the agent planning
> named as its owner (`frontend-developer`, `backend-developer`, `devops-security`). Never
> delegate to a generic agent. That agent commits its code and returns the envelope with the
> commit or diff reference in `artefato`, not the code itself.

> **Design note.** This is the **third pillar**: it writes the code, but it does not write new
> decisions. The moment a product question surfaces mid-implementation, the correct move is to
> stop and return it — not to pick an answer that seems reasonable and keep going (`WF-IMPL-01`).
> This skill does not decide test level either — that is `test-design`, loaded from here.

---

## When to use

| Situation | Go to |
| --- | --- |
| the unit is not bounded yet — no acceptance criterion, no owner | `workflow-planning` |
| a product decision is missing or contradicted by what you find | `workflow-research` |
| the change is written and needs proof | `workflow-validation` |
| the question is "what level should this test be" | `test-design` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Fluxo de Entrega — Quatro Pilares](../../referencias/fluxo-de-entrega-quatro-pilares.md) §4.3 | the stop-and-return table — the core of this skill |
| 2 | Same hub, §6 `WF-CORE-*` and `WF-IMPL-*` | the 12 rules this skill enforces |

References in this skill:

| File | What for |
| --- | --- |
| `references/condicoes-de-parada.md` | the three stop conditions, each with a worked example |

---

## Step 1 — Confirm readiness

The unit is one Task in `.specs/<feature>/tasks.md`, and it needs from `workflow-planning`:
acceptance criterion, owning perfil, evidence plan. Missing any of these means this is not
actually a ready unit — return it (`WF-CORE-03`). The spec files the Task cites as inputs must be
accepted; one still in draft means the Task waits (`WF-SPEC-04`). Read only this Task and the
sections it links, not the whole `.specs/<feature>/` folder.

Start from a small context: a new instance of the owning agent, holding the unit and not the
conversation that produced it (`WF-CORE-06`). Implementing inside a long session re-reads all
of that history on every request
([`CC-CTX-01`, `CC-CTX-03`](../../referencias/claude-code-contexto-e-cache.md)).

**Returning with validation findings.** The owning agent runs on its declared tier, and rises
only when that tier has already failed twice on this unit:

| Fix round | Who runs it | What it receives |
| --- | --- | --- |
| 1 and 2 | the same implementer, resumed, on its declared tier | only the findings |
| 3 | a new instance of the owning agent, one tier up (`medio` → `alto`) | the unit, its acceptance criteria, the findings still open |
| 4 | nobody: stop and return to `workflow-planning` | the envelope, with the open findings under `lacunas` |

Resuming is cheaper than re-reading the plan, but each resumed round adds to the implementer's
context. A unit that three rounds could not close is a planning problem, not a model problem:
the appetite is blown (`WF-PLAN-02`). The tier ladder and what it maps to per provider are in
`agents/README.md`, section "Model and effort per role".

---

## Step 2 — Read the owning code and its existing tests

Before writing anything, read what already exists in the area this unit touches — the
existing contract, the existing tests, the existing conventions of that layer.

---

## Step 3 — Decide test level, then write the focused test first

Route to `test-design` for "what level, what cases" if that is not already obvious. The test
accompanies the change, not a step tacked on after (`WF-IMPL-02`).

---

## Step 4 — Implement the smallest change that satisfies the unit

`WF-IMPL-03`. Adjacent problems noticed along the way, that this unit did not decide to fix,
stay noticed — not fixed here. Preserve explicit contracts (types, schemas, tenant/auth
boundaries) exactly as declared; do not silently reshape them and plan to "adjust callers
later" (`WF-IMPL-04`).

---

## Step 5 — Decide: fix here, or stop and return

`references/condicoes-de-parada.md`, hub §4.3:

| Found during implementation | Action |
| --- | --- |
| missing or contradicted product behavior | stop, return to `workflow-research` |
| insufficient scope, dependency, or evidence plan in the unit | stop, return to `workflow-planning` |
| a local defect inside what this unit already decided | fix here, record as evidence (`WF-IMPL-05`) — not a return |

---

## Step 6 — Self-check before the handoff

| # | Check | Rule |
| --- | --- | --- |
| 1 | no product decision was reopened or improvised here | `WF-IMPL-01` |
| 2 | a focused test exists for the change, written alongside it | `WF-IMPL-02` |
| 3 | the scope is the smallest that satisfies the unit's acceptance criterion | `WF-IMPL-03` |
| 4 | explicit contracts (types, schemas, boundaries) are preserved | `WF-IMPL-04` |
| 5 | any local defect fixed along the way is recorded as evidence | `WF-IMPL-05` |
| 6 | this pillar's output is code + evidence, not a claim of "done" | `WF-CORE-04` |
| 7 | the unit ran in its owning agent, and the envelope references the commit or diff | `WF-CORE-06`, `WF-CORE-07` |

---

## Step 7 — Hand off

Return the envelope from hub §5 (`pilar: implementacao`). This pillar always routes forward
to `workflow-validation` — it never marks work complete itself (`WF-CORE-04`).

**Advance without asking.** Start `workflow-validation` right away. Do not ask whether to
continue. Validation already runs in a context independent from this one (`WF-VAL-01`), so the
context reset is built in. If the owner gave an instruction during the work that departs from
the unit, record it under `decisoes` in the envelope, not only in chat. A product-level
departure returns to `workflow-research` instead (`WF-IMPL-01`).

---

## Example

Unit: "a request with `discount > 0.5` and no `approvedBy` returns 422." `test-design` routes
this to a unit test (a pure validation rule, not a journey). While implementing, the developer
notices the existing discount function also silently clamps negative discounts to zero — a
local defect, inside what this unit already touches, unrelated to the approval rule. Per
`WF-IMPL-05`, it gets fixed here and recorded as evidence, not escalated as a new unit.

---

## Related

- [Fluxo de Entrega — Quatro Pilares](../../referencias/fluxo-de-entrega-quatro-pilares.md) — source of this skill, §4.3, §6
- `test-design` — where the test-level decision comes from
- `frontend-developer` · `backend-developer` — the perfis that carry out this pillar
- `workflow-validation` — always the next stop
