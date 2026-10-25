---
tags: [bun, bun-workspace]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Since the dependency PR last week, `sharp` fails at runtime in CI and on fresh clones with "Could not load the sharp module using the linux-x64 runtime" — but `bun install` finishes without any error, and it worked before. The PR added our internal `@acme/native-tools` package, which has a postinstall step. Review our dependency and workspace setup (root and packages, CI workflow) and tell me what is wrong and exactly how to fix it.

Input files: package.json, bunfig.toml, apps/images/package.json, packages/native-tools/package.json, packages/core/package.json, .github/workflows/ci.yml
