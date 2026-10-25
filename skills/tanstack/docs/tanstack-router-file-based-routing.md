---
title: TanStack Router - File-Based Routing
link: https://tanstack.com/router/latest/docs/framework/react/routing/file-based-routing
tags:
  - tanstack-router
  - routing
  - build
  - agent-context
source: "Official documentation: https://tanstack.com/router/latest/docs/framework/react/"
verified-at: 2026-08-14
---

# TanStack Router - File-Based Routing

## Contents

- [1. Concept: the file name is compiler input](#1-concept-the-file-name-is-compiler-input)
- [2. The file-name grammar](#2-the-file-name-grammar)
- [3. Installation and plugin order](#3-installation-and-plugin-order)
- [4. Configuration and defaults](#4-configuration-and-defaults)
- [5. routeTree.gen.ts](#5-routetreegents)
- [Version notes](#version-notes)
- [Antipatterns](#antipatterns)

> **Generation mechanics**: the canonical file-name token table, the bundler plugin and the CLI, the config options with their defaults, and `routeTree.gen.ts` as an artifact.
>
> **Does not cover:** what each route type means and when to use it ([TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) · flat × directory × mixed and code-based ([TanStack Router - Route Trees](tanstack-router-route-trees.md)) · match precedence ([TanStack Router - Route Matching](tanstack-router-route-matching.md)) · replacing the convention with code ([TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)) · `autoCodeSplitting` in practice ([TanStack Router - Route Context and Code Splitting](tanstack-router-route-context-and-code-splitting.md)).

Entry: [TanStack Router](tanstack-router.md) · Normative basis: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Concept: the file name is compiler input

File-based routing is not "the router reads the folder at runtime". It is a **build step**: a bundler plugin (or the CLI) reads `routesDirectory`, parses file names as a grammar, and **writes two artifacts**:

1. `routeTree.gen.ts`: the assembled tree, with every route's types;
2. the path literal inside each `createFileRoute('…')`, rewritten in your file.

> "our plugin will **automatically generate your route configuration through your bundler's dev and build processes**"

Hence: **a hand-written path is overwritten** (output, not input, `TSR-ROUTE-01`), and **renaming a file is a route refactor**, with immediate type errors wherever it was referenced.

Supported bundlers: Vite, Rspack/Rsbuild, Webpack, Esbuild; otherwise see [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md).

---

## 2. The file-name grammar

Canonical token table, quoted from the source; route-type meaning is in [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md).

| Token | Meaning (source) |
| --- | --- |
| `__root.tsx` | "The root route file must be named `__root.tsx` and must be placed in the root of the configured `routesDirectory`." |
| `.` | "Routes can use the `.` character to denote a nested route. For example, `blog.post` will be generated as a child of `blog`." |
| `$` | "Route segments with the `$` token are parameterized and will extract the value from the URL pathname as a route `param`." |
| `_` (prefix) | "Route segments with the `_` prefix are considered to be pathless layout routes and will not be used when matching its child routes against the URL pathname." |
| `_` (suffix) | "Route segments with the `_` suffix exclude the route from being nested under any parent routes." |
| `-` (prefix) | "Files and folders with the `-` prefix are excluded from the route tree." |
| `(folder)` | "A folder that matches this pattern is treated as a route group, preventing the folder from being included in the route's URL path." |
| `[x]` | Escapes a special character: `script[.]js.tsx` yields `/script.js`. |
| `index` | "Route segments ending with the `index` token will match the parent route when the URL pathname matches the parent route exactly." |
| `route` | "The `route` suffix can be used to create a route file at the directory's path" (`blog/post/route.tsx` for `/blog/post`). |

Minimum route file:

```tsx
// src/routes/posts.$postId.tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/posts/$postId')({
  component: PostComponent,
})
```

The generator looks for the named export `Route`; a file in `routesDirectory` exporting something else is not a usable route.

| ID | Rule |
| --- | --- |
| `TSR-FILE-01` | Every route file **MUST** export `const Route` as a named export. |

`route` and `index` are **not fixed reserved words**: they are the defaults of `routeToken` and `indexToken`, configurable per project (§ 4). Same for the `-` of `routeFileIgnorePrefix`.

| ID | Rule |
| --- | --- |
| `TSR-FILE-02` | A project's naming convention **MUST** be read from its configuration before being assumed: `routeToken`, `indexToken`, `routeFilePrefix` and `routeFileIgnorePrefix` change the grammar. |

---

## 3. Installation and plugin order

```bash
npm install @tanstack/router-plugin
```

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { tanstackRouter } from '@tanstack/router-plugin/vite'

export default defineConfig({
  plugins: [
    tanstackRouter({
      target: 'react',
      autoCodeSplitting: true,
    }),
    react(),
  ],
})
```

Order matters: *"Please make sure that '@tanstack/router-plugin' is passed before '@vitejs/plugin-react'"*; otherwise the router transform does not run over the React plugin's output. Without a bundler: the CLI, configured by `tsr.config.json` with the same options.

| ID | Rule |
| --- | --- |
| `TSR-FILE-03` | `tanstackRouter()` **MUST** come before `@vitejs/plugin-react` in the `plugins` array. |

---

## 4. Configuration and defaults

| Option | Default | What it does |
| --- | --- | --- |
| `routesDirectory` | `./src/routes` | "The path to the directory where the route files are located, relative to the cwd" |
| `generatedRouteTree` | `./src/routeTree.gen.ts` | "The path to the file where the generated route tree will be saved, relative to the cwd" |
| `routeFilePrefix` | *(empty)* | Only files starting with this prefix count as routes |
| `routeFileIgnorePrefix` | `-` | "Used to ignore specific files and directories in the route directory" |
| `routeToken` | `route` | Identifies a directory's layout file; accepts a regex |
| `indexToken` | `index` | Identifies the index route file; accepts a regex |
| `virtualRouteConfig` | `undefined` | Enables [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) |
| `quoteStyle` | `single` | Quotes in generated files |
| `semicolons` | `false` | Semicolons in generated files |
| `autoCodeSplitting` | `false` | Automatic code splitting of the route's non-critical items |
| `disableTypes` | `false` | "Disables generating types for the route tree": emits `.js` instead of `.ts` |

`disableTypes` turns off exactly what this router is chosen for; a TypeScript project has no legitimate use for it.

| ID | Rule |
| --- | --- |
| `TSR-FILE-04` | `disableTypes: true` **NEVER** in a TypeScript project: it removes the tree's type generation, the reason to use file-based routing. |

> **Not verified:** `target` (`'react'` / `'solid'`) appears in every official `vite.config.ts` example but not in the file-based routing options reference consulted. Keep `target` (it is in the source), but do not assume the set of accepted values without checking.

---

## 5. routeTree.gen.ts

Generator output, rewritten on every dev and build. Editing it by hand is lost work and hides the real problem (some file name). A diff in it during review means the route structure changed: it shows a PR's real impact on the tree.

| ID | Rule |
| --- | --- |
| `TSR-FILE-05` | `routeTree.gen.ts` is **NEVER** edited by hand. To change the tree, change the file names in `routesDirectory`. |

---

## Version notes

Conventions that look plausible and do not exist:

- `.layout.tsx` is not a layout suffix. A layout is the `route` token (`posts/route.tsx`) or the flat sibling (`posts.tsx`); a layout with no path is the `_` prefix.
- `*.tsx` is not a catch-all. The catch-all is `$.tsx`, read from `params._splat`.
- `.` is a level separator, not a pathless marker; `pathless/` folders mean nothing. Pathless is `_` prefix; route group is `(folder)`.
- A group is `(protected)` with no dot, and `__root.tsx` exists only once, at the root of `routesDirectory`.
- In file-based the constructor is `createFileRoute('/path')({...})`; `createRoute({ getParentRoute, path })` is the code-based API ([TanStack Router - Route Trees](tanstack-router-route-trees.md) § 4).

---

## Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| Fixing the path inside `createFileRoute` | Generated artifact; comes back on the next build | Rename the file (`TSR-ROUTE-01`) |
| Editing `routeTree.gen.ts` to "fix" a route | Overwritten on every build | Fix the file name (`TSR-FILE-05`) |
| `plugins: [react(), tanstackRouter(...)]` | The router transform does not run over React's output | Router plugin first (`TSR-FILE-03`) |
| `src/routes/posts/PostsTable.tsx` helper | Becomes the route `/posts/PostsTable` | `-PostsTable.tsx` (`TSR-ROUTE-13`) |
| `export default` in a route file | The generator expects the named export `Route` | `export const Route = createFileRoute(…)` (`TSR-FILE-01`) |
| Assuming `index.tsx` is always the index route | `indexToken` is configurable | Read the project config (`TSR-FILE-02`) |
| `disableTypes: true` to speed up the build | Removes all type safety | Keep types (`TSR-FILE-04`) |
