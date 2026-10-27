# quotes-app

Sellers send quotes; customers approve or reject them from a signed link.

- Stack: Bun, Elysia (`src/server/`), TanStack Router (`src/routes/`), Drizzle on PostgreSQL (`src/db/`).
- Tests: `bun test` for unit, integration (`src/server/`, `src/db/`) and component (`src/routes/`) tests; `bun run e2e` for Playwright.
- Delivery flow: `.specs/` holds the PRD, ADRs, triage files and delivery plans (`.specs/delivery/<date>-<slug>/`: the index `plan.md`, one file per layer under `plans/`, and `contract.md`); `.sdd/` is runtime state, git-ignored.
