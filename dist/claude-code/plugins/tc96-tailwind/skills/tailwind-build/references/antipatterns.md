# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| `` `bg-${color}-600` `` | `TW-SRC-01` | [Installation and Detection](../../../docs/tailwind/tailwindcss-installation-and-detection.md) |
| `grid flex`, `p-4 p-2` on one element | `TW-UTIL-01` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `!` to beat the project's own class | `TW-UTIL-02` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| the same arbitrary value in several files | `TW-UTIL-03` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `[display:flex]` | `TW-UTIL-04` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `style={{ padding: 12 }}` | `TW-UTIL-05` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `.btn { @apply … }` in `globals.css` | `TW-UTIL-07` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `sm:` for "mobile" | `TW-VAR-01` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| viewport breakpoints on a component that lives at many widths | `TW-VAR-03` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `peer` after the element using `peer-*` | `TW-VAR-04` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `is-open` class next to `aria-expanded` | `TW-VAR-06` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `focus:outline-none` with no replacement | `TW-A11Y-01` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| icon button with no name | `TW-A11Y-03` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `animate-spin` with no `motion-reduce:` | `TW-A11Y-05` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| a menu that only opens on hover | `TW-A11Y-08` | [Utilities and Variants](../../../docs/tailwind/tailwindcss-utilities-and-variants.md) |
| `bg-[#0f766e]` with a brand token available | `TW-THEME-04` | [Theme and Tokens](../../../docs/tailwind/tailwindcss-theme-and-tokens.md) |
| `bg-white dark:bg-zinc-900` in every component | `TW-THEME-06`, `TW-THEME-11` | [Theme and Tokens](../../../docs/tailwind/tailwindcss-theme-and-tokens.md) |
| `bg-primary text-foreground` | `TW-THEME-12` | [Theme and Tokens](../../../docs/tailwind/tailwindcss-theme-and-tokens.md) |
| the same class string copied across files | `TW-COMP-01` | [Components and Composition](../../../docs/tailwind/tailwindcss-components-and-composition.md) |
| `cn('px-4', compact && 'px-2')` | `TW-COMP-02` | [Components and Composition](../../../docs/tailwind/tailwindcss-components-and-composition.md) |
| `cn(className, base)` | `TW-COMP-03` | [Components and Composition](../../../docs/tailwind/tailwindcss-components-and-composition.md) |
| a `--text-*` token not registered in the merge | `TW-COMP-04` | [Components and Composition](../../../docs/tailwind/tailwindcss-components-and-composition.md) |
| `<Button className="bg-destructive text-white" />` across the app | `TW-COMP-06` | [Components and Composition](../../../docs/tailwind/tailwindcss-components-and-composition.md) |
| a utility class as a test selector | `PW-LOC-01` | `Playwright - Locators` |
