---
product: Quotes
owner: product-manager
status: Approved
---

### Summary
Customers approve quotes online.

### Problem and Opportunity
- **PO-1** Approvals stall about 3 days — source: support tickets

### Objectives
| ID | Objective | Metric | Target |
| --- | --- | --- | --- |
| OBJ-1 | Faster approvals | median time from send to approval | from 3 days to 1 |

### User Stories
1. **US-1 Approve a quote online**
   As a customer, I want to approve or reject a quote from its link, so that my order starts without email back-and-forth.
   - **AC-01** Given a valid quote link, when the customer approves, then the quote shows as approved.
   - **AC-02** Given a valid quote link, when the customer rejects, then the quote shows as rejected.
   - **AC-03** Given a quote sent more than 30 days ago, when the customer opens its link, then they see it expired and cannot decide.
   - **AC-04** Given an approval, when it is saved, then the sales rep who sent the quote is notified.

### Functionalities
| ID | Feature | Satisfies | Provides | Consumes (from) | Priority |
| --- | --- | --- | --- | --- | --- |
| F01 | Quote link — a signed link to one quote | — | a signed link to one quote | — | P0 |
| F02 | Approval — approve or reject from the link | AC-01, AC-02, AC-03 | approved quote event | signed link (F01) | P0 |
| F03 | Sales notification | AC-04 | — | approved quote event (F02) | P1 |
