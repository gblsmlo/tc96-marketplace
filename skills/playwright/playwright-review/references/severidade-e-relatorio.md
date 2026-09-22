# Severity, format and the cut

---

## Classification

| Severity | What goes in |
| --- | --- |
| **Blocking** | an assertion that asserts nothing (`PW-CORE-04`, `PW-EXP-01`); `.only` without `forbidOnly` (`PW-CFG-01`); a committed `storageState` (`PW-AUTH-02`); `trace: 'off'` in CI (`PW-CFG-02`); an assertion erased by a healer (`PW-AGT-05`); `no-floating-promises` switched off |
| **High** | `waitForTimeout` and `networkidle` (`PW-CORE-05`, `PW-ACT-04`); `force: true` without a reason (`PW-ACT-01`); an account shared between workers (`PW-AUTH-03`); a business rule in E2E (`TS-CORE-02`); a shard without `fullyParallel` (`PW-RUN-01`); a runner option in `use` (`PW-CORE-07`) |
| **Medium** | `.first` (`PW-LOC-02`); a structural CSS locator (`PW-LOC-01`); login in `beforeEach` (`PW-AUTH-01`); a business assertion in a page object (`PW-STR-02`); an absolute URL (`PW-CFG-05`); a screenshot where aria would do (`PW-SNAP-01`); a `skip` without a reason (`PW-STR-05`) |
| **Low** | preference without an ID — **not a finding** |

Two criteria decide the boundary:

- **Blocking × High:** *does the defect make CI lie?* An assertion that asserts nothing, a `.only` without
 a gate and a healer that erased an assertion produce **false green**.
- **High × Medium:** *does it produce flakiness today, or debt for later?* `waitForTimeout` already costs
 time on every run; `.first` is a delayed-action bomb.

---

## Format

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change>
See the corresponding satellite.
```

```
`PW-EXP-01` — e2e/orders.spec.ts:41
expect(await page.getByRole('alert').textContent).toBe('Order created') asserts on a
frozen instant: if the alert appears 40 ms later, the test fails with no defect present.
Fix: await expect(page.getByRole('alert')).toHaveText('Order created').
See Playwright - Assertions.
```

For a probe, **the evidence is the command's output** — paste it:

```
`PW-CFG-01` — playwright.config.ts (absence) + e2e/checkout.spec.ts:18
S2: grep found test.only in checkout.spec.ts:18, and the config does not declare forbidOnly.
CI is green running 1 test out of 214.
Fix: forbidOnly: !!process.env.CI in the config, and remove the.only.
See Playwright - Configuração e Projects.
```

Rules of the format:

- **ID checked in `mapa-de-ids.md`**, and **never an alias**.
- **`file:line` always.**
- **A concrete fix.** If the suite already has the right pattern in another file, point at that
 file: extending the established pattern is worth more than introducing a new one.
- **One satellite link.**

---

## The cut: three things that are **not** findings

| Not a finding | Why |
| --- | --- |
| **the absence of a test** | "this journey has no E2E" is a strategy decision — report it as a question, and the ID would belong to `test-review` |
| **`getByTestId` with the debt recorded** | it is an honest solution when the component has no semantics and will not be fixed in this PR (`PW-LOC-04`). The finding is the test id **without** the record |
| **the choice of suite proportion** | "there is too much E2E" is only a finding with the level argument — and then the ID is `TS-CORE-02`, not `PW-*` |

If the scan finds a recurring, real defect **with no matching rule**, the right product
is a **rule proposal** for [Playwright](../../../../knowledge-base/docs/playwright.md) § 6 — not a fake citation.

---

## Closing the audit

1. **Turn a probe into a gate.** S2 becomes `forbidOnly`; S3 becomes `trace: 'on-first-retry'`; S6 becomes the lint rule in CI; S8 becomes the line in `.gitignore`.
2. **Separate "not protected" from "broken".** A suite can be green, correct and protect nothing.
3. **Separate "wrong level" from "bad test".** A well-written E2E verifying a business rule has no writing defect — the fix is to **move** it, not to improve it.
4. **Order by severity**, not by file.
5. **An exposed credential (S8) goes separately and first.**
6. **Declare what was not verified.** "Not verified" is not "no findings".
7. **If the fix is writing a test**, the source becomes `playwright-build`; if it is investigating a concrete failure, `playwright-diagnose`.
