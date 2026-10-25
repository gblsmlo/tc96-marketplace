# Rules of the ADR

The rule text this skill enforces, copied here so the skill needs no other file. IDs match the
repository's notes (`DOC-*` from the decision-documents note, `SDD-*` from the delivery-flow
note), so a citation resolves either way.

## Contents

- Rules
- Lifecycle
- Numbering and location
- Superseding

---

## Rules

| ID | Rule |
| --- | --- |
| `DOC-CORE-01` | A document **MUST** answer a single question; a document that answers two is two documents. |
| `DOC-CORE-02` | The number of documents **MUST** be proportional to the cost of getting the decision wrong; opening one for a change with no real trade-off **NEVER**. |
| `DOC-ADR-01` | An ADR **MUST** record a single decision; three choices are three ADRs. |
| `DOC-ADR-02` | An `Accepted` ADR is **NEVER** edited; a decision that changes **MUST** become a new ADR, and the old one receives only `Superseded by ADR-NNNN` in its status. |
| `DOC-ADR-03` | An ADR **MUST** live in the code repository, in `.specs/adr/NNNN-<slug>.md`, numbered in sequence with four digits; an ADR in a wiki **NEVER**. |
| `DOC-ADR-04` | An ADR **MUST** record the consequences, cost included, and the discarded alternatives; recording only the gain **NEVER**. |
| `SDD-CORE-03` | The file **MUST** be born `Proposed` and change status only through the owner's explicit reply in the conversation; the writer accepting its own ADR, or silence counting as approval, **NEVER**. |

## Lifecycle

`Proposed` -> `Accepted` -> `Superseded by ADR-NNNN`. Free to change while `Proposed`; after
`Accepted`, never. The new decision is another ADR.

## Numbering and location

`NNNN` is the highest number in `.specs/adr/` plus one, zero-padded to four digits; the first
is `0001`. The slug is the decision in kebab-case. Other documents cite it as `ADR-0003`. There
is one ADR folder per repository, not per feature.

## Superseding

1. Write a new ADR with `Supersedes: ADR-NNNN` in its header.
2. In the old ADR, change only the status line to `Superseded by ADR-NNNN`.
3. Keep the old file.
