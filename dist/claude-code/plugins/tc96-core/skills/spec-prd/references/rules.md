# Rules of the PRD

The rule text this skill enforces, copied here so the skill needs no other file. IDs match the
repository's notes (`DOC-*` from the decision-documents note, `WF-*` from the delivery-flow
note), so a citation resolves either way.

## Contents

- Rules
- Lifecycle
- Edge sweep
- Amendment

---

## Rules

| ID | Rule |
| --- | --- |
| `DOC-CORE-01` | A document **MUST** answer a single question; a document that answers two is two documents. |
| `DOC-CORE-02` | The number of documents **MUST** be proportional to the cost of getting the decision wrong; opening one for a change with no real trade-off **NEVER**. |
| `DOC-PRD-01` | The PRD **MUST** declare explicit non-goals; a vague non-goal **NEVER**, it is the door to scope creep. |
| `DOC-PRD-02` | Every requirement **MUST** have a metric or a verifiable scenario; a requirement with no measure is a wish, not a requirement. |
| `DOC-PRD-03` | The PRD **NEVER** contains technical design (schema, API contract, service boundary); that goes to an RFC, design doc or ADR. |
| `DOC-PRD-04` | An `Approved` PRD **MUST** be frozen; a later change enters as a dated amendment at the end of the file, approved by the owner; rewriting approved text or editing silently **NEVER**. |
| `WF-RES-04` | Every claim about user behavior **MUST** carry a source (data, interview, code, ticket); the team's opinion about the user, without a source, is a hypothesis and **MUST** be labeled as one. |
| `WF-SPEC-06` | The PRD **MUST** be born `Draft` and change status only through the owner's explicit reply in the conversation; the writer approving its own file, or silence counting as approval, **NEVER**. |

## Lifecycle

`Draft` -> `In review` -> `Approved`. Free to change during discovery. After `Approved`, only a
dated amendment.

## Edge sweep

Before asking for approval, run each rule and each acceptance scenario through seven
categories. A category that does not apply leaves no trace.

| Category | The question that tends to slip through |
| --- | --- |
| boundary | is the value exactly at the limit in or out (`>` or `>=`)? minimum, maximum, zero, negatives, rounding? |
| time | counted from when? expires when, in which time zone? what if events arrive out of order? |
| empty | the empty list, the missing optional field, first use, nothing registered yet? |
| repetition | the same action twice (double click, retry)? two people at the same time? |
| permission | who can: which role, which resource owner, which tenant, which visitor with no session? |
| failure | what if a dependency goes down or the operation stops halfway? what does the person see, what is undone? |
| what already exists | data stored before the change, the client on the previous version, behavior someone depends on? |

Each edge that applies ends in one of three places:

| Destination | Where it lives in the PRD |
| --- | --- |
| answered, with a source | an acceptance scenario in the story |
| out | a non-goal |
| gap | **Open gaps**, with who decides and when it must close |

The sweep deepens the decision, never widens it: an edge that calls for a new decision outside
what was asked becomes a non-goal or a gap, not extra scope.

## Amendment

Append at the end of an `Approved` file:

```
## Amendment NNN — YYYY-MM-DD — <one sentence>
status: Draft
<the change, and its own open gaps>
```

Only the owner's answer moves the amendment's status. The text above it is untouched.
