# The tree, and the bisection

> Steps 3 and 4. The full tree is § 5.2 of the [Playwright](../../../../knowledge-base/playwright.md) hub — the most detailed one in the knowledge base.

---

## Walk it without skipping

| # | Check | If yes, the cause is | Rule |
| --- | --- | --- | --- |
| 1 | is there a `waitForTimeout` in the test? | that is the cause, not the symptom | `PW-CORE-05` |
| 2 | does any assertion read a value before asserting? | a frozen instant | `PW-EXP-01` |
| 3 | is the wait armed **after** the action? | the event already passed | `PW-ACT-03` |
| 4 | is there a `waitUntil: 'networkidle'`? | non-deterministic by nature | `PW-ACT-04` |
| 5 | does it depend on data another test created? | order dependence | `PW-CORE-06` |
| 6 | does it fail only in CI? | see `falha-so-em-ci.md` | — |
| 7 | does it fail only with parallelism? | shared state | `PW-AUTH-03` |
| 8 | none of the above | go back to the trace | `PW-DBG-01` |

**What is never the answer:** raising `retries` (`PW-RUN-03`). Retry absorbs **residual**
instability in a healthy suite; using it against a test that fails 30% of the time converts a
diagnosable defect into a permanent CI cost.

---

## Bisection

Script: `scripts/isolar.sh <file[:line]> [repetitions]`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/playwright-diagnose/scripts/isolar.sh e2e/checkout.spec.ts:52 20
```

| Command | If the behavior changes, the cause is |
| --- | --- |
| `--repeat-each=20` | confirms it is intermittent and not deterministic |
| `--workers=1` | **shared state** between workers (`PW-AUTH-03`) |
| the case alone (`file:line`) | **dependence on another test** (`PW-CORE-06`) |
| `--project=chromium` | browser-specific |
| `--headed` | headless-dependent — rare, but real |
| a container with the CI image | **environment parity** (`PW-SNAP-02`) |

> **`--workers=1` diagnoses; it does not fix.** Configuring `workers: 1` because the suite
> passes serially keeps the coupling and leaves the suite N times slower. The same goes for
> prefixing files with `001-`, `002-`: that **encodes** the dependence, and the next
> insertion breaks everything.

---

## Related

- [Playwright](../../../../knowledge-base/playwright.md) § 5.2 — the full tree
- `falha-so-em-ci.md` — branch 6
- `conserto-x-anestesico.md` — what **not** to propose
