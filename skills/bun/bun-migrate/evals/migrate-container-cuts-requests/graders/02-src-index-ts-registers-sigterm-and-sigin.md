---
type: llm
focus: trace
weight: 1
---

src/index.ts registers SIGTERM (and SIGINT) handlers that await server.stop() and then call process.exit()
