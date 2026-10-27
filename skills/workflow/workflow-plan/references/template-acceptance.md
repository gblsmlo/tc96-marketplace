# Template: acceptance contract (index)

Saved as `.specs/delivery/<YYYY-MM-DD>-<slug>/contract.md`, beside the index. Answers one
question: **which checks prove each acceptance criterion of this delivery?** The text of each check
lives in the file of the layer that proves it (`plans/<layer-id>-<slug>.md`, **Checks**); this file
only maps. It is the page a person reads to validate the delivery, and the final review's input.
Rules: `SDD-PLAN-06`, `SDD-PLAN-07`, `SDD-PLAN-08`.

A contract is met only when every `AC-*` it traces has a passing check.

## Fields

| Field | Meaning |
| --- | --- |
| `delivery` | the delivery ID |
| `traces` | every `AC-*` of the PRD or amendment the plan covers |
| `risk` | `security` when any layer touches authentication, authorization or sensitive data |
| `status` | `Draft` · `Approved` |

## Body (copy from here down)

---

### Proof by acceptance criterion

One row per `AC-*`, in PRD order. The edge sweep (boundary, time, empty, repetition, permission,
failure, what already exists) runs once per `AC-*` (`SDD-PLAN-08`); its edges are the checks named
here, or a gap.

| AC | Checks (layer) | Edges covered |
| --- | --- | --- |
| AC-NN | C01 (L1b), C23 (L3c), C41 (L4b) | boundary, empty |

### ADR invariants

| ADR | Checks (layer) |
| --- | --- |
| ADR-NNNN §n | I1 (L3a) |

### Gates

| Gate | What | Level |
| --- | --- | --- |
| G1 | types and lint, formatting included, clean on the layer's surface — on **every** layer's pull request, from L1 | static |
| G2 | the project's test command green, every suite — on **every** layer's pull request, from L1 | unit · integration |
| G3 | [when `risk: security`] `devops-security` reviews the sensitive paths beside the reviewer | review |

### Met when

Every row above has all its checks green on the feature branch, and the gates pass there.
