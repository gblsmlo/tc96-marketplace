---
name: tailwind-migrate
description: Upgrade Tailwind CSS v3 to v4: renamed classes, changed defaults, CSS config
source: "[Tailwind CSS - Migration v3 to v4](docs/tailwindcss-migration-v3-to-v4.md)"
docs:
  - /tailwindlabs/tailwindcss.com
  - /websites/v3_tailwindcss
tags:
  - skill
  - tailwindcss
  - migration
---

# tailwind-migrate

Moves a project from Tailwind 3 to 4, or finishes a migration that stopped halfway (`LINE: MIXED`). Fresh v4 configuration is `tailwind-setup`; auditing markup is `tailwind-review`.

**The risk is the build passing.** `shadow-sm` still compiles, one step smaller; `border` still compiles, another color. A migration is reviewed visually or it is not reviewed.

## 1. Discover

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-setup/scripts/discover-line.sh [project-root]
```

`LINE: 3` → migrate. `MIXED` → finishing it is the task. `4` → not this skill.

Confirm the browser floor first: Safari 16.4, Chrome 111, Firefox 128 (`TW-CFG-11`). If the product needs older browsers, stay on 3.4 and stop.

## 2. Convert

Follow `references/migration.md`. In short:

1. Clean branch, then `npx @tailwindcss/upgrade` (`bunx` with Bun) (`TW-MIG-01`). Without network, apply the same edits by hand.
2. Read the whole diff. The tool misses classes built by interpolation (`TW-SRC-01`) and files it does not scan.
3. Renames that move one step, smallest first in one pass: `shadow-sm`→`shadow-xs`, then `shadow`→`shadow-sm`; same for `drop-shadow`, `blur`, `backdrop-blur`, `rounded` (`TW-MIG-02`). `outline-none`→`outline-hidden` (`TW-MIG-03`). `ring`→`ring-3`. `bg-opacity-50`→`bg-black/50` (`TW-MIG-04`). `flex-grow`→`grow`, `flex-shrink`→`shrink`. `bg-[--x]`→`bg-(--x)` (`TW-MIG-08`). `@layer utilities` → `@utility` (`TW-MIG-07`). Stacked variants read left to right: `first:*:pt-0`→`*:first:pt-0` (`TW-VAR-07`). `!flex`→`flex!`.
4. `@tailwind base/components/utilities` → `@import "tailwindcss"` (`TW-CFG-05`). Theme values from `tailwind.config.*` move to `@theme`; delete the config, or keep it behind `@config` only as a work list (`TW-CFG-08`).
5. Integration: PostCSS → `@tailwindcss/vite` when the project runs Vite; drop `autoprefixer`, `postcss-import` (`TW-CFG-01`, `TW-CFG-02`).
6. Leftovers: `bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-review/scripts/probes.sh <src> <root>`, probe S3.

## 3. Decide every changed default

Each needs a written decision, adopt or restore (`TW-MIG-05`); the table is in `references/migration.md`, the restore CSS in [the doc](docs/tailwindcss-migration-v3-to-v4.md) § 3: `border` and `divide` color, `ring` width and color, placeholder color, `<button>` cursor, `<dialog>` margin, `hover:` on touch, `space-*` selector. A `border` with no color gets one where v3 relied on gray (`TW-MIG-06`).

## 4. Verify and close

1. Discovery script again: `LINE: 4`, no `->`.
2. Compare visually: Storybook, `toHaveScreenshot`, or side by side. It is the only check for step 3.
3. Report: each rename with its ID, the decision per changed default, what was not verified (the visual comparison, when it could not run).

## Lookups

- Rule text: `grep -h 'TW-MIG-0' references/rules.md`. Never load it whole.
- The why: [Migration v3 to v4](docs/tailwindcss-migration-v3-to-v4.md), the section `rules.md` names.
- The doc was verified on 2026-10-02 (`tailwindcss` 4.3.3). Query Context7 `/tailwindlabs/tailwindcss.com`, topic `upgrade guide`, only for a target newer than 4.3.
