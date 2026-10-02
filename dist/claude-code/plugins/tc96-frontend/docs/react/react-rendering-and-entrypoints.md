---
titulo: React - Rendering and Entrypoints
Link: https://react.dev/reference/react-dom/client
tags:
  - react
  - rendering
  - ssr
  - agent-context
source: "Official React documentation — react-dom/client, react-dom/server, react-dom/static, StrictMode, preloading"
verificado-em: 2026-08-14
---

# React — Rendering and Entrypoints

> `createRoot` · `hydrateRoot` · `react-dom/server` and `/static` APIs · `<StrictMode>` · preloading · `act`
>
> Where the React tree meets the DOM or the HTML. Few lines of code, but choices that define hydration, streaming and what breaks in production.

Entry: [React.js](react-js.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. Client: `createRoot` × `hydrateRoot`

```tsx
import { createRoot } from 'react-dom/client'

const root = createRoot(document.getElementById('root')!)
root.render(<App />)
```

```tsx
import { hydrateRoot } from 'react-dom/client'

hydrateRoot(document.getElementById('root')!, <App />)
```

| | `createRoot` | `hydrateRoot` |
| --- | --- | --- |
| Initial container state | empty | already contains HTML from the server |
| What it does | creates the DOM from scratch | attaches listeners to the existing DOM |
| Use in | pure SPA | app with SSR/SSG |

`root.unmount()` unmounts the tree. `ReactDOM.render` and `unmountComponentAtNode` were removed — they no longer exist.

| ID | Rule |
| --- | --- |
| `REACT-DOM-01` | HTML coming from the server **MUST** be hydrated with `hydrateRoot`, never with `createRoot` — the latter would discard the HTML and lose the benefit of SSR. |

### Hydration error

It happens when the tree rendered on the client does not match the server HTML. Typical causes:

| Cause | Fix |
| --- | --- |
| `Date.now()`, `Math.random()`, `new Date()` in render | `REACT-PURE-01` — move into state or pass it from the server |
| `typeof window !== 'undefined'` branching the render | render the same and adjust in an Effect |
| `localStorage` read in render | read it in `useEffect` after mount |
| Invalid HTML (`<div>` inside `<p>`) | fix the markup |
| Locale/timezone-dependent formatting | pin locale/timezone explicitly |

The pattern for genuinely client-only content:

```tsx
const [mounted, setMounted] = useState(false)
useEffect(() => setMounted(true), [])
if (!mounted) return <Placeholder />   // same as what the server rendered
return <ClientContent />
```

`suppressHydrationWarning` silences the warning on a specific node (a server-generated timestamp, for example). It **does not fix** the mismatch — it only mutes the alert.

| ID | Rule |
| --- | --- |
| `REACT-DOM-02` | A hydration error is **NEVER** resolved with `suppressHydrationWarning` without understanding the cause. |
| `REACT-DOM-03` | Render **NEVER** branches on `typeof window` — render the same on both sides and adjust in an Effect. |

---

## 2. Server: `react-dom/server`

Inventory and runtimes per the official reference:

| API | Runtime | Note |
| --- | --- | --- |
| `renderToPipeableStream` | Node.js Streams | **recommended on Node** |
| `resumeToPipeableStream` | Node.js Streams | resumes a `prerenderToNodeStream` |
| `renderToReadableStream` | Web Streams | Deno, edge, browser |
| `resume` | Web Streams | resumes a `prerender` |
| `renderToString` | no streaming | **legacy**, limited functionality |
| `renderToStaticMarkup` | no streaming | **legacy**, non-interactive HTML |

Two notes verified at the source:

- the **Web Streams APIs exist on Node for compatibility, but are not recommended there** because of worse performance — on Node, use the Node Streams ones;
- `renderToString` and `renderToStaticMarkup` are explicitly marked as legacy, with limited functionality compared to the streaming ones, and intended only for environments without streaming.

| ID | Rule |
| --- | --- |
| `REACT-DOM-04` | On Node, SSR **MUST** use `renderToPipeableStream`, not the Web Streams APIs. |
| `REACT-DOM-05` | `renderToString` **NEVER** goes into new code when streaming is available — it does not support the benefits of Suspense in streaming. |

### `react-dom/static`

`prerender` (Web Streams) and `prerenderToNodeStream` (Node Streams) generate static HTML by waiting for all data to resolve — for SSG. The `resume`/`resumeToPipeableStream` pair allows resuming later with the dynamic content.

> In practice, the framework is what calls these APIs. They matter for **understanding** what Next.js or TanStack Start does — not for writing by hand.

---

## 3. `<StrictMode>`

```tsx
createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
```

In development only, React:

1. **renders components twice** — reveals render impurity (`REACT-PURE-01`);
2. **runs Effects twice** (setup → cleanup → setup) — reveals missing or incomplete cleanup (`REACT-EFFECT-01`);
3. **runs reducers and state initializers twice** — reveals impurity in them (`REACT-STATE-05`);
4. **warns about deprecated APIs**.

None of this happens in production and none of it is a React bug. **Every double run that breaks something is your bug being shown.** The answer is never to remove `<StrictMode>`.

| ID | Rule |
| --- | --- |
| `REACT-DOM-06` | `<StrictMode>` is **NEVER** removed to "fix" the double run — it is the purity bug being revealed. |

Verified note: the `useActionState` action is **not** invoked twice in StrictMode, precisely because it may have side effects — see [React - Forms and Actions](react-forms-and-actions.md).

---

## 4. Resource preloading

`react-dom` APIs to get ahead on network work. Hints, not guarantees — the browser decides.

| API | Does |
| --- | --- |
| `prefetchDNS(href)` | resolves a domain's DNS |
| `preconnect(href)` | opens a connection to a server |
| `preload(href, options)` | downloads a stylesheet, font, image or script |
| `preloadModule(href, options)` | downloads an ESM module |
| `preinit(href, options)` | downloads **and evaluates** a script, or downloads and inserts a stylesheet |
| `preinitModule(href, options)` | downloads and evaluates an ESM module |

```tsx
import { preload, preconnect } from 'react-dom'

function Gallery({ nextUrl }: { nextUrl: string }) {
  preconnect('https://cdn.example.com')
  preload(nextUrl, { as: 'image' })
  // ...
}
```

Increasing cost scale: `prefetchDNS` < `preconnect` < `preload` < `preinit`. Preloading everything competes for bandwidth with what is critical right now and makes the result worse.

| ID | Rule |
| --- | --- |
| `REACT-DOM-07` | Preloading **MUST** be applied to a few resources with a high probability of use — mass preloading degrades. |

---

## 5. `act` in tests

```tsx
import { act } from 'react'

await act(async () => {
  root.render(<App />)
})
```

It ensures renders, Effects and scheduled updates finish before the assertions. Testing Library already wraps its APIs in `act` — calling it manually usually indicates the test observes implementation instead of behavior..

> `act` comes from `react`, not from `react-dom/test-utils`.

---

## 6. Review checklist

- [ ] SSR hydrating with `hydrateRoot`, not `createRoot`? → `REACT-DOM-01`
- [ ] Any `Date.now()`, `Math.random()` or `localStorage` in render? → `REACT-PURE-01` / `REACT-PURE-02` (root cause of the hydration mismatch)
- [ ] `typeof window` branching the render? → `REACT-DOM-03`
- [ ] SSR on Node using the Node Streams APIs? → `REACT-DOM-04`
- [ ] `renderToString` in new code? → `REACT-DOM-05`
- [ ] `<StrictMode>` present and not removed to silence warnings? → `REACT-DOM-06`
- [ ] Preloading restricted to what is likely? → `REACT-DOM-07`

---

## Related

- [React.js](react-js.md) · [React - Rules of React](react-rules-of-react.md) · [React - Patterns](react-patterns.md)
- [React - Server Components and Directives](react-server-components-and-directives.md) · [React - Suspense and Async](react-suspense-and-async.md) · [React - Effects and Synchronization](react-effects-and-synchronization.md)
- `Next.js` · `TanStack Router`

## Sources consulted

Verified on 2026-08-14:

- [react-dom/client](https://react.dev/reference/react-dom/client) — `createRoot`, `hydrateRoot`
- [react-dom/server](https://react.dev/reference/react-dom/server) — inventory and runtime recommendations
- [react-dom/static](https://react.dev/reference/react-dom/static)
- [StrictMode](https://react.dev/reference/react/StrictMode) · [act](https://react.dev/reference/react/act)
- [react-dom APIs](https://react.dev/reference/react-dom) — preloading family
