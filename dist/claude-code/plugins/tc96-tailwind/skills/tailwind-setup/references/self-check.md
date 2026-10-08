# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-setup/scripts/discover-line.sh
```

Every `->` line from Step 1 must be gone, or explained in the delivery.

| # | Check | Rule |
| --- | --- | --- |
| 1 | the line is recorded, and the browser floor was accepted | `TW-CORE-01`, `TW-CFG-11` |
| 2 | Vite project → `@tailwindcss/vite`; no `autoprefixer`/`postcss-import` | `TW-CFG-01`, `TW-CFG-02` |
| 3 | `tailwindcss` and `@tailwindcss/*` on the same version | `TW-CFG-03` |
| 4 | TanStack Start links the stylesheet through `?url` | `TW-CFG-04` |
| 5 | one entry stylesheet per app, starting with `@import "tailwindcss"`; modules use `@reference` | `TW-CFG-05`, `TW-CFG-06` |
| 6 | no `tailwind.config.*` — or, legacy, loaded by `@config` and without `corePlugins`/`safelist`/`separator` | `TW-CFG-08`, `TW-CFG-09` |
| 7 | every UI package and generated file the scanner must see has an `@source` | `TW-SRC-03`, `TW-SRC-04`, `TW-SRC-06` |
| 8 | tokens: `@theme inline` when pointing at a variable; every token in `:root` **and** `.dark` | `TW-THEME-05`, `TW-THEME-13` |
| 9 | dark toggle → `@custom-variant dark` + inline script in `<head>` | `TW-THEME-09`, `TW-THEME-10` |
| 10 | shadcn/ui: `tailwind.config` empty, `tw-animate-css` | `TW-THEME-14` |
| 11 | migration: every changed default has a recorded decision | `TW-MIG-05` |

**Then start the app and look — light and dark.** A missing `@source`, an unmapped token, an ignored config: none of them raises an error (`TW-CORE-04`).
