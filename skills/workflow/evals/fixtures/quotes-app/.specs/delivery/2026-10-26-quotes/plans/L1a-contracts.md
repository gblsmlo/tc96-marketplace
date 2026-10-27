---
layer: L1a
delivery: 2026-10-26-quotes
owner: backend-developer
depends: []
status: Approved
---

**Goal.** Every later layer codes against one set of schemas and one API shape, and its gates run
from its first pull request.

**Skills.** `tc96-backend:elysia-schema`, `tc96-backend:bun-test-build`

**Consumes.**
- `quotes` and `sessions` tables — `src/db/schema.ts:3`, `src/db/schema.ts:14`

### Provides

- `QuoteRow` — `{ id: string; sellerId: string; customerEmail: string; listPrice: number; discountPct: number; status: "pending" | "approved" | "rejected"; sentAt: Date; decidedAt: Date | null }`
- `DecisionBody` — `{ decision: "approve" | "reject" }`
- `DiscountPct` — an integer from 0 to 50
- The API's shape:
  - `GET /quotes`, seller or admin session → `200 QuoteRow[]` · `401` · `403`
  - `GET /quotes/:id?token=<signed link>`, no session → `200 QuoteRow` · `401` · `404` · `410`
  - `POST /quotes/:id/decision?token=<signed link>`, body `DecisionBody`, no session → `200 QuoteRow` · `401` · `404` · `409` · `410` · `422`
- The test environment: `bun test` runs every `*.test.ts` and `*.test.tsx` under `src/`, with a
  DOM for component tests; G1 is `bun run lint && bunx tsc --noEmit`.

### Must hold

- A quote's status is one of `pending`, `approved`, `rejected` — AC-06
- A discount is a whole percent from 0 to 50 — AC-07

### Free to decide

The schema library's idioms, file names under `src/`, and how the DOM is loaded for tests.

### Checks

- **C01** (AC-06) a quote row's status accepts `pending`, `approved` and `rejected`, and refuses `cancelled` · `unit`
- **C02** (AC-07) the discount schema accepts 0 and 50, and refuses -1, 51 and 12.5 · `unit`
- **C03** (AC-02) the decision body accepts `approve` and `reject`, and refuses `maybe` and an empty body · `unit`

### Surface, size, done

- **Surface:** `src/contracts/`, `bunfig.toml`, `package.json`
- **Size:** about 90 changed lines with tests; one review family (backend)
- **Done when:** the checks above green, and G1 and G2 pass on this layer's pull request
