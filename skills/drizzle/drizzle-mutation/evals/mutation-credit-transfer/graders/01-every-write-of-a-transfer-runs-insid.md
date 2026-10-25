---
type: llm
focus: trace
weight: 1
---

Every write of a transfer runs inside one db.transaction, and every statement inside it uses the transaction handle — the outer db is no longer used for the credit
