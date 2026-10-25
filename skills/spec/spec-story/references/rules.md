# Rules of the Story

The rule text this skill enforces, kept here so the skill needs no other file. The
`SPEC-STORY-*` IDs are local to this skill; `WF-*` IDs match the repository's delivery-flow
note.

## Contents

- Rules
- Edge sweep

---

## Rules

| ID | Rule |
| --- | --- |
| `SPEC-STORY-01` | A Story **MUST** have a parent Epic and inherit its `capability`; a Story with no parent is an orphan, outside the backlog until linked. |
| `SPEC-STORY-02` | A Story **MUST** carry three to eight acceptance scenarios in Given/When/Then, each describing a situation and an observable result a test can execute; a scenario that restates the rule's text **NEVER**. |
| `SPEC-STORY-03` | A Story is done only when every scenario is covered by an executable, green, reviewed test with the run linked; hand-checking a scenario **NEVER**, and no automation closes the Story because its Tasks closed. |
| `SPEC-STORY-04` | Each rule and scenario **MUST** go through the edge sweep; every applicable edge ends as a scenario, an explicit exclusion or an open gap. |
| `WF-PLAN-04` | Every unit **MUST** enter implementation with written acceptance criteria; "ready to start" without them is never ready. |
| `WF-SPEC-02` | Each spec file **MUST** have a single owner and cite the others by link; copying content from one into another **NEVER**. |

## Edge sweep

A category that does not apply leaves no trace.

| Category | The question that tends to slip through |
| --- | --- |
| boundary | is the value exactly at the limit in or out (`>` or `>=`)? minimum, maximum, zero, negatives, rounding? |
| time | counted from when? expires when, in which time zone? what if events arrive out of order? |
| empty | the empty list, the missing optional field, first use, nothing registered yet? |
| repetition | the same action twice (double click, retry)? two people at the same time? |
| permission | who can: which role, which resource owner, which tenant, which visitor with no session? |
| failure | what if a dependency goes down or the operation stops halfway? what does the person see, what is undone? |
| what already exists | data stored before the change, the client on the previous version, behavior someone depends on? |

| Destination | Where it lives |
| --- | --- |
| answered, with a source | a scenario in the Story |
| out | stated as excluded, in the Story or its Epic |
| gap | an open question with who decides it and when it must close |

The sweep deepens the Story, never widens it.
