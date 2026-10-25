---
type: llm
focus: trace
weight: 1
---

If the rewrite uses db.query with `with`, src/db/client.ts now registers the relations in the drizzle schema object; the tests run without the relation error
