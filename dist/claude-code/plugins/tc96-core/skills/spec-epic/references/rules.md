# Rules of the Epic

The rule text this skill enforces, kept here so the skill needs no other file. The `SPEC-EPIC-*`
IDs are local to this skill; `WF-*` IDs match the repository's delivery-flow note.

## Contents

- Rules
- The hierarchy
- Lifecycle

---

## Rules

| ID | Rule |
| --- | --- |
| `SPEC-EPIC-01` | An Epic **MUST** carry a unique `capability` slug; it is the value every child groups by. A second Epic for the same capability **NEVER**. |
| `SPEC-EPIC-02` | An Epic describes the capability, never the implementation: no screen, table or component name. |
| `SPEC-EPIC-03` | Every line under "What a person can do" **MUST** have a Story behind it; a line with none is an open gap, not a promise. |
| `SPEC-EPIC-04` | An Epic **MUST** name what is explicitly out of it. |
| `SPEC-EPIC-05` | An Epic is accepted through its Stories' acceptance; it **NEVER** gets a separate acceptance round (business acceptance of the whole capability is a later, separate step; `WF-VAL-03`). |
| `WF-SPEC-02` | Each spec file **MUST** have a single owner and cite the others by link; copying content from one into another **NEVER**. |

## The hierarchy

Four levels, connected by parent and child; Milestone is a property, not a template.

| Level | Is | Closes when |
| --- | --- | --- |
| Milestone | a roadmap block, set as a property on Epic, Story or Task | never gates a child's closure |
| Epic | the permanent capability | every child Story closes |
| Story | the acceptance unit: what a role can do, with scenarios | its scenarios pass, tested |
| Task | the executable cut an implementer reads | its done-conditions hold, validated |

An item with no parent is an orphan: outside the backlog until linked, a divergence to
resolve, never a case to guess at.

## Lifecycle

Tracker-dependent. The Epic is permanent: it reopens when its governing rule set gains a new
rule, rather than a new Epic being opened.
