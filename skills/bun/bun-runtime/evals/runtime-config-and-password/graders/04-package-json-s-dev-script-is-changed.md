---
type: llm
focus: trace
weight: 1
---

package.json's dev script is changed from --hot to --watch, and the response ties the change to the module-level sessions Map in src/server.ts
