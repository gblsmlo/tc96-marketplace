# The six questions and the ten causes

---

## The six questions (§ 4.5 of the hub) — walk them in order

| # | Question | If yes, the cause is | Rule |
| --- | --- | --- | --- |
| 1 | is any failure intermittent? | **flakiness** — problem #1, it contaminates everything else | `TS-CORE-04` |
| 2 | when it fails, can you tell why in < 1 min? | poor diagnosis: naming, granularity, instrumentation | `TS-PROC-06` |
| 3 | if you break the code on purpose, does anything go red? | a **weak assertion**, or a double in the wrong place | `TS-CORE-03`, `TS-SUI-04` |
| 4 | does a refactor with no behavior change break many tests? | the tests observe **implementation** | `TS-CORE-07`, `TS-SUI-06` |
| 5 | does the suite take so long that nobody runs it before the PR? | inverted shape: mass at the wrong level | `TS-NIV-04` |
| 6 | does everything pass and a defect reach production? | an uncovered **risk class**, not a line | `TS-CORE-05`, `TS-TIPO-02` |

Question **3 is the most revealing and the least asked** — a suite can be 100%
deterministic, fast, green **and detect nothing** (`deteccao.md`).

Question **6 is the one that most often brings the team here**, and the answer is almost never
"we lack coverage": it is a missing **risk class** — error state, boundary input, invalid
transition (`TS-TEC-01`, `TS-TEC-04`, `TS-TIPO-02`).

---

## The ten causes, in order of frequency

| Cause | Symptom | Rule |
| --- | --- | --- |
| **fixed-time wait** | passes on a fast machine, fails in CI | `TS-SUI-07` |
| **shared state** | fails only in parallel; passes with one worker | `TS-SUI-09` |
| **order dependence** | passes alone, fails in the suite | `TS-SUI-01` |
| **real clock** | fails at midnight, at month rollover, at daylight saving | `TS-DUB-05` |
| **randomness** | fails 1 in 50, with no pattern | `TS-DUB-05` |
| **external network** | fails when the third party wobbles | `TS-CORE-03` |
| **animation / render** | click lands in the wrong place | — |
| **leakage between tests** | the second test sees the first one's state | `TS-SUI-08` |
| **runner parallelism** | a port, file or database in contention | `TS-SUI-09` |
| **collection order** | a list assertion fails sometimes | `TS-SUI-01` |

**Cause #1 is always the same, in any tool:** waiting on **time** instead of waiting on a
**condition**. It is slow when the machine is fast and insufficient when it is slow — the worst
of both worlds, by construction.

---

## Separating the hypotheses

| Run | If the behavior changes, the cause is |
| --- | --- |
| the test alone | dependence on another test |
| with **one worker** | shared state / parallelism |
| in random order | order dependence |
| the same test 20× | confirms it is intermittent |
| in a container with the CI image | environment parity |

Concrete forms per tool: [Playwright](../../../../knowledge-base/docs/playwright.md) § 5.2 (the most detailed tree in the vault) and
[Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md).

> **Diagnosing is not fixing.** One worker makes the failure disappear and **keeps** the
> coupling, with the suite N times slower. Prefixing files with `001-`, `002-`
> **encodes** the dependence instead of removing it, and the next insertion breaks everything.

---

## Related

- [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) § 2 — the ten causes, with the body
- [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) § 4.5 — the tree of the six questions
- `conserto-x-anestesico.md` — what **not** to do with what you found
