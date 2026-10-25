---
type: llm
focus: trace
weight: 1
---

src/auth/password.ts hashes and verifies with Bun.password, and no password path uses crypto.createHash, Bun.hash or a hand-rolled hash
