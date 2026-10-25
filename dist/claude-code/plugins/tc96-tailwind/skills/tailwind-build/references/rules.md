---
generated-by: skills/tailwind/tailwind-setup/scripts/generate-id-map.sh
generated-at: 2026-10-25
---

# `TW-*` rules

> Grep, never load whole: `grep -h 'TW-SRC-01' references/rules.md` (or a family: `'TW-A11Y-'`).
> `MUST`/`NEVER` are normative. `†` marks a house decision, debatable in review and never Blocking alone.
> A project that stays on line 3: only `TW-SRC-01/02`, `TW-UTIL-01`, `TW-A11Y-*`, `TW-COMP-*` apply.

| ID | Rule | Source |
| --- | --- | --- |
| `TW-CORE-01` | Before prescribing configuration or a class, the project's line **MUST** be discovered — `package.json` **and** entry stylesheet. Prescribing line 4 syntax in a line 3 project, or the reverse, **NEVER**. † | `Tailwind CSS` § 6 (tailwind-review) |
| `TW-CORE-02` | New code **MUST** be written for line 4: configuration in CSS, 4.x names and syntax. Line 3 syntax in new code **NEVER**. | `Tailwind CSS` § 6 (tailwind-review) |
| `TW-CORE-03` | Component styling **MUST** be utilities in the markup. Custom CSS is a named exception (`@utility`, `@apply` on third-party code, `@layer base`), never the default path. † | `Tailwind CSS` § 6 (tailwind-review) |
| `TW-CORE-04` | A style change **MUST** be verified by rendering — story, snapshot or the screen. A green build as evidence of correct styling **NEVER**. † | `Tailwind CSS` § 6 (tailwind-review) |
| `TW-CFG-01` | A project that runs Vite **MUST** integrate Tailwind through `@tailwindcss/vite`. PostCSS **NEVER** when there is Vite. | `Tailwind CSS - Installation and Detection` § 1 (tailwind-setup) |
| `TW-CFG-02` | `postcss-import` and `autoprefixer` **NEVER** coexist with v4 — import and prefixing are built in. | `Tailwind CSS - Installation and Detection` § 1 (tailwind-setup) |
| `TW-CFG-03` | `tailwindcss` and every `@tailwindcss/*` package **MUST** be on the same version. † | `Tailwind CSS - Installation and Detection` § 1 (tailwind-setup) |
| `TW-CFG-04` | In TanStack Start, the entry stylesheet **MUST** be linked through `?url` in the root route's `head().links`. | `Tailwind CSS - Installation and Detection` § 1 (tailwind-setup) |
| `TW-CFG-05` | The entry stylesheet **MUST** start with `@import "tailwindcss"`. `@tailwind base/components/utilities` **NEVER** in v4. | `Tailwind CSS - Installation and Detection` § 2 (tailwind-setup) |
| `TW-CFG-06` | Each app **MUST** have a single stylesheet that imports `tailwindcss`. A CSS module or component `<style>` that uses `@apply` or a token **MUST** use `@reference`, and **NEVER** a second `@import "tailwindcss"`. | `Tailwind CSS - Installation and Detection` § 2 (tailwind-setup) |
| `TW-CFG-07` | Sass, Less and Stylus **NEVER** in a stylesheet processed by v4, nor in a component `<style>` block. | `Tailwind CSS - Installation and Detection` § 2 (tailwind-setup) |
| `TW-CFG-08` | A new project **NEVER** creates `tailwind.config.*`. A legacy config **MUST** be loaded through `@config` — without it the file is silently ignored. | `Tailwind CSS - Installation and Detection` § 2 (tailwind-setup) |
| `TW-CFG-09` | `corePlugins`, `safelist` and `separator` **NEVER** in a config loaded by v4 — they are not supported. The safelist becomes `@source inline()` (`TW-SRC-05`). | `Tailwind CSS - Installation and Detection` § 2 (tailwind-setup) |
| `TW-CFG-10` | A reset adjustment **MUST** live in `@layer base` in the entry stylesheet. Loose CSS, outside a layer, to fix Preflight **NEVER** — it beats the utilities by being outside the layers. † | `Tailwind CSS - Installation and Detection` § 4 (tailwind-setup) |
| `TW-CFG-11` | Adopting v4 **MUST** go through confirming that the product accepts the Safari 16.4 / Chrome 111 / Firefox 128 floor. Below that, 3.4. | `Tailwind CSS - Installation and Detection` § 5 (tailwind-setup) |
| `TW-SRC-01` | Every class name **MUST** appear complete and literal in the source code. Building a class name by interpolation or concatenation **NEVER**. | `Tailwind CSS - Installation and Detection` § 3 (tailwind-setup) |
| `TW-SRC-02` | Variation driven by a prop or state **MUST** be a map from value to a complete class string. | `Tailwind CSS - Installation and Detection` § 3 (tailwind-setup) |
| `TW-SRC-03` | A library in `node_modules` that ships Tailwind classes **MUST** be registered with `@source` in the entry stylesheet. | `Tailwind CSS - Installation and Detection` § 3 (tailwind-setup) |
| `TW-SRC-04` | In a monorepo, the app's stylesheet **MUST** declare the base (`source(…)`) or each consumed UI package (`@source`). Depending on the directory the build runs from **NEVER**. † | `Tailwind CSS - Installation and Detection` § 3 (tailwind-setup) |
| `TW-SRC-05` | A class that does not appear in the code **MUST** come in through `@source inline()`. Writing it in a comment or dead file to "force generation" **NEVER**. † | `Tailwind CSS - Installation and Detection` § 3 (tailwind-setup) |
| `TW-SRC-06` | Generated or git-ignored code that contains classes **MUST** be registered through an explicit `@source`. | `Tailwind CSS - Installation and Detection` § 3 (tailwind-setup) |
| `TW-THEME-01` | A token that should generate a utility **MUST** be declared in `@theme`, in the corresponding namespace. A variable that should not become a class **MUST** go in `:root`. | `Tailwind CSS - Theme and Tokens` § 1 (tailwind-setup) |
| `TW-THEME-02` | `@theme` **MUST** be at the top level of the stylesheet. Inside a selector or media query **NEVER**. | `Tailwind CSS - Theme and Tokens` § 1 (tailwind-setup) |
| `TW-THEME-03` | A design system with a closed palette **MUST** remove the default namespace (`--color-*: initial`) instead of relying on convention. † | `Tailwind CSS - Theme and Tokens` § 1 (tailwind-setup) |
| `TW-THEME-04` | A value that exists as a token **MUST** be used through the token's utility. An arbitrary value that duplicates a token (`p-[16px]` with `p-4` available, `bg-[#0ea5e9]` with `bg-sky-500` available) **NEVER**. † | `Tailwind CSS - Theme and Tokens` § 1 (tailwind-setup) |
| `TW-THEME-05` | A theme variable that references another variable **MUST** be declared in `@theme inline`. | `Tailwind CSS - Theme and Tokens` § 2 (tailwind-setup) |
| `TW-THEME-06` | A token that swaps at runtime (dark mode, `data-theme`, brand) **MUST** have its value in a regular variable swapped by selector, mapped through `@theme inline`. Redefining the `@theme` token by selector, or repeating `dark:` on every use of a semantic color, **NEVER**. † | `Tailwind CSS - Theme and Tokens` § 2 (tailwind-setup) |
| `TW-THEME-07` | A token read in JavaScript **MUST** come from the CSS variable. If it is read through `getComputedStyle`, the block **MUST** be `@theme static` or the token **MUST** be used by some class. | `Tailwind CSS - Theme and Tokens` § 2 (tailwind-setup) |
| `TW-THEME-08` | Tokens shared between apps **MUST** live in a single CSS file imported by each app. Duplicating the `@theme` per app **NEVER**. † | `Tailwind CSS - Theme and Tokens` § 2 (tailwind-setup) |
| `TW-THEME-09` | Dark mode controlled by the app (toggle, saved preference) **MUST** declare `@custom-variant dark`. Without the declaration, `dark:` follows the system and the toggle has no effect. | `Tailwind CSS - Theme and Tokens` § 4 (tailwind-setup) |
| `TW-THEME-10` | The script that applies the saved theme **MUST** run inline in `<head>`, before the first paint. Applying it in an Effect or after hydration **NEVER**. | `Tailwind CSS - Theme and Tokens` § 4 (tailwind-setup) |
| `TW-THEME-11` | A design system component **MUST** use a semantic token (`bg-primary`, `text-muted-foreground`, `border-border`). A raw palette color (`bg-zinc-900`) in a `components/ui` component **NEVER**. † | `Tailwind CSS - Theme and Tokens` § 5 (tailwind-setup) |
| `TW-THEME-12` | Surface and content **MUST** use the pair: `bg-x` with `text-x-foreground`. † | `Tailwind CSS - Theme and Tokens` § 5 (tailwind-setup) |
| `TW-THEME-13` | A new semantic token **MUST** be declared in `:root` **and** `.dark`, and mapped in `@theme inline`. Declared only in light **NEVER** — dark silently inherits the light value. | `Tailwind CSS - Theme and Tokens` § 5 (tailwind-setup) |
| `TW-THEME-14` | In a shadcn/ui project on v4, `components.json` **MUST** have an empty `tailwind.config`, and animation **MUST** come from `tw-animate-css`. `tailwindcss-animate` **NEVER**. | `Tailwind CSS - Theme and Tokens` § 5 (tailwind-setup) |
| `TW-UTIL-01` | Two utilities that set the same property **NEVER** coexist on the same element. The choice **MUST** be a condition that emits only one. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 1 |
| `TW-UTIL-02` | `!` (important) **MUST** be restricted to beating third-party CSS. To beat a class of the project itself **NEVER**. † | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 1 |
| `TW-UTIL-03` | An arbitrary value that repeats **MUST** be promoted to a token in `@theme`. † | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 2 |
| `TW-UTIL-04` | An arbitrary property or variant that reproduces an existing utility or variant **NEVER**. Use the canonical form. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 2 |
| `TW-UTIL-05` | A value known only at runtime **MUST** arrive through a CSS variable in `style`, consumed by a utility (`bg-(--x)`). `style` with a static value **NEVER**. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 2 |
| `TW-UTIL-06` | A custom utility that needs variants **MUST** be declared with `@utility`. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 3 |
| `TW-UTIL-07` | `@apply` **MUST** be restricted to three places: markup the project does not write, the body of an `@utility` composed from utilities, and global element rules in `@layer base`. As a component class of the project's own (`.btn { @apply … }`) **NEVER** — the component is the unit of reuse. † | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 3 |
| `TW-UTIL-08` | A custom class or `@utility` name **NEVER** imitates the form of a Tailwind utility with a different meaning. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 3 |
| `TW-VAR-01` | The mobile style **MUST** be the unprefixed one, and the prefixes **MUST** override upward. `sm:` to target mobile **NEVER**. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 5 |
| `TW-VAR-02` | Custom breakpoints **MUST** use the same unit as the defaults (rem). | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 5 |
| `TW-VAR-03` | A component reused in containers of different widths **MUST** respond to the container (`@container`), not the window. † | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 5 |
| `TW-VAR-04` | The element marked with `peer` **MUST** precede, in the DOM, the one that uses `peer-*`. When it cannot, it **MUST** be `has-*` on the parent. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 4 |
| `TW-VAR-05` | A `group` inside another `group` **MUST** be named (`group/nome`). | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 4 |
| `TW-VAR-06` | State already expressed by an ARIA or `data-*` attribute **MUST** be styled by the attribute's variant. A state class parallel to the attribute **NEVER**. † | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 4 |
| `TW-VAR-07` | Stacked variants **MUST** be written and read left to right. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 4 |
| `TW-A11Y-01` | Removing the outline (`outline-hidden`, `outline-none`) **MUST** come with a focus style of your own. Removing it with no replacement **NEVER**. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 6 |
| `TW-A11Y-02` | The focus ring of buttons and links **MUST** use `focus-visible:` — as long as the project's browser floor supports `:focus-visible` (Safari ≥ 15.4). Below that, `focus:`. † | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 6 |
| `TW-A11Y-03` | An icon-only control **MUST** have an accessible name — text in `sr-only` or `aria-label`. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 6 |
| `TW-A11Y-04` | Visually hidden content the screen reader needs to read **MUST** use `sr-only`. `hidden` or `invisible` for that **NEVER**. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 6 |
| `TW-A11Y-05` | Non-essential motion animation or transition **MUST** respect `motion-reduce:` or be conditioned on `motion-safe:`. † | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 6 |
| `TW-A11Y-06` | A custom control with `appearance-none` **MUST** have a `forced-colors:appearance-auto` fallback or equivalent. † | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 6 |
| `TW-A11Y-07` | A semantic list styled with no marker **MUST** carry `role="list"`. | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 6 |
| `TW-A11Y-08` | Information or action reachable **only** through `hover:` **NEVER** — in v4, `hover:` does not fire on devices without hover. † | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) § 6 |
| `TW-COMP-01` | A set of classes repeated in more than one file **MUST** become a component. Copying the string between files **NEVER**. | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 1 |
| `TW-COMP-02` | Conditional classes **internal** to the component **MUST** be joined without merge (`clsx`, `twJoin`) and structured so they do not conflict. Merge to resolve an internal conflict **NEVER**. | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 2 |
| `TW-COMP-03` | A `className` received from outside **MUST** go through `twMerge`/`cn`, **last**. | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 2 |
| `TW-COMP-04` | A custom token in a namespace that is not color (`--text-*`, `--spacing-*`, `--radius-*`, `--shadow-*`…) **MUST** be registered in `extendTailwindMerge`. | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 2 |
| `TW-COMP-05` | The project **MUST** have a single composition helper (`cn`), imported from one place only. † | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 2 |
| `TW-COMP-06` | A component with design variation **MUST** declare it as a variant (cva or tailwind-variants), with the derived type (`VariantProps`). Design variation passed through `className` **NEVER**. † | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 3 |
| `TW-COMP-07` | `cva` output that is joined with `className` **MUST** go through merge — cva does not resolve conflicts. | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 3 |
| `TW-COMP-08` | A design system component's `className` **MUST** be treated as a layout extension. Relying on it to redo focus, `disabled` or intent **NEVER**. † | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 3 |
| `TW-TOOL-01` | A project that uses `prettier-plugin-tailwindcss` on v4 **MUST** declare `tailwindStylesheet` and the project's helpers in `tailwindFunctions`, and the plugin **MUST** be the last one. | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 4 |
| `TW-TOOL-02` | Class order is **NEVER** a blocking finding in review — it is readability. An order finding only fits where a sorter is configured and it did not run. † | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 4 |
| `TW-TOOL-03` | The editor configuration **MUST** register the class helpers (`classFunctions`) and, in a monorepo, each app's stylesheet (`experimental.configFile`). † | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) § 4 |
| `TW-MIG-01` | The migration **MUST** start with `npx @tailwindcss/upgrade` on a clean branch, and the diff **MUST** be read in full. | `Tailwind CSS - Migration v3 to v4` § 2 (tailwind-migrate) |
| `TW-MIG-02` | The renamed scale (`shadow`, `drop-shadow`, `blur`, `backdrop-blur`, `rounded`) **MUST** be migrated from smallest to largest, in one go. Partially renaming by hand **NEVER**. † | `Tailwind CSS - Migration v3 to v4` § 2 (tailwind-migrate) |
| `TW-MIG-03` | v3's `outline-none` **MUST** become `outline-hidden`. Keeping it as `outline-none` **NEVER** — it removes visible focus in forced colors. | `Tailwind CSS - Migration v3 to v4` § 2 (tailwind-migrate) |
| `TW-MIG-04` | A `*-opacity-*` utility **MUST** become a `/NN` modifier on the color. | `Tailwind CSS - Migration v3 to v4` § 2 (tailwind-migrate) |
| `TW-MIG-05` | Each default that changed (§ 3) **MUST** be decided explicitly in the migration — adopted, or restored with the source's CSS in `@layer base`/`@theme`. Letting the change through without a decision **NEVER**. | `Tailwind CSS - Migration v3 to v4` § 3 (tailwind-migrate) |
| `TW-MIG-06` | A `border` with no color **MUST** get an explicit color (`border-border` or a shade) where v3 relied on the default gray. † | `Tailwind CSS - Migration v3 to v4` § 3 (tailwind-migrate) |
| `TW-MIG-07` | A custom class declared in `@layer utilities` or `@layer components` to work with variants **MUST** become `@utility`. | `Tailwind CSS - Migration v3 to v4` § 4 (tailwind-migrate) |
| `TW-MIG-08` | A variable in an arbitrary value **MUST** use parentheses: `bg-(--x)`. `bg-[--x]` **NEVER** on v4. | `Tailwind CSS - Migration v3 to v4` § 4 (tailwind-migrate) |

## Pairs that look like aliases and are not

- `TW-THEME-04` (arbitrary duplicating a token: use it) × `TW-UTIL-03` (repeated arbitrary, no token: create it).
- `TW-SRC-02` (scanner: complete strings) × `TW-COMP-06` (API: design variation is a variant).
- `TW-UTIL-01` (conflict on the element) × `TW-COMP-02` (merge hiding an internal conflict).
- `TW-MIG-03` (rename `outline-none` → `outline-hidden`) × `TW-A11Y-01` (focus replacement, for both).
