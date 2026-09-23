# A failure that only happens in CI

> Four causes, in order of frequency.

| Cause | Signal | Fix |
| --- | --- | --- |
| **CI is slower** | a 30 s timeout on a legitimate wait | read the trace **before** raising the timeout; usually the target never became actionable |
| **environment parity** | a screenshot differs because of font antialiasing | generate the reference in a container with the CI image (`PW-SNAP-02`) |
| **server state** | workers competing for the same account | one account per worker through `parallelIndex` (`PW-AUTH-03`) |
| **setup did not run** | everything fails pointing at the login screen | the setup wrote `storageState` without verifying the login (`PW-AUTH-06`) |

---

## Two CI-specific traps that look like flakiness

- **A Service Worker intercepting before the `route`** — the network events simply do not
 appear. `serviceWorkers: 'block'` is the **first** hypothesis to check, not the last
 (`PW-NET-03`).
- **Images blocked by a `route` in a suite with screenshots** — the reference has the
 images, the run does not (`PW-SNAP-06`).

---

## The rule that runs through all four

Raising the timeout is the right answer **only** when the trace shows the target became
actionable and the time was not enough. In the other three cases a larger timeout only delays the
failure and lengthens every run.

---

## Related

- [Playwright - Execução, Retries e CI](../../../../knowledge-base/playwright-execucao-retries-e-ci.md) · [Playwright - Snapshots e Visual](../../../../knowledge-base/playwright-snapshots-e-visual.md) · [Playwright - Autenticação e Isolamento](../../../../knowledge-base/playwright-autenticacao-e-isolamento.md)
- `arvore-de-hipoteses.md` — where this branch comes from
