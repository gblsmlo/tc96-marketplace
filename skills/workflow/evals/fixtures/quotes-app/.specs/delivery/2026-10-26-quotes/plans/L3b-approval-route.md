---
layer: L3b
delivery: 2026-10-26-quotes
owner: backend-developer
depends: [L1a, L2a]
status: Approved
---

**Goal.** The approval screen can show a quote and send the customer's decision with nothing but
the signed link the seller sent.

**Skills.** `tc96-backend:elysia-build`, `tc96-backend:bun-runtime`, `tc96-backend:bun-test-build`

**Consumes.**
- `GET /quotes/:id` and `POST /quotes/:id/decision` shapes, `DecisionBody` — `plans/L1a-contracts.md#provides`
- `findQuote`, `decideQuote` — `plans/L2a-quotes-repository.md#provides`
- `verifyLink(token, quoteId, now)` → `"valid" | "expired" | "invalid"` — `src/quotes/link.ts:6`

### Provides

- `GET /quotes/:id` and `POST /quotes/:id/decision` as `plans/L1a-contracts.md#provides` states them
- `signLink(quoteId: string, issuedAt: number): string` — the token `verifyLink` accepts
- The link a customer receives: `/q/<id>?token=<signLink(id, issuedAt)>`

### Must hold

- The signed link is the only credential on these two routes; no session is asked for — AC-01, ADR-0001
- A link is verified, never looked up: no link table — ADR-0001
- A link issued more than 30 days ago is refused with 410 — AC-05
- A decided quote is never decided again: 409 — AC-04

### Free to decide

How the routes map repository results to statuses, and how tests fix the clock.

### Checks

- **C08** (AC-01) `GET /quotes/:id` with a valid link and no session cookie → 200 with the quote · `integration`
- **C09** (AC-02) a pending quote, decision `approve` with a valid link → 200 and status `approved` · `integration`
- **C10** (AC-03) a pending quote, decision `reject` with a valid link → 200 and status `rejected` · `integration`
- **C11** (AC-04) an already decided quote, any decision → 409 and the status unchanged · `integration`
- **C12** (AC-05) a link issued 30 days less 1 ms ago → 200; 30 days plus 1 ms ago → 410 · `integration`
- **I1** (—) ADR-0001: a token with a changed signature, or signed for another quote → 401 · `integration`

### Surface, size, done

- **Surface:** `src/server/quotes.route.ts`, `src/server/approval.test.ts`, `src/quotes/link.ts`
- **Size:** about 150 changed lines with tests; one review family (backend)
- **Done when:** the checks above green, G1 and G2 pass on this layer's pull request, and G3: `devops-security` reviews the link path
