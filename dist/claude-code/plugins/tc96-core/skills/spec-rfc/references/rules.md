# Rules of the RFC and design doc

The rule text this skill enforces, copied here so the skill needs no other file. IDs match the
repository's notes (`DOC-*` from the decision-documents note, `WF-*` from the delivery-flow
note), so a citation resolves either way.

## Contents

- Rules
- Lifecycle
- Test types and their cost
- Amendment

---

## Rules

| ID | Rule |
| --- | --- |
| `DOC-CORE-01` | A document **MUST** answer a single question; a document that answers two is two documents. |
| `DOC-CORE-02` | The number of documents **MUST** be proportional to the cost of getting the decision wrong; opening one for a change with no real trade-off **NEVER**. |
| `DOC-RFC-01` | An RFC **MUST** open only for a decision not yet made; an RFC to approve what is already built **NEVER**, the record is an ADR. |
| `DOC-RFC-02` | An RFC **MUST** have an owner who decides and a decision date; an RFC with no deadline **NEVER**, it blocks the work that waits on it. |
| `DOC-RFC-03` | An alternative in an RFC **MUST** be real, with the reason it was discarded; a straw-man alternative **NEVER**. With no real alternative, the document **MUST** declare itself a design doc. |
| `DOC-RFC-04` | A resolved RFC **MUST** record the decision and list the ADRs it produced. |
| `WF-SPEC-06` | The file **MUST** be born `Draft` and change status only through the owner's explicit reply in the conversation; the writer accepting its own file, or silence counting as approval, **NEVER**. |
| `WF-SPEC-08` | Accepted text **MUST NOT** be rewritten; a change enters as a dated amendment, born `Draft`. |

## Lifecycle

`Draft` -> `In review` -> `Accepted` | `Rejected`. Revised freely during the comment period;
closes on the decision date, with the owner deciding. After `Accepted`, only an amendment; a
decision that outlives the increment becomes an ADR.

## Test types and their cost

Each verifiable invariant names the type that proves it, at the cheapest level that still
catches the defect. For an agent, the cost is time and tokens, and both repeat on every fix
round. The values are a relative order, not a measurement.

| Type | Catches | Time | Agent tokens | Needs running |
| --- | --- | --- | --- | --- |
| static (types, lint) | type error, import, lint rule | low | low | nothing |
| unit | rule, calculation, parsing, domain invariant | low | low | nothing |
| contract | the shape of what crosses a boundary | low | low to medium | the server, for a `curl` |
| integration | my pieces talking to a real dependency | medium | medium | local database or service |
| component | a component's visual state and interaction | medium | medium | Storybook |
| E2E | the critical journey end to end | high | high | app, browser, session |
| manual | what no check automates | n/a | n/a | person, date and environment recorded |

What fixes the cost is the boundary, chosen before the test: a rule in the backend is proved
by a unit test and a `curl`; the same rule spread across the interface can only be proved by
E2E.

## Amendment

Append at the end of an `Accepted` file:

```
## Amendment NNN — YYYY-MM-DD — <one sentence>
status: Draft
<the change, and its own open questions>
```

Only the owner's answer moves the amendment's status. The text above it is untouched.
