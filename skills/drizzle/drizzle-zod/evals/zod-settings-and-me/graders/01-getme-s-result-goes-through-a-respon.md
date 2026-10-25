---
type: llm
focus: trace
weight: 1
---

getMe's result goes through a response schema derived from createSelectSchema(users) that leaves passwordHash out (via .omit() or a .pick() allow-list), and a test shows passwordHash is absent
