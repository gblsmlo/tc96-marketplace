---
tags: [drizzle, drizzle-query]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Implement `searchPosts` in `src/search.ts` for our GET /search endpoint. It returns published posts only, newest first (by publishedAt). Filters are all optional and combine with AND: `tag` (posts that carry that tag), `authorId`, and `q` (case-insensitive match on the title). Each result carries the author's id and name and the full list of the post's tag names, sorted. `limit` defaults to 20 and must never exceed 50. This endpoint gets a lot of traffic, so keep it to a fixed number of queries no matter how many posts match. Add tests next to the existing setup and tell me what you ran.

Input files: package.json, src/db/client.ts, src/db/schema.ts, src/db/test-db.ts, src/search.ts, test/smoke.test.ts, tsconfig.json
