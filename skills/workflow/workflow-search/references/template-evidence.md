# Template: evidence file

Saved as `.specs/search/<YYYY-MM-DD>-<slug>.md` (default D6). Answers one question: **what held
up, and on what evidence?** Written by `workflow-search`; read by the owner with the PRD and by
`workflow-plan` for the repo facts.

## Fields

| Field | Meaning |
| --- | --- |
| `prd` | `.specs/PRD.md`, or the amendment's date |
| `status` | `Draft` · `Approved`, moves with the PRD |

## Body (copy from here down)

---

### Claims

| ID | Claim | Verdict | Evidence |
| --- | --- | --- | --- |
| CL-P1 | [the problem as the owner said it] | confirmed · refuted · unverified | [file:line · URL (accessed YYYY-MM-DD) · path §section · ADR-NNNN] |

### Sources not used

| Claim | Source | Why `n/a` |
| --- | --- | --- |
| [CL-*] | [codebase · web · docs · decision memory] | [one sentence] |

### Repo facts

One block per feature in the PRD. Facts only, each with `file:line`; "none" when nothing exists.

#### F<NN> [feature name]

- [what exists for a provided item] — [file:line]
- [a caller of something it changes] — [file:line]
- [the tests around it] — [file:line]
- [the layer's convention] — [file:line]
