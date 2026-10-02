# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| PostCSS plugin in a Vite project | `TW-CFG-01` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `autoprefixer` / `postcss-import` next to v4 | `TW-CFG-02` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `@tailwindcss/*` one minor behind `tailwindcss` | `TW-CFG-03` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `import './styles.css'` in TanStack Start's root route | `TW-CFG-04` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `@tailwind base` in a v4 stylesheet | `TW-CFG-05` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `@import "tailwindcss"` in every CSS module | `TW-CFG-06` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| Sass alongside v4 | `TW-CFG-07` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `tailwind.config.ts` "out of habit", loaded by nothing | `TW-CFG-08` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `safelist` in the config | `TW-CFG-09` → `TW-SRC-05` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| a reset written outside `@layer base` | `TW-CFG-10` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| UI library unstyled after upgrading to 4.1 | `TW-SRC-03` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| relying on the cwd of the build in a monorepo | `TW-SRC-04` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| a dead file listing classes "to force generation" | `TW-SRC-05` | [Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) |
| `@theme` inside `.dark` or a media query | `TW-THEME-02` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| plain `@theme` mapping to `var(--x)` | `TW-THEME-05` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| `@theme` copied into every app | `TW-THEME-08` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| a dark toggle with no `@custom-variant dark` | `TW-THEME-09` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| theme applied in a `useEffect` (flash) | `TW-THEME-10` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| a token in `:root` only | `TW-THEME-13` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| `components.json` pointing at a config on v4; `tailwindcss-animate` | `TW-THEME-14` | [Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) |
| "the build passed, so it migrated" | `TW-CORE-04` | [Tailwind CSS](../../docs/tailwindcss.md) |
| a find-and-replace of `shadow` by `shadow-sm` | `TW-MIG-02` | [Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) |
| `outline-none` kept as `outline-none` | `TW-MIG-03` | [Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) |
| restoring every v3 default by reflex | `TW-MIG-05` | [Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) |
