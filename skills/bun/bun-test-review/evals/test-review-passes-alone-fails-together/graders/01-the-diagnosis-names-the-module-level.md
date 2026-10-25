---
type: llm
focus: trace
weight: 1
---

The diagnosis names the module-level state in src/registry.ts, set by test/locale.test.ts and never reset, as the cause, and explains that bun test runs every file in one process with a shared global by default
