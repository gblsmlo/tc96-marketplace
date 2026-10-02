---
titulo: Tailwind CSS - Installation and Detection
Link: https://tailwindcss.com/docs/installation/using-vite
tags:
  - tailwindcss
  - css
  - vite
  - configuration
  - agent-context
source: "Official Tailwind CSS documentation — Installation, Framework guides, Compatibility, Functions and directives, Detecting classes in source files, Preflight"
verificado-em: 2026-10-02
---

# Tailwind CSS — Installation and Detection

> Satellite of [Tailwind CSS](tailwindcss.md). Covers **how Tailwind enters the build** — the integration (Vite plugin, PostCSS, CLI), the entry stylesheet, Preflight, what the compiler sees in the source code and what it does not.
>
> **The characteristic failure of this note is silent:** a class the scanner did not find produces no error and no warning — the element simply ends up unstyled. That is why half the rules here are about **what the scanner sees**.

---

## 1. The integration, and which one to choose

Line 4 has four official entry points. They are not equivalent:

| Integration | Packages | When |
| --- | --- | --- |
| **Vite plugin** | `tailwindcss` `@tailwindcss/vite` | every project that already runs Vite — TanStack Start, React Router, SPA with Vite, Storybook with the Vite builder |
| **PostCSS** | `tailwindcss` `@tailwindcss/postcss` `postcss` | the bundler is not Vite, but has a PostCSS pipeline (Next.js, Rspack, Parcel) |
| **Webpack** | `tailwindcss` `@tailwindcss/webpack` | plain webpack, since 4.2 |
| **CLI** | `tailwindcss` `@tailwindcss/cli` | there is no bundler — static HTML, server template. There is also a standalone binary, without Node |

The official doc describes the Vite plugin as the path with the **best performance and the best developer experience**, and the migration guide says to migrate from PostCSS to it when the project uses Vite.

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({ plugins: [tailwindcss()] });
```

```js
// postcss.config.mjs — only when there is no Vite
export default { plugins: { '@tailwindcss/postcss': {} } };
```

`@tailwindcss/vite` 4.3.3 accepts Vite `^5.2 || ^6 || ^7 || ^8` (Vite 7 support since 4.1.11; Vite 8 since 4.2.2).

### 1.1 TanStack Start — the official guide

The TanStack Start guide uses the Vite plugin, a stylesheet at `src/styles.css`, and links it in the root route **through the `?url` query**:

```tsx
// src/routes/__root.tsx
import appCss from '../styles.css?url';

export const Route = createRootRoute({
  head: () => ({ links: [{ rel: 'stylesheet', href: appCss }] }),
  component: RootComponent,
});
```

`?url` imports the **address** of the processed CSS, not the CSS. It is what lets TanStack Start emit the `<link>` in the SSR HTML — a bare `import '../styles.css'` works on the client and arrives late for the server's first paint.

> **Error in the source itself (2026-10-02):** the guide's `vite.config.ts` is missing a comma after `tailwindcss()`. The guide lists `tailwindcss()` first, but **does not state** that the order matters — "it has to be the first plugin" is inference, not a rule.

### 1.2 What line 4 already does on its own

| Before (v3) | In v4 |
| --- | --- |
| `postcss-import` | built-in import — `@import` is resolved by Tailwind itself |
| `autoprefixer` | built-in vendor prefixing (Lightning CSS) |
| `content: [...]` in the config | **automatic detection** of sources (§ 3) |
| `tailwind.config.js` | configuration in CSS — `@theme`, `@utility`, `@custom-variant` |

Keeping `postcss-import` or `autoprefixer` alongside v4 is redundancy that processes the CSS twice.

### 1.3 Rules — `TW-CFG-01` to `TW-CFG-04`

| ID | Rule |
| --- | --- |
| `TW-CFG-01` | A project that runs Vite **MUST** integrate Tailwind through `@tailwindcss/vite`. PostCSS **NEVER** when there is Vite. |
| `TW-CFG-02` | `postcss-import` and `autoprefixer` **NEVER** coexist with v4 — import and prefixing are built in. |
| `TW-CFG-03` | `tailwindcss` and every `@tailwindcss/*` package **MUST** be on the same version. † |
| `TW-CFG-04` | In TanStack Start, the entry stylesheet **MUST** be linked through `?url` in the root route's `head().links`. |

---

## 2. The entry stylesheet

### 2.1 One line, and what it expands to

```css
/* src/styles.css */
@import "tailwindcss";
```

Equivalent to:

```css
@layer theme, base, components, utilities;
@import "tailwindcss/theme.css" layer(theme);
@import "tailwindcss/preflight.css" layer(base);
@import "tailwindcss/utilities.css" layer(utilities);
```

**The four layers are native cascade layers.** That is why a utility beats a `.card` in `@layer components` without `!important`: layer order decides before specificity.

`@tailwind base; @tailwind components; @tailwind utilities;` is v3 syntax and **does not exist** in v4.

### 2.2 `@import` options

| Option | Effect | Detail |
| --- | --- | --- |
| `source("../src")` | changes the detection base | § 3.3 |
| `source(none)` | turns off automatic detection | § 3.3 |
| `prefix(tw)` | prefixes every class: `tw:flex` | the prefix looks like a variant and always comes first |
| `important` | every utility with `!important` | — |
| `theme(static)` · `theme(inline)` | mode of the default theme | [Tailwind CSS - Theme and Tokens](tailwindcss-theme-and-tokens.md) |

When importing the pieces separately, each option goes on the corresponding import: `source(…)` and `important` on `utilities.css`; `theme(…)` on `theme.css`; `prefix(tw)` **on both**.

### 2.3 One stylesheet per app, and `@reference` everywhere else

Each `@import "tailwindcss"` generates a whole Tailwind. A CSS module or a component `<style>` block that needs `@apply` or a token does **not** import Tailwind again — it **references** the main stylesheet:

```css
/* Button.module.css */
@reference "../styles.css";

.legacy { @apply rounded-md px-3; }
```

`@reference` brings theme, variants and utilities **for resolution**, without emitting CSS. If the main stylesheet has no `@theme`, `@custom-variant` or `@plugin`, `@reference "tailwindcss";` is enough.

The source advises against CSS modules with Tailwind "if you can avoid it": each module is processed separately (**50 modules, 50 Tailwind runs**) and none sees the `@theme` without `@reference`. The preferred form inside your own CSS is the variable: `background: var(--color-blue-500);`.

`package.json` subpath imports work in `@import`, `@reference`, `@plugin` and `@config`: `"imports": { "#app.css": "./src/styles.css" }` → `@reference "#app.css";`.

### 2.4 Preprocessors

Line 4 **was not designed for Sass, Less or Stylus** — "think of Tailwind CSS itself as your preprocessor". What Sass did has a native replacement:

| Sass | In v4 |
| --- | --- |
| `@import` with bundling | `@import` resolved at build |
| `$x` variables | CSS variables and `@theme` |
| nesting | native CSS nesting, flattened by Lightning CSS |
| loops to generate classes | classes generated on demand |
| `darken()` / `lighten()` | palette shades, `color-mix()`, `--alpha()` |

### 2.5 JavaScript configuration

`tailwind.config.js` still works, but **is no longer detected** — it must be loaded explicitly with `@config "../tailwind.config.js";`. `corePlugins`, `safelist` and `separator` **are not supported**. A third-party plugin comes in through `@plugin "@tailwindcss/typography";`. What is defined in CSS wins over what comes from the config, a preset or a plugin.

`@config` and `@plugin` are **compatibility**, not the line 4 way.

### 2.6 Rules — `TW-CFG-05` to `TW-CFG-09`

| ID | Rule |
| --- | --- |
| `TW-CFG-05` | The entry stylesheet **MUST** start with `@import "tailwindcss"`. `@tailwind base/components/utilities` **NEVER** in v4. |
| `TW-CFG-06` | Each app **MUST** have a single stylesheet that imports `tailwindcss`. A CSS module or component `<style>` that uses `@apply` or a token **MUST** use `@reference`, and **NEVER** a second `@import "tailwindcss"`. |
| `TW-CFG-07` | Sass, Less and Stylus **NEVER** in a stylesheet processed by v4, nor in a component `<style>` block. |
| `TW-CFG-08` | A new project **NEVER** creates `tailwind.config.*`. A legacy config **MUST** be loaded through `@config` — without it the file is silently ignored. |
| `TW-CFG-09` | `corePlugins`, `safelist` and `separator` **NEVER** in a config loaded by v4 — they are not supported. The safelist becomes `@source inline()` (`TW-SRC-05`). |

---

## 3. What the scanner sees

### 3.1 Plain text, no parser

Tailwind reads each source file **as text**. It does not interpret JSX, does not evaluate expressions, does not follow imports. Every token that *could* be a class is tried; whatever does not match any utility is discarded.

The consequence is the most violated rule of the tool: **a class only exists if it appears whole, literally, in some scanned file.**

```tsx
// ✗ the scanner sees "bg-" and "-600", never "bg-red-600"
<div className={`bg-${color}-600`} />
<div className={`text-${error ? 'red' : 'green'}-600`} />

// ✓ map the value to the full name
const tone = { primary: 'bg-blue-600 hover:bg-blue-500', danger: 'bg-red-600 hover:bg-red-500' } as const;
<button className={tone[variant]} />
```

The defect **works in development by accident**: if `bg-red-600` appears literally in another file, the class is generated and the component "works". All it takes is that other file changing for the style to vanish in production — with no error.

### 3.2 What is left out by default

| Not scanned | Consequence |
| --- | --- |
| files in `.gitignore` | generated code ignored by git contributes no classes |
| `node_modules` (since 4.1) | a published UI library with Tailwind classes **is not seen** without `@source` |
| binaries (image, video, zip), `.node`, `.wasm` | — |
| CSS files | classes mentioned in CSS are not detected |
| package manager lockfiles | — |
| `.jj` directories (since 4.2) | — |

### 3.3 Registering and restricting sources

```css
@import "tailwindcss";

/* UI library in node_modules — path relative to the stylesheet */
@source "../node_modules/@acme/ui";

/* sibling package in the monorepo */
@source "../../../packages/ui/src";

/* exclude a folder */
@source not "../src/legacy";
```

**Detection base.** The default is the build process's **current working directory**. In a monorepo, when the build runs from the root, this scans the whole repository; when it runs from inside the app, `packages/ui` is left out. The two ways out:

```css
@import "tailwindcss" source("../src");   /* pins the base */
```

```css
@import "tailwindcss" source(none);        /* turns off the automatic one */
@source "../src";
@source "../../../packages/ui/src";        /* and declares each source */
```

Since 4.3.1, a directory referenced explicitly by `@source` is scanned **even** if it is in `.gitignore`, and an `@source` can re-include what an `@source not` excluded.

### 3.4 Safelist

A class that never appears in the code — it comes from the CMS, the database, a customer — comes in through `@source inline()`, with brace expansion:

```css
@source inline("underline");
@source inline("{hover:,focus:,}underline");
@source inline("{hover:,}bg-red-{50,{100..900..100},950}");
@source not inline("{hover:,focus:,}bg-red-{50,{100..900..100},950}");
```

A safelist is an **exception with a cost**: every listed class goes into the production CSS, used or not.

### 3.5 Rules — `TW-SRC-01` to `TW-SRC-06`

| ID | Rule |
| --- | --- |
| `TW-SRC-01` | Every class name **MUST** appear complete and literal in the source code. Building a class name by interpolation or concatenation **NEVER**. |
| `TW-SRC-02` | Variation driven by a prop or state **MUST** be a map from value to a complete class string. |
| `TW-SRC-03` | A library in `node_modules` that ships Tailwind classes **MUST** be registered with `@source` in the entry stylesheet. |
| `TW-SRC-04` | In a monorepo, the app's stylesheet **MUST** declare the base (`source(…)`) or each consumed UI package (`@source`). Depending on the directory the build runs from **NEVER**. † |
| `TW-SRC-05` | A class that does not appear in the code **MUST** come in through `@source inline()`. Writing it in a comment or dead file to "force generation" **NEVER**. † |
| `TW-SRC-06` | Generated or git-ignored code that contains classes **MUST** be registered through an explicit `@source`. |

---

## 4. Preflight

Preflight is the `base` layer reset, built on top of **modern-normalize**. It explains most of the "why did my HTML come out raw":

| Preflight rule | What changes in practice |
| --- | --- |
| margin and padding zeroed on everything | `h1`, `p`, `ul` without their own spacing |
| `box-sizing: border-box; border: 0 solid` | `border` alone gives **1px solid in `currentColor`**; a third-party component that relied on borders may gain one |
| `h1`–`h6` with `font-size` and `font-weight: inherit` | headings without visual hierarchy until they get a class |
| `ol, ul, menu { list-style: none }` | **accessibility:** VoiceOver does not announce an unstyled list as a list — a list that really is a list needs `role="list"` |
| `img, svg, video, canvas…` with `display: block` | images stop aligning like text |
| `img, video` with `max-width: 100%; height: auto` | media never overflows the container |
| `[hidden]:not([hidden="until-found"])` with `display: none !important` | the `hidden` attribute beats display utilities |

Extending the reset is `@layer base { … }`. Turning it off is importing only `theme.css` and `utilities.css`. Neutralizing it for a third-party widget is scoping: `@layer base { .google-map * { border-style: none; } }`.

### 4.1 Rules — `TW-CFG-10`

| ID | Rule |
| --- | --- |
| `TW-CFG-10` | A reset adjustment **MUST** live in `@layer base` in the entry stylesheet. Loose CSS, outside a layer, to fix Preflight **NEVER** — it beats the utilities by being outside the layers. † |

---

## 5. Compatibility

### 5.1 The browser floor

**Safari 16.4 · Chrome 111 · Firefox 128.** Line 4 depends on `@property` and `color-mix()` and "is designed for modern browsers". A product that needs to support below that stays on **3.4** (the npm `v3-lts` tag, 3.4.19 on 2026-10-02).

Some utilities have even narrower support (`field-sizing`, `@starting-style`, `text-wrap: balance`) — they are optional, and the defect of using them is degrading, not breaking.

### 5.2 Rules — `TW-CFG-11`

| ID | Rule |
| --- | --- |
| `TW-CFG-11` | Adopting v4 **MUST** go through confirming that the product accepts the Safari 16.4 / Chrome 111 / Firefox 128 floor. Below that, 3.4. |

---

## 6. Antipatterns

### 6.1 Class assembled by template string

See § 3.1. The symptom is a style that **appears and disappears** as another file in the project changes — the defect is never where the symptom shows up (`TW-SRC-01`).

### 6.2 PostCSS plugin in a Vite project

It works, and it is what many old scaffolds leave behind. It costs performance and the integration with Vite's module graph (`TW-CFG-01`).

### 6.3 `@import "tailwindcss"` in every CSS module

Each import is a complete Tailwind: Preflight and the utilities repeat in the bundle, and layer order across files stops being predictable (`TW-CFG-06`).

### 6.4 `tailwind.config.ts` "out of habit"

The file exists, has `theme.extend`, and **nothing from it reaches the CSS** — without `@config` v4 does not even read it. The symptom is a configured token that generates no class (`TW-CFG-08`).

### 6.5 Internal UI library unstyled after upgrading to 4.1

4.1 started ignoring `node_modules`. The package that worked on 4.0 loses the classes only it used (`TW-SRC-03`).

---

## Related

- [Tailwind CSS](tailwindcss.md) — hub
- [Tailwind CSS - Theme and Tokens](tailwindcss-theme-and-tokens.md) — what goes into `@theme` once the stylesheet exists
- [Tailwind CSS - Migration v3 to v4](tailwindcss-migration-v3-to-v4.md) — when the project comes from line 3
- `Monorepo com Bun - estrutura e tooling` — why Vite is the bundler, and where `packages/ui` lives
- `Bun - Bundler e Build` § 10.1 — Vite × Bun, and Tailwind's place in that decision
- `Storybook - Configuração e Builder` § 2 — global CSS in Storybook, which inherits the app's Vite

## Sources consulted

Verified directly on **2026-10-02**, against `tailwindcss` **4.3.3**:

- [Installation — Using Vite](https://tailwindcss.com/docs/installation/using-vite) · [Using PostCSS](https://tailwindcss.com/docs/installation/using-postcss) · [Tailwind CLI](https://tailwindcss.com/docs/installation/tailwind-cli)
- [Framework guides](https://tailwindcss.com/docs/installation/framework-guides) · [TanStack Start](https://tailwindcss.com/docs/installation/framework-guides/tanstack-start) · [React Router](https://tailwindcss.com/docs/installation/framework-guides/react-router)
- [Compatibility](https://tailwindcss.com/docs/compatibility)
- [Functions and directives](https://tailwindcss.com/docs/functions-and-directives)
- [Detecting classes in source files](https://tailwindcss.com/docs/detecting-classes-in-source-files)
- [Preflight](https://tailwindcss.com/docs/preflight)
- [Releases on GitHub](https://github.com/tailwindlabs/tailwindcss/releases) — 4.0 to 4.3.3

**Verification notes:**

- **`node_modules` ignored by default since 4.1.0;** `.jj` since 4.2.0; explicit `@source` beats `.gitignore` since 4.3.1.
- **Plugin order in Vite is not a rule of the source.** The guide lists `tailwindcss()` first, and that is all.
- **The detection page shows `@media (focus: focus)`** in an example of generated CSS — it looks like a doc error, not normative.
- **The Play CDN page (`@tailwindcss/browser`) was not read.** Do not prescribe the CDN in production without checking.
