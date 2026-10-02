---
titulo: Tailwind CSS - Theme and Tokens
Link: https://tailwindcss.com/docs/theme
tags:
  - tailwindcss
  - css
  - design-system
  - design-tokens
  - dark-mode
  - agent-context
source: "Official Tailwind CSS documentation — Theme variables, Colors, Dark mode, Functions and directives; shadcn/ui documentation — Tailwind v4, Theming, components.json"
verificado-em: 2026-10-02
---

# Tailwind CSS — Theme and Tokens

> Satellite of [Tailwind CSS](tailwindcss.md). Covers `@theme`, the namespaces that decide which utilities exist, the difference between `@theme`, `@theme inline` and `:root`, dark mode, and the shadcn/ui semantic token pattern.
>
> **The idea that organizes the note:** in line 4, the theme **is** the list of utilities. A token in the right namespace creates the class; a token outside it is just a variable. Getting the namespace wrong gives no error — it gives a class that does not exist.

---

## 1. Theme variable × regular variable

```css
@import "tailwindcss";

@theme {
  --color-mint-500: oklch(0.72 0.11 178);
}
```

This creates `bg-mint-500`, `text-mint-500`, `fill-mint-500` **and** the variable `--color-mint-500`, usable in your own CSS, in an arbitrary value and in inline style.

| Where to declare | Generates a utility? | What for |
| --- | --- | --- |
| `@theme { … }` | **yes** | design token: color, font, spacing, radius, shadow, breakpoint |
| `:root { … }` | no | a variable that should not become a class — a runtime value, the "real value" of a semantic token |

`@theme` **must be at the top level** of the stylesheet: never inside a selector or a media query. The special syntax exists so that this rule is verifiable.

### 1.1 The namespaces

| Namespace | Utilities |
| --- | --- |
| `--color-*` | `bg-*`, `text-*`, `border-*`, `fill-*`, `ring-*`, `shadow-*`, `accent-*`, `caret-*`, `decoration-*`, `outline-*`, `stroke-*`… |
| `--font-*` | family: `font-sans` |
| `--text-*` | size: `text-xl` — with a `--text-xl--line-height` pair |
| `--font-weight-*` | weight: `font-bold` |
| `--tracking-*` | `tracking-wide` |
| `--leading-*` | `leading-tight` |
| `--tab-size-*` | `tab-github` |
| `--breakpoint-*` | responsive variants `sm:*` |
| `--container-*` | `@sm:*` variants **and** `max-w-md` |
| `--spacing` / `--spacing-*` | `px-4`, `max-h-16`, `gap-2`… |
| `--radius-*` | `rounded-sm` |
| `--shadow-*` · `--inset-shadow-*` · `--drop-shadow-*` | shadows |
| `--blur-*` · `--perspective-*` · `--zoom-*` · `--aspect-*` | filters, 3D, zoom, aspect ratio |
| `--ease-*` · `--animate-*` | timing and animation |

**`--spacing` is a base value, not a scale.** The default is `0.25rem`, and `p-4` is `calc(var(--spacing) * 4)`. Changing `--spacing` rescales all spacing in the project.

The `--<token>--<sub>` convention (two hyphens) couples a companion value to the token: `--text-xs--line-height`.

### 1.2 Extend, override, replace

| Intent | CSS | Effect |
| --- | --- | --- |
| extend | `--font-script: Great Vibes, cursive;` | `font-script` is born |
| override one value | `--breakpoint-sm: 30rem;` | `sm:*` fires at 30rem, not 40rem |
| remove part of a namespace | `--color-lime-*: initial;` | `bg-lime-*` stops existing |
| replace a namespace | `--color-*: initial;` + your colors | **only** your colors exist — `bg-red-500` disappears |
| replace the whole theme | `--*: initial;` + your values | no theme-driven utility survives beyond yours |

Restricting the palette is the way to **prevent** a component from using `bg-red-500` in a design system that only has `danger`. The restriction is verifiable by the compiler; the convention "don't use the raw colors" is not.

### 1.3 Rules — `TW-THEME-01` to `TW-THEME-04`

| ID | Rule |
| --- | --- |
| `TW-THEME-01` | A token that should generate a utility **MUST** be declared in `@theme`, in the corresponding namespace. A variable that should not become a class **MUST** go in `:root`. |
| `TW-THEME-02` | `@theme` **MUST** be at the top level of the stylesheet. Inside a selector or media query **NEVER**. |
| `TW-THEME-03` | A design system with a closed palette **MUST** remove the default namespace (`--color-*: initial`) instead of relying on convention. † |
| `TW-THEME-04` | A value that exists as a token **MUST** be used through the token's utility. An arbitrary value that duplicates a token (`p-[16px]` with `p-4` available, `bg-[#0ea5e9]` with `bg-sky-500` available) **NEVER**. † |

---

## 2. `@theme inline`, and why the runtime theme depends on it

### 2.1 The problem `inline` solves

Without `inline`, the utility **points to the theme variable**: `.font-sans { font-family: var(--font-sans) }`. If `--font-sans` is itself `var(--font-inter)`, CSS resolves `var()` **where the variable was defined**, not where it is used:

```html
<div style="--font-sans: var(--font-inter, sans-serif);">
  <div style="--font-inter: Inter; font-family: var(--font-sans);">
    This text uses sans-serif, not Inter.
  </div>
</div>
```

With `inline`, the utility receives **the value** of the theme variable:

```css
@theme inline { --font-sans: var(--font-inter); }
/* generates: .font-sans { font-family: var(--font-inter); } */
```

The source's rule is direct: **a theme variable that references another variable uses `inline`**.

### 2.2 The swappable theme pattern

This detail is what makes dark mode, `data-theme` and per-customer branding work. The **real value** lives in a regular variable, swapped by selector; `@theme inline` only maps the utility name to it:

```css
:root            { --canvas: oklch(0.967 0.003 264.542); }
[data-theme=dark] { --canvas: oklch(0.21 0.034 264.665); }

@theme inline { --color-canvas: var(--canvas); }
/* bg-canvas emits var(--canvas), resolved on the element — swaps with the theme */
```

**What not to do:** a second `@theme` inside `.dark` (violates `TW-THEME-02`), or `dark:` on every use of a semantic color — the token swaps in one place, the component does not know a theme exists.

### 2.3 `@theme static` and what reaches the final CSS

By default, **only the theme variables that are used** are emitted in the final `:root`. `@theme static { … }` emits all of them.

The practical consequence: JS code that reads a token with `getComputedStyle(document.documentElement).getPropertyValue('--shadow-xl')` depends on the variable having been emitted — if no class uses it, it may not be there. `static` solves it. (Inference from two of the source's statements; the source does not say it in one sentence.)

`resolveConfig` **does not exist** in v4. A theme value in JS comes from the variable: `animate={{ backgroundColor: 'var(--color-blue-500)' }}`.

### 2.4 Keyframes

`@keyframes` declared **inside** `@theme` goes along with its `--animate-*`. For a `@keyframes` to always be output, even without an animation token, it goes **outside** `@theme`.

### 2.5 Rules — `TW-THEME-05` to `TW-THEME-08`

| ID | Rule |
| --- | --- |
| `TW-THEME-05` | A theme variable that references another variable **MUST** be declared in `@theme inline`. |
| `TW-THEME-06` | A token that swaps at runtime (dark mode, `data-theme`, brand) **MUST** have its value in a regular variable swapped by selector, mapped through `@theme inline`. Redefining the `@theme` token by selector, or repeating `dark:` on every use of a semantic color, **NEVER**. † |
| `TW-THEME-07` | A token read in JavaScript **MUST** come from the CSS variable. If it is read through `getComputedStyle`, the block **MUST** be `@theme static` or the token **MUST** be used by some class. |
| `TW-THEME-08` | Tokens shared between apps **MUST** live in a single CSS file imported by each app. Duplicating the `@theme` per app **NEVER**. † |

---

## 3. Colors

The default palette has **26 names** (red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose, slate, gray, zinc, neutral, stone, taupe, mauve, mist, olive — the last four since 4.2), plus `black` and `white`, in **11 shades** from `50` to `950`, all in **OKLCH**.

| Form | Example |
| --- | --- |
| opacity by modifier | `bg-black/75` · `bg-pink-500/[71.37%]` · `bg-cyan-400/(--alpha)` |
| in your own CSS | `color: var(--color-gray-950)` |
| with alpha in CSS | `--alpha(var(--color-gray-950) / 10%)` → `color-mix(in oklab, …)` |

The `bg-opacity-*`, `text-opacity-*` utilities and the like **do not exist** in v4 — see [Tailwind CSS - Migration v3 to v4](tailwindcss-migration-v3-to-v4.md).

---

## 4. Dark mode

### 4.1 The three modes

| Strategy | Declaration | Who decides |
| --- | --- | --- |
| **system** (default) | none — `dark:` uses `prefers-color-scheme` | the operating system |
| **class** | `@custom-variant dark (&:where(.dark, .dark *));` | `<html class="dark">` |
| **attribute** | `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));` | `<html data-theme="dark">` |

`:where(…)` has **zero specificity** and matches the element itself and its descendants. shadcn/ui declares `@custom-variant dark (&:is(.dark *));` — it matches **only descendants**, and `:is` takes on the specificity of its argument. Both work with `class="dark"` on `<html>`; they differ when `.dark` is put on a container and when there is a specificity contest. (The difference is CSS semantics; neither source discusses it.)

### 4.2 The three-state toggle

Light, dark and "follow the system" — the script goes **inline in `<head>`**, before the first paint, so it does not flash:

```js
document.documentElement.classList.toggle(
  'dark',
  localStorage.theme === 'dark' ||
    (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches),
);
```

In an app with SSR (TanStack Start), the script goes into the root route's `head()` as `scripts`, never in a `useEffect` — the Effect runs **after** the paint, and the flash is the symptom.

### 4.3 Rules — `TW-THEME-09` and `TW-THEME-10`

| ID | Rule |
| --- | --- |
| `TW-THEME-09` | Dark mode controlled by the app (toggle, saved preference) **MUST** declare `@custom-variant dark`. Without the declaration, `dark:` follows the system and the toggle has no effect. |
| `TW-THEME-10` | The script that applies the saved theme **MUST** run inline in `<head>`, before the first paint. Applying it in an Effect or after hydration **NEVER**. |

---

## 5. The shadcn/ui semantic token pattern

shadcn/ui is this house's component layer (see the `scaffold-06-shadcn` command), and its theme is the canonical example of § 2.2:

```css
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:is(.dark *));

:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
}
.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --radius-sm: calc(var(--radius) * 0.6);
  --radius-lg: var(--radius);
}
```

| Convention | Reading |
| --- | --- |
| `x` / `x-foreground` pair | `x` is the surface; `x-foreground` is text and icon **on** it. `bg-primary text-primary-foreground` is the pair; `bg-primary text-foreground` is the defect |
| value already wrapped (`oklch(…)`) in `:root`/`.dark`, **outside** `@layer base` | `@theme inline` maps it without `hsl(var(--x))` |
| radius derived from `--radius` | changing one number rescales `rounded-sm` through `rounded-4xl` |
| new token | `--warning` + `--warning-foreground` in `:root` **and** `.dark`, mapped in `@theme inline` |
| `components.json` | `tailwind.config` **empty** in v4; `tailwind.css` points to the stylesheet; `baseColor` does not change after init |
| animation | `tw-animate-css` (import). `tailwindcss-animate` (plugin) is **deprecated** |

The intermediate form generated by the old codemod — `:root` inside `@layer base` with raw HSL channels and `@theme { --color-x: hsl(var(--x)) }` — "works", but is not the recommended one.

### 5.1 Rules — `TW-THEME-11` to `TW-THEME-14`

| ID | Rule |
| --- | --- |
| `TW-THEME-11` | A design system component **MUST** use a semantic token (`bg-primary`, `text-muted-foreground`, `border-border`). A raw palette color (`bg-zinc-900`) in a `components/ui` component **NEVER**. † |
| `TW-THEME-12` | Surface and content **MUST** use the pair: `bg-x` with `text-x-foreground`. † |
| `TW-THEME-13` | A new semantic token **MUST** be declared in `:root` **and** `.dark`, and mapped in `@theme inline`. Declared only in light **NEVER** — dark silently inherits the light value. |
| `TW-THEME-14` | In a shadcn/ui project on v4, `components.json` **MUST** have an empty `tailwind.config`, and animation **MUST** come from `tw-animate-css`. `tailwindcss-animate` **NEVER**. |

---

## 6. Antipatterns

### 6.1 `tailwind.config.ts` with `theme.extend.colors`

See [Tailwind CSS - Installation and Detection](tailwindcss-installation-and-detection.md) § 2.5. In v4, without `@config`, nothing from that file reaches the CSS (`TW-CFG-08`). The color goes into `@theme`.

### 6.2 Brand color as a scattered arbitrary value

`bg-[#0f766e]` in twenty files is a token nobody declared. A brand change becomes a find-and-replace (`TW-THEME-04`).

### 6.3 `dark:` everywhere

`bg-white dark:bg-zinc-900 text-zinc-900 dark:text-zinc-50` repeated in every component is the theme implemented in the wrong place. With semantic tokens, the component writes `bg-background text-foreground` and dark mode is **one block** of CSS (`TW-THEME-06`, `TW-THEME-11`).

### 6.4 `@theme` without `inline` pointing to a runtime variable

`@theme { --color-canvas: var(--canvas); }` — the utility emits `var(--color-canvas)`, resolved at `:root`. Inside a container with a different `--canvas`, the color does not swap (`TW-THEME-05`).

### 6.5 Token only in `:root`

`--warning` declared in light and forgotten in `.dark`: in dark, the light-yellow warning on a dark background loses contrast. There is no error — just a user who does not read the warning (`TW-THEME-13`).

---

## Related

- [Tailwind CSS](tailwindcss.md) — hub
- [Tailwind CSS - Installation and Detection](tailwindcss-installation-and-detection.md) — the stylesheet where `@theme` lives
- [Tailwind CSS - Components and Composition](tailwindcss-components-and-composition.md) — how the component consumes the token
- `Storybook - Configuração e Builder` § 2.3 — theme in Storybook, through a global decorator
- `Monorepo com Bun - estrutura e tooling` — `packages/ui` as owner of the tokens file

## Sources consulted

Verified directly on **2026-10-02**, against `tailwindcss` **4.3.3**:

- [Theme variables](https://tailwindcss.com/docs/theme)
- [Colors](https://tailwindcss.com/docs/colors)
- [Dark mode](https://tailwindcss.com/docs/dark-mode)
- [Functions and directives](https://tailwindcss.com/docs/functions-and-directives)
- [shadcn/ui — Tailwind v4](https://ui.shadcn.com/docs/tailwind-v4) · [Theming](https://ui.shadcn.com/docs/theming) · [Manual installation](https://ui.shadcn.com/docs/installation/manual) · [components.json](https://ui.shadcn.com/docs/components-json)

**Verification notes:**

- **Not verified:** whether a variable declared in `@theme inline` is also emitted in `:root`. Do not write a rule that depends on it without testing.
- **Not verified:** the mechanism of the `/NN` modifier on utilities. Only `--alpha()` is documented as `color-mix(in oklab, …)`.
- **Not verified:** the content of `shadcn/tailwind.css`, imported by the current shadcn/ui manual installation.
- **4.3.3 changed the default `--font-sans`:** explicit platform fonts in place of `system-ui`/`ui-sans-serif`. A visual text snapshot may change on upgrade.
- **Minor divergence in shadcn/ui:** the manual installation maps `--color-destructive-foreground`; the Theming table lists only `destructive`.
