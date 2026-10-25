---
type: llm
focus: trace
weight: 1
---

The overdraft guard is enforced by the database write itself (balance >= amount in the debit's where with returning checked) or by a row locked with for('update') inside the transaction — not by comparing a value read without a lock
