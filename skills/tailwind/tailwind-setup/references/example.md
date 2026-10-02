# Worked example

Task: *"the brand color in `tailwind.config.ts` doesn't show up and the dark-mode toggle doesn't work — fix the Tailwind setup"* — a TanStack Start app.

**Step 1 — the script:**

```
   -> tailwindcss and @tailwindcss/* disagree (4.2 4.3): TW-CFG-03
   LINE: 4
   -> Vite project integrating through PostCSS: TW-CFG-01
   -> autoprefixer/postcss-import alongside v4: TW-CFG-02
   -> TanStack Start importing the CSS without ?url in ./src/routes/__root.tsx: TW-CFG-04
   -> a tailwind.config exists and NOTHING loads it: every value in it is silently ignored (TW-CFG-08)
   -> the app toggles .dark/data-theme but declares no @custom-variant dark: the toggle has no effect (TW-THEME-09)
   -> a plain @theme maps to var(...): the utility resolves at :root, not at the element (TW-THEME-05)
   -> tailwind.config is NOT empty under v4 (TW-THEME-14)
   -> tailwindcss-animate is deprecated: tw-animate-css (TW-THEME-14)
```

Both symptoms are explained before reading a file: the brand color lives in a config **nobody loads** (`TW-CFG-08`), and `dark:` follows the OS because nothing declares the class variant (`TW-THEME-09`).

**Step 2 — integration:** `@tailwindcss/postcss` and `autoprefixer` out, `@tailwindcss/vite` in at the same version as `tailwindcss`; `postcss.config.mjs` deleted; `__root.tsx` links `styles.css?url` in `head().links`.

**Step 3 — tokens:** the brand color moves to the stylesheet as a semantic token, in `:root` **and** `.dark`; `:root`/`.dark` leave `@layer base`, values wrapped in `oklch()`; `@theme` becomes `@theme inline`; `--warning`, present only in `:root`, gains its dark value (`TW-THEME-13`). `@custom-variant dark (&:is(.dark *));` is declared. The `useEffect` that added `.dark` becomes an inline script in `head().scripts` (`TW-THEME-10`). `tailwind.config.ts` is deleted, `components.json` gets `"config": ""`, `tailwindcss-animate` becomes `@import "tw-animate-css"`.

**Step 4 — self-check:** the script again prints only `LINE: 4`. Started the app, toggled the theme: brand color present, dark applied before the first paint.

**Closing:**

- **Line 4, entry stylesheet `src/styles.css`.**
- `safelist: ['bg-red-500']` was dropped with the config. No code builds `bg-red-500` dynamically (probe S2 empty), so nothing replaced it — if the CMS needs it, `@source inline("bg-red-500")` (`TW-SRC-05`).
- **Not verified:** a visual comparison of every screen — the project has no stories. Handed to `tailwind-review` for the markup, which still has `focus:outline-none` and raw palette colors in `components/ui`.
