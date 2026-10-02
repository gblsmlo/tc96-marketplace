# Antipatterns, with ID and satellite

| Antipattern | ID | Satellite |
| --- | --- | --- |
| prescribing v4 syntax in a v3 project | `TW-CORE-01` | [Tailwind CSS](../../docs/tailwindcss.md) |
| "the build is green, so the CSS is right" | `TW-CORE-04` | [Tailwind CSS](../../docs/tailwindcss.md) |
| PostCSS plugin in a Vite project | `TW-CFG-01` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `tailwind.config.ts` loaded by nothing | `TW-CFG-08` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `@import "tailwindcss"` in every CSS module | `TW-CFG-06` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| a class name built by interpolation | `TW-SRC-01` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `packages/ui` without `@source` | `TW-SRC-04` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| two utilities on one property | `TW-UTIL-01` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| repeated arbitrary value | `TW-UTIL-03` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `[display:flex]` | `TW-UTIL-04` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `style` with a static value | `TW-UTIL-05` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `.btn { @apply … }` | `TW-UTIL-07` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `sm:` for mobile | `TW-VAR-01` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `peer` after its dependent | `TW-VAR-04` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| class state parallel to `aria-*` | `TW-VAR-06` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| v3 variant order `first:*:` | `TW-VAR-07` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `focus:outline-none` with no replacement | `TW-A11Y-01` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `focus:ring` | `TW-A11Y-02` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| icon button with no name | `TW-A11Y-03` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `hidden` to visually hide | `TW-A11Y-04` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| bare `animate-*` | `TW-A11Y-05` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `list-none` on a real list without `role="list"` | `TW-A11Y-07` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| hover-only menu | `TW-A11Y-08` | [Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) |
| `text-[#hex]` with a token available | `TW-THEME-04` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| plain `@theme` → `var(--x)` | `TW-THEME-05` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| `dark:` on every semantic color | `TW-THEME-06` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| dark toggle with no `@custom-variant dark` | `TW-THEME-09` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| theme applied in an Effect | `TW-THEME-10` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| raw palette in `components/ui` | `TW-THEME-11` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| token in `:root` only | `TW-THEME-13` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| `components.json` with a config on v4 | `TW-THEME-14` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| `cn` hiding an internal conflict | `TW-COMP-02` | [Components and Composition](../../docs/tailwindcss-components-and-composition.md) |
| `cn(className, …)` | `TW-COMP-03` | [Components and Composition](../../docs/tailwindcss-components-and-composition.md) |
| non-color token not in `extendTailwindMerge` | `TW-COMP-04` | [Components and Composition](../../docs/tailwindcss-components-and-composition.md) |
| two `cn` helpers | `TW-COMP-05` | [Components and Composition](../../docs/tailwindcss-components-and-composition.md) |
| a variant passed through `className` | `TW-COMP-06` | [Components and Composition](../../docs/tailwindcss-components-and-composition.md) |
| cva output joined with no merge | `TW-COMP-07` | [Components and Composition](../../docs/tailwindcss-components-and-composition.md) |
| class order reported as a finding | `TW-TOOL-02` | [Components and Composition](../../docs/tailwindcss-components-and-composition.md) |
| `shadow`→`shadow-sm` find-and-replace | `TW-MIG-02` | [Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) |
| `outline-none` from v3 kept | `TW-MIG-03` | [Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) |
| `bg-opacity-*` | `TW-MIG-04` | [Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) |
| `bg-[--x]` | `TW-MIG-08` | [Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) |
| a utility class as a test selector | `PW-LOC-01` | `Playwright - Locators` |
