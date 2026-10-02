---
generated-by: skills/react/react-structure/scripts/generate-id-map.sh
generated-at: 2026-10-02
---

# ID map `REACT-ARCH-*`

> An index, not a copy: each rule's text lives in [Feature-Based Architecture](../../../docs/react/feature-based-architecture.md) § 4.
> The **Enforced by** column says whether lint catches it or it depends on human review — that is what decides
> whether a finding comes back in the next PR. Regenerate with `bash skills/react/react-structure/scripts/generate-id-map.sh`.

| ID | Severity | Enforced by | Section of the extended body |
| --- | --- | --- | --- |
| `REACT-ARCH-01` | critical | review | — |
| `REACT-ARCH-02` | critical | review | — |
| `REACT-ARCH-03` | critical | review | — |
| `REACT-ARCH-04` | critical | `noImportCycles` | why the cycle detects it |
| `REACT-ARCH-05` | critical | `noRestrictedImports` | — |
| `REACT-ARCH-06` | critical | `noRestrictedImports` | — |
| `REACT-ARCH-07` | critical | `noRestrictedImports` partial | — |
| `REACT-ARCH-08` | high | review | the third-consumer rule |
| `REACT-ARCH-09` | high | review (see bench test) | bench test |
| `REACT-ARCH-10` | high | `noImportCycles` | — |
| `REACT-ARCH-11` | medium | review | — |
| `REACT-ARCH-12` | medium | review | — |

A row with `—` in the last column: the rule is declared in the § 4 table and has no
extended-body subsection of its own. The others do, and that is where the reasoning lives.
