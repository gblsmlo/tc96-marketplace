# Choosing the integration

Source: [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) § 1–3 · the tree is [Tailwind CSS](../../docs/tailwindcss.md) § 5.1.

## The tree

```
Does the project run Vite (TanStack Start, React Router, SPA, Storybook on Vite)?
├── YES → tailwindcss + @tailwindcss/vite                     (TW-CFG-01)
└── NO
    ├── a PostCSS pipeline (Next.js, Rspack, Parcel)? → @tailwindcss/postcss
    ├── plain webpack? → @tailwindcss/webpack (≥ 4.2)
    └── no bundler → @tailwindcss/cli, or the standalone binary
```

In this house's stack the answer is the first branch. `@tailwindcss/vite` 4.3.3 accepts Vite `^5.2 || ^6 || ^7 || ^8` — for the installed version, query Context7 `/tailwindlabs/tailwindcss.com`, topic `installation vite`.

## TanStack Start

| File | What |
| --- | --- |
| `vite.config.ts` | `tailwindcss()` in `plugins` — the guide lists it first, but **does not state** that order matters |
| `src/styles.css` | `@import "tailwindcss";` and nothing from line 3 |
| `src/routes/__root.tsx` | `import appCss from '../styles.css?url'` and `head: () => ({ links: [{ rel: 'stylesheet', href: appCss }] })` — `TW-CFG-04` |

A bare `import '../styles.css'` works on the client and arrives late in the server's first paint. The guide's own `vite.config.ts` misses a comma after `tailwindcss()` — do not copy it blindly. Current snippet: Context7 `/tailwindlabs/tailwindcss.com`, topic `tanstack start`.

## What the scanner will not see

| Case | Line in the entry stylesheet | ID |
| --- | --- | --- |
| a UI library published with Tailwind classes | `@source "../node_modules/@acme/ui";` | `TW-SRC-03` |
| `packages/ui` in the monorepo, build run from the app | `@source "../../../packages/ui/src";` — or `source(none)` + one `@source` per package | `TW-SRC-04` |
| generated or git-ignored files with classes | `@source` explicit | `TW-SRC-06` |
| classes that never appear in code (CMS, DB) | `@source inline("…")` — not a dead file | `TW-SRC-05` |

The path in `@source` is relative to **the stylesheet**, not to the root.

## One stylesheet per app

Each `@import "tailwindcss"` is a whole Tailwind. A CSS module or a component `<style>` that needs `@apply` or a token uses `@reference "../styles.css";` (`TW-CFG-06`). No Sass, Less or Stylus (`TW-CFG-07`).
