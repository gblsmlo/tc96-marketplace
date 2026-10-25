---
type: llm
focus: trace
weight: 1
---

The CI workflow pins the Bun version, installs with bun ci or --frozen-lockfile, and has a step that reaches tsc --noEmit directly or through a package.json script
