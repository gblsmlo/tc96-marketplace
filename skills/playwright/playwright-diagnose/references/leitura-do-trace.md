# Obtaining and reading the trace

> Steps 1 and 2. **Reading the trace comes before touching the code** (`PW-DBG-01`) — it is what
> separates this skill from trial and error.

---

## Obtaining it

| Situation | Command |
| --- | --- |
| it failed in CI | download the `playwright-report` artifact, then `npx playwright show-report <folder>` |
| you have the `.zip` | `npx playwright show-trace test-results/…/trace.zip` |
| you want to reproduce locally | `npx playwright test <file>:<line> --trace on` |
| there is no trace at all | **that is the first finding** — `PW-CFG-02`, `PW-DBG-05` |

Without a configured trace, every CI failure is guesswork. If `trace` is `'off'`, the fix is the
**configuration**, not the test — and the diagnosis only begins on the next run.

> **Never** use `--debug` to decide whether it is flakiness: it forces `timeout=0` and `workers=1`, so
> it **always passes** (`PW-DBG-02`). Concluding "it passes under debug, so it is not flaky" is invalid.

---

## Reading it, in four steps

| # | Tab | Answers |
| --- | --- | --- |
| 1 | **Errors** | which action failed |
| 2 | the **Log** for that action | **at which check** it stalled |
| 3 | **Snapshot Before** | what was on screen at that moment |
| 4 | **Network** | which request failed or never came back |

Step 2 is what no `console.log` gives, and it is where the cause appears:

| Message in the Log | Cause | Rule |
| --- | --- | --- |
| `waiting for element to be visible` | the target never appeared: wrong locator, or a different screen | `PW-LOC-01` |
| `element is not stable` | an animation in progress | § 1 of the actions satellite |
| `element intercepts pointer events` | **an overlay stealing the click** — that is a product defect | `PW-ACT-01` |
| `element is not enabled` | a disabled button: hydration, or an unmet precondition | § 7.2 of the actions satellite |
| `strict mode violation` | an ambiguous locator | `PW-LOC-02` |

Step 3 usually closes the case: the snapshot shows the open modal, the spinner turning, the
error screen, or **the login page nobody expected** — which is the authentication setup
failing (`PW-AUTH-06`).

---

## Related

- [Playwright - Debug e Trace](../../../../knowledge-base/playwright-debug-e-trace.md) § 3 — the source of this reading
- `arvore-de-hipoteses.md` — what to do when the trace does not close the case
