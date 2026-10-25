# Template: PRD

Tool-neutral, saved as `.specs/<capability>/requirements.md`. The capability's **PRD**: what is
being built and why, before any design or code. Written by `product-manager`. Rules:
`rules.md` in this folder.

## Fields

| Field | Meaning |
| --- | --- |
| `capability` | the slug of `.specs/<capability>/` |
| `owner` | `product-manager` |
| `status` | `Draft` · `In review` · `Approved`; once `Approved` it is frozen and changes enter as amendments |
| `scope` | `product` |

## Body (copy from here down)

---

### Problem

[One sentence: "the problem is X, and a resolved decision looks like Y." Then the evidence,
each item with its source: data, interview, ticket, code.]

### What we know

| Kind | Item | Source |
| --- | --- | --- |
| fact | [...] | [...] |
| hypothesis | [...] | [...] |
| decision | [...] | [who decided, when] |
| gap | [...] | — |

Every item sits in exactly one row kind. Existing code is evidence of the present, never
authority over the intent.

### Goals

| Goal | Metric | Target |
| --- | --- | --- |
| [...] | [...] | [...] |

### Non-goals

- [what someone might expect from this capability and is deliberately left out, and why]

### Stories

One entry per story: role, action, outcome, and three to eight acceptance scenarios in
Given / When / Then. Priority per story: Must · Should · Could. Each edge that applies (see
`rules.md`, "Edge sweep") is a scenario, a non-goal or an open gap.

1. **[STORY-<capability>-NNN] [title]** (Must)
   As a [role], I want [action], so that [outcome].
   1. Given [...], when [...], then [...].

### Constraints and assumptions

- [constraint or assumption, marked as such, with what would invalidate it. A gap the owner
  accepted as an assumption, to proceed without an answer, comes here with the owner's words.]

### Open gaps

- [the question in one sentence — decided by: owner or a role — must close before: approval of
  this file, or the design/plan. An empty list is a precondition for `Approved`.]

### Done when

- The problem sentence exists and every claim has a source.
- Every goal has a metric; every story has scenarios.
- Every story's applicable edges are a scenario, a non-goal or an open gap.
- Non-goals are written, not implied.
- Open gaps that block approval is empty, and the status is `Approved`.

### Out of this file

| Belongs in | What |
| --- | --- |
| a design doc, RFC or ADR | schema, API contract, service boundary |
| a user-experience doc | flow, screen states, accessibility |
| a task plan | who implements what, evidence plan, test types |
