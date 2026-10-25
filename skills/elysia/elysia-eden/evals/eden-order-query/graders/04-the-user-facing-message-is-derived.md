---
type: llm
focus: trace
weight: 1
---

The user-facing message is derived from `error.status`/`error.value` (for example "not found" for 404) and never from `error.message`; a test shows the text is not "[object Object]"
