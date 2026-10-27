---
tags: [workflow, search]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash, Agent]
---

Run workflow-search on this request, and stop after the triage (search only; do not plan):

"Bug: a quote with a negative discount ends up priced above its list price. Clamp the discount to the range the product already promises."
