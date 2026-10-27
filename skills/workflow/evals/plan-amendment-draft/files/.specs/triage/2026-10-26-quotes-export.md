---
request: "Add a CSV export of the quotes list, for admins only, with an Export button on the quotes page."
date: 2026-10-26
route: amendment
---

### Slices

| # | Axis | Slice | Entities · capabilities | Answer | Source | Verdict | Next step |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S1 | product | Admins can export the quotes list as CSV | Quote · export | exporting is Out of Scope | record: .specs/PRD.md | product-decision | plan · product-manager, amendment |
| S2 | stack | Only admins may export | Session · role | `requireRole("admin")` on the route | record: .specs/adr/0002-roles.md | exists | nothing |
| S3 | backend | A route that returns the quotes as CSV | Quote · read | `GET /quotes` returns the seller's own quotes; no export route | code: src/server/quotes.route.ts:10 | build | plan · spec-writer, delivery plan |
| S4 | frontend | An Export button on the quotes page, hidden for sellers | Quotes page · button | the page has no toolbar | code: src/routes/quotes.tsx:18 | build | plan · spec-writer, delivery plan |

### Facts

- S3 — `GET /quotes` selects the logged-in seller's quotes, behind `requireRole("seller")`; an all-sellers export needs its own query — src/server/quotes.route.ts:10
- S3 — the delivery 2026-10-26-quotes is merged; its `listQuotesBySeller` reads one seller's quotes only — .specs/delivery/2026-10-26-quotes/plans/L2a-quotes-repository.md
- S4 — the quotes page renders a table with no toolbar — src/routes/quotes.tsx:18

### Route

1. amendment: S1 — product-manager
2. delivery plan: S3 backend `GET /quotes/export.csv`, S4 frontend button consuming it (proposed) — spec-writer

### Gaps

- The CSV's date format — decides: owner
