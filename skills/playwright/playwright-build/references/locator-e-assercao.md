# Locator and assertion — the inseparable pair

> Steps 2 and 3. The full trees are § 5.1 of the [Playwright](../../../../knowledge-base/docs/playwright.md) hub,
> [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) and [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md).

---

## Locator, in priority order

1. `getByRole('role', { name })` — the default, and the right path in most cases (`PW-LOC-01`).
2. `getByLabel` / `getByPlaceholder` / `getByAltText` / `getByText` — case by case.
3. `getByTestId` — the escape hatch, and **record the debt** (`PW-LOC-04`).
4. `locator('css=…')` — last resort, with a justification on the line above.

**Resolved to more than one element?** The answer is **not** `.first` (`PW-LOC-02`). It is, in this
order: `filter({ hasText })`, chaining inside a container, `filter({ has: … })`.

**`getByRole` cannot reach the element?** In most cases the finding is about the
**component**, not about the test — a missing role or accessible name. Follow the bridge in § 8 of
the hub instead of dropping down to CSS.

**Generate the locator, do not write it from memory.** `npx playwright codegen <url>` or the UI mode's
pick locator already prioritizes role, text and test id — it solves `PW-LOC-01` without requiring
discipline. But **codegen's output is not the test** (`PW-DBG-06`): extract the locators and rewrite.

---

## Assertions

One rule dominates all of them: **assert on the condition, never on a read value** (`PW-EXP-01`).

```ts
// ✗ freezes one instant
expect(await page.getByText('Saved').isVisible).toBe(true);
// ✓ re-waits
await expect(page.getByText('Saved')).toBeVisible;
```

And the twin defect, which passes **always**: a web-first assertion without `await` (`PW-CORE-04`). The
only automatic defense is `@typescript-eslint/no-floating-promises` — confirm it is switched on. The
two are **not** the same defect and require different fixes (§ 6.2 of the hub).

| Situation | Use |
| --- | --- |
| UI state | `expect(locator).…` |
| a whole list | `toHaveText([...])` — checks order and content with retry |
| an HTTP response | `await expect(response).toBeOK` |
| a value outside the UI that takes time | `expect.poll(...)` |
| a block with several assertions that takes time | `expect(fn).toPass({ timeout })` — **timeout required** (`PW-EXP-03`) |
| UI structure | `toMatchAriaSnapshot` **before** `toHaveScreenshot` (`PW-SNAP-01`) |

**Never** assert absence on its own: `not.toBeVisible` also passes with the wrong locator.
Assert the expected positive state (`PW-EXP-06`).

---

## Related

- [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) · [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) — this skill's two sources
- `ambiente-e-estrutura.md` — what to replace, and how to organize
- `mapa-de-ids.md` — where each `PW-*` is declared
