# Template: spec.md (flow v2)

Saved as `.specs/features/<ID>-<slug>/spec.md`. Answers one question: **what does this feature
expose and consume?** Written by `spec-writer` with `spec-write`. Rules: `SDD-SPEC-02`, `SDD-SPEC-03`.

## Fields

The file opens with these fields as YAML frontmatter, then the body.

| Field | Meaning |
| --- | --- |
| `feature` | `<ID>-<slug>`, as in the folder name |
| `prd` | `F<NN>` and the `AC-*` it satisfies, from `.specs/PRD.md` |
| `status` | `Draft` · `Approved`; frozen once the feature merges (`SDD-SPEC-08`) |

## Body (copy from here down)

---

### Consumes

| Item | From | Where it is defined |
| --- | --- | --- |
| [interface, data or capability] | [provider feature ID] | [the provider's `spec.md` section, or `file:line` when it already exists] |

### Provides

For each item the PRD says this feature provides: its exact shape, so a consumer can code against
it before this feature merges.

#### [item name]

- **Shape:** [type, schema, route with method, status codes and body, event name and payload —
  whatever the item is, written so a consumer needs nothing else]
- **Invariants:** [what is always true of it; each one is proved by a check in `contract.md`]
- **Errors:** [each failure the consumer can see, and what it means]

### What already exists

Facts from the repo search, each with `file:line`. What this feature reuses, what it changes, and
who calls what it changes.

- [fact] — [path:line]

### Boundary decisions

- [where a rule lives and why; one line each. A decision that outlives this feature becomes an
  ADR (`spec-adr`) and is cited here as `ADR-NNNN`.]

### UX

[Required when `contract.md` marks the `design` lane `small` or `large`; otherwise delete this
section. The flow in steps, and each screen state: loading, empty, error, success. Accessibility
requirements that a check can observe. The design lane draws from this section; it never adds a
state that is not listed here.]

### Open gaps

- [question in one sentence — decided by: owner or a role. Empty before `Approved`.]

### Out of this file

| Belongs in | What |
| --- | --- |
| `story.md` | who the feature is for, the `AC-*` it delivers |
| `contract.md` | the checks, Surface, Size, base branch, lanes, when the contract is met |
| `.specs/PRD.md` | why the feature exists, its acceptance criteria |
