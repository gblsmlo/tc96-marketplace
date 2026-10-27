# Template: PRD

Tool-neutral, saved as `.specs/PRD.md`. The product's **PRD**: its single source of truth. What
is being built and why, which capabilities it offers, and the acceptance criteria that prove each
one. It carries no delivery cut: layers, order and size belong to the delivery plan. Written by
`doc-prd` from the decisions of `product-manager` or the product owner. Rules: `rules.md` in this
folder.

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

### Capabilities

One row per capability: what a person can do with the product, in one sentence. Each names the
acceptance criteria that prove it, and every `AC-*` belongs to at least one capability. A
capability is not a unit of work: it crosses every layer of the code, and how it is built, in what
order and in what size is the delivery plan's.

| ID | Capability | Satisfies | Priority |
| --- | --- | --- | --- |
| CAP-1 | [what a person can do — one sentence] | AC-01, AC-02 | P0 |
| CAP-2 | [...] | AC-03 | P1 |

**Priority levels:** `P0` the product does not work without it · `P1` should ship · `P2` could
ship. Priority says what a delivery may leave out, never how or in what order it is built.

### Out of Scope

- [what someone might expect from this product and is deliberately left out, and why]

### Traceability

| Item | Capabilities |
| --- | --- |
| PO-1 | CAP-1, CAP-2 |
| OBJ-1 | CAP-1 |

Every `PO-*` and `OBJ-*` lists at least one capability; every capability appears at least once.

### Open gaps

- [the question in one sentence — decided by: owner or a role. An empty list is a precondition
  for `Approved`. A gap the owner accepted as an assumption moves here, under "Assumptions", with
  the owner's words and what would invalidate it.]

### Done when

- Every claim has a source or is labeled `hypothesis`.
- Every objective has a metric and a target; every acceptance criterion has an `AC-NN` ID and an
  observable outcome.
- Every capability names the `AC-*` it satisfies and its priority, and every `AC-*` belongs to at
  least one capability.
- No layer, order, size or provides/consumes cut appears: that is the delivery plan's.
- Every `PO-*` and `OBJ-*` traces to a capability, and every capability traces to one of them.
- Open gaps is empty, and the status is `Approved`.

### Out of this file

| Belongs in | What |
| --- | --- |
| the delivery plan's index (`plan.md`) | actors and doors, vocabulary, the layers and their order |
| a layer file (`plans/<layer>-<slug>.md`) | the seams between layers — schema, API contract, data shapes — the rules each layer holds, and its checks |
| the delivery plan's `contract.md` | which checks prove each `AC-*` |
| an ADR | a technical decision that outlives the delivery |
