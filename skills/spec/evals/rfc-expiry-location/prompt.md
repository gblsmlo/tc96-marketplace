---
tags: [spec]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

We need to decide where quote-expiry logic lives: in the browser, in a BFF, or in the backend. A web app and a mobile app both call the API. Write the design doc or RFC for this and save it as design.md.
