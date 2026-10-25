# Rules of the Task and the plan

The rule text this skill enforces, kept here so the skill needs no other file. IDs match the
repository's delivery-flow note (`WF-*`), so a citation resolves either way.

## Contents

- Rules
- Review budget
- Test types and their cost
- Waves
- Lifecycle

---

## Rules

| ID | Rule |
| --- | --- |
| `WF-PLAN-03` | Decomposing into multiple units **MUST** follow a criterion: each unit with its own acceptance, evidence and dependency; decomposing without it **NEVER**, it is cost fragmentation. |
| `WF-PLAN-04` | Every unit **MUST** enter implementation with written acceptance criteria. |
| `WF-PLAN-05` | Each unit's layer and owner **MUST** be named; "fullstack" as an owner **NEVER**. |
| `WF-PLAN-06` | Each unit's evidence plan **MUST** name the test types validation will run, each at the cheapest level that catches the defect, plus its risk class (`contract`, `security`, `focused`); integration or E2E without the sentence saying what only they catch **NEVER**. |
| `WF-PLAN-07` | Each unit **MUST** declare its Surface and Size and fit the review budget; above it, re-slice by acceptance scenario or by expand-migrate-contract step; slicing by layer or by file **NEVER**. |
| `WF-PLAN-08` | A contract shared by units that would otherwise be built side by side **MUST** land first, as its own unit holding only the contract and its validator; the shape test stays in the first consumer. |
| `WF-SPEC-02` | Each spec file **MUST** have a single owner and cite the others by link; copying content from one into another **NEVER**. |
| `WF-SPEC-04` | A Task **MUST** start only when the plan is `Ready` and the files that Task cites are accepted; starting on a draft **NEVER**. The plan may be `Ready` while a file another Task cites is still `Draft`: that Task waits, the others start. |
| `WF-SPEC-06` | The plan **MUST** be born `Draft` and change status only through the owner's explicit reply; the writer marking it `Ready`, or silence counting as approval, **NEVER**. |
| `WF-SPEC-08` | Each increment **MUST** get its own plan; piling increments into one plan **NEVER**. |
| `WF-IMPL-03` | A Task's scope **MUST** be the smallest that resolves the decided unit; each Task **MUST** ship to production alone without breaking what is live. |

## Review budget

A review is as long as the diff it reads, and it repeats on every fix round. Default when the
project records none: at most **300 changed lines**, **two review families**, **one owner** per
Task. Measured data replaces the default once it exists.

A Task above the budget is re-sliced, in this order of preference:

1. by acceptance scenario: each scenario cluster becomes a Task;
2. by expand, migrate, contract step: add the new shape, move the callers, remove the old one;
3. never by layer or by file.

## Test types and their cost

Each unit names the types that prove it, at the cheapest level that still catches the defect.
The values are a relative order, not a measurement.

| Type | Catches | Time | Agent tokens | Needs running |
| --- | --- | --- | --- | --- |
| static (types, lint) | type error, import, lint rule | low | low | nothing |
| unit | rule, calculation, parsing, domain invariant | low | low | nothing |
| contract | the shape of what crosses a boundary | low | low to medium | the server, for a `curl` |
| integration | my pieces talking to a real dependency | medium | medium | local database or service |
| component | a component's visual state and interaction | medium | medium | Storybook |
| E2E | the critical journey end to end | high | high | app, browser, session |
| manual | what no check automates | n/a | n/a | person, date and environment recorded |

Risk class, decided at plan time with this tree:

```
Does the change alter a public contract (API, schema, route)?  -> contract
Does it touch authentication, authorization or sensitive data? -> security
Neither                                                        -> focused
```

## Waves

Wave 0 holds the contract Tasks and every Task with no dependency; each later wave holds the
Tasks whose dependencies sit in earlier ones. Waves are how the plan **reads**; execution is
**rolling**. A Task starts as soon as it meets all five conditions:

1. every Task in its `Depends on` closed in validation;
2. every input it cites is accepted;
3. no open gap it depends on;
4. its Surface shares no file with any running Task's Surface, except a landed contract;
5. a slot is free inside the wave width (default **4** writing Tasks at once).

## Lifecycle

Plan: `Draft` -> `Ready`, set only by the owner. The next increment gets a new plan. A Task's
checkbox is ticked by the implementer when validation closes it, never before.
