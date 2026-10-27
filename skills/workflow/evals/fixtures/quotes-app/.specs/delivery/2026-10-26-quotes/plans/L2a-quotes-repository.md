---
layer: L2a
delivery: 2026-10-26-quotes
owner: backend-developer
depends: [L1a]
status: Approved
---

**Goal.** The routes read a seller's quotes and decide a quote without touching SQL, and a quote is
decided once even when two decisions arrive together.

**Skills.** `tc96-backend:drizzle-query`, `tc96-backend:drizzle-mutation`, `tc96-backend:bun-test-build`

**Consumes.**
- `QuoteRow`, `DecisionBody` — `plans/L1a-contracts.md#provides`

### Provides

- `listQuotesBySeller(db: Database, input: { sellerId: string }): Promise<QuoteRow[]>`
- `findQuote(db: Database, input: { id: string }): Promise<QuoteRow | null>`
- `decideQuote(db: Database, input: { id: string; decision: "approve" | "reject"; now: Date }): Promise<{ ok: true; quote: QuoteRow } | { ok: false; reason: "not-found" | "already-decided" }>`

### Must hold

- A quote is decided once: the write applies only while the quote is `pending` — AC-04
- A seller reads only their own quotes — ADR-0002

### Free to decide

Query shape, transaction or guarded update, and the test database's setup.

### Checks

- **C04** (AC-06) a seller with three quotes gets exactly those three with their status, never another seller's, and a seller with none gets an empty list · `integration`
- **C05** (AC-04) two decisions on one pending quote at once: one is `ok`, the other `already-decided`, and the status is the first decision's · `integration`

### Surface, size, done

- **Surface:** `src/db/quotes.ts`, `src/db/quotes.test.ts`
- **Size:** about 120 changed lines with tests; one review family (backend)
- **Done when:** the checks above green, and G1 and G2 pass on this layer's pull request
