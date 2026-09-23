---
nome: workflow-research
descricao: Decide whether a task's intent is actually resolved yet — separates fact, hypothesis, decision and gap, classifies whether a change is product, architecture, or implementation detail, and routes to the agent that owns that decision, citing `WF-RES-*` and `WF-CORE-*` IDs. Use when a task arrives ambiguous, when "implement X" carries an undecided product or architecture question, or when you need to know whether a decision is safe to proceed on. Do not use once the decision is already made and accepted — that is `workflow-planning`. Do not use to write the fix for a bug already understood — that is `workflow-implementation`.
tipo: skill
familia: workflow
idioma: en
fonte: "[Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md)"
tags:
  - skill
  - workflow
  - research
  - discovery
---

# workflow-research

> **Source of this skill:** [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md), §4.1 and the `WF-RES-*` / `WF-CORE-*` rules in §6.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and to whom to hand it off.

Contract this skill implements: [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §7.

> **Design note.** This is the **first pillar**: it decides *whether the intent is resolved*, never the intent itself. It does not write product spec, does not design the flow, does not decide architecture — those stay with `product-manager`, `product-designer`, `software-architect`. Skipping this pillar and going straight to implementation with an open decision is the most expensive antipattern this family exists to catch (`WF-CORE-03`).

---

## When to use

| Situation | Go to |
| --- | --- |
| the intent is already accepted, work needs to become executable | `workflow-planning` |
| the bug or change is already understood, no open product question | `workflow-implementation` |
| the question is "how should this work for the user" | `product-designer` |
| the question is "is this worth building, what to prioritize" | `product-manager` |
| the question is "where should this live, does this cross a boundary" | `software-architect` |
| there is already code and the question is "is it correct" | `code-reviewer` — that is `workflow-validation`, not research |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §0, §2 | the pillar × role distinction, the four-pillar table |
| 2 | Same hub, §4.1 | the scope decision tree — the core of this skill |
| 3 | Same hub, §6 `WF-CORE-*` and `WF-RES-*` | the 10 rules this skill enforces |

**Never load §4.2–§4.4** (planning gates, implementation stop conditions, validation
proportionality) — those belong to the sibling skills, loaded only when the handoff reaches
them.

References in this skill:

| File | What for |
| --- | --- |
| `references/separar-fato-hipotese-decisao.md` | the technique and a worked example (Step 2) |
| `references/classificar-escopo.md` | the product/architecture/detail tree, expanded with examples (Step 3) |

---

## Step 1 — State the problem and the outcome, in one sentence

If you cannot write "the problem is X, and a resolved decision looks like Y" in one sentence,
the task is not ready for this pillar either — it needs a person to state what they actually
want first.

---

## Step 2 — Separate fact, hypothesis, decision, and gap

`references/separar-fato-hipotese-decisao.md`. Read the existing code, tests, tickets, and
prior decisions. Sort everything you find into exactly one of these four buckets — never leave
an item unsorted (`WF-RES-01`).

Existing code is evidence of the **present**, never authority over the **intent** — the
current behavior may itself be the defect (`WF-RES-02`).

---

## Step 3 — Classify the scope

`references/classificar-escopo.md`, or hub §4.1:

```
Does the change alter what the product does or promises?
├── yes → PRODUCT scope → product-manager decides, product-designer designs the flow
└── no
    Does it move where a responsibility lives, or introduce a new service boundary?
    ├── yes → ARCHITECTURE scope → software-architect decides
    └── no → IMPLEMENTATION DETAIL → go straight to workflow-planning
```

The most expensive misclassification is treating a product change as a detail — it arrives at
Implementation with no one having decided whether the product should change at all (`WF-RES-05`).

---

## Step 4 — Resolve the smallest decision that unblocks Planning

Do not produce a broad report. A research pass that returns more open questions than the one
decision Planning needed does not count as finished output for this pillar (`WF-RES-03`).

Every claim about user behavior **must** carry a source — data, an interview, code, a ticket.
Team opinion about the user, without that source, never substitutes for research (`WF-RES-04`).

---

## Step 5 — Self-check before the handoff

| # | Check | Rule |
| --- | --- | --- |
| 1 | the problem + outcome sentence exists | — |
| 2 | facts, hypotheses, decisions, and gaps are sorted, not mixed | `WF-RES-01` |
| 3 | code was treated as evidence of the present, not authority over intent | `WF-RES-02` |
| 4 | the scope (product / architecture / detail) is classified | `WF-RES-05` |
| 5 | every user-behavior claim has a source | `WF-RES-04` |
| 6 | the output is a decision, not just a report | `WF-RES-03` |
| 7 | remaining gaps are declared explicitly, not implied | `WF-CORE-05` |

---

## Step 6 — Hand off

Return the envelope from hub §5 (`pilar: pesquisa`), and route by scope:

| Scope | Continue in |
| --- | --- |
| product | `product-manager` |
| user flow / UX | `product-designer` |
| architecture | `software-architect` |
| implementation detail, decision resolved | `workflow-planning` |

**Hand the decision over with it:** the one-sentence problem, the scope classification, and
what stays an open gap. The next pillar does not reopen this classification without new
evidence.

---

## Example

*"Users report the checkout discount is sometimes wrong."* The sentence: "a discount above
50% is being applied without approval, and no one decided whether that should require one."
That is a **product** question — does the rule need approval above a threshold — not a bug to
patch silently. Routes to `product-manager` to resolve the rule, before `workflow-planning`
sizes the fix.

Full case: `references/separar-fato-hipotese-decisao.md`.

---

## Related

- [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) — source of this skill, §4.1, §6
- `workflow-planning` — where the resolved decision goes next
- `product-manager` · `product-designer` · `software-architect` — where the scope-specific decision goes
