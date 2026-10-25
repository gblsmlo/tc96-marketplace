---
title: TanStack Router - Route Matching
link: https://tanstack.com/router/latest/docs/framework/react/routing/route-matching
tags:
  - tanstack-router
  - routing
  - agent-context
source: "Official documentation: https://tanstack.com/router/latest/docs/framework/react/"
verified-at: 2026-08-14
---

# TanStack Router - Route Matching

## Contents

- [1. Concept: declaration order does not exist](#1-concept-declaration-order-does-not-exist)
- [2. Sorting in practice](#2-sorting-in-practice)
- [3. The four cases from the source](#3-the-four-cases-from-the-source)
- [4. Precedence table](#4-precedence-table)
- [Antipatterns](#antipatterns)

> **Which route wins** when more than one could match: the specificity precedence order, the automatic tree sorting and the four cases the docs walk through.
>
> **Does not cover:** what each route type is ([TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) · tree topology ([TanStack Router - Route Trees](tanstack-router-route-trees.md)) · file-name conventions ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · what happens *after* the match: `beforeLoad`, `loader`, `<Outlet />` ([TanStack Router - Data Loading](tanstack-router-data-loading.md)).

Entry: [TanStack Router](tanstack-router.md) · Normative basis: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Concept: declaration order does not exist

In list-based routers (classic `react-router`, Express) declaration order is the semantics: `/blog/new` after `/blog/:postId` never matches. TanStack Router **re-sorts the tree by specificity** before matching; written or file-system order is irrelevant. A match yields a **chain** of routes from root to leaf, not one route.

Precedence order, from the source:

1. **Index Route**
2. **Static Routes** (most specific → least specific)
3. **Dynamic Routes** (longest → shortest)
4. **Splat / Wildcard Routes**

Plus: *"Routes with optional parameters are ranked lower in priority than exact matches"*, so `{-$param}` loses to the matching static segment.

| ID | Rule |
| --- | --- |
| `TSR-MATCH-01` | Route declaration order is **NEVER** used as a precedence mechanism: the router re-sorts by specificity. Code that depends on order is wrong. |

---

## 2. Sorting in practice

```
As written:           As the router sorts it:
Root                  Root
  - blog                - /
    - $postId           - about/us
    - /                 - about
    - new               - blog
  - /                     - /
  - *                     - new
  - about                 - $postId
  - about/us            - *
```

- `/` rises to the top: index has the highest precedence;
- `about/us` comes before `about`: among statics, the most specific wins;
- inside `blog`: `/` → `new` → `$postId` (index, then static before dynamic), splat after everything.

So `/blog/new` works with no special care next to `/blog/$postId`.

| ID | Rule |
| --- | --- |
| `TSR-MATCH-02` | A static route sibling of a dynamic one **NEVER** needs a workaround (artificial prefix, manual order, guard inside the component): the static one already wins by specificity. |

---

## 3. The four cases from the source

- **`/blog`**: root index fails (URL is not `/`), statics `about/us` and `about` fail, the router enters `blog` and matches its **index route**.
- **`/blog/my-post`**: same descent; blog's index fails, `new` fails, `$postId` matches with `postId = "my-post"`.
- **`/`**: matches the root index immediately.
- **`/not-a-route`**: everything fails and the **splat** catches it as fallback.

The splat is **the last line of defence**, not "a route that catches anything". Using it to capture URLs that could have their own routes means routing by hand in the component and losing typed params, per-route loader and code splitting.

| ID | Rule |
| --- | --- |
| `TSR-MATCH-03` | A splat route is **NEVER** used to route by hand, inside the component, a set of URLs that could have their own routes. It is a fallback, not a dispatcher. |
| `TSR-MATCH-04` | Code **NEVER** counts on `{-$param}` beating a static segment: an optional parameter ranks below an exact match. |

---

## 4. Precedence table

| Type | Example | Priority | Internal tie-break |
| --- | --- | --- | --- |
| Index | `/` | 1st | none |
| Static | `/about/us`, `/blog/new` | 2nd | most specific first |
| Dynamic | `/blog/$postId` | 3rd | longest first |
| Optional param | `/posts/{-$category}` | below exact match | none |
| Splat | `/files/$` | last | none |

> **Not verified:** the exact position of `{-$param}` *relative to* required dynamic routes. The source only says optional params rank below exact matches. If the design depends on it, test it.

URLs that are exact paths of routes with children still need an index route (`TSR-ROUTE-04`).

---

## Antipatterns

**Splat as dispatcher**

```tsx
// WRONG: one match, one loader, untyped params, no code splitting
export const Route = createFileRoute('/admin/$')({
  component: () => {
    const { _splat } = Route.useParams()
    if (_splat === 'users') return <Users />
    if (_splat?.startsWith('reports/')) return <Report />
    return <NotFound />
  },
})

// RIGHT: each URL is a route with its own loader and types
// routes/admin.users.tsx
// routes/admin.reports.$reportId.tsx
// routes/admin.$.tsx        ← only the real fallback
```

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| Reordering, renaming or prefixing files (`blog._new.tsx`) to force precedence | Declaration order is not read; `_` does something else | Trust specificity: `blog.new.tsx` (`TSR-MATCH-01`) |
| `if` inside the dynamic route's component for a special value (`postId === 'new'`) | A static sibling route would solve it | Create `blog.new.tsx` (`TSR-MATCH-02`) |
| Splat at the root covering a whole section | One loader, no typed params, no code splitting | Explicit routes + splat only as 404 (`TSR-MATCH-03`) |
| `{-$category}` expected to beat `/posts/featured` | Optional ranks below exact match | Accept the precedence or do not create the static (`TSR-MATCH-04`) |
