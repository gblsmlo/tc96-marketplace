---
id: ADR-0002
status: Accepted
date: 2026-10-03
---

# ADR-0002 — Two roles, checked on the server

**Decision.** The session carries one role, `admin` or `seller`. Every server route that needs a
role checks it with `requireRole(role)` from `src/server/auth.ts`. The client only hides
controls; it never decides access.

**Consequences.** A new admin-only capability needs no new mechanism: its route calls
`requireRole("admin")`, and its button is hidden for sellers.
