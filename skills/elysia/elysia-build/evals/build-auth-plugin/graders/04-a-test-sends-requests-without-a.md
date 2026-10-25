---
type: llm
focus: trace
weight: 1
---

A test sends requests without a token to routes defined in the feature modules (`/me` or `/admin/...`), not only to routes inside the auth plugin, and they get 401
