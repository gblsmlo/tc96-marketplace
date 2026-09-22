# Self-check before delivering

> It is the same scan `playwright-review` would apply. Script: `scripts/autoverificar.sh`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/playwright-build/scripts/autoverificar.sh e2e/orders.spec.ts
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | no `waitForTimeout` | `PW-CORE-05` |
| 2 | every `expect` over a `Locator`/`Page` has `await` | `PW-CORE-04` |
| 3 | no assertion reads a value before asserting | `PW-EXP-01` |
| 4 | no `.first`/`.nth` silencing strict mode | `PW-LOC-02` |
| 5 | no `force: true` without a written reason | `PW-ACT-01` |
| 6 | the event wait is **armed before** the action | `PW-ACT-03` |
| 7 | no `waitUntil: 'networkidle'` | `PW-ACT-04` |
| 8 | navigation by relative path, through `baseURL` | `PW-CFG-05` |
| 9 | the title describes the behavior that stops working | `PW-STR-04` |
| 10 | `toPass` has an explicit `timeout` | `PW-EXP-03` |
| 11 | no leftover `test.only` | `PW-CFG-01` |
| 12 | `skip`/`fixme` with a textual reason | `PW-STR-05` |

Item 2 is the only one **no grep catches well** — the defense is
`@typescript-eslint/no-floating-promises` switched on in the project.

---

## The three checks worth more than the twelve

1. **Break the code on purpose** and confirm the test goes red. Flip a sign,
 invert a condition, remove the call. If nothing breaks, the assertion does not exist
 (`TS-TEC-08` in [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md)). Thirty seconds, and it
 separates a real test from a decorative one.
2. **`npx playwright test <file> --repeat-each=5`** — five green runs are worth more
 than one.
3. **Run the whole suite.** A new test that dirties state breaks its neighbor, and the symptom
 shows up in **another** file.

---

## Closing

1. **If the test needed `getByTestId` or CSS**, record the debt: the finding is about the
 component (`PW-LOC-04`).
2. **If the test turned out slow or fragile**, the question is whether it belongs at this level —
 `test-design`.
3. **Declare what you did not cover.** Error, empty and loading are distinct states and deserve
 their own case (`TS-TIPO-02`). "Not covered" is not "does not exist".
