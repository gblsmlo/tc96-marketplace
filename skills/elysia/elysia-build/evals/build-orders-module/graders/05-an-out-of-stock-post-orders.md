---
type: llm
focus: trace
weight: 1
---

An out-of-stock POST /orders still answers 409 with the sku after the error-handling change (a global handler does not turn it into a 500), shown by a test
