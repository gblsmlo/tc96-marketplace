---
tags: [elysia, elysia-openapi]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

A partner team will generate a Python client from our OpenAPI document (`/openapi/json`). Get the spec ready for code generation: every operation must be identifiable and documented with the responses it can give, the auth requirements must be in the spec, and the docs must not be publicly reachable in production. Add a test that guards the spec.

Input files: package.json, src/app.ts, src/auth.ts, src/index.ts, src/users.ts, tsconfig.json
