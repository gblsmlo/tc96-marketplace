# Worked example — a click that fails 1 in 4 in CI

`e2e/checkout.spec.ts:52` fails ~25% of runs in CI. It passes locally, always.

---

## Step 0 — is it a real product defect?

The failure is **intermittent** and the product works manually. Continue.

## Step 1 — the trace

`trace: 'on-first-retry'` is on — the artifact exists. (Were it `'off'`, the
**first finding** would be the configuration, and the diagnosis would only begin on the next run.)

## Step 2 — the reading, in four steps

| Tab | What it showed |
| --- | --- |
| Errors | the `click` on "Confirm" failed |
| **Log** of the action | `element intercepts pointer events` |
| **Snapshot Before** | the "item added" toast still on screen, **over** the button |
| Network | nothing abnormal |

Step 2 closed the case. No `console.log` would give that line.

## Step 3 — the tree

Items 1 to 4: there is no `waitForTimeout`, no assertion reading a value, no out-of-order wait,
no `networkidle`. Item 6: **it fails only in CI** → the cause is that the previous step finishes
faster there, and the 3 s toast is still on screen.

## Step 4 — bisection (confirmation)

```
$ bash scripts/isolar.sh e2e/checkout.spec.ts:52 20
== 1. Is it intermittent? 20 runs → FAILED
== 2. Shared state? --workers=1 → passed
== 3. Dependence on another test? → passed
```

Item 2 passing does **not** mean the cause is parallelism: it means the timing changes when run
serially. `--workers=1` diagnoses, it does not fix.

## The finding

```
`PW-ACT-01` — e2e/checkout.spec.ts:52
Symptom: fails ~1 in 4 runs in CI, always on the click on "Confirm"; passes locally.
Evidence: trace, Log tab of the click action — "element intercepts pointer events";
 Snapshot Before shows the "item added" toast still on screen, over the button.
Cause: the toast lasts 3 s and covers the button; in CI the previous step finishes faster.
Fix: do NOT use force: true. Wait for the toast to leave before clicking —
 await expect(page.getByRole('status')).toBeHidden — or fix the toast's z-index/position,
 which is the real defect: the user cannot click either.
See Playwright - Ações e Auto-waiting.
```

## What this example demonstrates

| Decision | Where the rule is |
| --- | --- |
| the **Log** tab gave the cause, not Errors | `leitura-do-trace.md` |
| `force: true` was explicitly discarded | `conserto-x-anestesico.md` |
| the fix points at the **product defect**, not just the test | § *Format*, third rule |
| `--workers=1` was used to confirm, not to fix | `arvore-de-hipoteses.md` |
| the closing is `--repeat-each=20`, not one green run | § *Closing*, item 1 |
