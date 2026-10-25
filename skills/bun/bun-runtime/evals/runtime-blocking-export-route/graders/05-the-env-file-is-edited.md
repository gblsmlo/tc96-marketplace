---
type: llm
focus: trace
weight: 1
---

The .env file is edited so that ADMIN_PASSWORD no longer loses its `$` characters (escaped as \$ or moved out of the runtime .env), and the response explains that Bun's .env loader expands `$` and truncates the value
