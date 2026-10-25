---
name: tailwind-setup
description: Set up or fix Tailwind CSS v4 config: Vite plugin, @source, tokens, dark mode
type: skill
family: tailwind
language: en
source: "[Tailwind CSS - Installation and Detection](docs/tailwindcss-installation-and-detection.md)"
docs:
  - /tailwindlabs/tailwindcss.com
  - /shadcn-ui/ui
tags:
  - skill
  - tailwindcss
  - frontend
---

# tailwind-setup

Configures how Tailwind enters the build: packages, Vite plugin, entry stylesheet, `@source`, `@theme` tokens, dark mode, `components.json`. Writing classes is `tailwind-build`; auditing markup is `tailwind-review`; a v3 project is `tailwind-migrate`.

Most defects here **compile**: a config nobody loads, a token nobody maps, a toggle with no variant. Nothing errors, so the script and the render are the evidence, never the build (`TW-CORE-04`).

## 1. Discover

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-setup/scripts/discover-line.sh [project-root]
```

Prints `LINE` (3, 4, MIXED), the integration, entry stylesheet(s) and every contradiction as `-> … (ID)`. Each `->` is a work item.

| LINE | Do |
| --- | --- |
| `4` | continue here |
| `3` or `MIXED` | stop; this is `tailwind-migrate` |

## 2. Integration and entry stylesheet

Read `references/choosing-the-integration.md`. The default answer in this stack:

- `tailwindcss` + `@tailwindcss/vite`, same version (`TW-CFG-01`, `TW-CFG-03`); no `autoprefixer`, `postcss-import`, nor a PostCSS config whose only job was Tailwind (`TW-CFG-02`).
- One entry stylesheet per app, starting `@import "tailwindcss"`; CSS modules use `@reference` (`TW-CFG-05`, `TW-CFG-06`).
- TanStack Start links it with `?url` in the root route's `head().links` (`TW-CFG-04`).
- No new `tailwind.config.*`. An existing one is loaded by nothing unless `@config` names it: move its values into CSS and delete it (`TW-CFG-08`); `safelist` becomes `@source inline(…)` (`TW-SRC-05`).
- `@source` for what the scanner cannot see: a UI package in `node_modules`, a sibling `packages/ui`, generated files (`TW-SRC-03`, `TW-SRC-04`, `TW-SRC-06`). Paths are relative to the stylesheet.

## 3. Tokens and dark mode (only if the task has them)

Read `references/sequence.md`, block "Tokens", and copy its CSS shape:

- Value in `:root` **and** `.dark` (`TW-THEME-13`), mapping in `@theme inline` (`TW-THEME-05`, `TW-THEME-06`).
- App toggles `.dark` → `@custom-variant dark (&:is(.dark *));` (`TW-THEME-09`).
- Saved-theme script inline in `<head>` (TanStack Start: `head().scripts`), never in an Effect (`TW-THEME-10`).
- shadcn/ui on v4: `components.json` `tailwind.config` empty, `tw-animate-css` instead of `tailwindcss-animate` (`TW-THEME-14`).

## 4. Verify and close

1. Run the discovery script again: every `->` from step 1 is gone or explained.
2. Walk `references/self-check.md`.
3. Start the app and look, light and dark. If you cannot render, say so under "not verified".
4. Report: the line and entry stylesheet, each change with its ID, what was not verified.

## Lookups

- Rule text by ID: `grep -h 'TW-THEME-05' references/rules.md`. Never load `rules.md` or a doc whole.
- The why behind a rule: the section `rules.md` names, in [Installation and Detection](docs/tailwindcss-installation-and-detection.md) or [Theme and Tokens](docs/tailwindcss-theme-and-tokens.md).
- The docs were verified on 2026-10-02 against `tailwindcss` 4.3.3. Query Context7 (`/tailwindlabs/tailwindcss.com`, `/shadcn-ui/ui`) only for a version newer than 4.3 or a fact the docs do not have.
- Worked case: `references/example.md`. Antipattern grid: `references/antipatterns.md`.
