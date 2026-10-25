---
tags: [spec]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Record this decision as an ADR: we store sessions in PostgreSQL instead of Redis, because ops does not want another service to run. The highest ADR we have so far is 0004. Save it in the current folder.
