---
tags: [design-docs]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Write the spec for quote approval and save it as docs/specs/quote-approval/spec.md. Decided so far:
- Provides POST /quotes/:id/decision with body {decision: "approve" | "reject"}: 200 with the quote, 409 if already decided, 410 if expired.
- Emits the event quote.approved with quoteId and approvedAt.
- Consumes the signed link token from the quote-link spec (docs/specs/quote-link/spec.md, Provides section).
- Fact from the repo search: the quotes table has no status column (src/db/schema.ts:40).
- Decision: links are signed, not stored — we want this for every link we ever add.
- Not doing partial approval.
