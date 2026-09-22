---
gerado-por: Skills/react/react-structure/scripts/gerar-mapa-de-ids.sh
gerado-em: 2026-09-05
---

# Mapa de IDs `REACT-ARCH-*`

> Índice, não cópia: o texto de cada regra mora em `Pages/Feature-Based Architecture.md` § 4.
> A coluna **Faz valer** diz se o lint pega ou se depende de revisão humana — é o que decide
> se um achado se repete no próximo PR. Regenerar com:
> `bash Skills/react/react-structure/scripts/gerar-mapa-de-ids.sh`

| ID | Severidade | Faz valer | Seção do corpo estendido |
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

Linha com `—` na última coluna: a regra é declarada na tabela da § 4 e não tem
subseção própria de corpo estendido. As demais têm, e é onde mora o raciocínio.
