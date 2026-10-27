---
delivery: 2026-10-26-quotes
prd: .specs/PRD.md
adr: [.specs/adr/0001-signed-links.md, .specs/adr/0002-roles.md]
trunk: main
branch: feat/2026-10-26-quotes
status: Approved
---

### 1. From the outside

| Actor | Door | Capabilities |
| --- | --- | --- |
| seller | the quotes page `/quotes`, and `GET /quotes` with a session cookie | CAP-3, CAP-4 |
| admin | the same doors; an admin may do whatever a seller may (ADR-0002) | CAP-3 |
| customer | the approval page `/q/:id?token=…`, and `GET /quotes/:id` and `POST /quotes/:id/decision` with the link's token; no account | CAP-1, CAP-2 |

Outside the code: PostgreSQL through Drizzle, the browser, and `LINK_KEY` in the environment.

### 2. Vocabulary

- **quote status** — `pending`, `approved`, `rejected` — AC-02, AC-03, AC-06
- **decision** — `approve` or `reject`; a quote is decided once — AC-02, AC-03, AC-04
- **signed link** — a token `<issuedAt>.<hmac>` over the quote ID and its issue date, verified and never stored — ADR-0001
- **expired link** — issued more than 30 days ago — AC-05
- **discount** — a whole percent from 0 to 50; the total is never above the list price — AC-07
- **roles** — `admin` and `seller`, checked on the server with `requireRole` — ADR-0002
- **error codes** — 401 no session or invalid link · 403 wrong role · 404 unknown quote · 409 already decided (AC-04) · 410 expired link (AC-05) · 422 invalid body

### 3. Starting point

- `quotes` and `sessions` tables — src/db/schema.ts:3, src/db/schema.ts:14
- `authMiddleware` sets `user` from the session cookie — src/server/auth.ts:6
- `requireRole(role)` — src/server/auth.ts:12
- the Elysia app mounts `quotesRoute` — src/server/index.ts:4
- `bun test` runs unit and component tests; `bun run e2e` runs Playwright — package.json:9-10

### 4. Layers

| Layer | Goal | Owner | Depends on | File | Status | PR |
| --- | --- | --- | --- | --- | --- | --- |
| L1a | One set of schemas, the API's shape and the test environment every later layer codes and tests against | backend-developer | — | `plans/L1a-contracts.md` | merged | #1 |
| L2a | Quotes read and decided in the database, a quote decided once | backend-developer | L1a | `plans/L2a-quotes-repository.md` | merged | #2 |
| L3a | A seller lists their quotes, and a discount never raises a total | backend-developer | L2a | `plans/L3a-quotes-routes.md` | in-review | — |
| L3b | A customer opens and decides a quote with its signed link, no account | backend-developer | L1a, L2a | `plans/L3b-approval-route.md` | waiting | — |
| L4a | The quotes list screen shows each quote's status | frontend-developer | L1a | `plans/L4a-quotes-list-screen.md` | running | — |
| L4b | The approval screen a customer opens from the link | frontend-developer | L1a, L3b | `plans/L4b-approval-screen.md` | waiting | — |

No L5 or L6: every check is provable inside one layer, and G3 runs on L3b, the one layer on an
authentication path.

### 5. Order and branches

L1a first. Then L2a and L4a side by side; L3a and L3b once L2a is merged; L4b once L3b is merged.

| Pull request | From → into | Merged when |
| --- | --- | --- |
| one per layer | `feat/2026-10-26-quotes-<layer>` → `feat/2026-10-26-quotes` | the layer's checks green, G1 and G2 pass, its review `met` |
| the delivery | `feat/2026-10-26-quotes` → `main` | every row of `contract.md` proved on the feature branch, and the owner approves |

### 6. Risks and open gaps

none
