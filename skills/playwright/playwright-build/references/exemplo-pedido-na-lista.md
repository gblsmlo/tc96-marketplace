# Worked example — the created order appears in the list

Task: *"test that the created order appears in the list"*.

---

## Step 1 — the three questions

| Question | Answer |
| --- | --- |
| what can go wrong? | the listing does not reflect the just-created order |
| journey or rule? | **journey** — were it a rule, it would go to `bun-test-build` |
| does the state exist or do I have to create it? | create — and **through the API** (`PW-NET-06`) |

The third is the one that saves most time: twelve clicks to reach the test's subject become
one `POST`, and the test starts failing for **one** reason instead of for any defect along the
way.

## The test

```ts
import { test, expect } from './fixtures'; // PW-FIX-05: never from '@playwright/test'

test('created order appears in the list immediately', async ({ page, request }) => {
 const r = await request.post('/orders', { data: { item: 'Coffee' } });
 await expect(r).toBeOK;
 const { id } = await r.json;

 await page.goto('/orders'); // relative — PW-CFG-05

 await expect(
 page.getByRole('row').filter({ hasText: String(id) }) // PW-LOC-01 + filter, not.first
 ).toBeVisible; // web-first — PW-EXP-01
});
```

## What these decisions prevented

| Decision | Bad alternative | Rule |
| --- | --- | --- |
| creating the order through `request` | 12 clicks in the creation form | `PW-NET-06` |
| `getByRole('row').filter(…)` | `page.locator('tr').nth(1)` | `PW-LOC-01`, `PW-LOC-02` |
| `await expect(...).toBeVisible` | `expect(await....isVisible).toBe(true)` | `PW-EXP-01` |
| `page.goto('/orders')` | `page.goto('http://localhost:3000/orders')` | `PW-CFG-05` |
| a title with the behavior | `test('orders')` | `PW-STR-04` |
| `test`/`expect` from `./fixtures` | from `@playwright/test` | `PW-FIX-05` |

No `waitForTimeout`: the web-first assertion re-waits on its own.

## Self-check

```
$ bash scripts/autoverificar.sh e2e/orders.spec.ts
 1. ✓ no waitForTimeout
...
12. ✓ test/expect come from the project's module
```

Then, the three that are worth most: breaking the code on purpose (the assertion **does** go red),
`--repeat-each=5`, and the whole suite.
