---
titulo: React - Performance and Concurrency
Link: https://react.dev/reference/react/memo
tags:
  - react
  - performance
  - concurrency
  - agent-context
source: "Official React documentation — memo, useMemo, useCallback, useTransition, useDeferredValue, Activity, Profiler, React Compiler"
verificado-em: 2026-08-14
---

# React — Performance and Concurrency

> `memo` · `useMemo` · `useCallback` · `useTransition` · `startTransition` · `useDeferredValue` · `<Activity>` · `<Profiler>` · React Compiler
>
> Two distinct families that are often confused: **memoization** avoids repeated work; **concurrency** reorders work by priority. They solve different problems.

Entry: [React.js](react-js.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. The rule that comes before all others

Optimization without measurement is noise: it adds comparison cost, reading complexity and bug surface, typically with no gain.

| ID | Rule |
| --- | --- |
| `REACT-PERF-01` | `memo`, `useMemo` and `useCallback` **MUST** have a measured justification — Profiler, a DevTools recording or reproducible slowness. |

What counts as a measurement — baseline first, render count as the gate, timing as the report, the results file — is [React - Performance Measurement](react-performance-measurement.md) (`REACT-PERF-11..19`).

**Exception to `REACT-PERF-01`:** stabilizing a Context's `value` (`REACT-STATE-07`) does not require measurement. There `useMemo` is not an optimization — it is what keeps every consumer from re-rendering on every render of the provider, a structural and predictable cost, not a hypothetical one. The measurement requirement applies to **speculative** memoization.
| `REACT-PERF-02` | Before memoizing by hand, you **MUST** check whether the React Compiler is active in the project (§ 7). |

Correct order of attack, from cheapest to most expensive:

1. Don't create unnecessary state →
2. Put the state in the right place → [React - Patterns](react-patterns.md) § 2
3. Composition to reduce the reach of the re-render
4. **Reduce the rendered volume** (§ 5) — when the bottleneck is the number of nodes
5. Concurrency (§ 4) — changes the *perception*, not the cost
6. Memoization (§ 3) — only with measurement

Step 3 is the most underrated: moving state into a smaller component, or passing children as a prop, eliminates re-renders without any memoization.

### Diagnosis: computation or volume?

Before choosing the tool, find out where the time is spent — these are different problems with solutions that do not substitute for each other.

| Symptom in the Profiler / DevTools | Bottleneck | Go to |
| --- | --- | --- |
| Few components, high `actualDuration` in one of them | **computation** | `useMemo`, `useDeferredValue` |
| Thousands of components, each fast, high total | **volume** | § 5 — virtualization/pagination |
| Many children re-rendering without their props changing | **unnecessary re-render** | steps 2-3, then `memo` |
| Fast render, but the browser freezes afterwards | **DOM/paint** | § 5 — fewer nodes |

The mistake this table prevents: treating volume with memoization. `memo` on 5000 rows still mounts 5000 components on the first render — it only avoids re-renders, never the initial cost.

---

## 2. `<Profiler>`

Measure before optimizing. `<Profiler>` programmatically measures a subtree.

```tsx
<Profiler id="List" onRender={(id, phase, actualDuration) => {
  console.log(id, phase, actualDuration)
}}>
  <List items={items} />
</Profiler>
```

`phase` is `"mount"`, `"update"` or `"nested-update"`; `actualDuration` is the subtree's render time. It adds overhead — it is an investigation tool, not permanent instrumentation. For interactive use, the React DevTools profiler is usually enough. For a repeatable before/after, `actualDuration` is reported next to a render count, never used as the gate (`REACT-PERF-11`, [React - Performance Measurement](react-performance-measurement.md)).

---

## 3. Memoization

### `memo`

```tsx
const Row = memo(function Row({ item }: { item: Item }) { /* ... */ })
```

Skips the re-render when the props are **shallowly equal** to the previous ones. It only works if the props are stable — hence the dependency on `useCallback`/`useMemo` in the parent.

```tsx
// USELESS memo: onSelect is new on every render of the parent
<Row item={item} onSelect={() => select(item.id)} />

// effective memo
const onSelect = useCallback((id: string) => select(id), [select])
<Row item={item} onSelect={onSelect} />
```

**One unstable prop cancels the entire `memo`.** That is why memoizing a component without stabilizing its props is usually pure cost.

### `useMemo` × `useCallback`

```tsx
const value  = useMemo(() => computeExpensive(a, b), [a, b])   // caches the RESULT
const handler = useCallback((x: string) => doSomething(x, a), [a]) // caches the FUNCTION
```

`useCallback(fn, deps)` is equivalent to `useMemo(() => fn, deps)`.

Legitimate cases:

| Case | Hook |
| --- | --- |
| Provably expensive computation | `useMemo` |
| Value that is a dependency of another Hook | `useMemo` |
| Context `value` with costly consumers | `useMemo` |
| Function passed to a `memo` child | `useCallback` |
| Function that is a dependency of an Effect | `useCallback` |

Outside of that, it is noise. `useMemo` does **not** guarantee the value will be preserved — React may discard the cache.

| ID | Rule |
| --- | --- |
| `REACT-PERF-03` | `memo` without stabilizing the props is **NEVER** applied — it has no effect and adds cost. |
| `REACT-PERF-04` | The computation inside `useMemo`/`useCallback` **MUST** be pure (`REACT-PURE-01`). |
| `REACT-PERF-05` | `useMemo` is **NEVER** used to guarantee semantically required identity — the cache may be discarded. If identity is mandatory, use `useRef`. |

---

## 4. Concurrency

Concurrency does not make the work faster — it keeps the UI **responsive** during the work, letting urgent updates (typing, clicking) interrupt non-urgent ones.

### `useTransition`

```tsx
const [isPending, startTransition] = useTransition()

function selectTab(tab: Tab) {
  startTransition(() => setTab(tab))   // non-urgent: may be interrupted
}

return (
  <>
    <TabBar onSelect={selectTab} />
    <div style={{ opacity: isPending ? 0.6 : 1 }}>
      <TabPanel tab={tab} />
    </div>
  </>
)
```

The input stays responsive while the heavy panel renders. `isPending` lets you indicate the wait without hiding the current UI.

### `startTransition`

The same marking, without the pending flag, and callable **outside** a component — useful in stores and utilities.

The function passed to `startTransition` **can be `async`** — the `await`s inside it are part of the Transition. What is not automatic is what comes **after** the `await`:

```tsx
// WRONG — the setState after the await is not treated as a Transition
startTransition(async () => {
  await save()
  setPage('/done')
})

// RIGHT
startTransition(async () => {
  await save()
  startTransition(() => setPage('/done'))
})
```

The documentation itself calls this a known limitation to be fixed. Other caveats that change decisions: a Transition **is interrupted** by later updates, and **cannot be used to control text inputs**.

| ID | Rule |
| --- | --- |
| `REACT-PERF-06` | Every `setState` after an `await` inside `startTransition` **MUST** be wrapped in a new `startTransition`. |
| `REACT-PERF-10` | A Transition is **NEVER** used to control the value of a text input. |

### `useDeferredValue`

```tsx
const deferredQuery = useDeferredValue(query)
const results = useMemo(() => search(deferredQuery), [deferredQuery])
```

When you **don't control** the `setState` — you only receive the value. React first renders with the old value and then with the new one, in the background.

| Do you control the `setState`? | Use |
| --- | --- |
| Yes, and you want a pending flag | `useTransition` |
| Yes, but you are outside a component | `startTransition` |
| No — you only have the value | `useDeferredValue` |

---

## 5. Reduce the rendered volume

When the bottleneck is the **number of nodes**, no API in this note solves it — neither memoization nor concurrency. `<Suspense>`, `useTransition` and `useDeferredValue` improve the *perception*; the browser still has to build and paint every node.

The only way out is to render less.

| Strategy | When | Cost |
| --- | --- | --- |
| **Virtualization** (windowing) | long, scrollable list/table, all items of the same type | row height, accessibility, Ctrl+F stop working for free |
| **Pagination** | the user doesn't need to scroll through everything | extra navigation |
| **Server-side search/filter** | the dataset is large at the source | round-trip |
| **Collapse by default** | trees, groupings | one more click |

Virtualization renders only the visible rows (plus a margin), keeping the number of nodes constant regardless of dataset size. It is the default answer for lists in the thousands.

> **Bridge:** React does not ship virtualization built in — it is a library. In the TanStack ecosystem, TanStack Virtual covers lists and grids, and pairs with TanStack Table. Check the version and the API in the library's documentation; this note did not verify it.

**Order of choice:** if the user doesn't need to see everything, paginate — it is simpler and preserves accessibility. Virtualize when continuous scrolling is a requirement.

| ID | Rule |
| --- | --- |
| `REACT-PERF-09` | A list with thousands of items is **NEVER** treated with memoization or concurrency alone — the bottleneck is volume; reduce the rendered nodes. |

---

## 6. `<Activity>`

An alternative to conditionally mounting/unmounting, **preserving state**.

```tsx
<Activity mode={isShowingSidebar ? 'visible' : 'hidden'}>
  <Sidebar />
</Activity>
```

Behavior verified at the source:

| `mode` | Effect |
| --- | --- |
| `'visible'` | renders normally; Effects active |
| `'hidden'` | hides with `display: none`; **state preserved**; **Effects cleaned up**; children still re-render at low priority; DOM preserved |

The combination that matters: **state survives, Effects don't**. A subscription is closed on hide and recreated on show, while the scroll position, the typed text and the selection remain.

Caveats quoted from the source:

> "A *hidden* Activity that just renders text will not render anything rather than rendering hidden text, because there's no corresponding DOM element to apply visibility changes to."

> "Only data read from a source that activates a Suspense boundary, such as a Promise read with `use`, is fetched during pre-rendering. Activity does not detect data fetched inside an Effect."

The second one is the trap: pre-rendering hidden content only works with data read through Suspense — data fetched in an Effect is not preloaded. One more argument against fetching in an Effect (`REACT-EFFECT-06`).

| ID | Rule |
| --- | --- |
| `REACT-PERF-07` | `<Activity mode="hidden">` is **NEVER** used assuming Effects are active — they are cleaned up. |

---

## 7. React Compiler

The compiler automatically memoizes components and Hooks, making most hand-written `memo`/`useMemo`/`useCallback` unnecessary.

**Its working condition is the contract of this entire doc:** the compiler can only optimize code that follows the [Rules of React](https://react.dev/reference/rules). Impure code is skipped or breaks the build, depending on `panicThreshold`. See [React - Rules of React](react-rules-of-react.md).

Main configuration options, per the reference:

| Option | Purpose |
| --- | --- |
| `compilationMode` | what to compile: everything, only annotated, or automatic detection |
| `target` | target React version (17, 18 or 19) |
| `panicThreshold` | fail the build or skip problematic components |
| `logger` | custom logging of compilation events |
| `gating` | runtime feature flag for gradual rollout |

Per-function directives:

```tsx
function Heavy() {
  'use memo'      // opts in to compilation — useful with compilationMode: 'annotation'
  // ...
}

function Legacy() {
  'use no memo'   // opts OUT of compilation — debugging or incompatible code
  // ...
}
```

**Status:** React Compiler reached **stable 1.0 on 2025-10-07** ([announcement](https://react.dev/blog/2025/10/07/react-compiler-1)). It is compatible with React 17 onward, and Vite, Next.js and Expo have integrations. In other words: `REACT-PERF-02` is not hypothetical — checking whether the compiler is active is a real step before memoizing by hand.

| ID | Rule |
| --- | --- |
| `REACT-PERF-08` | `'use no memo'` **MUST** be temporary and commented with the reason; it is a debt marker, not a solution. |

---

## 8. Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| `useCallback`/`useMemo` on everything | comparison cost with no gain | measure first · `REACT-PERF-01` |
| `memo` with an inline callback prop | the comparison always fails | stabilize props · `REACT-PERF-03` |
| `useMemo` for a side effect | violates purity | Effect or handler · `REACT-PERF-04` |
| `useTransition` to hide network slowness | it is not a render problem | cache/Suspense |
| `useDeferredValue` without `memo` in the consumer | the expensive work runs anyway | memoize the derived computation |
| Manual memoization with the Compiler active | redundant and noisy | remove · `REACT-PERF-02` |
| `<Activity>` expecting live Effects | Effects are cleaned up on hide | `REACT-PERF-07` |

---

## Related

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Suspense and Async](react-suspense-and-async.md) — transitions and Suspense combine
- [React - Performance Measurement](react-performance-measurement.md) — how to measure before and after (`REACT-PERF-11..19`)

## Sources consulted

Verified on 2026-08-14:

- [memo](https://react.dev/reference/react/memo) · [useMemo](https://react.dev/reference/react/useMemo) · [useCallback](https://react.dev/reference/react/useCallback)
- [useTransition](https://react.dev/reference/react/useTransition) · [startTransition](https://react.dev/reference/react/startTransition) · [useDeferredValue](https://react.dev/reference/react/useDeferredValue)
- [Activity](https://react.dev/reference/react/Activity) — caveats quoted literally
- [Profiler](https://react.dev/reference/react/Profiler)
- [React Compiler — Configuration](https://react.dev/reference/react-compiler/configuration) · [Directives](https://react.dev/reference/react-compiler/directives)
