---
layer: L4b
delivery: 2026-10-26-quotes
owner: frontend-developer
depends: [L1a, L3b]
status: Approved
---

**Goal.** A customer opens the link, sees the quote and approves or rejects it, with no account.

**Skills.** `tc96-frontend:tanstack-router`, `tc96-frontend:tanstack-query`, `tc96-frontend:react-developer`, `tc96-backend:bun-test-build`

**Consumes.**
- `GET /quotes/:id` and `POST /quotes/:id/decision` shapes — `plans/L1a-contracts.md#provides`
- The link a customer receives — `plans/L3b-approval-route.md#provides`

### Provides

- The route `/q/$id`, search param `token`

### Must hold

- The page asks for no login — AC-01
- A 409 and a 410 each tell the customer what happened, in words — AC-04, AC-05

### Free to decide

Layout, copy beyond the states above, and how the mutation reports progress.

### Checks

- **C15** (AC-01) the approval page with a valid link shows the quote's price and the approve and reject buttons, with no login prompt · `component`
- **C16** (AC-04) after a 409, the page says the quote was already decided and hides both buttons · `component`
- **C17** (AC-05) after a 410, the page says the link expired · `component`

### Surface, size, done

- **Surface:** `src/routes/q.$id.tsx`, `src/routes/q.$id.test.tsx`
- **Size:** about 130 changed lines with tests; one review family (frontend)
- **Done when:** the checks above green, and G1 and G2 pass on this layer's pull request
