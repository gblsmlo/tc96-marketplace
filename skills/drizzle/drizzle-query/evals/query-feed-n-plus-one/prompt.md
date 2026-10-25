---
tags: [drizzle, drizzle-query]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Our /feed endpoint got slow — with ~200 published posts a request takes seconds and the database dashboard shows hundreds of queries per request. Rewrite `listFeed` in `src/feed.ts` so a page is cheap. Keep the item shape the frontend uses (see `test/feed.test.ts`), and add pagination since the feed has no limit today: 20 items per page with a cursor for the next page. Tell me how many queries a page costs before and after, and show me how you know.

Input files: package.json, tsconfig.json, src/db/schema.ts, src/db/client.ts, src/db/test-db.ts, src/feed.ts, test/feed.test.ts
