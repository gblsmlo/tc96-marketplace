---
tags: [bun, bun-migrate]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Every deploy of this service on ECS gives us a burst of 502s and a few requests that just get cut off mid-flight, for a couple of seconds. The app itself is fine once it's up. Here is the service and the Dockerfile — what is going on, and what should the Dockerfile and the entrypoint look like?

Input files: package.json, src/index.ts, Dockerfile
