# The scan, in the order that fails most

Each level can erase the findings of the next: a config nobody loads explains the "arbitrary" colors; a class never generated explains a "conflict" that does not exist. Scan top-down.

| # | Level | Question | IDs | Satellite |
| --- | --- | --- | --- | --- |
| 1 | **line and stylesheet** | which line, which integration, one entry per app, is the config loaded? | `TW-CORE-01`, `TW-CFG-01…09` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| 2 | **what the scanner cannot see** | interpolated names; UI packages, generated files without `@source` | `TW-SRC-01…06` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| 3 | **conflicts** | two utilities on one property; merge hiding an internal one | `TW-UTIL-01`, `TW-COMP-02` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| 4 | **line-3 leftovers** | removed names, renamed scale, `outline-none`, `!` first, `bg-[--x]`, variant order | `TW-MIG-*`, `TW-VAR-07` | [Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) |
| 5 | **accessibility** | focus, names, `sr-only`, motion, forced colors, hover-only | `TW-A11Y-01…08` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| 6 | **tokens and dark mode** | raw palette in the design system, the pair, `:root` × `.dark`, `@theme inline`, the toggle | `TW-THEME-*` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| 7 | **composition** | `className` last, one `cn`, `extendTailwindMerge`, variants declared, `className` as layout | `TW-COMP-*` | [Components and Composition](../../docs/tailwindcss-components-and-composition.md) |
| 8 | **values and custom CSS** | repeated arbitraries, static `style`, `@apply` in own CSS, utility-shaped custom names | `TW-UTIL-02…08` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| 9 | **layout and variants** | mobile-first, container queries, `peer` order, named groups, ARIA state | `TW-VAR-01…06` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |

**Style is not a level.** Class order is legibility (`TW-TOOL-02`); it is mentioned only when a sorter is configured and did not run.

## In a PR

Review only the diff's files, **but** run S1 on the whole project: a PR can be correct markup on top of a config that ignores it. A PR that adds a token checks `.dark` (`TW-THEME-13`); a PR that adds a package checks `@source` (`TW-SRC-04`).
