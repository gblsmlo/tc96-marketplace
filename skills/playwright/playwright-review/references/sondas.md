# The eight probes — before reading the code

> In an E2E suite, the worst defects are **invisible to reading**: the files look
> right, CI is green, and even so the trace was never recorded, the gate never closed,
> or the suite only passes because a `test.only` is reducing everything to one case.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/playwright-review/scripts/sondas.sh e2e
```

| Probe | What it measures | What it reveals |
| --- | --- | --- |
| **S1. Version and Node floor** | `node -v`, versions of `@playwright/test` and `playwright` | `PW-CORE-01`, `PW-CORE-03` — Node < 22 does not run 1.62; the two packages out of lockstep is an install bug |
| **S2. `test.only` and the gate** | `.only(` in the suite + `forbidOnly` in the config | `PW-CFG-01` — a forgotten `.only` makes CI green running **one** test |
| **S3. Does a trace exist?** | `trace:` in the config | `PW-CFG-02`, `PW-DBG-05` — `'off'` in CI makes every failure guesswork |
| **S4. Time-based waits** | `waitForTimeout`, `networkidle` | `PW-CORE-05`, `PW-ACT-04` — the two #1 causes of flakiness |
| **S5. An assertion that freezes the instant** | `expect(await ` | `PW-EXP-01` — the most common defect, and the one no linter catches |
| **S6. An assertion without `await`** | `no-floating-promises` in the lint config | `PW-CORE-04` — without that rule, an assertion without `await` passes **always** and nobody sees it |
| **S7. Shard, `fullyParallel`, blob** | config + workflow | `PW-RUN-01`, `PW-RUN-06` — a shard without `fullyParallel` splits by **file**; without blob it produces N reports |
| **S8. Committed `storageState`** | config/suite + `.gitignore` | `PW-AUTH-02` — a live session credential in the git history |

S1, S2, S3, S6, S7 and S8 run in seconds. S4 and S5 are a scan over the suite.

---

## Three mandatory stops

| If the probe shows… | Stop and report before continuing |
| --- | --- |
| **S2**: `.only` without `forbidOnly` | the whole suite may be decorative — CI is green running 1 of N |
| **S8**: `storageState` outside `.gitignore` | a **security finding**, not a test one: different deadline and channel |
| **S3**: `trace: 'off'` | the flakiness audit **stops here** — without a trace there is no diagnosis, and the first finding is the configuration |

And a fourth, which is blocking but does not interrupt: **S6 without `no-floating-promises`** — there
may be any number of assertions that assert nothing, and none shows up as a failure.

---

## What the probe does not catch

| Not detectable by grep | ID | How to find it |
| --- | --- | --- |
| a business rule verified in E2E | `TS-CORE-02` | read what each assertion asserts |
| an assertion erased by a healer | `PW-AGT-05` | compare the test's diff with the corresponding `.md` spec |
| a page object with a business assertion | `PW-STR-02` | read the page objects |
| an account shared between workers | `PW-AUTH-03` | read the authentication setup |
| a test that does everything (fails for six reasons) | § 8.1 of the satellite | read the title and count the business steps |

---

## Related

- `ordem-da-varredura.md` — what to do with what the probes pointed at
- `severidade-e-relatorio.md` — classify and write
- [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) · [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md)
