# Severity, format and the cut

---

## Classification

| Severity | What goes in |
| --- | --- |
| **Blocking** | a CI gate that does not fail (`TS-PROC-03`); `no-floating-promises` off with Playwright in the project; a recurring production defect with no test (`TS-CORE-06`); flakiness above ~1% (`TS-CORE-04` — and go to `test-diagnose`) |
| **High** | inverted shape (`TS-NIV-04`); business rules in E2E (`TS-NIV-02`); the error state uncovered in a critical flow (`TS-TIPO-02`); mocking what the test came to prove (`TS-CORE-03`); a coverage target as an indicator (`TS-CORE-05`) |
| **Medium** | `strict` off (`TS-TIPO-08`); a non-functional requirement without a number (`TS-TIPO-05`); shared pre-existing data (`TS-SUI-05`); a retest without regression (`TS-TIPO-04`); a `skip` without a reason (`TS-SUI-11`); a global proportion (`TS-NIV-08`) |
| **Low** | preference without an ID — **not a finding** |

Two criteria decide the boundary:

- **Blocking × High:** *does the suite produce false green?* A gate that does not fail and an
 assertion that asserts nothing **lie**; an unbalanced suite is inefficient.
- **High × Medium:** *is the risk uncovered today, or is the structure suboptimal?* The error
 state untested in payments is active risk; `strict` off is debt.

---

## Format

```
`RULE-ID` — <where: file, directory, or the workflow>
<what is wrong, one sentence>
Fix: <concrete change>
See the corresponding satellite.
```

**For a finding about shape, the evidence is the measurement** — paste the probe's numbers:

```
`TS-NIV-04` — e2e/ (187 cases) × packages/core/ (22 cases)
S1: 89% of the suite's cases are E2E. The suite takes 34 min (S2) and nobody runs it before the PR.
Sampling 10 files from e2e/: 7 verify business rules, not journeys (TS-NIV-02).
Fix: move the rule assertions to unit tests in packages/core; keep in E2E
 one case per critical journey, verifying that the screen displays the calculated value.
 Start with e2e/discount.spec.ts, which has 23 cases about discount ranges.
See Teste de Software - Níveis e Escopo.
```

Rules of the format:

- **ID checked in `mapa-de-ids.md`**, and **never an alias**.
- **Location always** — file, directory or workflow line.
- **Numbers for a finding about shape.** "There is too much E2E" without a count is an opinion.
- **A fix with a starting point.** In an unbalanced suite, "move the assertions" is useless without saying which file to start with.

---

## The cut: four things that are **not** findings

Confusing them burns the credibility of the whole report.

| Not a finding | It becomes one when… |
| --- | --- |
| **absence of a test**, on its own | crossed with **risk**: the payments module untested, or a production defect that came back (`TS-CORE-06`) |
| **the proportion matching neither pyramid NOR trophy** | only the **inverted shape** (`TS-NIV-04`) is a finding — mass in integration is a trophy, not an error |
| **low coverage** | the finding is the coverage **target** (`TS-CORE-05`), or an uncovered risk class |
| **tool preference** | never. "They should use Vitest instead of `bun test`" is not a finding of this skill |

And one **invalid** case: citing an alias (`TS-NIV-01`, `TS-DUB-02`, `TS-SUI-02`).

If the scan finds a recurring, real defect **with no matching rule**, the right product is a
**rule proposal** for [Teste de Software](../../../../knowledge-base/teste-de-software.md) § 6 — suggested ID, text and the
case that motivated it — not a fake citation.

---

## Closing the audit

1. **Turn a probe into a gate.** S3 becomes a lint rule in CI; S4 becomes the corrected exit code; S6 becomes a list of states per critical flow; S9 becomes an issue per `skip`. A finding that only exists in the report comes back in six months.
2. **Separate the three conclusions** — not protected, at the wrong level, broken.
3. **Order by severity**, not by directory.
4. **Give the next step, not the whole list.** Point at the file with the best ratio of cases to value.
5. **If there is active flakiness, the report stops here** and continues in `test-diagnose`: with an untrustworthy suite, no conclusion about coverage is interpretable (`TS-CORE-04`).
6. **Declare what was not verified.** A probe that did not run — the suite does not start, CI is inaccessible, no git history — say which and why. **"Not verified" is not "no findings"**.
