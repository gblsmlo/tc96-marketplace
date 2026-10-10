# Spec template: ADR

Tool-neutral, saved as `.specs/adr/NNNN-<slug>.md`. An ADR records **one** architecture
decision that outlives the increment that produced it (`DOC-ADR-01`). `software-architect` writes
it when a `design.md` reaches `Accepted`, or when a decision is made outside any capability. Rules:
`DOC-ADR-*` in [Documentos de Decisão — PRD, RFC e ADR](../../../referencias/documentos-de-decisao-prd-rfc-adr.md).

---

## Numbering

`NNNN` is the highest number in `.specs/adr/` plus one, zero-padded to four digits; the first
ADR is `0001`. The slug is the decision in kebab-case: `0003-keep-sessions-in-postgres.md`.
Other files cite it as `ADR-0003`.

## Superseding

An `Accepted` ADR is never edited (`DOC-ADR-02`). When the decision changes:

1. Write a new ADR, with `Supersedes: ADR-NNNN` in its header.
2. In the old ADR, change only the status line to `Superseded by ADR-NNNN`.
3. Keep the old file. Deleting it erases why the first decision was made.

## Body (copy from here down)

---

# NNNN. [The decision, in a short sentence]

- **Status:** Proposed · Accepted · Superseded by ADR-NNNN; born `Proposed`, `Accepted` only on the owner's answer (`WF-SPEC-06`)
- **Date:** [YYYY-MM-DD]
- **Origin:** [`.specs/<capability>/design.md`, or "none"]
- **Supersedes:** [ADR-NNNN, or "none"]

## Context

[The forces that made this decision necessary, in a few sentences. Facts cite `file:line`.]

## Decision

We will [the decision, in active voice].

**Axis that decided it:** [state ownership | boundary | contract | distribution | operating cost]

## Alternatives

| Alternative | Why it was discarded |
| --- | --- |
| [a real option] | [the reason] |

## Consequences

- **Gains:** [...]
- **Costs:** [indirection, types, operations, migration effort; this section is not optional
  (`DOC-ADR-04`)]
- **Verifiable invariants:** [`ID` or decidable test; the test type that proves it at the cheapest level (static · unit · contract · integration · component · E2E) and how it is run; an invariant that only an E2E proves says why (`WF-PLAN-06`, hub §4.2)]

---

## Related

- `../SKILL.md` (`workflow-spec`): the skill that writes this file as a draft and records the owner's approval

- `template-design.md`: the design that usually produces this record
- `software-architect`: the agent that writes it; its "Output format" is the source of the axis
  and invariants fields
- Michael Nygard's format (context, decision, status, consequences), cited in the note above
