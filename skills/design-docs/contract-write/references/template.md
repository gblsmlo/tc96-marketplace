# Template: contract.md (flow v2)

Saved as `.specs/features/<ID>-<slug>/contract.md`. Answers one question: **how do we prove this
feature works?** It is the reviewer's only checklist, so whatever is not listed here is not
verified. Written by `spec-writer` with `contract-write`. Rules: `SDD-SPEC-04` to
`SDD-SPEC-07`. Self-check: `scripts/self-check.sh` of `contract-write`.

**A contract is met only when it proves that every acceptance criterion it traces was met.**
Green checks that cover no `AC-*` do not close it; an `AC-*` with no passing check does not
either.

With no `plan.md` in this flow, the delivery fields live here (default D1): the reviewer already
receives this file, `scripts/spawn-detached` reads `base`, and `workflow-implementation` reads the
lane map.

## Fields

The file opens with these fields as YAML frontmatter.

| Field | Meaning |
| --- | --- |
| `feature` | `<ID>-<slug>` |
| `traces` | every `AC-*` the PRD assigns to this feature, or, in the fast lane, the `AC-*` it protects |
| `risk` | `security` for authentication, authorization or sensitive data; `contract` when it changes something another feature consumes; otherwise `focused` |
| `base` | the branch the feature starts from: the trunk, or the failing branch for a new item |
| `owner` | the feature implementer: `frontend-developer` or `backend-developer`, the role of the lane with most checks among the code lanes |
| `surface` | list of paths or globs the feature touches; a file outside it is a finding |
| `size` | estimated changed lines, tests included; budget 300 unless the project records another |
| `lanes` | map of the seven lanes to `none` · `small` · `large`, with the estimated lines of each `large` lane |
| `status` | `Draft` · `Approved` |

```yaml
feature: F03-invitations
traces: [AC-01, AC-02, AC-03]
risk: security
base: main
owner: frontend-developer
surface:
  - apps/api/src/invitations/**
  - apps/web/src/features/invitations/**
size: 260
status: Draft
lanes:
  design: small
  frontend: small
  backend: { size: large, lines: 180 }
  ai: none
  devops: none
  tooling: none   # never large (default D5)
  qa: small
```

## Body (copy from here down)

---

### Interface

- **Consumes:** [item (provider ID)], one per line
- **Provides:** [item], one per line, as defined in `spec.md`

### Inputs, outputs and rules

| Input | Rule | Output |
| --- | --- | --- |
| [a concrete input] | [the rule that applies] | [the observable output] |

### Checks

One per line: the `AC-*` it proves (`—` for a non-functional gate), what is observed, the lane
that writes it, and the gate type last, where `run-gates` reads it: `static` · `unit` ·
`contract` · `integration` · `component` · `e2e` · `manual`. An `integration` or `e2e` check says,
before its lane, what a cheaper level would miss.

- [ ] **C1** (AC-NN) [given input] → [observed outcome] · lane `backend` · `unit`
- [ ] **C2** (AC-NN) [...] · lane `frontend` · `component`

Each edge from the sweep that applies is a check here.

### Non-functional gates

- [ ] **G1** (—) static checks (types, lint) on the Surface · `static`
- [ ] **G2** (—) the suites the Surface touches stay green · `unit`
- [ ] **G3** (—) [only when `risk: security`] `devops-security` reviews the sensitive path and returns no finding · `review`

### Delivery

- **Commands beyond the global scripts:** [command], or `none`
- **Local scripts:** [path, what it does, when it runs], or delete this line

### Met when

Met when: AC-NN proved by C1 and C2; AC-MM proved by C3; G1 and G2 green.

### Out of this file

| Belongs in | What |
| --- | --- |
| `story.md` | who the feature is for |
| `spec.md` | why the shape is what it is |
