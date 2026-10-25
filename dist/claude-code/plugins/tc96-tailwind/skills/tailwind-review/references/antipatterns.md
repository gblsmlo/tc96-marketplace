# Antipatterns, with ID and satellite

| Antipattern | ID | Satellite |
| --- | --- | --- |
| prescribing v4 syntax in a v3 project | `TW-CORE-01` | [Tailwind CSS](../docs/tailwindcss.md) |
| "the build is green, so the CSS is right" | `TW-CORE-04` | [Tailwind CSS](../docs/tailwindcss.md) |
| PostCSS plugin in a Vite project | `TW-CFG-01` | `Tailwind CSS - Installation and Detection` |
| `tailwind.config.ts` loaded by nothing | `TW-CFG-08` | `Tailwind CSS - Installation and Detection` |
| `@import "tailwindcss"` in every CSS module | `TW-CFG-06` | `Tailwind CSS - Installation and Detection` |
| a class name built by interpolation | `TW-SRC-01` | `Tailwind CSS - Installation and Detection` |
| `packages/ui` without `@source` | `TW-SRC-04` | `Tailwind CSS - Installation and Detection` |
| two utilities on one property | `TW-UTIL-01` | `Tailwind CSS - Utilities and Variants` |
| repeated arbitrary value | `TW-UTIL-03` | `Tailwind CSS - Utilities and Variants` |
| `[display:flex]` | `TW-UTIL-04` | `Tailwind CSS - Utilities and Variants` |
| `style` with a static value | `TW-UTIL-05` | `Tailwind CSS - Utilities and Variants` |
| `.btn { @apply … }` | `TW-UTIL-07` | `Tailwind CSS - Utilities and Variants` |
| `sm:` for mobile | `TW-VAR-01` | `Tailwind CSS - Utilities and Variants` |
| `peer` after its dependent | `TW-VAR-04` | `Tailwind CSS - Utilities and Variants` |
| class state parallel to `aria-*` | `TW-VAR-06` | `Tailwind CSS - Utilities and Variants` |
| v3 variant order `first:*:` | `TW-VAR-07` | `Tailwind CSS - Utilities and Variants` |
| `focus:outline-none` with no replacement | `TW-A11Y-01` | `Tailwind CSS - Utilities and Variants` |
| `focus:ring` | `TW-A11Y-02` | `Tailwind CSS - Utilities and Variants` |
| icon button with no name | `TW-A11Y-03` | `Tailwind CSS - Utilities and Variants` |
| `hidden` to visually hide | `TW-A11Y-04` | `Tailwind CSS - Utilities and Variants` |
| bare `animate-*` | `TW-A11Y-05` | `Tailwind CSS - Utilities and Variants` |
| `list-none` on a real list without `role="list"` | `TW-A11Y-07` | `Tailwind CSS - Utilities and Variants` |
| hover-only menu | `TW-A11Y-08` | `Tailwind CSS - Utilities and Variants` |
| `text-[#hex]` with a token available | `TW-THEME-04` | `Tailwind CSS - Theme and Tokens` |
| plain `@theme` → `var(--x)` | `TW-THEME-05` | `Tailwind CSS - Theme and Tokens` |
| `dark:` on every semantic color | `TW-THEME-06` | `Tailwind CSS - Theme and Tokens` |
| dark toggle with no `@custom-variant dark` | `TW-THEME-09` | `Tailwind CSS - Theme and Tokens` |
| theme applied in an Effect | `TW-THEME-10` | `Tailwind CSS - Theme and Tokens` |
| raw palette in `components/ui` | `TW-THEME-11` | `Tailwind CSS - Theme and Tokens` |
| token in `:root` only | `TW-THEME-13` | `Tailwind CSS - Theme and Tokens` |
| `components.json` with a config on v4 | `TW-THEME-14` | `Tailwind CSS - Theme and Tokens` |
| `cn` hiding an internal conflict | `TW-COMP-02` | `Tailwind CSS - Components and Composition` |
| `cn(className, …)` | `TW-COMP-03` | `Tailwind CSS - Components and Composition` |
| non-color token not in `extendTailwindMerge` | `TW-COMP-04` | `Tailwind CSS - Components and Composition` |
| two `cn` helpers | `TW-COMP-05` | `Tailwind CSS - Components and Composition` |
| a variant passed through `className` | `TW-COMP-06` | `Tailwind CSS - Components and Composition` |
| cva output joined with no merge | `TW-COMP-07` | `Tailwind CSS - Components and Composition` |
| class order reported as a finding | `TW-TOOL-02` | `Tailwind CSS - Components and Composition` |
| `shadow`→`shadow-sm` find-and-replace | `TW-MIG-02` | `Tailwind CSS - Migration v3 to v4` |
| `outline-none` from v3 kept | `TW-MIG-03` | `Tailwind CSS - Migration v3 to v4` |
| `bg-opacity-*` | `TW-MIG-04` | `Tailwind CSS - Migration v3 to v4` |
| `bg-[--x]` | `TW-MIG-08` | `Tailwind CSS - Migration v3 to v4` |
| a utility class as a test selector | `PW-LOC-01` | `Playwright - Locators` |
