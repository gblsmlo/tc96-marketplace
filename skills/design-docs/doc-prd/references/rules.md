# Rules of the PRD

The rule text this skill enforces, copied here so the skill needs no other file. IDs match the
repository's notes (`DOC-*` from the decision-documents note, `SDD-*` from the delivery-flow
note), so a citation resolves either way. `DD-*` rules are the family's
[writing contract](../../docs/writing-contract.md).

## Contents

- Rules
- Lifecycle
- Limits in the input
- Amendment

---

## Rules

| ID | Rule |
| --- | --- |
| `DOC-CORE-01` | A document **MUST** answer a single question; a document that answers two is two documents. |
| `DOC-PRD-01` | The PRD **MUST** declare explicit non-goals (its Out of Scope); a vague one **NEVER**, it is the door to scope creep. |
| `DOC-PRD-02` | Every requirement **MUST** have a metric or a verifiable scenario; a requirement with no measure is a wish. |
| `DOC-PRD-03` | The PRD **NEVER** contains technical design (schema, API contract, service boundary); that goes to the delivery plan's layer files or an ADR. |
| `SDD-CORE-01` | The PRD **MUST** be the product's single source of truth: every capability and acceptance criterion **MUST** trace to it, and every layer's checks **MUST** trace to its acceptance criteria or to an ADR; work that traces to nothing **NEVER** enters a run. † |
| `SDD-CORE-03` | The PRD **MUST** be born `Draft` and change status only through the owner's explicit reply; the writer approving its own file, or silence counting as approval, **NEVER**. |
| `SDD-PRD-01` | The PRD **MUST** keep these sections, in order: Summary, Problem and Opportunity, Target Audience, Objectives, User Stories, Capabilities, Out of Scope, Traceability, Open gaps. † |
| `SDD-PRD-02` | Every capability **MUST** name the acceptance criteria it satisfies, and every acceptance criterion **MUST** belong to at least one capability; a capability with no criterion, or a criterion no capability holds, **NEVER**. † |
| `SDD-PRD-03` | Every acceptance criterion **MUST** carry a PRD-wide ID (`AC-NN`) and an observable outcome in Given / When / Then; a criterion with nothing to observe **NEVER** — no check can prove it (`DOC-PRD-02`). |
| `SDD-PRD-04` | The PRD **NEVER** carries a delivery cut — layers, order, waves, size, what one part provides another: that is the delivery plan's; a size problem found while planning **NEVER** comes back as an amendment. † |
| `SDD-PRD-05` | Every Problem and Opportunity item and every Objective **MUST** list the capabilities that address it, and every capability **MUST** appear under at least one; a capability traced to nothing, or a problem no capability addresses, **NEVER**. † |
| `SDD-PRD-06` | The PRD **NEVER** carries technical design (`DOC-PRD-03`); once `Approved` it **MUST** be frozen, and a change, including a new capability, enters as a dated amendment approved by the owner (`DOC-PRD-04`). |

† marks a decision of the delivery-flow note, with no direct parallel in a single external source.

## Lifecycle

`Draft` -> `In review` -> `Approved`. Free to change before approval. After `Approved`, only a
dated amendment.

## Limits in the input

The writer does not sweep for edges: finding them is the owner role's work, before the writer
runs. It only places every limit the input states — a number, a duration, a role, a count — so the
boundary is explicit:

| The input... | Where it goes |
| --- | --- |
| states the limit and its open side | an acceptance criterion |
| excludes it | an Out of Scope line |
| states the limit but not its open side (inclusive? which time zone? what after?) | the criterion, plus a gap with who decides |

## Amendment

Append at the end of an `Approved` file:

```
## Amendment NNN — YYYY-MM-DD — <one sentence>
status: Draft
<the change: new or changed AC-*, new or changed capabilities with the AC-* they satisfy and
their priority, the traceability rows it moves, and its own open gaps>
```

Only the owner's answer moves the amendment's status. The text above it is untouched. A new
capability takes the next free `CAP` number; an acceptance criterion takes the next free `AC`
number. A size or ordering problem found while planning never enters as an amendment: it is solved
inside the delivery plan (`SDD-PRD-04`).
