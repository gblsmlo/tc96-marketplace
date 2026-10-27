---
layer: L4a
delivery: 2026-10-26-quotes
owner: frontend-developer
depends: [L1a]
status: Approved
---

**Goal.** A seller opens `/quotes` and sees every quote with its status.

**Skills.** `tc96-frontend:tanstack-router`, `tc96-frontend:tanstack-query`, `tc96-frontend:react-developer`, `tc96-backend:bun-test-build`

**Consumes.**
- `GET /quotes` shape, `QuoteRow` — `plans/L1a-contracts.md#provides`

### Provides

- The route `/quotes`
- `quotesQuery` — the query options for `GET /quotes`, key `["quotes"]`

### Must hold

- Each quote shows its status as text: pending, approved or rejected — AC-06
- The client never decides access; it only shows what `GET /quotes` returns — ADR-0002

### Free to decide

Table layout, the status badge's look, and the loading and error copy.

### Checks

- **C13** (AC-06) the quotes table with one approved, one pending and one rejected quote shows each status as text · `component`
- **C14** (AC-06) while loading, on an error and with no quotes, the page shows "Loading quotes…", an alert, and "No quotes yet." · `component`

### Surface, size, done

- **Surface:** `src/routes/quotes.tsx`, `src/routes/quotes.test.tsx`, `src/quotes/queries.ts`, `src/styles/badges.css`
- **Size:** about 110 changed lines with tests; one review family (frontend)
- **Done when:** the checks above green, and G1 and G2 pass on this layer's pull request
