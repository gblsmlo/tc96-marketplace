---
type: llm
focus: trace
weight: 1
---

src/config.ts validates DATABASE_URL, PORT and ADMIN_PASSWORD at startup, and the response shows a real boot with a missing or malformed variable exiting non-zero with the validation message
