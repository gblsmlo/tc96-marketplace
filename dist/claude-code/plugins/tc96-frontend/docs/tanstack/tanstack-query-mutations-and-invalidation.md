---
title: TanStack Query - Mutations and Invalidation
link: https://tanstack.com/query/latest/docs/framework/react/guides/mutations
tags:
  - tanstack-query
  - mutations
  - agent-context
source: "Official documentation: https://tanstack.com/query/latest/docs/framework/react"
verified-at: 2026-08-14
---

# TanStack Query - Mutations and Invalidation

## Contents

- [1. Concept: reads and writes are not symmetric](#1-concept-reads-and-writes-are-not-symmetric)
- [2. useMutation](#2-usemutation)
- [3. invalidateQueries](#3-invalidatequeries)
- [4. setQueryData](#4-setquerydata)
- [5. Optimistic update with snapshot and rollback](#5-optimistic-update-with-snapshot-and-rollback)
- [Version notes](#version-notes)
- [Antipatterns](#antipatterns)

> `useMutation` · lifecycle callbacks and their current signatures · `mutate` × `mutateAsync` · `invalidateQueries` and `refetchType` · `setQueryData` · optimistic update with snapshot and rollback · `useMutationState` · scopes and serialization.
>
> **Does not cover:** key identity and `queryFn` ([TanStack Query - Fundamentals](tanstack-query-fundamentals.md)) · `staleTime` and freshness policy ([TanStack Query - Cache and Freshness](tanstack-query-cache-and-freshness.md)) · React's `useOptimistic` (skill `react-developer`).

Entry: [TanStack Query](tanstack-query.md) · Normative base: [TanStack Query - Fundamentals](tanstack-query-fundamentals.md)

---

## 1. Concept: reads and writes are not symmetric

A query is idempotent, cacheable and may run on its own at any time. A mutation has a server effect, runs once on explicit request, and **invalidates knowledge the cache does not know it lost**. It ends when the cache reflects the server again, not at the `200`.

| Strategy | Cost | When |
| --- | --- | --- |
| `invalidateQueries` | one extra request | default; the server may have derived things you do not see |
| `setQueryData` with the response | zero requests | the mutation response **is** the full, updated resource |
| Optimistic update | zero perceived requests, more code and tests | latency is felt in the interaction (toggle, like, drag) |

---

## 2. `useMutation`

States: `idle`, `pending`, `error`, `success` (mirrored by `isIdle`, `isPending`, `isError`, `isSuccess`). Variables arrive *"by calling the mutate function with a single variable or object"*: one argument.

```tsx
const queryClient = useQueryClient()

const createTodo = useMutation({
  mutationFn: (input: NewTodo) => api.post('/todos', input),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})

createTodo.mutate({ title: 'Do laundry' })
```

A POST through `useQuery` runs on mount, window focus, reconnect and automatic retry: four paths that execute the write with nobody asking.

| ID | Rule |
| --- | --- |
| `TSQ-MUT-01` | A server write **MUST** use `useMutation`; `useQuery` **NEVER** fires POST/PUT/PATCH/DELETE. |

### Callback signatures

The most outdated point in material circulating about the library. Current signatures:

```tsx
useMutation({
  mutationFn: updateTodo,
  onMutate: (variables, context) => {
    return { id: 1 }                       // becomes `onMutateResult`
  },
  onError: (error, variables, onMutateResult, context) => {},
  onSuccess: (data, variables, onMutateResult, context) => {},
  onSettled: (data, error, variables, onMutateResult, context) => {},
})
```

- The return of `onMutate` is still the **third positional argument**, now named `onMutateResult` (formerly `context`).
- A new **last argument `context`** is an object with `client` (the `QueryClient`), so callbacks can touch the cache without `useQueryClient`.

The change is **additive**, so the breakage runs the opposite way from what one expects:

- Old form `onError: (err, vars, context) => context.previousTodos` **still works**: the third argument is the `onMutate` return; only the name misleads.
- New form `context.client` on a version without the fourth argument **throws**: `context` is `undefined`.

Since `TSQ-BASE-10` pins the exact patch, adopting `context.client` in a project locked to an earlier v5 release is the common failure. Name the third argument `onMutateResult`.

> **Verified present on 5.104.5;** the first v5 release with `onMutateResult` and `context.client` is not pinned here. Before using `context.client`, check the signature in the installed types (`node_modules/@tanstack/react-query`). If absent, use `useQueryClient()` in the component scope, which works on any version.

### Promise returned from a callback

A Promise returned from any callback is awaited before the next callback runs. This keeps `isPending` true until the refetch finishes. Without `return`, the button goes back to "Save" while the list still shows the old state, and the user clicks again.

```tsx
// WRONG: the mutation "ends" before the list updates
onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['todos'] }) }

// RIGHT
onSuccess: () => queryClient.invalidateQueries({ queryKey: ['todos'] })
```

### Per-call callbacks

`onSuccess`/`onError`/`onSettled` can also go to `mutate` itself, where they fire *"only once and only if the component is still mounted"*; `useMutation` callbacks always run. Cache sync, invalidation and rollback belong to `useMutation`. Navigating, closing a modal and toasts belong to `mutate`.

```tsx
const save = useMutation({
  mutationFn: updateTodo,
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})

save.mutate(values, {
  onSuccess: () => { closeModal(); toast('Saved') },
})
```

### `mutate` × `mutateAsync`

`mutateAsync` returns a Promise that resolves on success or throws on error. `mutate` returns nothing and does not throw; the error lives in `mutation.error`. `await mutateAsync(...)` without `try/catch` is an unhandled rejection even with `onError` defined: the callback handles the effect, not the Promise. Use `mutateAsync` only to chain (two sequential writes, composing with another Promise).

### Retry and scope

Mutations are not retried on error by default, the opposite of queries: retrying a non-idempotent write duplicates the effect.

Mutations run in parallel by default; *"All mutations with the same `scope.id` will run in serial"*. Two parallel writes on the same resource arrive at the server in undefined order and, with an optimistic update, nest snapshots that restore the wrong state on rollback. `scope: { id }` is a direct `useMutation` option.

| ID | Rule |
| --- | --- |
| `TSQ-MUT-02` | A callback that triggers invalidation or refetch **MUST** return the Promise, so the mutation stays `pending` until the refetch finishes. |
| `TSQ-MUT-03` | A callback passed to `mutate(vars, {...})` **NEVER** carries cache sync, invalidation or rollback: it does not run if the component unmounts. |
| `TSQ-MUT-04` | `mutateAsync` **MUST** have `catch` or `try/catch`: it throws, unlike `mutate`. |
| `TSQ-MUT-05` | `retry` on a mutation is **NEVER** enabled without guaranteed server-side idempotency. |
| `TSQ-MUT-06` | Mutations writing the same cache entry **MUST** declare `scope: { id }` to run serially. |

---

## 3. `invalidateQueries`

Two effects: every matching query *"is marked as stale"*, overriding any `staleTime`; a match *"currently being rendered via `useQuery`"* is also refetched in the background. Marking hits **every** match; refetch hits, by default, only active ones.

### Prefix matching

`{ queryKey: ['todos'] }` matches `['todos']`, `['todos', 'list', { page: 1 }]`, `['todos', 'detail', 42]`. This makes the key hierarchy (`TSQ-BASE-02`) an architecture decision: the key defines what one write can invalidate at once.

```tsx
queryClient.invalidateQueries({ queryKey: ['todos'] })                      // lists and details
queryClient.invalidateQueries({ queryKey: ['todos', 'list'] })              // lists only
queryClient.invalidateQueries({ queryKey: ['todos', 'list'], exact: true }) // exact entry
queryClient.invalidateQueries({
  predicate: (query) => query.queryKey[0] === 'todos' && someCriterion(query),
})
```

Filters: `queryKey`, `exact`, `type: 'active' | 'inactive' | 'all'`, `stale`, `fetchStatus`, `predicate`. `predicate` receives each `Query` instance (not the key), so it can read `query.state`.

### `refetchType`

Default **`'active'`**:

| Value | Behaviour |
| --- | --- |
| `'active'` (default) | only matches actively rendered via `useQuery` and friends are refetched in the background |
| `'inactive'` | only matches **not** being rendered |
| `'all'` | all matches |
| `'none'` | nothing is refetched; matches are only marked invalid |

The default is almost always right: refetch what is on screen, mark the rest for when it mounts. `'all'` on a broad prefix in an app with many visited screens fires a burst of requests for data nobody is looking at. Also accepts `cancelRefetch` (default `true`) and `throwOnError`.

### Invalidating without a filter

`queryClient.invalidateQueries()` marks **the whole cache** stale: it hides "I forgot to invalidate something" at the cost of refetching every active query on every write. If you do not know what a mutation affects, the key hierarchy is the problem.

| ID | Rule |
| --- | --- |
| `TSQ-MUT-07` | `invalidateQueries()` without a filter **NEVER** enters new code; invalidate by the most specific prefix covering the write's effect. |

---

## 4. `setQueryData`

When the mutation returns the full updated resource, writing it directly skips the round trip.

> "Updates via `setQueryData` must be performed in an *immutable* way."

Mutating in place breaks structural sharing and the `Object.is` React relies on: the cache is right and the screen does not update.

```tsx
const edit = useMutation({
  mutationFn: editTodo,
  onSuccess: (updated, variables, onMutateResult, context) => {
    context.client.setQueryData(todoOptions(updated.id).queryKey, updated)
    context.client.setQueryData<Todo[]>(['todos', 'list'], (old) =>
      old?.map((t) => (t.id === updated.id ? updated : t)),
    )
  },
})
```

An updater returning `undefined` does not update; receiving `undefined` and returning `undefined` bails out without creating an entry. `(old) => old?.map(...)` already behaves. Creating an entry from a write that was never fetched serves partial data as if complete.

| ID | Rule |
| --- | --- |
| `TSQ-MUT-08` | `setQueryData` **MUST** be immutable; **NEVER** mutate in place the object read from the cache. |
| `TSQ-MUT-09` | A `setQueryData` updater **MUST** return `undefined` when it receives `undefined`: do not create a cache entry from a write. |

---

## 5. Optimistic update with snapshot and rollback

The full cycle, as the docs present it today (official examples now use `context.client` instead of `useQueryClient()`):

```tsx
const toggle = useMutation({
  mutationFn: updateTodo,
  onMutate: async (next, context) => {
    await context.client.cancelQueries({ queryKey: ['todos'] })
    const previousTodos = context.client.getQueryData<Todo[]>(['todos'])
    context.client.setQueryData<Todo[]>(['todos'], (old) =>
      old?.map((t) => (t.id === next.id ? next : t)),
    )
    return { previousTodos }
  },
  onError: (err, next, onMutateResult, context) => {
    context.client.setQueryData(['todos'], onMutateResult.previousTodos)
  },
  onSettled: (data, error, variables, onMutateResult, context) =>
    context.client.invalidateQueries({ queryKey: ['todos'] }),
})
```

| Step | Failure it prevents |
| --- | --- |
| `await cancelQueries` | a refetch in flight from before the mutation lands after `setQueryData` and reverts the optimism; the bug flickers and is nearly impossible to reproduce |
| snapshot **before** writing | in `onError` the value is already overwritten |
| snapshot through the `onMutate` return | `useRef` or a module variable breaks under concurrent mutations: the second overwrites the first's snapshot and rollback restores the wrong state |
| invalidate in `onSettled`, not `onSuccess` | on success the server may derive things the response lacks (`updatedAt`, counters, ordering); on error the rolled-back local value must also be confirmed against the source |
| `return` in `onSettled` | keeps `isPending` until the refetch ends (`TSQ-MUT-02`) |

Expected and unexpected failures are handled differently: `409 Conflict` is a business result that becomes a form message; a timeout is a defect for the boundary (`REACT-ASYNC-09`, skill `react-developer`).

### The cheaper alternative: optimism through the UI

For a single spot in the UI, render the mutation's `variables` while it is `pending`, without touching the cache:

```tsx
const add = useMutation({
  mutationFn: (text: string) => api.post('/todos', { text }),
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})

const { isPending, variables, isError } = add

return (
  <ul>
    {todos.map((t) => <Item key={t.id} todo={t} />)}
    {isPending && <li className="opacity-50">{variables}</li>}
    {isError && <li>Failed. <button onClick={() => add.mutate(variables!)}>Retry</button></li>}
  </ul>
)
```

No snapshot, no rollback, no temporary ID left in the cache. To read mutations fired by **another** component, use `useMutationState` filtered by `mutationKey`.

Choice: if the optimistic data must appear in more than one place or survive navigation, optimism belongs in the cache. One place only: use `variables`, which cannot roll back wrong.

| ID | Rule |
| --- | --- |
| `TSQ-MUT-10` | An optimistic update on the cache **MUST** have the full cycle: `cancelQueries` → snapshot → `setQueryData` → rollback in `onError` → invalidation in `onSettled`. |
| `TSQ-MUT-11` | The snapshot **MUST** travel through the `onMutate` return (`onMutateResult`); **NEVER** through `useRef`, a module variable or component state. |
| `TSQ-MUT-12` | Post-optimism invalidation **MUST** be in `onSettled`, never only in `onSuccess`. |

---

## Version notes

- Changed against older material: callback signatures (§ 2), `refetchType` default `'active'` (§ 3), documented `undefined` updater semantics (§ 4).
- `setMutationDefaults` is tied to **offline mutation persistence**, not to scopes; `scope: { id }` needs no `setMutationDefaults`.

---

## Antipatterns

```tsx
// FRAGILE: works, but the name lies; the third argument is the onMutate return
onError: (err, next, context) => {
  queryClient.setQueryData(['todos'], context.previous)
},

// RIGHT: name it for what it is, and guard against an onMutate that threw
onError: (err, next, onMutateResult) => {
  if (!onMutateResult?.previousTodos) return
  queryClient.setQueryData(['todos'], onMutateResult.previousTodos)
},
```

If `onMutate` throws before `return` (`cancelQueries` rejecting, for example), `onMutateResult` is `undefined` and **the rollback line is the one that crashes the app**.

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| `getQueryData(...)!.push(todo)` | in-place mutation: the cache changes, the screen does not | `setQueryData(key, (old) => (old ? [...old, todo] : old))`: `TSQ-MUT-08` |
| `await mutateAsync(values); navigate(...)` without `catch` | unhandled rejection even with `onError` | `mutate(values, { onSuccess: () => navigate(...) })` or `try/catch`: `TSQ-MUT-04` |
| `invalidateQueries()` without a filter after every write | refetches every active query for any mutation | invalidate by prefix: `TSQ-MUT-07` |
| Optimistic update without `cancelQueries` | an in-flight refetch lands later and reverts the optimism; intermittent bug | `await cancelQueries` in `onMutate`: `TSQ-MUT-10` |
| Snapshot in `useRef` | concurrent mutations overwrite it; rollback restores the wrong state | `onMutate` return: `TSQ-MUT-11` |
| Invalidating only in `onSuccess` | rollback leaves a local value unconfirmed against the server | `onSettled`: `TSQ-MUT-12` |
| `retry: 3` on `POST /orders` | three duplicated orders | keep the default, or guarantee idempotency: `TSQ-MUT-05` |
| Closing a modal in the `useMutation` `onSuccess` | runs even after the screen is gone | `mutate(vars, { onSuccess })`: `TSQ-MUT-03` |
