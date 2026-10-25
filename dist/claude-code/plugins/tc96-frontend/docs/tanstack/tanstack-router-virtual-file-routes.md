---
title: TanStack Router - Virtual File Routes
link: https://tanstack.com/router/latest/docs/framework/react/routing/virtual-file-routes
tags:
  - tanstack-router
  - routing
  - build
  - agent-context
source: "Official documentation: https://tanstack.com/router/latest/docs/framework/react/"
verified-at: 2026-08-14
---

# TanStack Router - Virtual File Routes

## Contents

- [1. Concept: separating the tree from the folder](#1-concept-separating-the-tree-from-the-folder)
- [2. The API](#2-the-api)
- [3. physical: mounting file-based inside virtual](#3-physical-mounting-file-based-inside-virtual)
- [4. __virtual.ts: virtual inside file-based](#4-__virtualts-virtual-inside-file-based)
- [5. Configuration](#5-configuration)
- [Antipatterns](#antipatterns)

> The `@tanstack/virtual-file-routes` package: `rootRoute`, `route`, `index`, `layout`, `physical`, `defineVirtualSubtreeConfig`. Declaring the tree in code, pointing at files wherever they live, and mixing that with file-based at any level.
>
> **Does not cover:** what each route type means ([TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) · the naming convention `physical` applies ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · code-based routing, which is something else ([TanStack Router - Route Trees](tanstack-router-route-trees.md) § 4) · match precedence, which is identical ([TanStack Router - Route Matching](tanstack-router-route-matching.md)).

Entry: [TanStack Router](tanstack-router.md) · Normative basis: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Concept: separating the tree from the folder

File-based routing ties **what the route tree is** to **where the files live**. That stops helping when the project has a feature-based layout (`src/features/invoices/…`) you do not want to dismantle, or the router convention clashes with the house one. Virtual file routes untie them: the tree is declared in TypeScript and each node **points at a real file**, at any path.

| | Where the tree is declared | Components come from | Generated types |
| --- | --- | --- | --- |
| **File-based** | file names | route files | yes |
| **Virtual file routes** | a TS module | real files, referenced | yes |
| **Code-based** | a TS module | direct imports | no generation |

Virtual is **not** code-based: the generator still produces `routeTree.gen.ts` and type safety; only the source of the structure changes. So virtual, not code-based, answers "the convention does not fit" ([TanStack Router - Route Trees](tanstack-router-route-trees.md) § 4).

| ID | Rule |
| --- | --- |
| `TSR-VIRTUAL-01` | Virtual file routes are **NEVER** the default choice. They enter only when the file-based convention cannot be adopted: existing structure, conflicting internal convention, or a bundler without a plugin. |

---

## 2. The API

Package: `@tanstack/virtual-file-routes`.

| Function | Signature | Creates |
| --- | --- | --- |
| `rootRoute` | `rootRoute(file, children)` | the virtual root, equivalent to `__root.tsx` |
| `route` | `route(path, file?, children?)` | route with a path; `file` and `children` optional |
| `index` | `index(file)` | the parent's index route |
| `layout` | `layout(file, children?)` or `layout(id, file, children)` | pathless layout, contributes no segment |
| `physical` | `physical(path, dir?)` or `physical(dir)` | mounts a directory using file-based |
| `defineVirtualSubtreeConfig` | `defineVirtualSubtreeConfig(children)` | virtual subtree inside file-based (§ 4) |

```ts
// routes.ts
import {
  rootRoute,
  route,
  index,
  layout,
  physical,
} from '@tanstack/virtual-file-routes'

export const routes = rootRoute('root.tsx', [
  index('index.tsx'),

  layout('pathlessLayout.tsx', [
    route('/dashboard', 'app/dashboard.tsx', [
      index('app/dashboard-index.tsx'),
      route('/invoices', 'app/dashboard-invoices.tsx', [
        index('app/invoices-index.tsx'),
        route('$id', 'app/invoice-detail.tsx'),
      ]),
    ]),
  ]),

  // mounts all of posts/ under /posts, with the file-based convention
  physical('/posts', 'posts'),
])
```

**`route` without a file** creates a path prefix with no component; it only makes sense with children:

```ts
route('/hello', [
  route('/world', 'world.tsx'),      // /hello/world
  route('/universe', 'universe.tsx'), // /hello/universe
])
```

**`layout` with an id** (three-argument overload) names the layout, useful with several sibling pathless layouts:

```ts
layout('auth', 'auth-layout.tsx', [
  route('/login', 'login.tsx'),
])
```

| ID | Rule |
| --- | --- |
| `TSR-VIRTUAL-02` | `route` without `file` **MUST** have `children`: with neither, the node renders nothing and contains nothing. |
| `TSR-VIRTUAL-03` | `layout` **NEVER** takes a path. If the node must contribute a URL segment, it is `route`, not `layout`. |

---

## 3. physical: mounting file-based inside virtual

`physical(path, dir)` mounts a whole directory under a prefix with the normal file-based convention ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) § 2).

```ts
rootRoute('root.tsx', [
  index('index.tsx'),
  physical('/posts', 'posts'),
  layout('app-layout.tsx', [
    physical('/dashboard', 'app'),
  ]),
])
```

With `routes/` holding `root.tsx`, `index.tsx`, `posts/{index,$postId}.tsx` and `app/dashboard.tsx`: `/` → `index.tsx` · `/posts` → `posts/index.tsx` · `/posts/$postId` → `posts/$postId.tsx` · `/dashboard` → `app/dashboard.tsx`.

### Merging at the current level

With no path prefix, the directory is merged where it is:

```ts
export const routes = rootRoute('__root.tsx', [
  route('/about', 'about.tsx'),
  physical('features'), // same as physical('', 'features')
])
```

| URL | File |
| --- | --- |
| `/about` | `about.tsx` |
| `/` | `features/index.tsx` |
| `/contact` | `features/contact.tsx` |

The feature's only real trap, per the source: *"ensure there are no conflicting route paths between your virtual routes and the physical directory routes."*

| ID | Rule |
| --- | --- |
| `TSR-VIRTUAL-04` | When merging `physical` at the current level, the physical directory's paths and those of sibling virtual routes **NEVER** collide. |

---

## 4. __virtual.ts: virtual inside file-based

The reverse: a `__virtual.ts` in a directory of a file-based project makes the generator *"switch over to virtual file route configuration for this directory (and its child directories)."*

```
/routes
├── __root.tsx
├── index.tsx
└── foo/
    ├── bar.tsx
    └── bar/
        ├── __virtual.ts    ← virtual from here down
        ├── home.tsx
        └── details.tsx
```

```ts
// routes/foo/bar/__virtual.ts
import {
  defineVirtualSubtreeConfig,
  index,
  route,
} from '@tanstack/virtual-file-routes'

export default defineVirtualSubtreeConfig([
  index('home.tsx'),           // /foo/bar
  route('$id', 'details.tsx'), // /foo/bar/$id
])
```

`defineVirtualSubtreeConfig` accepts a config array, a function or an async function (like Vite's `defineConfig`). The switch repeats: a directory inside the virtual subtree is file-based again, a deeper `__virtual.ts` virtual again.

```
routes/posts/__virtual.ts               ← virtual
routes/posts/lets-go/index.tsx          ← file-based again
routes/posts/lets-go/deeper/__virtual.ts  ← virtual again
```

So virtual file routes are a **migration** tool: convert one section at a time.

| ID | Rule |
| --- | --- |
| `TSR-VIRTUAL-05` | `__virtual.ts` **MUST** `export default` the return of `defineVirtualSubtreeConfig`. |

---

## 5. Configuration

One option turns it on, `virtualRouteConfig`:

```ts
// vite.config.ts
import { tanstackRouter } from '@tanstack/router-plugin/vite'

export default defineConfig({
  plugins: [
    tanstackRouter({
      target: 'react',
      virtualRouteConfig: './routes.ts',
    }),
    react(),
  ],
})
```

It also accepts the tree inline:

```ts
import { rootRoute, index, route } from '@tanstack/virtual-file-routes'

const routes = rootRoute('root.tsx', [
  index('index.tsx'),
  route('/about', 'about.tsx'),
])

tanstackRouter({ target: 'react', virtualRouteConfig: routes })
```

And via the CLI:

```json
// tsr.config.json
{ "virtualRouteConfig": "./routes.ts" }
```

The plugin still comes before `@vitejs/plugin-react` (`TSR-FILE-03`).

| ID | Rule |
| --- | --- |
| `TSR-VIRTUAL-06` | `virtualRouteConfig` **MUST** be declared in one place: in the plugin option **or** in `tsr.config.json`, never both with diverging values. |

> **Not verified:** a literal JSON tree in `tsr.config.json` (objects with `"type": "root" | "index" | "route" | "layout"`, `"file"`, `"path"`, `"id"`, `"children"`). The source shows `virtualRouteConfig` pointing at a **file path**; the embedded-JSON variant was not confirmed. Prefer the `routes.ts` file.

---

## Antipatterns

**`layout` where a URL segment was wanted**

```ts
// WRONG: /dashboard and /settings sit at /, without the /app prefix
layout('app-layout.tsx', [
  route('/dashboard', 'dashboard.tsx'),
  route('/settings', 'settings.tsx'),
])

// RIGHT: route contributes the segment; the layout still wraps
route('/app', 'app-layout.tsx', [
  route('/dashboard', 'dashboard.tsx'),  // /app/dashboard
  route('/settings', 'settings.tsx'),    // /app/settings
])
```

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| Adopting virtual routes for aesthetic preference | Swaps a known convention for a file nobody else reads | Only when the convention cannot be adopted (`TSR-VIRTUAL-01`) |
| `route('/hello')` with no file and no children | Empty node: renders and contains nothing | Give it `file` or `children` (`TSR-VIRTUAL-02`) |
| `physical('features')` with a sibling virtual `/contact` and `features/contact.tsx` | Path collision on merge | Prefix one side (`TSR-VIRTUAL-04`) |
| `export const config = defineVirtualSubtreeConfig(...)` | The generator reads the `default` | `export default` (`TSR-VIRTUAL-05`) |
| `virtualRouteConfig` in the plugin **and** in `tsr.config.json` | Two sources of truth diverging between dev and CI | One place (`TSR-VIRTUAL-06`) |
| Migrating the whole app at once | Unnecessary: `__virtual.ts` converts per subtree | Incremental migration (§ 4) |
