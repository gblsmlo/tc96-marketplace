---
type: llm
focus: trace
weight: 1
---

The response finds that node_modules/fake-apm uses createHook / executionAsyncId, classifies it as blocking or requiring replacement, and backs the claim with a probe executed under Bun (for example hook init count 0 or currentSpan undefined)
