---
delivery: 2026-10-26-quotes
traces: AC-01, AC-02, AC-03, AC-04, AC-05, AC-06, AC-07
risk: security
status: Approved
---

### Proof by acceptance criterion

| AC | Checks (layer) | Edges covered |
| --- | --- | --- |
| AC-01 | C08 (L3b), C15 (L4b) | permission |
| AC-02 | C03 (L1a), C09 (L3b) | — |
| AC-03 | C10 (L3b) | — |
| AC-04 | C05 (L2a), C11 (L3b), C16 (L4b) | repetition |
| AC-05 | C12 (L3b), C17 (L4b) | boundary, time |
| AC-06 | C01 (L1a), C04 (L2a), C06 (L3a), C13 (L4a), C14 (L4a) | empty, permission |
| AC-07 | C02 (L1a), C07 (L3a) | boundary |

### ADR invariants

| ADR | Checks (layer) |
| --- | --- |
| ADR-0001 | I1 (L3b) |
| ADR-0002 | I2 (L3a) |

### Gates

| Gate | What | Level |
| --- | --- | --- |
| G1 | types and lint, formatting included, clean on the layer's surface — on every layer's pull request | static |
| G2 | `bun test` green, every suite — on every layer's pull request | unit · integration · component |
| G3 | `devops-security` reviews the signed-link path of L3b beside the reviewer | review |

### Met when

Every row above has all its checks green on the feature branch, and the gates pass there.
