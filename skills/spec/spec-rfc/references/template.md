# Template: RFC / design doc

Tool-neutral, saved as `.specs/<capability>/design.md`. The capability's **technical design**:
boundaries, contracts and the decisions behind them. Written by `software-architect`. Rules:
`rules.md` in this folder.

## Fields

| Field | Meaning |
| --- | --- |
| `capability` | the slug of `.specs/<capability>/` |
| `mode` | `rfc` · `design-doc` |
| `owner` | `software-architect` |
| `decider` | `rfc` only: the person who closes the discussion |
| `decision-by` | `rfc` only: the date the decision closes |
| `status` | `Draft` · `In review` · `Accepted` · `Rejected`; born `Draft`, moves only on the owner's answer |
| `requirements` | link to the PRD, or the research that prompted this, when there is no PRD |

## Body (copy from here down)

---

### Summary

[Two or three sentences: what this design decides.]

### Context

[The problem in two sentences, linking the PRD or the issue that prompted it. Facts cite
`file:line`.]

### Proposal

```
## Decision: <one sentence>

**Axis that decided it:** <state ownership | boundary | contract | distribution | operating cost>
**Boundaries:** <which layer, package or service owns each responsibility>
**Contracts:** <API, schema, event: shape and owner of each>
**Verifiable invariants:**
- `ID` or decidable test — test type (static · unit · contract · integration · component · E2E) and how it is verified (lint, test, curl); an E2E says why no cheaper type proves it
**Cost introduced:** <indirection, types, operations>
**Migration:** <order of steps; what changes first and what stays>
```

### Alternatives considered

| Alternative | Why it was discarded |
| --- | --- |
| [a real option] | [the reason] |

In `design-doc` mode, write "No real alternative" and say why.

### Shared contracts

| Contract | Producer unit | First consumer unit | Shape test |
| --- | --- | --- | --- |
| [...] | [...] | [...] | [the consumer's real output fed into the producer's real validator] |

### Open questions

- [what must be answered before `Accepted` — decided by: owner or a role — must close before:
  acceptance of this file, or the task plan]

### Decision

[Filled when the status leaves `In review`: what was decided, by whom, on what date, and the
ADRs it produced.]

- `ADR-NNNN`: [title], `.specs/adr/NNNN-<slug>.md`

### Done when

- The mode is declared, and in `rfc` mode the decider and the date are set.
- Every alternative is real, or the file says there is none.
- Every shared contract has a shape test named.
- Every verifiable invariant names its test type, at the cheapest level that proves it.
- Every decision that outlives the increment has its own ADR.

### Out of this file

| Belongs in | What |
| --- | --- |
| the PRD | whether to build it, goals, non-goals |
| a user-experience doc | flow, screen states, components, accessibility |
| a task plan | the units, owners, evidence plan and test types |
| the Task, decided by the implementer | where a file lives inside a feature, which library API |
