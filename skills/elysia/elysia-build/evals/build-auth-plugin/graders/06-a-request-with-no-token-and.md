---
type: llm
focus: trace
weight: 1
---

A request with no token and an invalid body or params (for example `PATCH /me` with `{ "name": 1 }`, or `DELETE /admin/users/abc`) answers 401, not a 422 that describes the schema — shown by a test
