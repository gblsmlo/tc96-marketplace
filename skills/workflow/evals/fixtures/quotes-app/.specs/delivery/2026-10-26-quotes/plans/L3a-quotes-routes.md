---
layer: L3a
delivery: 2026-10-26-quotes
owner: backend-developer
depends: [L2a]
status: Approved
---

**Goal.** The quotes screen can load a seller's quotes over HTTP, and any total shown applies the
discount without ever rising above the list price.

**Skills.** `tc96-backend:elysia-build`, `tc96-backend:bun-test-build`

**Consumes.**
- `GET /quotes` shape — `plans/L1a-contracts.md#provides`
- `listQuotesBySeller` — `plans/L2a-quotes-repository.md#provides`
- `requireRole(role)` — `src/server/auth.ts:12`

### Provides

- `GET /quotes` as `plans/L1a-contracts.md#provides` states it
- `applyDiscount(listPrice: number, discountPct: number): number` — the total a quote shows

### Must hold

- Only a seller or an admin lists quotes, checked on the server with `requireRole` — ADR-0002
- The total is never above the list price — AC-07

### Free to decide

Where `applyDiscount` lives inside the Surface, and the rounding of a fractional total.

### Checks

- **C06** (AC-06) `GET /quotes` with a seller's session → 200 with that seller's quotes, each with its status · `integration`
- **C07** (AC-07) on a list price of 1000, `applyDiscount` gives 1000 at 0%, 900 at 10% and 500 at 50% · `unit`
- **I2** (—) ADR-0002: `GET /quotes` with no session → 401 · `integration`

### Surface, size, done

- **Surface:** `src/server/quotes.route.ts`, `src/server/quotes.test.ts`, `src/quotes/discount.ts`, `src/quotes/discount.test.ts`
- **Size:** about 100 changed lines with tests; one review family (backend)
- **Done when:** the checks above green, and G1 and G2 pass on this layer's pull request
