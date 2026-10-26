# Template: ADR

Tool-neutral, saved as `.specs/adr/NNNN-<slug>.md`. An ADR records **one** architecture
decision that outlives the increment that produced it. Written by `doc-adr` from a decision `software-architect` or the team already made. Rules:
`rules.md` in this folder (numbering and superseding are there).

## Body (copy from here down)

---

# NNNN. [The decision, in a short sentence]

- **Status:** Proposed · Accepted · Superseded by ADR-NNNN; born `Proposed`, `Accepted` only on the owner's answer
- **Date:** [YYYY-MM-DD]
- **Origin:** [the design doc or RFC that produced it, or "none"]
- **Supersedes:** [ADR-NNNN, or "none"]

## Context

[The forces that made this decision necessary, in a few sentences, from the input. A `file:line` only when the input gives it.]

## Decision

We will [the decision, in active voice].

**Axis that decided it:** [state ownership | boundary | contract | distribution | operating cost]

## Alternatives

| Alternative | Why it was discarded |
| --- | --- |
| [a real option] | [the reason] |

## Consequences

- **Gains:** [...]
- **Costs:** [indirection, types, operations, migration effort; this section is not optional]
- **Verifiable invariants:** [`ID` or decidable test; the test type that proves it at the cheapest level (static · unit · contract · integration · component · E2E) and how it is run; an invariant that only an E2E proves says why]

## Open questions

- [GAP: the question — decides: who. Delete this section when there is none.]
