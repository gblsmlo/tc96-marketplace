---
id: ADR-0001
status: Accepted
date: 2026-10-01
---

# ADR-0001 — Quote links are signed, not stored

**Decision.** A quote link carries an HMAC-signed token with the quote ID and its issue date. The
server verifies the signature; no link table exists.

**Consequences.** A link cannot be revoked one by one; rotating the key revokes all of them.
