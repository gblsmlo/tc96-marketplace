---
gerado-por: skills/react/react-structure/scripts/gerar-mapa-de-ids.sh
gerado-em: 2026-09-22
---

# ID map `REACT-ARCH-*`

> An index, not a copy: each rule's text lives in [Feature-Based Architecture](../../../../knowledge-base/pages/feature-based-architecture.md) § 4.
> The **Enforced by** column says whether lint catches it or it depends on human review — that is what decides
> whether a finding comes back in the next PR. Regenerate with:
> `bash skills/react/react-structure/scripts/gerar-mapa-de-ids.sh`

| ID | Severity | Enforced by | Section of the extended body |
| --- | --- | --- | --- |
| `REACT-ARCH-01` | crítica | revisão | — |
| `REACT-ARCH-02` | crítica | revisão | — |
| `REACT-ARCH-03` | crítica | revisão | — |
| `REACT-ARCH-04` | crítica | `noImportCycles` | por que o ciclo detecta |
| `REACT-ARCH-05` | crítica | `noRestrictedImports` | — |
| `REACT-ARCH-06` | crítica | `noRestrictedImports` | — |
| `REACT-ARCH-07` | crítica | `noRestrictedImports` parcial | — |
| `REACT-ARCH-08` | alta | revisão | a regra do terceiro consumidor |
| `REACT-ARCH-09` | alta | revisão (ver teste de bancada) | teste de bancada |
| `REACT-ARCH-10` | alta | `noImportCycles` | — |
| `REACT-ARCH-11` | média | revisão | — |
| `REACT-ARCH-12` | média | revisão | — |

A row with `—` in the last column: the rule is declared in the § 4 table and has no
extended-body subsection of its own. The others do, and that is where the reasoning lives.
