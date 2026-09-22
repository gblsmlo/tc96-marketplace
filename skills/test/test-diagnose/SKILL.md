---
nome: test-diagnose
descricao: Diagnose a suite nobody trusts — measure the flakiness rate before opining, find the cause and tell a fix from an anesthetic, citing `TS-*` IDs — use when the task is investigating an unstable suite as a system, answering "why do we pass green and the defect reaches production?", assessing whether the assertions detect a break, deciding whether retry is masking a defect, or when the same test goes flaky again after being fixed. Do not use for one concrete failing test, which is playwright-diagnose or bun-test-review. Do not use to audit the shape of the suite, which is test-review, nor to decide a new test, which is test-design.
tipo: skill
familia: test
idioma: en
fonte: "[Teste de Software - Confiabilidade da Suíte](../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md)"
tags:
  - skill
  - testing
  - software-quality
  - flaky-tests
---
# test-diagnose

> **Source of this skill:** [Teste de Software - Confiabilidade da Suíte](../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md), with § 4.5 of the [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) hub as the diagnostic tree. The 64 rules of the `TS-*` family live in § 6 of the hub.
> This skill **does not contain** the text of the rules — it says what to measure, in what order to eliminate hypotheses and how to report.

Contract this skill implements: [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 7 ("Contrato de skill").

> **Design note.** This skill diagnoses the **suite as a system**: flakiness rate, trust, ability to detect a break. `playwright-diagnose` and `bun-test-review` diagnose **one test** that fails. The practical difference: they read a trace; this one reads the CI history. Arriving here with a single red test is using the wrong tool — and arriving there with "the suite is flaky" produces one diagnosis at a time, forever.

---

## When to use

The suite, as a whole, has lost credibility: intermittent failures, people re-running the job by reflex, green that does not convince, or defects reaching production with everything passing.

| Situation | Go to |
| --- | --- |
| **one** failing or flaky test | `playwright-diagnose` (E2E) · `bun-test-review` (Bun) |
| auditing the shape and risk coverage | `test-review` |
| deciding a new test | `test-design` |
| the failure is a real product defect | then **the suite worked** — stop and fix the product |
| a recurring defect with an organizational cause | [Teste de Software - Processo e Artefatos](../../../knowledge-base/docs/teste-de-software-processo-e-artefatos.md) |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 2 (claim 5) | **the arithmetic**: an untrustworthy suite is worse than no suite |
| 2 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 4.5 | the six questions of "I do not trust the suite" |
| 3 | [Teste de Software - Confiabilidade da Suíte](../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) § 1 and § 2 | the numbers, and the ten causes in order of frequency |
| 4 | `references/mapa-de-ids.md` | before citing — three IDs are aliases |

References in this skill:

| File | What for |
| --- | --- |
| `references/medicao.md` | Step 0, the metrics and the thresholds |
| `references/causas-de-flake.md` | the six questions, the ten causes, and the commands that separate hypotheses |
| `references/deteccao.md` | the thirty-second test and the corollary about coverage |
| `references/conserto-x-anestesico.md` | the seven anesthetics and the grid of 21 antipatterns |
| `references/mapa-de-ids.md` | the 64 `TS-*` by satellite and section |
| `references/exemplo-diagnostico.md` | a whole diagnosis, from the measurement to the report |
| `scripts/medir-flakiness.sh` | inventories anesthetics and measures the rate over N runs |

---

## Step 0 — The question that comes first

> **Are the failures real product defects?**

If so, **the suite did its job**. A **deterministic** failure is a defect; an **intermittent** one is the suite. Only the second case belongs to this skill.

---

## Step 1 — Measure before opining

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/test-diagnose/scripts/medir-flakiness.sh "bun test" 20
```

The script inventories the **anesthetics already installed** (retry, `workers: 1`, `skip`, fixed-time waits, real clock, numeric prefix, `try/catch` in the body) and **measures the rate**.

**Without the rate, there is no diagnosis** — there is an impression. 0.05% and 3% have the same perceived symptom and opposite prognoses. Above **~1%** people stop believing the red, and the real red passes along with the false ones (`TS-CORE-04`).

Thresholds and how to read a zero: `references/medicao.md`.

---

## Step 2 — The six questions

`references/causas-de-flake.md`, **in order**. Question 1 (is there an intermittent failure?) interrupts the other five: flakiness contaminates everything else.

Question **3** is the most revealing and the least asked — go to Step 4.
Question **6** is the one that most often brings the team here, and the answer is almost never "we lack coverage": it is a missing **risk class**.

---

## Step 3 — Find the cause

Ten causes in order of frequency, and the commands that separate them — alone, one worker, random order, 20×, the CI container. **Cause #1 is always the same:** waiting on **time** instead of waiting on a **condition** (`TS-SUI-07`).

> **Diagnosing is not fixing.** One worker makes the failure disappear and **keeps** the coupling.

---

## Step 4 — The thirty-second test

`references/deteccao.md`. **Break the code on purpose** in three places chosen by risk. If the suite stays green in any of them, the assertion does not exist (`TS-SUI-04`) — a **blocking** finding, and it explains question 6 all by itself.

Coverage does not answer that question: a test that calls the function and asserts nothing gives full coverage (`TS-CORE-05`).

---

## Step 5 — Output format

Five parts — **the measurement** is what separates this skill from a guess:

```
`RULE-ID` — <where>
Symptom: <how the problem presents itself to the team>
Measurement: <the number, and where it came from>
Cause: <one sentence>
Fix: <concrete change, with a starting point>
See the corresponding satellite.
```

"The suite is flaky" without a rate is not a finding. "Fix the waits" without saying which file to start with is useless in a suite at 17%.

---

## Step 6 — Fix × anesthetic

`references/conserto-x-anestesico.md`: seven fixes that make the red disappear without solving anything. The two worst — `try/catch` in the body and removing the assertion — are **invisible in review**.

---

## Step 7 — Closing

1. **Report the rate, before and after.** "It dropped from 17% to 0.4%" is the only verifiable closing.
2. **Confirm by repetition.** 20 green runs; one proves nothing on a 1-in-6 flake.
3. **If the cause was a product defect**, the suite does not change. Say so.
4. **If the cause was the shape of the suite**, continue in `test-review` — that is restructuring, not fixing.
5. **Turn the diagnosis into a gate:** random order in the pipeline, flaky not counting as green, repetition in the nightly job, the thirty-second test as a review step.
6. **If the same test goes flaky again**, the root cause was not found (`TS-PROC-08`).
7. **Declare what was not measured.** "Not measured" is not "no problem".

---

## Example

A team re-runs the job by reflex. The script measures **25% over 20 local runs**, and the CI history confirms 17% over 200. Question 1 interrupts the others; the cause is 9 files with fixed-time waits and 3 sharing an account across workers. A second finding comes from the thirty-second test: with one comparison inverted, the whole suite stays green — with 96% coverage on the file.

Full diagnosis, with both reports: `references/exemplo-diagnostico.md`.

---

## Related

- [Teste de Software - Confiabilidade da Suíte](../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) — source of this skill: the arithmetic, the ten causes, test smells
- [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) — § 2 (claim 5), § 4.5 (the tree), § 6, § 7
- `test-design` · `test-review` — the sibling skills
- `playwright-diagnose` · `bun-test-review` — they diagnose **one test**; this one diagnoses the **suite**
- `Docs/Playwright.md` § 5.2 · `Docs/Bun - Testes - Ciclo de Vida e Isolamento.md` — the concrete forms per tool
