# Template: plan.md

Saved as `.specs/features/<ID>-<slug>/plan.md`. Answers one question: **how is this feature
built?** Written by `spec-writer`. Rules: `SDD-SPEC-02`, `SDD-SPEC-04`.

## Fields

The file opens with these fields as YAML frontmatter, then the body. `scripts/spawn-detached`
reads `base` from it.

| Field | Meaning |
| --- | --- |
| `feature` | `<ID>-<slug>` |
| `owner` | the implementer role: `frontend-developer` or `backend-developer`; one, never "fullstack" |
| `base` | the branch the feature starts from: the trunk, or the failing branch for a new item |
| `status` | `Draft` · `Approved` |

## Body (copy from here down)

---

### Surface

The files, packages, routes and components this feature touches. The reviewer compares the diff
with this list first; a file outside it is a finding.

- [path or glob]

### Size

- **Estimated changed lines, tests included:** [number] (budget: 300 unless the project records
  another)
- **Review families touched:** [at most two, e.g. React, HTTP]

### Stories and tasks

One `####` heading per story, one `#####` heading per task under it. A story is the slice of the
feature that satisfies its `AC-*`; split by acceptance criterion, never by layer. Every `AC-*` in
`contract.md`'s `traces` belongs to exactly one story. The Given / When / Then stays in the PRD;
the story cites it.

A task is one step the implementer finishes and commits alone. It names a part of the Surface,
what it consumes (an earlier task, or a provider feature from `contract.md`'s Interface), what it
provides, and exactly one check from `contract.md`. Each check belongs to exactly one task. Tasks
are ordered so that each comes after every task it consumes from.

- **Task done:** its check is green and its commit stays inside its Surface.
- **Story done:** every task under it is done and every check citing its `AC-*` is green.

#### S1 · [story name] (AC-NN)

##### S1.T1 · [task name]

- **Surface:** [paths, a subset of the Surface above]
- **Consumes:** [item ← S1.T0 or F<NN>], or `none`
- **Provides:** [item], or `none`
- **Check:** [C1]

### Commands

The commands this feature runs beyond the global scripts, in order, e.g. a code generator after a
schema change. `none` when the global scripts cover it.

- [command]

### Local scripts

[Only when this feature needs a script no other feature needs; otherwise delete this section.
Path under the feature's own folder or the code it touches, what it does, when it runs.]

### Out of this file

| Belongs in | What |
| --- | --- |
| `spec.md` | the shape of what is provided and consumed |
| `contract.md` | acceptance, checks, when the contract is met |
