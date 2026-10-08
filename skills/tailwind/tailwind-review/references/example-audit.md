# A whole audit

Task: *"review the order-card PR"* — a TanStack Start app, CI green, screenshots attached.

## Step 1 — probes

```
S1  -> tailwindcss and @tailwindcss/* disagree (4.2 4.3): TW-CFG-03
    LINE: 4
    -> Vite project integrating through PostCSS: TW-CFG-01
    -> a tailwind.config exists and NOTHING loads it (TW-CFG-08)
    -> the app toggles .dark … but declares no @custom-variant dark (TW-THEME-09)
    -> a plain @theme maps to var(...) (TW-THEME-05)
S2  src/components/ui/badge.tsx:4: className={`bg-${tone}-100 text-${tone}-800 …`}
S4  TW-UTIL-01  order-card.tsx:7  display: grid × flex
    TW-COMP-02  order-card.tsx:6  cn(…) p: p-4 × p-2
S5  2 text-[#0f766e]   1 text-[18px]   1 mt-[13px]   · [display:flex]
S6  order-card.tsx:13 style={{ padding: 12 }}
S8  button.tsx:6 bg-zinc-900 bg-zinc-800 bg-red-600 · :root without .dark: --warning
S9  button.tsx:14 cn(className, button({ intent })) · --text-display, extendTailwindMerge ABSENT
S10 button.tsx:4 focus:outline-none · order-card.tsx:14 animate-spin
S11 e2e/order.spec.ts:2 locator('article.rounded-lg.bg-white')
```

**Mandatory stop:** a `tailwind.config.ts` nothing loads. Its `brand: '#0f766e'` never reached the CSS — which is why the PR writes `text-[#0f766e]` twice: the arbitrary is a workaround for the config, not an independent finding.

## Step 2 — reading what the probes do not read

- `order-card.tsx:9` — `<button>` with only an `<svg aria-hidden>`: **no accessible name** (`TW-A11Y-03`).
- `order-card.tsx:13` — `sm:text-center` "to center on mobile" per the PR description (`TW-VAR-01`).
- `order-card.tsx:16` — `<ul className="list-none">` with real items, no `role="list"` (`TW-A11Y-07`).

## Step 3 — report

**Configuration** (one fix, `tailwind-setup`):

- [Blocking] `TW-CFG-08` — `tailwind.config.ts`: loaded by nothing; `brand` and `safelist` are ignored. Move `brand` to a token.
- [Blocking] `TW-THEME-09` — the toggle in `__root.tsx` adds `.dark`, and `dark:` follows the OS. The `dark:bg-zinc-900` in this PR does not work with the toggle.
- [High] `TW-THEME-13` — `--warning` in `:root` only.
- [Medium] `TW-CFG-01`, `TW-CFG-03`, `TW-THEME-05` — PostCSS in a Vite project, packages out of step, plain `@theme` over variables.

**Markup:**

- [Blocking] `TW-SRC-01` — `badge.tsx:4`. `bg-green-100` exists only because another file writes it.
- [High] `TW-UTIL-01` — `order-card.tsx:7`, `grid flex`: `display` is decided by stylesheet order.
- [High] `TW-A11Y-01` — `button.tsx:4`, `focus:outline-none` with no replacement: the keyboard user loses focus on every button in the app.
- [High] `TW-A11Y-03` — `order-card.tsx:9`, icon button with no name.
- [Medium] `TW-COMP-02` — `order-card.tsx:6`, `cn('… p-4 …', compact && 'p-2')` → `compact ? 'p-2' : 'p-4'`.
- [Medium] `TW-COMP-03` — `button.tsx:14`, `className` first: the consumer can never override.
- [Medium] `TW-THEME-11` — `button.tsx:6`, raw palette in `components/ui`.
- [Medium] `TW-UTIL-05` — `order-card.tsx:13`, `style={{ padding: 12 }}` → `p-3`. The `style={{ color: statusColor }}` on line 14 is a runtime value: **correct**, though `text-(--status)` would keep variants.
- [Medium] `TW-MIG-04` — `bg-opacity-50` no longer exists.
- [Low] `TW-UTIL-04` — `[display:flex]` → `flex`. `TW-A11Y-05` — `animate-spin` → `motion-safe:animate-spin`.
- Handed to `playwright-review`: `e2e/order.spec.ts:2`, `PW-LOC-01`.

**Not reported:** the class order; `mt-[13px]` (one use) — asked the author whether 13 is in the design scale.

**Not verified:** the rendered result in dark mode — it cannot work until `TW-THEME-09` is fixed; contrast of `text-[#0f766e]` on white.
