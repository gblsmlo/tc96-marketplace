---
type: llm
focus: trace
weight: 1
---

GET /orders/:id returns (not throws) status(404, …) and declares 404 in its response map, so the 404 is part of the route's type
