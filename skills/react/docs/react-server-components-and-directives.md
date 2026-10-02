---
titulo: React - Server Components and Directives
Link: https://react.dev/reference/rsc/server-components
tags:
  - react
  - rsc
  - server-components
  - agent-context
source: "Official React documentation — RSC, 'use client', 'use server', cache, taint (experimental)"
verificado-em: 2026-08-14
---

# React — Server Components and Directives

> Server Components · Server Functions · `'use client'` · `'use server'` · `cache` · taint (experimental)
>
> The server/client boundary is the most expensive architectural decision to reverse later. This satellite exists so that it is made on purpose.

Entry: [React.js](react-js.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

> **Prerequisite:** RSC requires a framework with support (Next.js App Router, TanStack Start with server functions, or a configured bundler). In a pure Vite SPA, nothing in this note applies — the architectural equivalent is in.

---

## 1. Server Components

They render **ahead of time**, in a server environment separate from the client app — at build time or per request. They can:

- read the filesystem and the database directly;
- keep expensive dependencies out of the client bundle;
- fetch data without a waterfall, placing the fetch next to the render;
- use `async`/`await` **in render** — the only legitimate exception to "do not do I/O in render", because there is no concurrent re-render on the server side.

```tsx
// Server Component — no directive; it is the default in an RSC environment
async function Notes() {
  const notes = await db.notes.list()   // direct database access
  return (
    <ul>
      {notes.map((n) => (
        <Expandable key={n.id}><p>{n.text}</p></Expandable>
      ))}
    </ul>
  )
}
```

### What a Server Component **cannot** do

| Cannot | Why |
| --- | --- |
| `useState`, `useReducer`, `useEffect` | there is no client lifecycle |
| event handlers (`onClick`, `onChange`) | functions are not serializable to the client |
| browser APIs (`window`, `localStorage`) | they do not exist on the server |
| `useContext` | context belongs to the client |
| libraries that depend on client APIs | same reason |

What reaches the client is the **rendered result**, not the component.

| ID | Rule |
| --- | --- |
| `REACT-RSC-01` | A Server Component **NEVER** uses state, Effects, handlers or browser APIs. |
| `REACT-RSC-02` | Server data **MUST** be fetched in the Server Component, not handed to the client to fetch again. |

---

## 2. `'use client'`

```tsx
'use client'

import { useState } from 'react'
```

Marks the file **and all of its transitive dependencies** as client code.

### Placement rules (verified)

- **At the top of the file**, above any import. Comments before it are allowed.
- Single or double quotes — **never** backticks.

### The point almost everyone gets wrong

`'use client'` operates on the **module tree**, not on the render tree. A component without a directive can be a Server Component when imported from a server module and a Client Component when imported from a client module. The same source serves both uses.

And, decisively: **all the code in the marked subgraph goes to the client** — not just the components. A directive at the top of a module that imports a heavy library drags the library along.

### Push the boundary down

```tsx
// WRONG — the whole page and everything it imports become client
'use client'
export default function Page() {
  const [open, setOpen] = useState(false)
  return <><Header /><HugeList /><Button onClick={() => setOpen(true)} /></>
}

// RIGHT — only the interactive piece is client
// Page.tsx (Server Component)
export default async function Page() {
  const data = await load()
  return <><Header /><HugeList data={data} /><OpenButton /></>
}

// OpenButton.tsx
'use client'
export function OpenButton() {
  const [open, setOpen] = useState(false)
  return <button onClick={() => setOpen(true)}>Open</button>
}
```

| ID | Rule |
| --- | --- |
| `REACT-RSC-03` | `'use client'` **MUST** sit as low as possible in the tree — never at the top of the page for convenience. |

### Composition across the boundary

A Client Component **can** render Server Components — as long as they are received as `children` or props, not imported directly. The Server Component runs first and the rendered result is passed along.

```tsx
// Server Component composes: server content inside an interactive shell
<Expandable>
  <ServerContent />
</Expandable>
```

| ID | Rule |
| --- | --- |
| `REACT-RSC-04` | A Client Component **NEVER** imports a Server Component directly — it receives it as `children`/props. |

### Props must be serializable

| ✅ Crosses | ❌ Does not cross |
| --- | --- |
| primitives: string, number, bigint, boolean, undefined, null | plain functions |
| symbols registered with `Symbol.for()` | class instances |
| String, Array, Map, Set, TypedArray, ArrayBuffer | objects with a `null` prototype |
| `Date` | symbols not registered globally |
| plain objects with serializable properties | |
| Server Functions (`'use server'`) | |
| JSX elements | |
| Promises | |

Promises crossing is what enables the pattern of starting the fetch on the server and reading it on the client with `use` — see [React - Suspense and Async](react-suspense-and-async.md) § 3.

| ID | Rule |
| --- | --- |
| `REACT-RSC-05` | Props that cross the boundary **MUST** be serializable — a class instance or a plain function throws an exception. |

---

## 3. `'use server'`

Marks server functions callable from the client. It is **not** the opposite of `'use client'`: it does not mark components, it marks **functions**.

```tsx
'use server'

export async function createTopic(formData: FormData) {
  const session = await authenticate()                  // authenticate
  const data = topicSchema.parse({                      // validate
    title: formData.get('title'),
  })
  if (!canCreate(session, data)) throw new Error('No permission')  // authorize
  return db.topics.create({ ...data, authorId: session.userId })
}
```

**Every Server Function is a public HTTP endpoint.** The bundler generates a route for it; any client can call it with any payload. Client-side validation protects nothing.

| ID | Rule |
| --- | --- |
| `REACT-RSC-06` | Every Server Function **MUST** authenticate, validate and authorize in the function itself — it is a public endpoint. |
| `REACT-RSC-07` | Arguments and return value **MUST** be serializable. |

Developed in; schema validation in. Form integration in [React - Forms and Actions](react-forms-and-actions.md).

---

## 4. `cache`

```tsx
import { cache } from 'react'

const getUser = cache(async (id: string) => db.users.find(id))
```

It memoizes the result by arguments **within a single server render pass**. Two components that ask for the same user result in one query — it solves the duplication without needing to lift the fetch and prop-drill.

It is not a cross-request cache, nor a persistent cache. It only applies in Server Components.

| ID | Rule |
| --- | --- |
| `REACT-RSC-08` | `cache` is **NEVER** used as a cross-request cache — the scope is one render pass. |

---

## 5. Taint — **experimental**

Marking verified at the source:

> "This API is experimental and is not available in a stable version of React yet. […] Experimental versions of React may contain bugs. Don't use them in production. This API is only available inside React Server Components."

The exports are `experimental_taintObjectReference` and `experimental_taintUniqueValue`. They prevent a specific object or value from crossing to the client.

```tsx
import { experimental_taintObjectReference } from 'react'

experimental_taintObjectReference(
  'Do not pass ALL environment variables to the client.',
  process.env,
)
```

And the warning that defines how to treat them, quoted literally:

> "Do not rely on just tainting for security. Tainting an object doesn't prevent leaking of every possible derived value. For example, the clone of a tainted object will create a new untainted object. Using data from a tainted object (e.g. `{secret: taintedObj.secret}`) will create a new value or object that is not tainted. Tainting is a layer of protection; a secure app will have multiple layers of protection, well designed APIs, and isolation patterns."

| ID | Rule |
| --- | --- |
| `REACT-RSC-09` | Taint is **NEVER** the primary defense against leaks — it is an extra layer. The defense is not assembling the sensitive object in the first place. |
| `REACT-RSC-10` | Experimental APIs **NEVER** go into production. |

In practice: build an explicit DTO with the fields the client may see, instead of passing the whole entity and hoping.

```tsx
// Instead of <Profile user={user} /> with the password hash and tokens inside:
const profile = { id: user.id, name: user.name, avatarUrl: user.avatarUrl }
<Profile profile={profile} />
```

---

## 6. Review checklist

- [ ] Is `'use client'` at the lowest possible point? → `REACT-RSC-03`
- [ ] Is the directive before all imports, with normal quotes?
- [ ] Does a Client Component import a Server Component directly? → `REACT-RSC-04`
- [ ] Is any crossing prop a plain function or a class instance? → `REACT-RSC-05`
- [ ] Does every Server Function authenticate, validate and authorize? → `REACT-RSC-06`
- [ ] Does any whole entity cross the boundary instead of a DTO? → `REACT-RSC-09`
- [ ] `useState`/`useEffect` in a component without `'use client'`? → `REACT-RSC-01`

---

## Related

- [React.js](react-js.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Forms and Actions](react-forms-and-actions.md) · [React - Suspense and Async](react-suspense-and-async.md) · [React - Rendering and Entrypoints](react-rendering-and-entrypoints.md)

## Sources consulted

Verified on 2026-08-14:

- [Server Components](https://react.dev/reference/rsc/server-components) · [Directives](https://react.dev/reference/rsc/directives)
- ['use client'](https://react.dev/reference/rsc/use-client) — placement rules and serialization table
- ['use server'](https://react.dev/reference/rsc/use-server) · [cache](https://react.dev/reference/react/cache)
- [experimental_taintObjectReference](https://react.dev/reference/react/experimental_taintObjectReference) — warnings quoted literally
