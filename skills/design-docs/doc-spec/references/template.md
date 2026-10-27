# Template: Spec

Saved where the caller names, or returned inline. A spec answers one question: **what does this
feature expose and consume, and how is it built at its boundaries?** Hints in brackets are deleted
when filled.

## Fields

The file opens with these fields as YAML frontmatter, then the body.

| Field | Meaning |
| --- | --- |
| `feature` | the feature's or the change's name, as a slug |
| `prd` | the `CAP-*` and `AC-*` it serves, when it comes from a PRD; otherwise delete |
| `status` | `Draft` · `Approved`; born `Draft`, moved only on the owner's reply |

## Body (copy from here down)

---

### Summary

[Two or three sentences: what this feature adds or changes, and for which consumer.]

### Goals and non-goals

- **Goals:** [what this spec must make possible, from the input]
- **Non-goals:** [what it deliberately does not do, and why]

### Consumes

| Item | From | Where it is defined |
| --- | --- | --- |
| [interface, data or capability] | [provider feature or system] | [the provider's spec section, or `file:line` from the input] |

[Write `none` under the table when the feature consumes nothing.]

### Provides

#### [item name]

- **Shape:** [type, schema, route with method, status codes and body, event name and payload —
  whatever the item is, so a consumer needs nothing else]
- **Invariants:** [what is always true of it, each worded so a test can prove it]
- **Errors:** [each failure the consumer can see, and what it means]

### What already exists

- [fact from the input] — [path:line from the input]

[Write `none supplied` when the input gave no facts about existing code.]

### Boundary decisions

- [decision — reason. One line each. A decision that outlives this feature ends with "→ ADR", or
  cites `ADR-NNNN` when one exists.]

### Alternatives considered

| Alternative | Why it lost |
| --- | --- |
| [an option the input weighed] | [the reason] |

[Delete the section when the input weighed none.]

### Cross-cutting concerns

- **Security and privacy:** [...]
- **Observability:** [...]
- **Migration and rollout:** [...]

[Keep only the lines the input touches; delete the section when none.]

### UX

[Only when the feature has an interface and the input describes it: the flow in steps, each
screen state (loading, empty, error, success), and accessibility requirements a check can observe.
Otherwise delete.]

### Open gaps

- [GAP: the question — decides: who. Empty before `Approved`.]

### Out of this file

| Belongs in | What |
| --- | --- |
| the task list (`doc-tasks`) | step order, files, commands |
| the PRD or feature (`doc-prd`, `doc-feature`) | why the feature exists, its acceptance criteria |
| an ADR (`doc-adr`) | a decision that outlives this feature |
