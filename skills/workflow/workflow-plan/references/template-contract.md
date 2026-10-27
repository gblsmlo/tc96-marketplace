# Template: contract.md

Saved as `.specs/features/<ID>-<slug>/contract.md`. Answers one question: **how do we prove this
feature works?** It is the reviewer's only checklist, so whatever is not listed here is not
verified. Written by `spec-writer`. Rules: `SDD-SPEC-05`, `SDD-SPEC-06`, `SDD-SPEC-07`.

**A contract is met only when it proves that every acceptance criterion it traces was met.**
Green checks that cover no `AC-*` do not close it; an `AC-*` with no passing check does not
either.

## Fields

The file opens with these fields as YAML frontmatter, then the body. `scripts/run-gates` reads
the gate type at the end of each check line.

| Field | Meaning |
| --- | --- |
| `feature` | `<ID>-<slug>` |
| `traces` | every `AC-*` the PRD assigns to this feature, or, in the fast lane, the `AC-*` it protects or the defect it fixes |
| `risk` | `security` when the feature touches authentication, authorization or sensitive data; `contract` when it changes something another feature consumes; otherwise `focused` |
| `status` | `Draft` · `Approved` |

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

One per line. Each names the `AC-*` it proves (`—` for a non-functional gate), what is observed,
and the gate type at the cheapest level that catches the defect: `static` · `unit` · `contract` ·
`integration` · `component` · `e2e` · `manual`. The gate type is always last on the line, where
`run-gates` reads it. An `integration` or `e2e` check says, before its gate type, what a cheaper
level would miss.

- [ ] **C1** (AC-NN) [given input] → [observed outcome] · `unit`
- [ ] **C2** (AC-NN) [...] · `contract`

Each edge from the sweep that applies to this feature is a check here.

### Non-functional gates

Always present. `run-gates` runs G1 and G2 with the checks above; G3 is a review, not a script.

- [ ] **G1** (—) static checks (types, lint) on the Surface · `static`
- [ ] **G2** (—) the suites the Surface touches stay green · `unit`
- [ ] **G3** (—) [only when `risk: security`] `devops-security` reviews the sensitive path beside the reviewer and returns no finding · `review`

### Met when

[One line per `AC-*`: the checks that prove it. Then the gates.]

Met when: AC-NN proved by C1 and C2; AC-MM proved by C3; G1 and G2 green.

### Out of this file

| Belongs in | What |
| --- | --- |
| `spec.md` | why the shape is what it is |
| `plan.md` | how the code gets written |
