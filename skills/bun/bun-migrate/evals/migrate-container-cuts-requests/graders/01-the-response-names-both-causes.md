---
type: llm
focus: trace
weight: 1
---

The response names both causes: the shell-form CMD makes /bin/sh PID 1 so SIGTERM does not reach Bun, and the server has no SIGTERM listener that drains
