---
nome: test-review
descricao: Audit a repository's test strategy — the shape of the suite, not the individual tests — with nine executable probes and `TS-*` IDs, answering "does this suite protect anything?" — use when the task is assessing whether risk coverage is adequate, whether the proportion across levels makes sense, whether the quality gates actually close, whether the static layer is counting, or whether there is a risk class with no test at all. Do not use to find a defect in an individual test, which is playwright-review or bun-test-review. Do not use for an unstable suite, which is test-diagnose, nor to decide a new test, which is test-design.
tipo: skill
familia: test
idioma: en
fonte: "[Teste de Software](../../../knowledge-base/docs/teste-de-software.md)"
tags:
  - skill
  - testing
  - software-quality
  - code-review
---

# test-review

> **Source of this skill:** [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) — the normative § 6 (64 rules in 7 families), § 6.1 with the satellites' critical ones, and § 6.2 with the canonical IDs. The body of each family lives in the satellite that owns the ID.
> This skill **does not contain** the text of the rules — it says what to run, in what order to scan, how to classify and how to report.

Contract this skill implements: [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 7 ("Contrato de skill").

> **Design note.** This skill audits the **shape** of the suite; `playwright-review` and `bun-test-review` audit the **tests**. The difference is operational: they find `waitForTimeout` on line 41; this one finds that 200 of the 214 tests are E2E and that none covers the error state. A repository can pass both tool skills and fail here — and that is the most common case.

---

## When to use

Assessing a suite **as a system**. The question is *"does this suite protect anything?"* — different from *"do the tests pass?"* and different from *"are the tests well written?"*.

| Situation | Go to |
| --- | --- |
| finding a defect in an individual test | `playwright-review` (E2E) · `bun-test-review` (unit/integration) |
| an unstable, flaky suite nobody trusts | `test-diagnose` |
| deciding a new test | `test-design` |
| one concrete failure | `playwright-diagnose` |
| reviewing the application code | `react-review` · `drizzle-review` |
| process, defects, severity, team metrics | [Teste de Software - Processo e Artefatos](../../../knowledge-base/docs/teste-de-software-processo-e-artefatos.md) |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 2 | a test buys information at a price — the criterion for every judgment here |
| 2 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 6 + § 6.1 | the inviolable rules and the critical ones |
| 3 | `references/mapa-de-ids.md` | **required before citing** — three IDs are aliases |
| 4 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 4.1 and § 4.4 | the level tree, and "when to stop writing tests" |
| 5 | the satellite for the finding | via § 5 of the hub |

**Never load all six satellites.**

References in this skill:

| File | What for |
| --- | --- |
| `references/sondas.md` | the nine probes, the three mandatory stops, and what they do **not** measure |
| `references/ordem-da-varredura.md` | the 11 steps by impact, and the three conclusions that do not mix |
| `references/severidade-e-relatorio.md` | classification, format with measurement, the cut, and the closing |
| `references/antipadroes.md` | 29 antipatterns with ID and satellite |
| `references/mapa-de-ids.md` | the 64 `TS-*` by satellite and section, and the three aliases |
| `references/exemplo-auditoria.md` | a whole audit, from the probes to the "not verified" |
| `scripts/sondas-suite.sh` | runs S1, S3–S9 and prepares S2 |

---

## Step 1 — Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/test-review/scripts/sondas-suite.sh.
```

The shape of a suite is **invisible** when reading files: each test looks reasonable, and the whole is unbalanced.

**Three mandatory stops** — if any of them fires, report before continuing:

| Probe | If it shows… | Why |
| --- | --- | --- |
| S1 | an inverted shape | criticizing an individual test becomes noise; the fix rewrites much of the suite |
| S4 | a gate that does not fail | it makes every discussion of coverage decorative |
| S3 | `no-floating-promises` off with Playwright | **blocking**: an assertion that asserts nothing does not show up as a failure |

Detail of the nine and what they do not measure: `references/sondas.md`.

---

## Step 2 — Scan the strategy, in order

`references/ordem-da-varredura.md`, 11 steps by impact: gate → shape → uncovered risk class → static layer → non-functional attribute → contract → replacement → determinism → retest → exploratory → tests that do not pay.

If a step produces a finding that invalidates the next one, **stop auditing the interior** and report the change of shape.

---

## Step 3 — Classify and report

`references/severidade-e-relatorio.md`. Blocking is what produces **false green**; High is risk uncovered **today**; Medium is structural debt.

For a finding about shape, **the evidence is the measurement** — paste the probe's numbers. "There is too much E2E" without a count is an opinion.

**Four things are not findings:** absence of a test on its own, a proportion that matches neither pyramid *nor* trophy, low coverage, and tool preference. Confusing them burns the credibility of the whole report.

---

## Step 4 — Closing

1. **Turn a probe into a gate** — a finding that only exists in the report comes back in six months.
2. **Separate "not protected", "at the wrong level" and "broken"** — the middle one belongs to the tool skills.
3. **Order by severity**, not by directory.
4. **Give the next step**, not the whole list.
5. **If there is active flakiness, stop here** and continue in `test-diagnose` (`TS-CORE-04`).
6. **Declare what was not verified.** "Not verified" is not "no findings".

---

## Example

A suite of 214 cases, CI green for months, defects reaching production. The probes show 87% in E2E, `continue-on-error` in CI, `strict` off without `no-floating-promises`, and **two** files mentioning the error state. Two stops fire at once; reading 10 E2E files explains the shape (7 verify business rules). 62% coverage and mass in integration in the BFF do **not** become findings.

Full audit, with the report and the "not verified" section: `references/exemplo-auditoria.md`.

---

## Related

- [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) — source of this skill: normative § 6, § 6.1, § 6.2, § 7 contract
- `test-design` · `test-diagnose` — the sibling skills
- `playwright-review` · `bun-test-review` — they audit the **tests**; this one audits the **shape**
- `Github Actions` — where the gates live
- `Docs/Bun - Testes - Cobertura e CI.md` · `Docs/Playwright - Execução, Retries e CI.md` — the mechanism of the gates
