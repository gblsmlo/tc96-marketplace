---
nome: workflow-implementation
descricao: Executes a ready work unit without reopening product decisions — confirms readiness, keeps scope to what the unit decided, preserves explicit contracts, and decides when to stop and return a pillar instead of deciding ad-hoc, citing `WF-IMPL-*` and `WF-CORE-*` IDs. Use once a unit has acceptance criteria and an owning perfil from `workflow-planning`. Do not use to decide what to build — that is `workflow-research` or `workflow-planning`. Do not use to prove the change is correct — that is `workflow-validation`.
tipo: skill
familia: workflow
idioma: en
fonte: "[Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md)"
tags:
  - skill
  - workflow
  - implementation
---

# workflow-implementation

> **Source of this skill:** [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md), §4.3 and the `WF-IMPL-*` / `WF-CORE-*` rules in §6.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and to whom to hand it off.

Contract this skill implements: [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §7.

> **Delegation, read first (`WF-CORE-06`, `WF-CORE-07`).** The unit runs in the agent planning
> named as its owner (`frontend-developer`, `backend-developer`, `devops-security`), called as a
> subagent. Never delegate to a generic agent. That agent commits its code — the diff is already
> in its context, so no other agent re-reads it (`WF-CORE-08`) — and returns the envelope with
> the commit or diff reference in `artefato`, not the code itself.
>
> **If your system prompt is not the owning agent's body, you are not that agent** — even when
> the brief says "as `backend-developer`". A session that loads this skill orchestrates: it
> starts the owner as a subagent with the unit, then runs validation and the PR, and writes no
> code itself. Writing it here runs the unit on the model this session inherited, without the
> agent's rules ([`CC-PAR-05`](../../../knowledge-base/claude-code-paralelismo-e-escala.md)).

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
| 1 | [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §4.3, and the edge table in §4.1 | the questions before the first line and the stop-and-return table — the core of this skill |
| 2 | Same hub, §6 `WF-CORE-*` and `WF-IMPL-*` | the 15 rules this skill enforces |
| 3 | Same hub, §5 "Lacunas" | how a return names who decides its gap and where it closes |

References in this skill:

| File | What for |
| --- | --- |
| `references/condicoes-de-parada.md` | the three stop conditions, each with a worked example (Steps 3 and 6) |

---

## Step 1 — Confirm readiness

The unit is one Task in the current plan, `.specs/<capability>/tasks/NNNN-<slug>.md`, and it
needs from `workflow-planning`: acceptance criterion, owning perfil, evidence plan and test
types (`WF-PLAN-06`). Missing any of these means this is not
actually a ready unit — return it (`WF-CORE-03`). The spec files the Task cites as inputs must be
accepted; one still in draft means the Task waits (`WF-SPEC-04`), and so does an open gap the
Task depends on (`WF-CORE-09`). Read only this Task and the sections it links, not the whole
`.specs/<capability>/` folder nor its earlier plans.

Start from a small context: a new instance of the owning agent, called as a subagent so its
`modelo` and `esforco` apply, holding the unit and not the conversation that produced it
(`WF-CORE-06`). Implementing inside a long session re-reads all of that history on every
request ([`CC-CTX-01`, `CC-CTX-03`](../../../knowledge-base/claude-code-contexto-e-cache.md)).

**Returning with validation findings.** The owning agent runs on its declared tier, and rises
only when that tier has already failed twice on this unit:

| Fix round | Who runs it | What it receives |
| --- | --- | --- |
| 1 and 2 | the same implementer, resumed, on its declared tier | only the findings |
| 3 | a new instance of the owning agent, one tier up (`medio` → `alto`), set as the `model` of the subagent call — a session cannot open another one tier up | the unit, its acceptance criteria, the findings still open |
| 4 | nobody: stop and return to `workflow-planning` | the envelope, with the open findings under `lacunas` — `decide: dono`, `fecha-em: planejamento`, because the appetite is blown |

Resuming is cheaper than re-reading the plan, but each resumed round adds to the implementer's
context. A unit that three rounds could not close is a planning problem, not a model problem:
the appetite is blown (`WF-PLAN-02`). The tier ladder and what it maps to per provider are in
`agents/README.md`, section "Model and effort per role".

---

## Step 2 — Read the owning code and its existing tests

Before writing anything, read what already exists in the area this unit touches — the
existing contract, the existing tests, the existing conventions of that layer.

---

## Step 3 — List the questions before the first line

`WF-IMPL-06`, hub §4.3. With the Task and the code it touches read, list what you would need to
know to write it: run the unit through the seven edge categories of hub §4.1 — boundary, time,
empty, repetition, permission, failure, what already exists — against this Task and this code.
Each question leaves one of three ways:

| The answer | Then |
| --- | --- |
| is in an accepted artifact | cite it (file and section) and go on |
| stays inside what this unit already decided — a name, a local structure, a library API | decide it here and go on |
| belongs to someone else's scope | stop before any code; return through Step 6, with the gap's `decide` and `fecha-em` (`WF-CORE-09`) |

When unsure between the last two, ask the distinguishing question in
`references/condicoes-de-parada.md`. The list stays in this agent's context; the orchestrating
conversation receives only the gaps, in the envelope (`WF-CORE-07`). A question found here
costs a return; the same question found mid-code costs the return plus the code already
written on a guessed answer.

---

## Step 4 — Write the test types the plan named, first

The level was decided in planning, with its cost in time and tokens in view (`WF-PLAN-06`,
hub §4.2); route to `test-design` only for the cases inside that level. Writing a more
expensive type than the plan named — an E2E where it named a unit test — is a return to
`workflow-planning`, not a choice made here. The test accompanies the change, not a step tacked
on after (`WF-IMPL-02`).

---

## Step 5 — Implement the smallest change that satisfies the unit

`WF-IMPL-03`. Adjacent problems noticed along the way, that this unit did not decide to fix,
stay noticed — not fixed here. Preserve explicit contracts (types, schemas, tenant/auth
boundaries) exactly as declared; do not silently reshape them and plan to "adjust callers
later" (`WF-IMPL-04`).

---

## Step 6 — Decide: fix here, or stop and return

`references/condicoes-de-parada.md`, hub §4.3. The same table answers the questions of Step 3
and whatever only the code reveals:

| Found before or during implementation | Action |
| --- | --- |
| missing or contradicted product behavior | stop, return to `workflow-research`, the gap with `fecha-em: pesquisa` |
| insufficient scope, dependency, or evidence plan in the unit | stop, return to `workflow-planning`, the gap with `fecha-em: planejamento` |
| a local defect inside what this unit already decided | fix here, record as evidence (`WF-IMPL-05`) — not a return |

---

## Step 7 — Self-check before the handoff

| # | Check | Rule |
| --- | --- | --- |
| 1 | no product decision was reopened or improvised here | `WF-IMPL-01` |
| 2 | a focused test exists for the change, written alongside it, of the types the plan named | `WF-IMPL-02`, `WF-PLAN-06` |
| 3 | the scope is the smallest that satisfies the unit's acceptance criterion | `WF-IMPL-03` |
| 4 | explicit contracts (types, schemas, boundaries) are preserved | `WF-IMPL-04` |
| 5 | any local defect fixed along the way is recorded as evidence | `WF-IMPL-05` |
| 6 | this pillar's output is code + evidence, not a claim of "done" | `WF-CORE-04` |
| 7 | the unit ran in its owning agent called as a subagent — not in a session playing the role — and the envelope references the commit or diff | `WF-CORE-06`, `WF-CORE-07`, `CC-PAR-05` |
| 8 | the questions were listed before the first line; each was cited, decided inside the unit, or returned with `decide` and `fecha-em` | `WF-IMPL-06`, `WF-CORE-09` |

---

## Step 8 — Hand off

Return the envelope from hub §5 (`pilar: implementacao`). This pillar always routes forward
to `workflow-validation` — it never marks work complete itself (`WF-CORE-04`).

**Advance without asking.** Start `workflow-validation` right away. Do not ask whether to
continue. Validation already runs in a context independent from this one (`WF-VAL-01`), so the
context reset is built in. If the owner gave an instruction during the work that departs from
the unit, record it under `decisoes` in the envelope, not only in chat. A product-level
departure returns to `workflow-research` instead (`WF-IMPL-01`).

---

## Example

Unit: "a request with `discount > 0.5` and no `approvedBy` returns 422." Before the first line,
the developer's list runs the edge categories against the Task: exactly 0.5 is answered by the
criterion itself (`> 0.5`); an `approvedBy` naming the requester is answered by a story
scenario — the sweep raised it in research, and the owner answered it there; the other
categories do not touch this check. Nothing leaves the unit, so it goes ahead. `test-design`
routes this to a unit test (a pure validation rule, not a journey). While implementing, the
developer notices the existing discount function also silently clamps negative discounts to
zero — a local defect, inside what this unit already touches, unrelated to the approval rule.
Per `WF-IMPL-05`, it gets fixed here and recorded as evidence, not escalated as a new unit.

---

## Related

- [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) — source of this skill, §4.3, §6
- `test-design` — where the test-level decision comes from
- `frontend-developer` · `backend-developer` — the perfis that carry out this pillar
- `workflow-validation` — always the next stop
