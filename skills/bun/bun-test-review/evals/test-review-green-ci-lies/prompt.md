---
tags: [bun, bun-test-review]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Review the test suite of this project. CI has been green for months, but last week a payment that should have been declined went through in production. Tell me what is wrong with the suite, in order of severity, with file and line, and what to change.

Input files: package.json, tsconfig.json, bunfig.toml, .github/workflows/ci.yml, src/price.ts, src/charge.ts, src/cart.ts, test/setup.ts, test/price.test.ts, test/payment.test.ts, test/cart.test.ts, test/helpersTests.ts
