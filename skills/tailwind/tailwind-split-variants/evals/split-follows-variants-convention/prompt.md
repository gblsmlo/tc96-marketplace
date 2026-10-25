---
tags: [tailwind, tailwind-split-variants]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

this project keeps component styles in separate files (see src/components/ui/card.tsx and card.variants.ts). the newer components in src/components/ui still have their variants inline. split them out the same way, without changing how anything looks.

Input files: package.json, src/components/ui/alert.tsx, src/components/ui/badge.tsx, src/components/ui/button.tsx, src/components/ui/card.tsx, src/components/ui/card.variants.ts, src/features/pricing/pricing.tsx, src/lib/utils.ts
