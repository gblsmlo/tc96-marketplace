# Template: PRD

Tool-neutral, saved as `.specs/PRD.md`. The product's **PRD**: its single source of truth. What
is being built and why, which features build it, what each feature provides and consumes, and
the order they can run in. Written by `doc-prd` from the decisions of `product-manager` or the product owner. Rules: `rules.md` in this folder.

## Fields

The file opens with these fields as YAML frontmatter, then the body.

| Field | Meaning |
| --- | --- |
| `product` | the product's name |
| `owner` | `product-manager` |
| `status` | `Draft` · `In review` · `Approved`; once `Approved` it is frozen and changes enter as amendments |

## Body (copy from here down)

---

### Summary

[Three sentences: what the product is, for whom, and the outcome it promises.]

### Problem and Opportunity

Each item numbered, with its evidence and source (data, interview, ticket, `file:line`), copied from the input. An
unsourced claim is labeled `(hypothesis)`.

- **PO-1** [the problem or opportunity in one sentence] — evidence: [...] — source: [...]

### Target Audience

| Who | What they need | Source |
| --- | --- | --- |
| [...] | [...] | [...] |

### Objectives

| ID | Objective | Metric | Target |
| --- | --- | --- | --- |
| OBJ-1 | [...] | [...] | [...] |

### User Stories

One entry per story: role, action, outcome, and three to eight acceptance criteria. Acceptance
criteria are numbered across the whole PRD (`AC-01`, `AC-02`…), never restarted per story, and
each is a Given / When / Then with an observable outcome. Each limit the input states is an acceptance criterion, an Out of Scope line or an open gap
(see `rules.md`, "Limits in the input").

1. **US-1 [title]**
   As a [role], I want [action], so that [outcome].
   - **AC-01** Given [...], when [...], then [...].

### Functionalities

One row per feature. A feature is the smallest slice someone can build and prove alone; it fits
one review (by default at most 300 changed lines, tests included). Provides and consumes name
interfaces, data or capabilities in product words, not code.

| ID | Feature | Satisfies | Provides | Consumes (from) | Priority |
| --- | --- | --- | --- | --- | --- |
| F01 | [name — one sentence] | AC-01, AC-02 | [what other features can rely on] | — | P0 |
| F02 | [...] | AC-03 | [...] | [item] (F01) | P1 |

### Out of Scope

- [what someone might expect from this product and is deliberately left out, and why]

### Dependency Graph

**Foundation Features:** [the features that consume nothing]

**Execution Waves:**

| Wave | Features | Waits for |
| --- | --- | --- |
| W0 | F01, … | — |
| W1 | F02, … | F01 |

A feature sits in the first wave after all of its providers. No cycles: a cycle is broken by
extracting the shared part into its own provider feature.

**Priority levels:** `P0` the product does not work without it · `P1` should ship · `P2` could
ship. Priority orders features inside a wave; it never moves a feature ahead of its providers.

### Traceability

| Item | Features (role) |
| --- | --- |
| PO-1 | F01 (provider), F02 (consumer) |
| OBJ-1 | F02 (consumer) |

Every `PO-*` and `OBJ-*` lists at least one feature; every feature appears at least once.

### Open gaps

- [the question in one sentence — decided by: owner or a role. An empty list is a precondition
  for `Approved`. A gap the owner accepted as an assumption moves here, under "Assumptions", with
  the owner's words and what would invalidate it.]

### Done when

- Every claim has a source or is labeled `hypothesis`.
- Every objective has a metric and a target; every acceptance criterion has an `AC-NN` ID and an
  observable outcome.
- Every feature names what it satisfies, provides and consumes, and every consumed item names one
  provider.
- The waves respect the providers; there is no cycle.
- Every `PO-*` and `OBJ-*` traces to a feature, and every feature traces to one of them.
- Open gaps is empty, and the status is `Approved`.

### Out of this file

| Belongs in | What |
| --- | --- |
| the feature's `spec.md` | interfaces, data shapes, schema, API contract, UX states |
| the feature's `plan.md` | steps, files, commands |
| the feature's `contract.md` | the checks that prove each `AC-*` |
| an ADR | a technical decision that outlives a feature |
