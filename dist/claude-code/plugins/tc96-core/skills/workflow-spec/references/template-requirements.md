# Spec template: Requirements

Tool-neutral, saved as `.specs/<capability>/requirements.md`. It is the capability's **PRD**: what is
being built and why, before any design or code. `product-manager` writes it at the end of
`workflow-research`, only when the scope is product (`WF-SPEC-03`). Rules: `DOC-PRD-*` in
[Documentos de Decisão — PRD, RFC e ADR](../../../referencias/documentos-de-decisao-prd-rfc-adr.md).

---

## Amendments

Once this file is `Approved`, its text is never rewritten. A later increment that changes it
returns to the pillar that owns the change and appends, at the end of the file,
`## Amendment NNN — YYYY-MM-DD — <one sentence>`, with its own `status` line starting at
`Draft` and its own open gaps (`WF-SPEC-08`). Only the owner's answer moves the amendment's
status (`WF-SPEC-06`).

## Fields

| Field | Meaning |
| --- | --- |
| `capability` | the slug of `.specs/<capability>/`: the Epic's `capability` field, or the slug the owner confirmed when no Epic exists yet (hub §5) |
| `owner` | `product-manager` |
| `status` | `Draft` · `In review` · `Approved`; once `Approved` it is frozen, and a change returns to `workflow-research` as an amendment (`DOC-PRD-04`, `WF-SPEC-08`) |
| `scope` | `product`, from the classification in hub §4.1 (`WF-RES-05`) |

## Body (copy from here down)

---

### Problem

[One sentence: "the problem is X, and a resolved decision looks like Y." Then the evidence,
each item with its source: data, interview, ticket, code (`WF-RES-04`).]

### What we know

| Kind | Item | Source |
| --- | --- | --- |
| fact | [...] | [...] |
| hypothesis | [...] | [...] |
| decision | [...] | [who decided, when] |
| gap | [...] | — |

Every item sits in exactly one row kind (`WF-RES-01`). Existing code is evidence of the
present, never authority over the intent (`WF-RES-02`).

### Goals

| Goal | Metric | Target |
| --- | --- | --- |
| [...] | [...] | [...] |

A goal with no metric is a wish, not a requirement (`DOC-PRD-02`).

### Non-goals

- [what someone might expect from this capability and is deliberately left out, and why
  (`DOC-PRD-01`)]

### Stories

One entry per story, in the shape of `template-story.md`:
role, action, outcome, and three to eight acceptance scenarios in Given / When / Then.
Priority per story: Must · Should · Could. Every rule and scenario of a story goes through the
edge sweep (hub §4.1, `WF-RES-06`): each edge that applies becomes one of its scenarios, a
non-goal, or an open gap.

1. **[STORY-<capability>-NNN] [title]** (Must)
   As a [role], I want [action], so that [outcome].
   1. Given [...], when [...], then [...].

### Constraints and assumptions

- [constraint or assumption, marked as such, with what would invalidate it. A gap the owner
  accepted as an assumption, to proceed without an answer, comes here with the owner's words
  (hub §5 "Lacunas", `WF-CORE-09`).]

### Open gaps

- [the question in one sentence — decides: `dono` or the agent — closes in: `pesquisa`. Only
  gaps that close in research live here, and an empty list is a precondition for `Approved`.
  A question whose answer only changes how the work is designed, split or proved goes to the
  envelope with `fecha-em: planejamento` (`WF-CORE-09`).]

### Done when

- The problem sentence exists and every claim has a source.
- Every goal has a metric; every story has scenarios.
- Every story's edges were swept: each one that applies is a scenario, a non-goal or an open
  gap (`WF-RES-06`).
- Non-goals are written, not implied.
- Open gaps is empty, and the status is `Approved`.

### Out of this file

| Belongs in | What |
| --- | --- |
| `design.md` | schema, API contract, service boundary (`DOC-PRD-03`) |
| `user-experience.md` | flow, screen states, accessibility |
| `tasks/NNNN-<slug>.md` | who implements what, appetite, evidence plan, test types |

---

## Related

- `../SKILL.md` (`workflow-spec`): the skill that writes this file as a draft and records the owner's approval

- `workflow-research`: the skill whose output this file is
- `product-manager`: the agent that writes it; its "Writing a spec / PRD" step is the source of
  these sections
- `template-story.md`: the shape of each story
- [Fluxo de Entrega — Quatro Pilares](../../../referencias/fluxo-de-entrega-quatro-pilares.md) §5: where this file sits in `.specs/`
