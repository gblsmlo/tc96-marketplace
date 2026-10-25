---
name: tailwind-build
description: Write Tailwind classes for components: tokens, cva variants, states, a11y, cn
type: skill
family: tailwind
language: en
source: "[Tailwind CSS - Utilities and Variants](docs/tailwindcss-utilities-and-variants.md)"
docs:
  - /tailwindlabs/tailwindcss.com
  - /dcastil/tailwind-merge
  - /joe-bell/cva
tags:
  - skill
  - tailwindcss
  - frontend
  - design-system
---

# tailwind-build

Writes the Tailwind classes of a new component, screen or variant on line 4. Installing, tokens that do not exist yet and dark-mode wiring are `tailwind-setup`; auditing existing markup is `tailwind-review`.

Every defect this skill prevents compiles. That is why the self-check is a script and the proof is a render, not the build (`TW-CORE-04`).

## 1. Line and tokens, before the first class

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-setup/scripts/discover-line.sh | grep -e LINE -e '->'
```

`LINE: 3` that stays: use v3 names and cite only `TW-SRC-*`, `TW-UTIL-01`, `TW-A11Y-*`, `TW-COMP-*`.

Open the entry stylesheet and list what `@theme` declares. The component speaks in those names: `bg-primary text-primary-foreground`, never `bg-zinc-900 text-white` (`TW-THEME-11`, `TW-THEME-12`). A missing token that will repeat is created first in `tailwind-setup` (`TW-UTIL-03`).

## 2. Decide each value and style

`references/deciding-value-and-style.md` has the trees. The four that fail most:

- **Never build a class name by interpolation.** `` `bg-${tone}-100` `` is never generated, and sometimes "works" because another file writes it literally. Map each value to a complete string (`TW-SRC-01`, `TW-SRC-02`).
- Runtime-only value → CSS variable in `style` + `bg-(--x)`; static value in `style` never (`TW-UTIL-05`).
- Value that a token has → the token's utility, never an arbitrary duplicate (`TW-THEME-04`).
- Design variation (intent, size) → a cva/tv variant with `VariantProps`, not `className` (`TW-COMP-06`).

## 3. States, layout, accessibility

`references/states-and-responsiveness.md`. Minimum on every component:

- Mobile is unprefixed, prefixes override upward (`TW-VAR-01`); a component used at several widths answers to `@container` (`TW-VAR-03`).
- State already in `aria-*`/`data-*` is styled from the attribute (`TW-VAR-06`).
- Outline removed → `focus-visible:` replacement (`TW-A11Y-01`, `TW-A11Y-02`); icon-only control has a name (`TW-A11Y-03`); animation behind `motion-safe:`/`motion-reduce:` (`TW-A11Y-05`); nothing reachable only through `hover:` (`TW-A11Y-08`); color is never the only carrier of meaning.

## 4. Compose

`references/composition.md`. Internal conditionals emit one class per property, joined without merge (`TW-UTIL-01`, `TW-COMP-02`): `cn(compact ? 'p-2' : 'p-4')`, never `cn('p-4', compact && 'p-2')`. External `className` goes through `cn`, last (`TW-COMP-03`). Custom non-color tokens are registered in `extendTailwindMerge` (`TW-COMP-04`).

## 5. Self-check and render

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-build/scripts/self-check.sh <file-or-dir>
```

Fix every ✗, then read the "reading" items in `references/self-check.md`. Render light and dark (story or screen); if you cannot, say so under "not verified". Deliver the code, the IDs that shaped it, and what was not verified.

## Lookups

- Rule text by ID: `grep -h 'TW-COMP-03' references/rules.md`. Never load `rules.md` or a doc whole.
- The why: the section `rules.md` names, in [Utilities and Variants](docs/tailwindcss-utilities-and-variants.md) or [Components and Composition](docs/tailwindcss-components-and-composition.md).
- The docs were verified on 2026-10-02 (`tailwindcss` 4.3.3, `tailwind-merge` 3.7.0, `class-variance-authority` 0.7.1). Query Context7 only for a newer version or a utility the docs do not cover.
- Worked case: `references/example.md`. Antipattern grid: `references/antipatterns.md`.
