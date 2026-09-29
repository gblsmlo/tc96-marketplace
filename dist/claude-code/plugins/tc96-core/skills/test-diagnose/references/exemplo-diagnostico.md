# Worked example — diagnosing a suite

The team re-runs the job by reflex. Nobody investigates red before trying again.

---

## Step 0 — are the failures real defects?

No: same commit, same suite, different results. **Intermittent** → this skill's job.

## Step 1 — the measurement

```
$ bash scripts/medir-flakiness.sh "bunx playwright test" 20

== Anesthetics already installed
 -- retry configured:
 playwright.config.ts:12: retries: 3
 -- fixed-time waits, cause #1 (TS-SUI-07):
 e2e/checkout.spec.ts:22,31,44,58,63,71,88 (7 occurrences)
 -- accumulated skip / todo:
 e2e/payment.spec.ts:1
== Flakiness rate
..F....F..F.....F..F
 runs: 20 | failures: 5 | rate: 25.0%
 ABOVE ~1%: the suite has lost value.
```

The CI history confirms it: **34 of the last 200 runs** failed and passed on re-run with no
code change = **17%**.

## Step 2 — the six questions

Question 1: yes, intermittent. **Stop here** — flakiness contaminates everything else, and
answering the other five before resolving this one produces a diagnosis about noise.

## Step 3 — the cause

9 of the 12 files in `e2e/` use a **fixed-time wait** before the assertion (`TS-SUI-07`).
The other 3 share the same test account across workers (`TS-SUI-09`) — confirmed
because, with `--workers=1`, the failure disappears.

## The report

```
`TS-CORE-04` — the e2e/ suite, last 200 CI runs
Symptom: the team re-runs the job by reflex; nobody investigates red before trying again.
Measurement: 34 of 200 runs failed and passed on re-run with no code change = 17%
 flakiness rate. The threshold at which a suite loses value is ~1%.
Cause: 9 of the 12 files in e2e/ use a fixed-time wait before the assertion (TS-SUI-07);
 the other 3 share the same test account across workers (TS-SUI-09).
Fix: (1) replace time waits with an assertion that re-waits — start with
 e2e/checkout.spec.ts, which has 7 occurrences; (2) one account per worker.
 DO NOT raise retries: at 17%, retry masks and does not resolve (TS-SUI-03).
See Teste de Software - Confiabilidade da Suíte, and Playwright § 5.2 for the concrete forms.
```

And the second finding, of another nature — it came from the **thirty-second test**:

```
`TS-SUI-04` — packages/core/src/discount.ts
Symptom: the suite passes 100% and a discount calculation defect reached production.
Measurement: thirty-second test — with the comparison `>=` inverted to `>` on line 22,
 the whole suite stayed green (0 tests failed).
Cause: the 14 discount tests call the function and assert that it does not throw; none
 compares the returned value. File coverage: 96%.
Fix: assert on the value, with the boundary-value cases (TS-TEC-01):
 0%, 50%, 50.01%, 100%, −5%.
See Teste de Software - Técnicas de Design de Caso.
```

## What this example demonstrates

| Decision | Where the rule is |
| --- | --- |
| the measurement came before the opinion, and the number has a threshold | `medicao.md` |
| question 1 interrupted the other five | `causas-de-flake.md` |
| `--workers=1` was used to **diagnose**, not to fix | `conserto-x-anestesico.md` |
| "raise retries" was explicitly discarded in the report | `TS-SUI-03` |
| 96% coverage and a defect in production coexist without contradiction | `deteccao.md` |
| every fix has a named starting point | `TS-CORE-04` |
