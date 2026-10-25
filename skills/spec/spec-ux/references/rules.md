# Rules of the UX contract

The rule text this skill enforces, kept here so the skill needs no other file. The `SPEC-UX-*`
IDs are local to this skill; `WF-*` IDs match the repository's delivery-flow note.

## Contents

- Rules
- Lifecycle
- Catalog levels
- Amendment

---

## Rules

| ID | Rule |
| --- | --- |
| `SPEC-UX-01` | Every claim about the user **MUST** carry a source (data, interview, ticket); a claim without one **MUST** be listed under "Not validated with a user", with how it will be tested. |
| `SPEC-UX-02` | Every screen **MUST** define all four states: loading, empty, success and failure (with what the person does next); a screen with fewer **NEVER** counts as designed. |
| `SPEC-UX-03` | Every expected failure **MUST** have a recovery path, and every destructive action **MUST** say whether it confirms or can be undone. |
| `SPEC-UX-04` | Every control in the flow **MUST** appear in the accessibility table with its role and exact accessible name; this table is the contract tests locate controls by. |
| `SPEC-UX-05` | The file **MUST** state what lives in the URL (filter, tab, page, or "nothing") so reload and shared links keep state. |
| `SPEC-UX-06` | A component's catalog level **MUST** be decided by its vocabulary, not by how many consumers it has. |
| `WF-SPEC-02` | Each spec file **MUST** have a single owner and cite the others by link; copying content from one file into another **NEVER**, the copy diverges. |
| `WF-SPEC-06` | The file **MUST** be born `draft` and change status only through the owner's explicit reply in the conversation; the writer accepting its own file, or silence counting as approval, **NEVER**. |
| `WF-SPEC-08` | Accepted text **MUST NOT** be rewritten; a change enters as a dated amendment, born `draft`. |

## Lifecycle

`draft` -> `reviewed` -> `accepted`. Frontend work that cites this file does not start on a
`draft`; only the owner moves the status.

## Catalog levels

Where a component lives in the shared catalog, decided by what it is:

| Level | What it holds |
| --- | --- |
| UI | a primitive with no domain vocabulary (button, input) |
| Patterns | a composition of primitives with no domain vocabulary (labeled field, empty state) |
| Features | a composition that speaks the capability's domain (quote summary) |
| Layout | page frames and regions |

## Amendment

Append at the end of an `accepted` file:

```
## Amendment NNN — YYYY-MM-DD — <one sentence>
status: draft
<the change, and its own open gaps>
```

Only the owner's answer moves the amendment's status. The text above it is untouched.
