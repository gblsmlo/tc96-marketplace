# Spec template: Design

Tool-neutral, saved as `.specs/<feature>/design.md`. It is the feature's **technical design**:
boundaries, contracts and the decisions behind them. `software-architect` writes it in
`workflow-planning` when the scope is architecture, or when a product feature needs a boundary
or contract (`WF-SPEC-03`). Rules: `DOC-RFC-*` in
[Documentos de Decisão — PRD, RFC e ADR](../../../../knowledge-base/documentos-de-decisao-prd-rfc-adr.md).

It runs in one of two modes, declared in the header (`DOC-RFC-03`):

| Mode | When |
| --- | --- |
| `rfc` | there is a real alternative and the decision is still open |
| `design-doc` | there is no real alternative; the design only needs recording and review |

---

## Fields

| Field | Meaning |
| --- | --- |
| `feature` | the slug of `.specs/<feature>/` |
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
- `ID` or decidable test — how it's verified (lint, test, curl)
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

`workflow-planning` Step 4 turns each row into an acceptance criterion in `tasks.md`.

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
- Every decision that outlives the feature has its own ADR (`DOC-ADR-01`).

### Out of this file

| Belongs in | What |
| --- | --- |
| `requirements.md` | whether to build it, goals, non-goals |
| `user-experience.md` | flow, screen states, components, accessibility |
| `tasks.md` | the units, owners, appetite and evidence plan |
| the Task, decided by the implementer | where a file lives inside a feature, which library API |

---

## Related

- `../SKILL.md` (`workflow-spec`): the skill that writes this file as a draft and records the owner's approval

- `template-adr.md`: one per decision that outlives the feature
- `template-tasks.md`: the units this design is implemented by
- `software-architect`: the agent that writes this file
- [Fluxo de Entrega — Quatro Pilares](../../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5: where this file sits in `.specs/`
