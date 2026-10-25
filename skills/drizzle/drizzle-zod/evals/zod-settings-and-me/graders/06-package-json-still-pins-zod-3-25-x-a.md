---
type: llm
focus: trace
weight: 1
---

package.json still pins zod 3.25.x, and every file that refines or extends a drizzle-zod schema imports z from 'zod/v4' (the classic 'zod' import fails at runtime with these schemas)
