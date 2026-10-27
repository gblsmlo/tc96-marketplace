---
product: quotes-app
owner: product-manager
status: Approved
---

### Summary

Sellers create quotes and send each one as a signed link. Customers open the link and approve or
reject the quote without an account. Sellers follow every quote's status in one list.

### Problem and Opportunity

- **PO-1** Sellers chase customers by email to learn whether a quote was accepted. Source: 14
  support tickets, September 2026.
- **PO-2** Sellers agree on a discount by email, so the quote the customer approves is not the
  price agreed. Source: 5 of the same 14 tickets.

### Target Audience

Sellers of small service businesses, and their customers. Source: onboarding survey, 2026-08.

### Objectives

- **OBJ-1** Median time from quote sent to decision under 3 days. Metric: `decided_at - sent_at`.

### User Stories

**US-1** As a customer, I approve or reject a quote from its link.

- **AC-01** Given a valid link, when the customer opens it, then the quote is shown without login.
- **AC-02** Given a pending quote, when the customer approves it, then its status is `approved`.
- **AC-03** Given a pending quote, when the customer rejects it, then its status is `rejected`.
- **AC-04** Given a decided quote, when someone decides again, then the request returns 409.
- **AC-05** Given a link older than 30 days, when the customer opens it, then it returns 410.

**US-2** As a seller, I follow my quotes.

- **AC-06** Given the quotes page, when a seller opens it, then each quote shows its status:
  pending, approved or rejected.

**US-3** As a seller, I give a discount.

- **AC-07** Given a quote, when the seller sets a discount, then it is between 0% and 50%, and the
  total is never above the list price.

### Capabilities

| ID | Capability | Satisfies | Priority |
| --- | --- | --- | --- |
| CAP-1 | A customer opens a quote from its signed link, without an account | AC-01, AC-05 | P0 |
| CAP-2 | A customer approves or rejects a pending quote, once | AC-02, AC-03, AC-04 | P0 |
| CAP-3 | A seller follows each quote's status in one list | AC-06 | P0 |
| CAP-4 | A seller gives a discount within the allowed range | AC-07 | P1 |

### Out of Scope

- Exporting quotes (CSV, PDF): deferred; no customer asked for it yet.
- Customer accounts: a customer never logs in.

### Traceability

| Item | Capabilities |
| --- | --- |
| PO-1 | CAP-1, CAP-2, CAP-3 |
| PO-2 | CAP-4 |
| OBJ-1 | CAP-2, CAP-3 |

### Open gaps

none

## Amendment 001 — 2026-10-26 — Admins export the quotes list as CSV
status: Draft

- Removes "Exporting quotes (CSV, PDF)" from Out of Scope for CSV only; PDF stays out.
- **AC-08** Given an admin on the quotes page, when they press Export, then a CSV of every quote
  downloads, one row per quote: customer email, list price, discount, status, sent date.
- **AC-09** Given a seller, when they request the export, then the server returns 403 and the
  page shows no Export button.
- **CAP-5** An admin exports every quote as CSV · satisfies AC-08, AC-09 · priority P1.
- Traceability: PO-1 gains CAP-5.
- Open gaps: the CSV's date format — decides: owner.
