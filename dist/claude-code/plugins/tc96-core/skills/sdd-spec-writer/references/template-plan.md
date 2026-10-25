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

### Steps

Ordered. Each step names what it produces and, when it has one, the check in `contract.md` it
makes pass.

1. [step] — produces [...] — makes [C1] pass

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
