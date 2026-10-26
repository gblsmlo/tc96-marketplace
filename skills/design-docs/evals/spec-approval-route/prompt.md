---
tags: [design-docs]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Write the spec for F02 (approval) and save it as .specs/features/F02-approval/spec.md. Decided so far:
- Provides POST /quotes/:id/decision with body {decision: "approve" | "reject"}: 200 with the quote, 409 if already decided, 410 if expired.
- Emits the event quote.approved with quoteId and approvedAt.
- Consumes the signed link token from F01 (see F01's spec, Provides section).
- Fact from the repo search: the quotes table has no status column (src/db/schema.ts:40).
- Decision: links are signed, not stored — we want this for every link we ever add.
- Not doing partial approval.
