# Spec template: Design

Tool-neutral, saved as `.specs/<capability>/design.md`. It is the capability's **technical design**:
boundaries, contracts and the decisions behind them. `software-architect` writes it in
`workflow-planning` when the scope is architecture, or when a product change needs a boundary
or contract (`WF-SPEC-03`). Rules: `DOC-RFC-*` in
[Documentos de Decisão — PRD, RFC e ADR](../../../../knowledge-base/documentos-de-decisao-prd-rfc-adr.md).

It runs in one of two modes, declared in the header (`DOC-RFC-03`):

| Mode | When |
| --- | --- |
| `rfc` | there is a real alternative and the decision is still open |
| `design-doc` | there is no real alternative; the design only needs recording and review |

---

## Amendments

Once this file is `Accepted`, its text is never rewritten. A later increment that changes it
returns to the pillar that owns the change and appends, at the end of the file,
`## Amendment NNN — YYYY-MM-DD — <one sentence>`, with its own `status` line starting at
`Draft` and its own open gaps (`WF-SPEC-08`). Only the owner's answer moves the amendment's
status (`WF-SPEC-06`).

## Fields

| Field | Meaning |
| --- | --- |
| `capability` | the slug of `.specs/<capability>/`: the Epic's `capability` field, or the slug the owner confirmed when no Epic exists yet (hub §5) |
| `mode` | `rfc` · `design-doc` |
| `owner` | `software-architect` |
| `decider` | `rfc` only: the person who closes the discussion (`DOC-RFC-02`) |
| `decision-by` | `rfc` only: the date the decision closes (`DOC-RFC-02`) |
| `status` | `Draft` · `In review` · `Accepted` · `Rejected`; born `Draft`, moves only on the owner's answer (`WF-SPEC-06`) |
| `requirements` | link to `requirements.md`, or the research envelope when there is none |

## Body (copy from here down)

---

### Summary

[Two or three sentences: what this design decides.]

### Context

[The problem in two sentences, linking `requirements.md` or the issue that prompted it. Facts
cite `file:line` from `repo-explorer`.]

### Proposal

```
## Decision: <one sentence>

**Axis that decided it:** <state ownership | boundary | contract | distribution | operating cost>
**Boundaries:** <which layer, package or service owns each responsibility>
**Contracts:** <API, schema, event: shape and owner of each>
**Verifiable invariants:**
- `ID` or decidable test — test type (static · unit · contract · integration · component · E2E) and how it's verified (lint, test, curl); an E2E says why no cheaper type proves it
**Cost introduced:** <indirection, types, operations>
**Migration:** <order of steps; what changes first and what stays>
```

This is the `software-architect` output format; the fields are not renamed here.

### Alternatives considered

| Alternative | Why it was discarded |
| --- | --- |
| [a real option] | [the reason] |

In `design-doc` mode, write "No real alternative" and say why (`DOC-RFC-03`).

### Shared contracts

| Contract | Producer unit | First consumer unit | Shape test |
| --- | --- | --- | --- |
| [...] | [...] | [...] | [the consumer's real output fed into the producer's real validator] |

`workflow-planning` Step 4 turns each row into an acceptance criterion in the plan (`tasks/NNNN-<slug>.md`).

### Open questions

- [what must be answered before `Accepted`, and who answers it]

### Decision

[Filled when the status leaves `In review`: what was decided, by whom, on what date, and the
ADRs it produced (`DOC-RFC-04`).]

- `ADR-NNNN`: [title], `.specs/adr/NNNN-<slug>.md`

### Done when

- The mode is declared, and in `rfc` mode the decider and the date are set.
- Every alternative is real, or the file says there is none.
- Every shared contract has a shape test named.
- Every verifiable invariant names its test type, at the cheapest level that proves it (`WF-PLAN-06`).
- Every decision that outlives the increment has its own ADR (`DOC-ADR-01`).

### Out of this file

| Belongs in | What |
| --- | --- |
| `requirements.md` | whether to build it, goals, non-goals |
| `user-experience.md` | flow, screen states, components, accessibility |
| `tasks/NNNN-<slug>.md` | the units, owners, appetite, evidence plan and test types |
| the Task, decided by the implementer | where a file lives inside a feature, which library API |

---

## Related

- `../SKILL.md` (`workflow-spec`): the skill that writes this file as a draft and records the owner's approval

- `template-adr.md`: one per decision that outlives the increment
- `template-tasks.md`: the units this design is implemented by
- `software-architect`: the agent that writes this file
- [Fluxo de Entrega — Quatro Pilares](../../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5: where this file sits in `.specs/`
