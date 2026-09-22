# The nine probes — measure the shape before judging

> The shape of a suite is **invisible** when reading files: every test looks reasonable, and the
> whole is unbalanced. These nine measure the whole.

Script: `scripts/sondas-suite.sh [root]` — runs S1, S3–S9 and prepares S2.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/test-review/scripts/sondas-suite.sh.
```

---

| Probe | What it measures | What it reveals |
| --- | --- | --- |
| **S1. Suite shape** | cases per level (`test(`/`it(` per directory) | `TS-NIV-04` — mass in E2E is an *ice-cream cone*; no E2E at all is something else |
| **S2. Duration** | time per level, separately | `TS-SUI-*` — a suite nobody runs before the PR has stopped being a gate |
| **S3. Static layer** | `strict`, `noUncheckedIndexedAccess`, `no-floating-promises` | `TS-TIPO-08` — the cheapest layer, and frequently switched off |
| **S4. Does the gate close?** | `continue-on-error`, `\|\| true`, `exit 0` in the workflow | `TS-PROC-03` — a step that runs and does not fail is decorative |
| **S5. Coverage target** | `coverageThreshold`, `codecov`, `--coverage` | `TS-CORE-05` — a coverage target is a **finding**, not a virtue |
| **S6. Risk classes** | occurrence of the five states in the tests | `TS-TIPO-02` — the **error** state is the most absent |
| **S7. Non-functional attribute** | `p95`, `k6`, `lighthouse`, `axe` | `TS-TIPO-05` — a requirement without a number is not verified |
| **S8. Escapes** | fix commits × tests added alongside | `TS-CORE-06` — a production defect without a test comes back |
| **S9. `skip` and debt** | `.skip(`, `.todo(`, `fixme` | `TS-SUI-11` — a `skip` without a reason is anonymous debt |

S1, S3, S5, S6, S7 and S9 are mechanical reading. **S2 requires running**; **S4 requires reading
the CI**; **S8 requires git history**.

---

## Three mandatory stops

| If the probe shows… | Stop and report before continuing |
| --- | --- |
| **S1 with an inverted shape** | criticizing an individual test becomes noise: the fix is moving assertions down, and it rewrites much of the suite |
| **S4 with a gate that does not fail** | a CI that exits `0` regardless makes every discussion of coverage decorative — it is the finding that best explains "we have tests and it still breaks" |
| **S3 with `no-floating-promises` off** in a project with Playwright | **blocking**: there may be any number of `expect(...)` calls without `await`, and none shows up as a failure ([Playwright](../../../../knowledge-base/docs/playwright.md) `PW-CORE-04`) |

---

## What the probe does not measure

| Not detectable | Rule | How to find it |
| --- | --- | --- |
| a business rule verified in E2E | `TS-NIV-02` | sample 10 E2E files and read what each assertion asserts |
| the same logic at three levels | `TS-CORE-02` | look for the same domain name at different levels |
| mocking what the test came to prove | `TS-CORE-03` | read the doubles in the integration tests |
| a fake without declared fidelity | `TS-DUB-03` | read the fake and ask whether it honors the real contract |
| an assertion that does not detect a break | `TS-SUI-04` | the thirty-second test — that belongs to `test-diagnose` |

**Coverage substitutes for none of these.** A test that calls the function and asserts nothing
gives full coverage (`TS-CORE-05`).

---

## Related

- `ordem-da-varredura.md` — what to do with what the probes pointed at
- `severidade-e-relatorio.md` — how to classify and write
- [Teste de Software - Processo e Artefatos](../../../../knowledge-base/docs/teste-de-software-processo-e-artefatos.md) — the gates
