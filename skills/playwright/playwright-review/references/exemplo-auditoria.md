# Worked example — auditing an E2E suite

A suite of 214 tests, CI green, the team reports that "it sometimes fails".

---

## Step 1 — the probes

```
$ bash scripts/sondas.sh e2e

== S1. Version and Node floor
 node v20.11.0
 package.json:31: "@playwright/test": "^1.62.1"
 package.json:32: "playwright": "^1.58.0" ← out of lockstep
== S2. Leftover test.only, and the gate
 e2e/checkout.spec.ts:18: test.only('completes purchase',...)
 -- forbidOnly in the config: ABSENT
== S3. Does a trace exist?
 playwright.config.ts:14: trace: 'off'
== S4. Time-based waits
 e2e/checkout.spec.ts:22,31,44 waitForTimeout
 e2e/login.spec.ts:9 waitUntil: 'networkidle'
== S6. Assertion without await
 ABSENT — blocking
== S8. Committed storageState
 playwright.config.ts:22: storageState: '.auth/user.json'
 --.gitignore covers the session file? NO
```

**Three stops fired**: S2 (`.only` with no gate), S3 (`trace: 'off'`) and S8 (a committed
session). And S1 shows Node 20 with Playwright 1.62 — which **does not run**.

## Step 2 — the report

```markdown
## E2E suite audit — store

### Security (1) — a different deadline from the rest

`PW-AUTH-02` — playwright.config.ts:22 +.gitignore
S8: storageState writes.auth/user.json, which is not in.gitignore. If it has already been
committed, there is a live session credential in the git history.
Fix: add.auth/ to.gitignore, rotate the session, and rewrite history if the file
 already went in. The test does not change.
See Playwright - Autenticação e Isolamento.

### Blocking (3)

`PW-CFG-01` — playwright.config.ts (absence) + e2e/checkout.spec.ts:18
S2: test.only in checkout.spec.ts:18 and forbidOnly absent. CI is green running
 1 test out of 214.
Fix: forbidOnly: !!process.env.CI in the config, and remove the.only.
See Playwright - Configuração e Projects.

`PW-CFG-02` — playwright.config.ts:14
S3: trace: 'off'. Every CI failure is guesswork, and the flakiness audit cannot start.
Fix: trace: 'on-first-retry'.
See Playwright - Debug e Trace.

`PW-CORE-03` — package.json:31-32
S1: @playwright/test 1.62.1 with playwright 1.58.0, under Node 20. The two packages have to
 be in lockstep, and 1.62 requires Node ≥ 22.
Fix: align both versions and raise the CI's Node.
See Playwright § 0.

### High (2)

`PW-CORE-05` — e2e/checkout.spec.ts:22,31,44
S4: three waitForTimeout calls. It is the #1 cause of flakiness, and costs time on every run.
Fix: replace them with a web-first assertion, which re-waits. The file login.spec.ts:14 already
 uses the right pattern — extend it.
See Playwright - Ações e Auto-waiting.

`PW-ACT-04` — e2e/login.spec.ts:9
S4: waitUntil: 'networkidle' is non-deterministic by nature.
Fix: wait for the UI condition the navigation produces.
See Playwright - Ações e Auto-waiting.

### Not a finding (recorded)

- e2e/reports.spec.ts uses getByTestId with a comment recording the debt: that is an honest
 solution (PW-LOC-04), not a finding.
- "The suite has too much E2E": it only becomes a finding with the level argument — and the ID
 would be TS-CORE-02, in a strategy audit (test-review).

### Not verified

- S5 (expect(await …)): the scan ran, but 6 files use their own helper wrapping
 expect; the grep check does not cover them. It stays open.
- S7: the CI workflow is not in this repository.
```

## What this example demonstrates

| Decision | Where the rule is |
| --- | --- |
| the credential went **first and separately** | `severidade-e-relatorio.md` § *Closing*, item 5 |
| three stops fired and came before the interior | `sondas.md` § *Three mandatory stops* |
| the fix points at the file that already has the right pattern | `severidade-e-relatorio.md` § *Format* |
| `getByTestId` with recorded debt did **not** become a finding | `severidade-e-relatorio.md` § *The cut* |
| "too much E2E" was handed back to the strategy skill | `TS-CORE-02` |
| what the grep did not cover was declared | § *Closing*, item 6 |
