---
type: llm
focus: trace
weight: 1
---

An insufficient-funds transfer leaves both balances and the transfers table unchanged, proven by a test, and fails with an error the caller can tell apart (a domain error class or a handled TransactionRollbackError), not a generic Error('rollback')
