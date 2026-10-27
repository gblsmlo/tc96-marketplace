---
tags: [workflow, review]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash, Agent]
---

Run workflow-review on the layers in review of the delivery 2026-10-26-quotes, this phase only: stop when it hands off.

Environment: git is not installed here. The diff of `feat/2026-10-26-quotes-L3b` against the feature branch `feat/2026-10-26-quotes` is saved at `.sdd/run/2026-10-26-quotes/L3b.diff`; hand a reviewer that path where the phase would hand it the git command. Shell commands run on a read-only file system; write files with the Write tool, and skip the commits on the feature branch.
