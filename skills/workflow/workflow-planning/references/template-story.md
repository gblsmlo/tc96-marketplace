# Work-item template — Story

Tool-neutral, sibling of `template-epic.md`. Story is the **acceptance unit** — what a role
can do, and why, with scenarios a test can execute. It satisfies the acceptance gate
(`WF-PLAN-04`): a Story without a written, checkable criterion is not ready.

---

## Fields

| Field | Meaning |
| --- | --- |
| `id` | this item's identifier |
| `parent` | the Epic this Story belongs to — a Story with no parent is an orphan: outside the backlog until linked, a divergence to resolve, never a case to guess at |
| `capability` | inherited from the parent Epic |
| `milestone` | optional roadmap block, when this Story is part of a planned cycle |
| `title` | `<what this delivers, verb-first> [STORY-<capability>-NNN]` |

## Body (copy from here down)

---

As a [role], I want [action, domain verb], so that [outcome for the business or the person].

### Context

[Two to four sentences: what already exists, what this action changes, who can perform it. No
rule ID here — that belongs to the scenarios below.]

### Acceptance scenarios

1. Given [a starting situation reachable in a real environment], when [the person's action],
   then [what they see or stop seeing]. ([the rule ID this scenario exercises])
2. [...]

[Three to eight scenarios. Cover the main path, a refusal, who cannot do it, and what changes
when the data changes. A scenario describes a situation and an observable result — it never
restates the rule's own text.]

### Done when

- Every Task linked to this Story is complete.
- The scenarios above are covered by an executable test, green, reviewed, with the run linked
  as evidence. No scenario is accepted by hand-checking (`WF-VAL-02`, proportional evidence —
  for a Story, "proportional" means the scenarios themselves, executed).
- The cited rules are covered by a test in the repository.

No automation closes a Story just because its Tasks closed — the scenarios are the actual
gate, checked independently (`WF-VAL-01`).

### Tasks

[Filled by whoever implements: the Task items that cite this Story, and what shipped each
one.]

### Origin

[The research, decision record, or Epic this Story decomposes from.]

---

## Related

- `template-epic.md` — the parent this Story belongs to
- `template-task.md` — the children this Story decomposes into
- [Fluxo de Entrega — Quatro Pilares](../../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §4.2 — the acceptance gate this template satisfies
- Reference model: lemind `docs/product/templates/story.md`
