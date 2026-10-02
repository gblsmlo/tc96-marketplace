# The sequence

Source: [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) and [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md).

## Installation, in order

1. **Discover** — `discover-line.sh`. LINE 3 or MIXED → `migration.md` first.
2. **Browser floor** — Safari 16.4 · Chrome 111 · Firefox 128 accepted by the product (`TW-CFG-11`).
3. **Packages** — `tailwindcss` + `@tailwindcss/vite`, **same version** (`TW-CFG-03`). With Bun: `bun add -d tailwindcss @tailwindcss/vite`.
4. **Plugin** — `tailwindcss()` in `vite.config.ts`. Remove `postcss.config.*` if Tailwind was its only job, and `autoprefixer`/`postcss-import` (`TW-CFG-01`, `TW-CFG-02`).
5. **Entry stylesheet** — `@import "tailwindcss";` (`TW-CFG-05`), then the theme import, then `@source` lines (`TW-SRC-*`).
6. **Link it** — TanStack Start: `?url` in `head().links` (`TW-CFG-04`).
7. **Render** — a page with `bg-primary` or any class that depends on a token you declared. Seeing the color is the test; the build is not (`TW-CORE-04`).

## Tokens

The shape below follows shadcn/ui on v4. For the current token list and `components.json` fields, query Context7 `/shadcn-ui/ui`, topics `tailwind v4` and `theming`.

```css
@import "tailwindcss";
@import "tw-animate-css";                       /* shadcn/ui — not the tailwindcss-animate plugin */

@custom-variant dark (&:is(.dark *));            /* only if the app toggles — TW-THEME-09 */

:root  { --background: oklch(1 0 0);     --foreground: oklch(0.145 0 0); --radius: 0.625rem; }
.dark  { --background: oklch(0.145 0 0); --foreground: oklch(0.985 0 0); }

@theme inline {                                  /* inline: the token points at a variable — TW-THEME-05 */
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --radius-lg: var(--radius);
}
```

| Check | ID |
| --- | --- |
| `:root`/`.dark` **outside** `@layer base`, values already wrapped (`oklch(…)`) | shadcn/ui on v4 |
| every token in `:root` **also** in `.dark` | `TW-THEME-13` |
| `@theme` at the top level, never in a selector or media query | `TW-THEME-02` |
| a closed palette removes the default namespace (`--color-*: initial`) | `TW-THEME-03` |
| tokens shared between apps live in **one** file in `packages/ui` | `TW-THEME-08` |
| the saved-theme script inline in `<head>` — in TanStack Start, `head().scripts` of the root route | `TW-THEME-10` |
| `components.json`: `tailwind.config` empty, `tailwind.css` → the entry stylesheet | `TW-THEME-14` |

## Editor and formatter

`tailwindCSS.classFunctions: ["cn", "cva", "tv", "clsx"]`, and in a monorepo `tailwindCSS.experimental.configFile` mapping each app's stylesheet (`TW-TOOL-03`). The house formatter is Biome: `useSortedClasses` is nursery — class order is never a gate (`TW-TOOL-02`). If the project uses Prettier, the plugin needs `tailwindStylesheet` and goes last (`TW-TOOL-01`).
