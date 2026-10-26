---
feature: F02-approval
prd: F02 — AC-01, AC-02, AC-03
status: Approved
---

### Acceptance criteria (from the PRD)
- **AC-01** Given a valid quote link, when the customer approves, then the quote shows as approved.
- **AC-02** Given a valid quote link, when the customer rejects, then the quote shows as rejected.
- **AC-03** Given a quote sent more than 30 days ago, when the customer opens its link, then they see it expired and cannot decide.

### Provides
#### Decision route
- **Shape:** `POST /quotes/:id/decision`, body `{ decision: "approve" | "reject" }`; 200 with the quote, 409 when already decided, 410 when expired.

### What already exists
- quotes table has no status column — src/db/schema.ts:40
- the quote route file — src/server/quotes.route.ts:12
- the public quote page — src/routes/q.$token.tsx:1

### Boundary decisions
- status lives on the quotes table — one source of truth for the quote's state

### UX
The quote page shows Approve and Reject buttons; after a decision it shows the result. Expired quotes show an expired notice and no buttons.
