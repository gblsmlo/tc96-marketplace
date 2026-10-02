---
name: tailwind-setup
description: Install, configure or migrate Tailwind CSS in a project or monorepo — discovering the line (3 or 4) and the integration before prescribing anything, the entry stylesheet, `@source` for what the scanner does not see, `@theme` tokens and dark mode, shadcn/ui on v4, and the v3 → v4 migration with its silent visual changes — citing `TW-CFG-*`, `TW-SRC-*`, `TW-THEME-*` and `TW-MIG-*` IDs, with a script that discovers the line and finds the contradictions — use when the task is adding Tailwind to a TanStack Start/Vite app, moving from PostCSS to the Vite plugin, a `tailwind.config` whose values do not reach the CSS, classes from `packages/ui` that vanished, setting up design tokens or a dark-mode toggle, fixing `components.json` for v4, or running the upgrade from v3. Do not use to write a component's classes, which is tailwind-build, nor to audit existing markup, which is tailwind-review.
fonte: "[Tailwind CSS - Installation and Detection](../../docs/tailwind/tailwindcss-installation-and-detection.md)"
docs:
  - /tailwindlabs/tailwindcss.com
  - /shadcn-ui/ui
  - /websites/v3_tailwindcss
tags:
  - skill
  - tailwindcss
  - frontend
---

# tailwind-setup

> **Source of this skill:** [Tailwind CSS - Installation and Detection](../../docs/tailwind/tailwindcss-installation-and-detection.md) and [Tailwind CSS - Theme and Tokens](../../docs/tailwind/tailwindcss-theme-and-tokens.md), with the [Tailwind CSS](../../docs/tailwind/tailwindcss.md) hub as the router, and [Tailwind CSS - Migration v3 to v4](../../docs/tailwind/tailwindcss-migration-v3-to-v4.md) when the project comes from line 3.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and what to check.
> **API surface:** resolve it through Context7 — `/tailwindlabs/tailwindcss.com` (line 4), `/websites/v3_tailwindcss` (line 3), `/shadcn-ui/ui`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Tailwind CSS](../../docs/tailwind/tailwindcss.md) § 7.

---

## When to use

Installing, reconfiguring or migrating Tailwind — anything that touches `package.json`, `vite.config.*`, `postcss.config.*`, the entry stylesheet, `@theme`, `components.json`.

| Situation | Go to |
| --- | --- |
| writing the classes of a component or screen | `tailwind-build` |
| auditing markup that already exists | `tailwind-review` |
| Storybook does not pick up the styles | `storybook-setup` — the stylesheet is imported in `preview.tsx` |
| where `packages/ui` lives in the monorepo | `bun-workspace` |

---

## API lookups — Context7 first

**Context7 first.** Any API fact this skill needs — whether a utility exists, a directive's options, what changed in a version — comes from a Context7 query, not from memory and not from a docs URL. The knowledge base gives the **rule and the ID**; Context7 gives the **signature for the installed version**. If they disagree, the source wins and the note is a bug to report.

| Question | Context7 library | Topic to query |
| --- | --- | --- |
| install with Vite, TanStack Start, PostCSS, CLI | `/tailwindlabs/tailwindcss.com` | `installation vite` · `tanstack start` |
| `@import` options, `@source`, `@reference`, `@config`, `@plugin` | `/tailwindlabs/tailwindcss.com` | `functions and directives` · `detecting classes in source files` |
| `@theme` namespaces, `inline`, `static` | `/tailwindlabs/tailwindcss.com` | `theme variables` |
| dark mode and `@custom-variant` | `/tailwindlabs/tailwindcss.com` | `dark mode` |
| renamed utilities, changed defaults, the upgrade tool | `/tailwindlabs/tailwindcss.com` | `upgrade guide` |
| `components.json`, tokens, `tw-animate-css` | `/shadcn-ui/ui` | `components.json` · `tailwind v4` · `theming` |
| a project that stays on line 3 | `/websites/v3_tailwindcss` | the v3 topic |

---

## Step 1 — Discover before prescribing

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-setup/scripts/discover-line.sh
```

The script prints the **line** (3, 4 or MIXED), the integration, the entry stylesheet(s), the JavaScript config nobody loads, the sources, the dark-mode wiring, shadcn/ui and the formatter — and each contradiction with its ID.

**Why first:** prescribing the wrong line fails silently (`TW-CORE-01`). A v4 class in a v3 project compiles to nothing; a v3 name in a v4 project — `shadow`, `rounded`, `outline-none` — compiles to **another value**.

| LINE | What it means |
| --- | --- |
| `4` | every `TW-*` family applies |
| `3`, staying | only `TW-SRC-01/02`, `TW-UTIL-01`, `TW-A11Y-*`, `TW-COMP-*`. **Citing `TW-CFG/THEME/MIG` is an invalid finding**, except as a separate migration recommendation |
| `3`, migrating | `references/migration.md` before anything else |
| `MIXED` | a migration stopped halfway — finishing it **is** the task |

Before adopting line 4, confirm the browser floor: Safari 16.4 · Chrome 111 · Firefox 128 (`TW-CFG-11`).

---

## Minimum loading

| Order | Load |
| --- | --- |
| 1 | [Tailwind CSS](../../docs/tailwind/tailwindcss.md) § 1 (the line), § 3 (package boundaries), § 5.1 (the integration tree) |
| 2 | [Tailwind CSS - Installation and Detection](../../docs/tailwind/tailwindcss-installation-and-detection.md) |
| 3 | [Tailwind CSS - Theme and Tokens](../../docs/tailwind/tailwindcss-theme-and-tokens.md) — only if the task has tokens, dark mode or shadcn/ui |
| 4 | [Tailwind CSS - Migration v3 to v4](../../docs/tailwind/tailwindcss-migration-v3-to-v4.md) — only if LINE is 3 or MIXED |

**Never load Utilities and Variants or Components and Composition here** — they are about markup, not configuration.
**To read a rule's text by ID** without opening its note: `bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-review/scripts/rule.sh TW-THEME-05` (or a family, `TW-THEME`).


References in this skill:

| File | What for |
| --- | --- |
| `references/choosing-the-integration.md` | the tree, the TanStack Start `?url`, monorepo sources |
| `references/sequence.md` | the order, from package to first render, and the token block |
| `references/migration.md` | the v3 → v4 sequence and the decision table of changed defaults |
| `references/self-check.md` | the checklist |
| `references/antipatterns.md` | the grid, with IDs |
| `references/id-map.md` | the 77 `TW-*` by satellite and section |
| `references/example.md` | worked case |
| `scripts/discover-line.sh` | line, integration, contradictions |
| `scripts/generate-id-map.sh` | regenerates the map across the three skills |

---

## Step 2 — The integration and the entry stylesheet

`references/choosing-the-integration.md`. In this house's stack the answer is almost always **`@tailwindcss/vite`** (`TW-CFG-01`), one stylesheet per app beginning with `@import "tailwindcss"` (`TW-CFG-05`, `TW-CFG-06`), linked in TanStack Start through `?url` (`TW-CFG-04`). No `postcss-import`, no `autoprefixer` (`TW-CFG-02`), no new `tailwind.config.*` (`TW-CFG-08`).

**Then ask what the scanner will not see** — a UI package in `node_modules`, a sibling `packages/ui`, generated files (`TW-SRC-03`, `TW-SRC-04`, `TW-SRC-06`). A missing `@source` raises no error: the classes are just absent.

---

## Step 3 — Tokens and dark mode, when the task has them

`references/sequence.md`, block "Tokens". Semantic tokens with the value in `:root`/`.dark` and the mapping in `@theme inline` (`TW-THEME-05`, `TW-THEME-06`); every token in **both** `:root` and `.dark` (`TW-THEME-13`); `@custom-variant dark` when the app toggles (`TW-THEME-09`); the theme script inline in `<head>`, never in an Effect (`TW-THEME-10`). shadcn/ui on v4: `tailwind.config` empty, `tw-animate-css` (`TW-THEME-14`).

---

## Step 4 — Self-check, and render

`references/self-check.md`, then **run the discovery script again** — every `->` line it printed in Step 1 must be gone or explained.

Then start the app and look. **A build that passes proves nothing about the CSS** (`TW-CORE-04`): a class nobody generated, a token nobody mapped, a v3 default that changed — all compile.

---

## Step 5 — Closing, and handing off

1. **Record the line and the entry stylesheet.** They decide which IDs may be cited for the rest of the project's life.
2. **For a migration, list every changed default and the decision taken** — adopted or restored (`TW-MIG-05`).
3. **Declare what was not verified** — usually: the visual comparison, if no story or snapshot exists.
4. Classes of a component → `tailwind-build`; auditing the existing markup → `tailwind-review`.

---

## Example

A TanStack Start app on `@tailwindcss/postcss` + `autoprefixer`, a `tailwind.config.ts` with the brand color, `components.json` still pointing at it, and a dark toggle in a `useEffect`. The script prints six contradictions; the brand color **never reached the CSS** (`TW-CFG-08`), and the toggle never worked (`TW-THEME-09`).

Full case: `references/example.md`.

---

## Related

- [Tailwind CSS - Installation and Detection](../../docs/tailwind/tailwindcss-installation-and-detection.md) — source of this skill
- [Tailwind CSS](../../docs/tailwind/tailwindcss.md) § 1, § 3, § 5.1, § 7
- `tailwind-build` · `tailwind-review` — the sibling skills
- [Tailwind CSS - Theme and Tokens](../../docs/tailwind/tailwindcss-theme-and-tokens.md) · [Tailwind CSS - Migration v3 to v4](../../docs/tailwind/tailwindcss-migration-v3-to-v4.md)
