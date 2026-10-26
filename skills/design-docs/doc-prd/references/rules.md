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
| `DOC-PRD-03` | The PRD **NEVER** contains technical design (schema, API contract, service boundary); that goes to a feature's `spec.md` or an ADR. |
| `SDD-CORE-01` | The PRD **MUST** be the product's single source of truth: every feature, acceptance criterion and dependency traces to it. |
| `SDD-CORE-03` | The PRD **MUST** be born `Draft` and change status only through the owner's explicit reply; the writer approving its own file, or silence counting as approval, **NEVER**. |
| `SDD-PRD-01` | The PRD **MUST** keep these sections, in order: Summary, Problem and Opportunity, Target Audience, Objectives, User Stories, Functionalities, Out of Scope, Dependency Graph (Foundation Features, Execution Waves, Priority levels), Traceability, Open gaps. |
| `SDD-PRD-02` | Every feature **MUST** declare what it provides and what it consumes, and every consumed item **MUST** name exactly one provider feature; a consumer with no provider, or two providers of one item, **NEVER**. |
| `SDD-PRD-03` | Every acceptance criterion **MUST** carry a PRD-wide ID (`AC-NN`) and an observable outcome in Given / When / Then; a criterion with nothing to observe **NEVER**, no contract can prove it. |
| `SDD-PRD-04` | The Dependency Graph **MUST** list the foundation features and the execution waves, wave `Wn` holding only features whose providers sit in earlier waves; a cycle **NEVER**, it is broken by extracting the shared part into its own provider feature. |
| `SDD-PRD-05` | Every Problem and Opportunity item and every Objective **MUST** list the features that address it, each as provider or consumer, and every feature **MUST** appear under at least one; a feature traced to nothing, or a problem no feature addresses, **NEVER**. |
| `SDD-PRD-06` | Once `Approved`, the PRD **MUST** be frozen; a change, including a new feature, enters as a dated amendment approved by the owner; rewriting approved text or editing silently **NEVER**. |

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
<the change: new or changed AC-*, new features with satisfies / provides / consumes,
the waves and traceability rows it moves, and its own open gaps>
```

Only the owner's answer moves the amendment's status. The text above it is untouched. A new
feature takes the next free `F` number; an acceptance criterion takes the next free `AC` number.
