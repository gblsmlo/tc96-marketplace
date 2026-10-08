---
titulo: Tailwind CSS - Migration v3 to v4
Link: https://tailwindcss.com/docs/upgrade-guide
tags:
  - tailwindcss
  - css
  - migration
  - agent-context
source: "Official Tailwind CSS documentation — Upgrade guide, Compatibility; release notes 4.0 to 4.3.3"
verificado-em: 2026-10-02
---

# Tailwind CSS — Migration v3 to v4

> Satellite of [Tailwind CSS](tailwindcss.md). Covers the move from line 3 to line 4: the official tool, the renames, the **defaults that changed value** and the syntax that changed form.
>
> **The risk of this migration is not the build breaking — it is the build passing.** Almost nothing in the list below raises an error. `shadow-sm` still compiles; it just gets **smaller**. `border` still compiles; it just changes **color**. Reviewing a migration is visual, or it is not a review.

---

## 1. The sequence

1. **Confirm the browser floor** — Safari 16.4, Chrome 111, Firefox 128 (`TW-CFG-11`). Below that the migration does not start: the path is 3.4.
2. **Clean branch, Node ≥ 20.**
3. **Run the tool:** `npx @tailwindcss/upgrade`. It updates dependencies, converts the config to CSS and rewrites classes in the templates.
4. **Read the whole diff.** The tool rewrites what it recognizes; a dynamically built class (`TW-SRC-01`) and a class in a file it does not scan are left behind.
5. **Decide each default that changed** (§ 3) — adopt or restore, but in writing.
6. **Swap the integration** — PostCSS → `@tailwindcss/vite` if the project runs Vite (`TW-CFG-01`); remove `postcss-import` and `autoprefixer` (`TW-CFG-02`).
7. **Compare visually** — Storybook snapshot, Playwright `toHaveScreenshot`, or the page side by side. It is the only step that catches § 2 and § 3.

| Before | After |
| --- | --- |
| `@tailwind base; @tailwind components; @tailwind utilities;` | `@import "tailwindcss";` |
| `tailwindcss` as a PostCSS plugin | `@tailwindcss/postcss` |
| `npx tailwindcss` | `npx @tailwindcss/cli` |

---

## 2. Removed and renamed utilities

### 2.1 Removed — became a modifier or another name

| v3 | v4 |
| --- | --- |
| `bg-opacity-*` · `text-opacity-*` · `border-opacity-*` · `divide-opacity-*` · `ring-opacity-*` · `placeholder-opacity-*` | opacity modifier: `bg-black/50` |
| `flex-shrink-*` · `flex-grow-*` | `shrink-*` · `grow-*` |
| `overflow-ellipsis` | `text-ellipsis` |
| `decoration-slice` · `decoration-clone` | `box-decoration-slice` · `box-decoration-clone` |

### 2.2 Renamed — **the scale moved one step**

| v3 | v4 |
| --- | --- |
| `shadow-sm` → `shadow` | `shadow-xs` → `shadow-sm` |
| `drop-shadow-sm` → `drop-shadow` | `drop-shadow-xs` → `drop-shadow-sm` |
| `blur-sm` → `blur` | `blur-xs` → `blur-sm` |
| `backdrop-blur-sm` → `backdrop-blur` | `backdrop-blur-xs` → `backdrop-blur-sm` |
| `rounded-sm` → `rounded` | `rounded-xs` → `rounded-sm` |
| `outline-none` | `outline-hidden` |
| `ring` | `ring-3` |

Read the table as **pairs**: v3's `shadow` is v4's `shadow-sm`, and v3's `shadow-sm` is v4's `shadow-xs`. The "bare" forms (`shadow`, `rounded`, `blur`) still compile for compatibility — which is why a partial manual migration is the worst case: renaming `shadow` → `shadow-sm` **without** first renaming `shadow-sm` → `shadow-xs` makes both become the same shadow.

**`outline-none` changed meaning, not just name.** In v3 it set an **invisible** outline — which reappeared in Windows high-contrast mode (forced colors). In v4 that behavior is called `outline-hidden`, and the new `outline-none` is a real `outline-style: none`. Migrating `outline-none` → `outline-none` keeps the name and **loses visible focus in forced colors**.

Other changes that show up in the guide's examples: `bg-gradient-to-r` → `bg-linear-to-r`; individual transforms (`focus:transform-none` → `focus:scale-none`; `transition-[opacity,transform]` → `transition-[opacity,scale]`).

### 2.3 Deprecations after 4.0

| Version | Before | After |
| --- | --- | --- |
| 4.1 | `bg-left-top`, `object-left-top` | `bg-top-left`, `object-top-left` |
| 4.1.x | `break-words` · `order-none` | `wrap-break-word` · `order-0` |
| 4.2 | `start-*` · `end-*` | `inset-s-*` · `inset-e-*` |

### 2.4 Rules — `TW-MIG-01` to `TW-MIG-04`

| ID | Rule |
| --- | --- |
| `TW-MIG-01` | The migration **MUST** start with `npx @tailwindcss/upgrade` on a clean branch, and the diff **MUST** be read in full. |
| `TW-MIG-02` | The renamed scale (`shadow`, `drop-shadow`, `blur`, `backdrop-blur`, `rounded`) **MUST** be migrated from smallest to largest, in one go. Partially renaming by hand **NEVER**. † |
| `TW-MIG-03` | v3's `outline-none` **MUST** become `outline-hidden`. Keeping it as `outline-none` **NEVER** — it removes visible focus in forced colors. |
| `TW-MIG-04` | A `*-opacity-*` utility **MUST** become a `/NN` modifier on the color. |

---

## 3. Defaults that changed value

This is the part no tool decides for you — every line is a **visual change with no error**.

| What | v3 | v4 | Restore v3 |
| --- | --- | --- | --- |
| `border` and `divide` color | `gray-200` | `currentColor` | `@layer base { *, ::after, ::before, ::backdrop, ::file-selector-button { border-color: var(--color-gray-200, currentColor); } }` |
| `ring` width | 3px | 1px | `@theme { --default-ring-width: 3px; }` |
| `ring` color | `blue-500` | `currentColor` | `@theme { --default-ring-color: var(--color-blue-500); }` — the source says it is **compatibility only, not idiomatic** |
| placeholder color | `gray-400` | text color at 50% | `@layer base { input::placeholder, textarea::placeholder { color: var(--color-gray-400); } }` |
| `<button>` cursor | `pointer` | `default` | `@layer base { button:not(:disabled), [role="button"]:not(:disabled) { cursor: pointer; } }` |
| `<dialog>` margin | `auto` (centered) | reset to zero | `@layer base { dialog { margin: auto; } }` |
| `hidden` attribute | display utility won | `hidden` wins (except `until-found`) | remove the attribute |
| `hover:` | plain `:hover` | inside `@media (hover: hover)` | `@custom-variant hover (&:hover);` |
| `transition`, `transition-colors` | — | include `outline-color` | always set the outline color, not only in the state |
| `space-*` and `divide-*` selector | `> :not([hidden]) ~ :not([hidden])`, margin on top | `> :not(:last-child)`, margin at the bottom | the source recommends `flex flex-col gap-*` |
| gradient with a variant | the variant reset the gradient | values preserved | `via-none` to undo the third stop |

**`hover:` on touch.** In v4, on a device without hover, `hover:` simply does not fire. The source treats hover as **enhancement**, not as the only path to a piece of information — a menu that only opens on hover stops opening on mobile, and the defect was in the design before the migration. The rule is general, not migration-specific: `TW-A11Y-08` in [Tailwind CSS - Utilities and Variants](tailwindcss-utilities-and-variants.md).

### 3.1 Rules — `TW-MIG-05` and `TW-MIG-06`

| ID | Rule |
| --- | --- |
| `TW-MIG-05` | Each default that changed (§ 3) **MUST** be decided explicitly in the migration — adopted, or restored with the source's CSS in `@layer base`/`@theme`. Letting the change through without a decision **NEVER**. |
| `TW-MIG-06` | A `border` with no color **MUST** get an explicit color (`border-border` or a shade) where v3 relied on the default gray. † |

---

## 4. Syntax that changed form

| What | v3 | v4 |
| --- | --- | --- |
| stacked variant order | right to left: `first:*:pt-0` | **left to right**: `*:first:pt-0` |
| CSS variable in an arbitrary value | `bg-[--brand]` | `bg-(--brand)` |
| comma in arbitrary grid/position | `grid-cols-[max-content,auto]` | `grid-cols-[max-content_auto]` |
| `!important` | `!flex` (still accepted, deprecated) | `flex!` |
| prefix | `tw-flex` | `tw:flex` — and generated variables `--tw-color-…` |
| custom utility | `@layer utilities { .tab-4 {…} }` | `@utility tab-4 { tab-size: 4; }` |
| configurable `container` | `center`, `padding` in the config | `@utility container { margin-inline: auto; padding-inline: 2rem; }` |
| `theme()` | `theme(screens.xl)` | variable: `var(--breakpoint-xl)`; if you need the function, `theme(--breakpoint-xl)` |
| `resolveConfig` | imported from the package | **does not exist** — `getComputedStyle` or `var()` |
| `corePlugins`, `safelist`, `separator` | config | not supported — safelist becomes `@source inline()` |

Variant order gets no ID here: it applies to any code, migrated or new — `TW-VAR-07` in [Tailwind CSS - Utilities and Variants](tailwindcss-utilities-and-variants.md).

### 4.1 Rules — `TW-MIG-07` and `TW-MIG-08`

| ID | Rule |
| --- | --- |
| `TW-MIG-07` | A custom class declared in `@layer utilities` or `@layer components` to work with variants **MUST** become `@utility`. |
| `TW-MIG-08` | A variable in an arbitrary value **MUST** use parentheses: `bg-(--x)`. `bg-[--x]` **NEVER** on v4. |

---

## 5. Antipatterns

### 5.1 "The build passed, so it migrated"

See the warning at the top. The build is the least of the checks; the visual comparison is the one that counts (§ 1, step 7).

### 5.2 Find-and-replace of `shadow` with `shadow-sm`

Without first renaming `shadow-sm` → `shadow-xs`, two distinct shadows become one (`TW-MIG-02`).

### 5.3 Restoring every default by reflex

Pasting the seven "restore v3" blocks into the stylesheet is migrating the version number and keeping the old behavior as debt. The restored `ring-color` is **declaredly not idiomatic**. Decide one by one (`TW-MIG-05`).

### 5.4 Keeping `tailwind.config.js` "because the tool left it"

The tool converts to CSS; when an `@config` is left over, it is because something did not convert. That remainder is the work list, not the final state (`TW-CFG-08`).

---

## Related

- [Tailwind CSS](tailwindcss.md) — hub
- [Tailwind CSS - Installation and Detection](tailwindcss-installation-and-detection.md) — the target integration
- [Tailwind CSS - Theme and Tokens](tailwindcss-theme-and-tokens.md) — where `theme.extend` goes
- `Playwright - Snapshots e Visual` — the visual comparison of step 7
- `Storybook - Cobertura e CI` — the other visual regression surface

## Sources consulted

Verified directly on **2026-10-02**, against `tailwindcss` **4.3.3** (`v3-lts`: 3.4.19):

- [Upgrade guide](https://tailwindcss.com/docs/upgrade-guide)
- [Compatibility](https://tailwindcss.com/docs/compatibility)
- [Releases on GitHub](https://github.com/tailwindlabs/tailwindcss/releases)

**Verification notes:**

- **`@tailwindcss/upgrade` requires Node ≥ 20.**
- **Error in the source:** the guide's alternative example to `@apply` writes `var(--text-red-500)`; the color token is `--color-red-500`.
- **The tool does not reach dynamic classes** — a claim of this note, consistent with the textual scanner the source describes, not a sentence from the source.
