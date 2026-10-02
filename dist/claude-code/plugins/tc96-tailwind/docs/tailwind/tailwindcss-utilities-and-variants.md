---
titulo: Tailwind CSS - Utilities and Variants
Link: https://tailwindcss.com/docs/styling-with-utility-classes
tags:
  - tailwindcss
  - css
  - responsive-design
  - accessibility
  - agent-context
source: "Official Tailwind CSS documentation — Styling with utility classes, Hover/focus and other states, Responsive design, Adding custom styles, Display, Outline style, Forced color adjust"
verificado-em: 2026-10-02
---

# Tailwind CSS — Utilities and Variants

> Satellite of [Tailwind CSS](tailwindcss.md). Covers **what you write in `className`**: conflicts between utilities, arbitrary values and when they are the exception, runtime values, `@utility` and `@apply`, state variants, responsiveness, container queries and the accessibility utilities.
>
> **The note has one axis:** a utility is a **constraint** — the value comes from the design system, not from the keyboard. Every rule below protects that constraint or says when to break it on purpose.

---

## 1. Conflict: the winner is not whoever comes later in `className`

> "When you add two classes that target the same CSS property, the class that appears **later in the stylesheet** wins." — Styling with utility classes

```tsx
<div className="grid flex" />   // display: grid — the order in the attribute does not count
```

The order in the attribute is irrelevant; the order in the generated CSS belongs to Tailwind. The source is categorical: **you should just never add two conflicting classes to the same element** — add only the one that should apply:

```tsx
<div className={isGrid ? 'grid' : 'flex'} />
```

The case where the conflict is **wanted** — a component with internal defaults that accepts a `className` from outside — has its own tool, and is in [Tailwind CSS - Components and Composition](tailwindcss-components-and-composition.md) § 2.

### 1.1 `!important`

In v4 the `!` goes **at the end**: `bg-red-500!`, `hover:bg-red-600/50!`. The form `!bg-red-500` still compiles and is deprecated. `@import "tailwindcss" important;` marks all of them — it exists for projects with high-specificity legacy CSS.

`!` is a tool against CSS **you do not control**. Using it to beat another class of the project itself is the conflict of § 1 with a bandage on top.

### 1.2 Rules — `TW-UTIL-01` and `TW-UTIL-02`

| ID | Rule |
| --- | --- |
| `TW-UTIL-01` | Two utilities that set the same property **NEVER** coexist on the same element. The choice **MUST** be a condition that emits only one. |
| `TW-UTIL-02` | `!` (important) **MUST** be restricted to beating third-party CSS. To beat a class of the project itself **NEVER**. † |

---

## 2. Arbitrary value, arbitrary property, runtime value

### 2.1 Arbitrary is the named exception

> "Sometimes you need to break out of those constraints to get things pixel-perfect." — Adding custom styles

| Form | Example |
| --- | --- |
| arbitrary value | `top-[117px]` · `grid-cols-[1fr_500px_2fr]` (`_` is a space) |
| CSS variable | `bg-(--brand)` — shorthand for `bg-[var(--brand)]` |
| type hint | `text-(length:--size)` · `text-(color:--tone)` |
| `--spacing()` inside the arbitrary value | `py-[calc(--spacing(4)-1px)]` |
| arbitrary property | `[mask-type:luminance]` · `[--gutter:1rem] lg:[--gutter:2rem]` |
| arbitrary variant | `[&_p]:mt-4` · `lg:[&:nth-child(-n+3)]:hover:underline` |

An arbitrary value that appears **once** is the exception the source describes. The same arbitrary value in several places is a **token nobody declared**, and its place is `@theme` ([Tailwind CSS - Theme and Tokens](tailwindcss-theme-and-tokens.md), `TW-THEME-04`).

An arbitrary property or variant that **reproduces an existing utility** (`[display:flex]`, `[&:hover]:underline`, `[@media_print]:hidden`) is not an exception: it is the utility written wrong — and tailwind-merge cannot resolve it against the canonical form. The IntelliSense extension flags it with `suggestCanonicalClasses`.

### 2.2 Runtime value

A value that comes from the database, the API or the user **cannot** be a class — the scanner will never see it (`TW-SRC-01`). The source says to use `style`, and the form that preserves variants is to pass a **CSS variable** and consume it with a utility:

```tsx
<button
  style={{ '--bg': brand.color, '--bg-hover': brand.colorHover } as React.CSSProperties}
  className="bg-(--bg) hover:bg-(--bg-hover) rounded-md px-3 py-1.5"
/>
```

`style={{ padding: 16 }}` for a **static** value is the opposite: it loses the constraint, the state and the responsiveness.

### 2.3 Rules — `TW-UTIL-03` to `TW-UTIL-05`

| ID | Rule |
| --- | --- |
| `TW-UTIL-03` | An arbitrary value that repeats **MUST** be promoted to a token in `@theme`. † |
| `TW-UTIL-04` | An arbitrary property or variant that reproduces an existing utility or variant **NEVER**. Use the canonical form. |
| `TW-UTIL-05` | A value known only at runtime **MUST** arrive through a CSS variable in `style`, consumed by a utility (`bg-(--x)`). `style` with a static value **NEVER**. |

---

## 3. Your own CSS: `@utility`, `@layer components`, `@apply`

The source presents the ways out of duplication **in this order**, and the order is the recommendation: loop → multi-cursor editing → **component** → your own CSS. For anything "more complicated than just a single HTML element", it recommends the component. (The component detail is in [Tailwind CSS - Components and Composition](tailwindcss-components-and-composition.md).)

| Need… | Tool | Example |
| --- | --- | --- |
| a property Tailwind does not have, with variants | `@utility` | `@utility content-auto { content-visibility: auto; }` → `hover:content-auto` |
| a utility with a value | functional `@utility` | `@utility tab-* { tab-size: --value(--tab-size-*, integer); }` |
| styling markup you **do not write** (widget, CMS, library) | `@apply` on the third party's selector | `.select2-dropdown { @apply rounded-b-lg shadow-md; }` |
| a class for **one** element, reused outside React | `@layer components` | `.card { … }` — a utility still wins: `card rounded-none` |
| a block with a variant inside the CSS | `@variant` | `.x { @variant dark { background: black; } }` |
| a project-wide default for every element | `@apply` in `@layer base` | `* { @apply border-border outline-ring/50; }` — the shadcn/ui base |
| one name for a recurring combination, usable with variants | `@apply` inside `@utility` | `@utility ring-focus { @apply ring-2 ring-ring ring-offset-1; }` → `focus-visible:ring-focus` |

**Why `@apply` in a component class of the project's own is the defect** (as opposed to the base-layer default and the composed `@utility` above, which name a project-wide decision rather than a component): it recreates the semantic class the utility eliminated, hides the conflict from tailwind-merge (which does not see what `@apply` produced) and gives the component two places for style. The tailwind-merge doc says the same and proposes a JS string constant instead.

A `@utility` name that **imitates** a Tailwind utility (`text-2xs` that is not a font size) confuses tailwind-merge and the reader. Prefix it: `typography-2xs`, `ui-…`.

### 3.1 Rules — `TW-UTIL-06` to `TW-UTIL-08`

| ID | Rule |
| --- | --- |
| `TW-UTIL-06` | A custom utility that needs variants **MUST** be declared with `@utility`. |
| `TW-UTIL-07` | `@apply` **MUST** be restricted to three places: markup the project does not write, the body of an `@utility` composed from utilities, and global element rules in `@layer base`. As a component class of the project's own (`.btn { @apply … }`) **NEVER** — the component is the unit of reuse. † |
| `TW-UTIL-08` | A custom class or `@utility` name **NEVER** imitates the form of a Tailwind utility with a different meaning. |

---

## 4. State variants

### 4.1 The catalog, by question

| Question | Variants |
| --- | --- |
| interaction | `hover` · `focus` · `focus-visible` · `focus-within` · `active` · `visited` · `target` |
| position | `first` · `last` · `only` · `odd` · `even` · `nth-3` · `nth-[3n+1]` · `*-of-type` |
| form | `disabled` · `checked` · `indeterminate` · `required` · `invalid` · `user-invalid` · `placeholder-shown` · `autofill` · `read-only` |
| parent state | `group` + `group-hover:` · named `group/item` + `group-hover/item:` · implicit `in-focus:` |
| sibling state | `peer` + `peer-checked:` · named `peer/draft` |
| selector | `has-[input:checked]:` · `not-focus:` · `*:` (children) · `**:` (descendants) |
| attribute | `aria-expanded:` · `aria-[sort=ascending]:` · `data-active:` · `data-[state=open]:` · `open:` · `inert:` · `rtl:` |
| preference | `motion-safe` · `motion-reduce` · `contrast-more` · `forced-colors` · `print` · `pointer-coarse` |
| support | `supports-[display:grid]:` · `starting:` (`@starting-style`) · `noscript:` |
| pseudo-element | `before` · `after` · `placeholder` · `file` · `marker` · `selection` · `backdrop` |

### 4.2 What the list does not say

- **`peer` only looks back.** The CSS sibling combinator only reaches **following** siblings: the `peer` must come **before**, in the DOM, the element that uses `peer-*`. The other way around, the path is `has-*` on the parent.
- **A nested `group` needs a name.** Without a name, `group-hover:` matches the nearest `group` ancestor of **anything** — two nested cards fire together.
- **The state already exists in the attribute.** An accessible component already carries `aria-expanded`, `aria-selected`, `data-state` (Radix, shadcn/ui). Styling by `aria-expanded:rotate-180` uses the real state; a parallel `is-open` class is a second state that can diverge from the first.
- **`user-invalid` × `invalid`.** `invalid:` fires before the user touches the field; `user-invalid:` only after interaction. For an error message, the second is what the user expects. (Inference of this note from the behavior the source describes.)
- **Stacking order:** **left to right**, like nested selectors — `dark:md:hover:bg-fuchsia-600`, `*:first:pt-0`. v3 read it the other way round.

### 4.3 Rules — `TW-VAR-04` to `TW-VAR-07`

| ID | Rule |
| --- | --- |
| `TW-VAR-04` | The element marked with `peer` **MUST** precede, in the DOM, the one that uses `peer-*`. When it cannot, it **MUST** be `has-*` on the parent. |
| `TW-VAR-05` | A `group` inside another `group` **MUST** be named (`group/nome`). |
| `TW-VAR-06` | State already expressed by an ARIA or `data-*` attribute **MUST** be styled by the attribute's variant. A state class parallel to the attribute **NEVER**. † |
| `TW-VAR-07` | Stacked variants **MUST** be written and read left to right. |

---

## 5. Responsiveness and container queries

### 5.1 Mobile-first

An unprefixed class applies **at every width**; the prefix applies **from that width up**.

| Prefix | Minimum width |
| --- | --- |
| `sm` | 40rem |
| `md` | 48rem |
| `lg` | 64rem |
| `xl` | 80rem |
| `2xl` | 96rem |

```tsx
<p className="sm:text-center" />            // ✗ "center on mobile" — only centers from 40rem up
<p className="text-center sm:text-left" />   // ✓ centered on mobile, left-aligned from 40rem up
```

A range is `md:max-lg:flex`; an upper limit is `max-md:`; a one-off value is `min-[320px]:`. The `<meta name="viewport" content="width=device-width, initial-scale=1.0">` is a prerequisite — without it the phone pretends to be a desktop and no breakpoint fires as expected.

A custom breakpoint goes in `@theme` (`--breakpoint-3xl: 120rem`) and **in the same unit** as the others: the source warns that mixed units break the ordering.

### 5.2 Container queries

A component that lives in places of different widths — the same card in the sidebar and in the grid — should not ask the width of the **window**. A container query asks the width of the **container**, and it is native in v4:

```tsx
<div className="@container">
  <article className="flex flex-col @md:flex-row" />
</div>
```

Also `@max-md:`, range `@sm:@max-md:`, named `@container/main` + `@sm/main:`, arbitrary `@min-[475px]:`, units `w-[50cqw]`, and `@container-size` (4.3) to measure height. The sizes come from `--container-*`.

### 5.3 Rules — `TW-VAR-01` to `TW-VAR-03`

| ID | Rule |
| --- | --- |
| `TW-VAR-01` | The mobile style **MUST** be the unprefixed one, and the prefixes **MUST** override upward. `sm:` to target mobile **NEVER**. |
| `TW-VAR-02` | Custom breakpoints **MUST** use the same unit as the defaults (rem). |
| `TW-VAR-03` | A component reused in containers of different widths **MUST** respond to the container (`@container`), not the window. † |

---

## 6. Accessibility

Tailwind does not make anything accessible, but it has utilities that **remove** accessibility with one word. The rules below are about those.

| Utility | What it does | Trap |
| --- | --- | --- |
| `outline-hidden` | transparent outline — **shows up** in forced colors | it is v3's `outline-none` |
| `outline-none` | `outline-style: none` — gone in any mode | in v4 it is total removal |
| `focus:` | any focus, including click | focus ring showing up on mouse click |
| `focus-visible:` | focus the browser decides to show (keyboard) | — |
| `sr-only` | hides visually, keeps it for the screen reader | — |
| `hidden` | `display: none` — gone **also** from the accessibility tree | used to "hide visually" |
| `invisible` | `visibility: hidden` — keeps the space, gone from the reader | — |
| `motion-reduce:` · `motion-safe:` | respect `prefers-reduced-motion` | animation with neither of the two |
| `forced-colors:` · `forced-color-adjust-none` | high-contrast mode | `appearance-none` with no fallback |

About `outline-hidden` and `outline-none`, both source pages repeat: **"it's highly recommended to apply your own focus styling"** when using them.

**`:focus-visible` and the browser floor.** Safari only supports `:focus-visible` from **15.4**. Under the line 4 floor (Safari 16.4) this does not matter; in a project that stays on line 3 to serve Safari 15.0–15.3, `focus-visible:` **never** shows the ring on those devices — there the ring goes in `focus:`. It is the case where `TW-A11Y-02` yields to `TW-A11Y-01`: visible focus always beats pretty focus.

A list with `list-style: none` (the Preflight default) **is not announced as a list** by VoiceOver — see [Tailwind CSS - Installation and Detection](tailwindcss-installation-and-detection.md) § 4.

### 6.1 Rules — `TW-A11Y-01` to `TW-A11Y-08`

| ID | Rule |
| --- | --- |
| `TW-A11Y-01` | Removing the outline (`outline-hidden`, `outline-none`) **MUST** come with a focus style of your own. Removing it with no replacement **NEVER**. |
| `TW-A11Y-02` | The focus ring of buttons and links **MUST** use `focus-visible:` — as long as the project's browser floor supports `:focus-visible` (Safari ≥ 15.4). Below that, `focus:`. † |
| `TW-A11Y-03` | An icon-only control **MUST** have an accessible name — text in `sr-only` or `aria-label`. |
| `TW-A11Y-04` | Visually hidden content the screen reader needs to read **MUST** use `sr-only`. `hidden` or `invisible` for that **NEVER**. |
| `TW-A11Y-05` | Non-essential motion animation or transition **MUST** respect `motion-reduce:` or be conditioned on `motion-safe:`. † |
| `TW-A11Y-06` | A custom control with `appearance-none` **MUST** have a `forced-colors:appearance-auto` fallback or equivalent. † |
| `TW-A11Y-07` | A semantic list styled with no marker **MUST** carry `role="list"`. |
| `TW-A11Y-08` | Information or action reachable **only** through `hover:` **NEVER** — in v4, `hover:` does not fire on devices without hover. † |

---

## 7. Antipatterns

### 7.1 Overriding by order in `className`

`className={\`px-4 ${compact && 'px-2'}\`}` — both reach the element, and the winner is the one Tailwind generated last, not the one the author wrote last (`TW-UTIL-01`).

### 7.2 `p-[13px]` because "the design asked for 13"

Either the design has a scale and 13 is a mockup error, or the scale has a step nobody declared. In both cases the arbitrary value hides the question (`TW-UTIL-03`, `TW-THEME-04`).

### 7.3 `.btn` with `@apply` in `globals.css`

It is React's `Button` rewritten in CSS, with no props, no typing and invisible to tailwind-merge (`TW-UTIL-07`).

### 7.4 `focus:outline-none` with no replacement

The most copied pattern on the web and the one that most takes away keyboard focus. In v4, worse: `outline-none` also takes it away from high-contrast mode (`TW-A11Y-01`).

### 7.5 `md:` for "desktop", `sm:` for "mobile"

See § 5.1. Mobile is the unprefixed style (`TW-VAR-01`).

### 7.6 A menu that only opens on `hover:`

It does not open on touch — in v4, by the tool's design (`TW-A11Y-08`).

### 7.7 Utility class as a test selector

`page.locator('button.bg-blue-500')` breaks at the next design tweak. The class **is** the style — the locator is role and accessible name (`PW-LOC-01`, `Playwright - Locators` § 8.2).

---

## Related

- [Tailwind CSS](tailwindcss.md) — hub
- [Tailwind CSS - Theme and Tokens](tailwindcss-theme-and-tokens.md) — where the value the utility constrains comes from
- [Tailwind CSS - Components and Composition](tailwindcss-components-and-composition.md) — when the conflict is wanted, and how to compose
- [Tailwind CSS - Installation and Detection](tailwindcss-installation-and-detection.md) — why a runtime value cannot be a class
- `Playwright - Locators` — why a class is not a selector
- `Storybook - Testes e Interações` — the a11y scan, which catches part of § 6

## Sources consulted

Verified directly on **2026-10-02**, against `tailwindcss` **4.3.3**:

- [Styling with utility classes](https://tailwindcss.com/docs/styling-with-utility-classes)
- [Hover, focus, and other states](https://tailwindcss.com/docs/hover-focus-and-other-states)
- [Responsive design](https://tailwindcss.com/docs/responsive-design)
- [Adding custom styles](https://tailwindcss.com/docs/adding-custom-styles)
- [Functions and directives](https://tailwindcss.com/docs/functions-and-directives)
- [Display](https://tailwindcss.com/docs/display) · [Outline style](https://tailwindcss.com/docs/outline-style) · [Forced color adjust](https://tailwindcss.com/docs/forced-color-adjust)
- [Tailwind CSS IntelliSense — README](https://github.com/tailwindlabs/tailwindcss-intellisense/blob/main/packages/vscode-tailwindcss/README.md) — the `cssConflict` and `suggestCanonicalClasses` lints

**Verification notes:**

- **There is no source sentence saying "don't overuse `@apply`".** `TW-UTIL-07` is a decision of this note (†), derived from the order of preference the source gives for duplication and from the tailwind-merge doc's recommendation.
- **"Prefer `focus-visible:`" is an inference** from the source's description ("keyboard focus"); the source does not say "prefer". That is why `TW-A11Y-02` is †.
- **`sr-only` uses `clip-path` since 4.1.x**, instead of `clip`.
