---
tags: [spec]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Plan the increment "approval expiry" as tasks. Backend adds an expiresAt field to quotes and rejects approval of expired quotes. Frontend shows an expired state on the approval screen. Plan 0001 already exists for this capability (quote-approval). Save the plan as a markdown file in the current folder.
