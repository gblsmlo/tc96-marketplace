---
nome: tanstack-query
descricao: Work with server state in TanStack Query — reading remote data, freshness policy, mutations and invalidation, optimistic updates with rollback, paginated and infinite lists, integration with the route loader — citing `TSQ-*` IDs, with twelve executable probes and a symptom-based diagnostic table — use when the task is fetching data someone else can change, deciding `staleTime`, invalidating after a write, building an optimistic update, paginating, or understanding why the screen does not update or why there are too many requests. Do not use for ephemeral UI state, which is react-developer, for state that belongs to the URL, which is tanstack-router, nor for HTTP caching, which is http-cache.
tipo: skill
familia: tanstack
idioma: en
fonte: "[TanStack Query](../../../knowledge-base/tanstack-query.md)"
docs:
  - /websites/tanstack_query
tags:
  - skill
  - tanstack-query
  - react
---

# tanstack-query

> **Source of this skill:** [TanStack Query](../../../knowledge-base/tanstack-query.md), with the five satellites loaded **one at a time**.
> This skill **contains** neither the text of the rules nor the API surface — it routes by task and diagnoses by symptom.
> **API surface:** resolve it through Context7 — `/websites/tanstack_query`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [TanStack Query](../../../knowledge-base/tanstack-query.md) § 7.

---

## When to use

The data **comes from a server and someone else can change it**: reading, writing, invalidating, paginating, deciding freshness, or understanding the cache.

Before anything, go through the first tree in [TanStack Query](../../../knowledge-base/tanstack-query.md) § 5 ("Este dado é da Query?"):

| The data is… | Go to |
| --- | --- |
| ephemeral UI state, or component structure | `react-developer` · `react-review` |
| state that belongs to the URL (filter, tab, page, sorting) | `tanstack-router` |
| a route's data, loaded by the loader | `tanstack-router`, **and** task 6 |
| global client state with frequent writes | |
| freshness decided by the **server**, through headers | `http-cache` — another layer |

---

## Minimum loading

```
ALWAYS: TanStack Query § 2 (mental model) and § 5 (trees)
ON DEMAND, via § 4: the satellite for the task
IF it involves a route/loader: TanStack Router - Carregamento de Dados
NEVER: all satellites at once
```

The five satellites add up to more than 100 KB. **Loading all of them is the most expensive context mistake in this doc.**

References in this skill:

| File | What for |
| --- | --- |
| `references/por-tarefa.md` | the task → satellite map, and the seven cuts |
| `references/nao-assumir-de-memoria.md` | the callback signatures in v5, and the two layers of optimism |
| `references/diagnostico.md` | "the screen does not update" and "too many requests", symptom by symptom |
| `references/fronteira.md` | what belongs to another skill |
| `references/mapa-de-ids.md` | the 55 `TSQ-*` by satellite and section |
| `references/exemplo.md` | worked case |
| `scripts/sondas.sh` | twelve probes over the code |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map from `knowledge-base/tanstack-query*` |

---

## Step 1 — Probe

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tanstack-query/scripts/sondas.sh src
```

**The two that pay most:**

| Probe | What it reveals |
| --- | --- |
| **S1** — `staleTime` never declared | **every piece of data is born stale** (`TSQ-CACHE-01`): network on every mount, tab focus and reconnect |
| **S6** — optimistic update without `cancelQueries`/`onError`/`onSettled` | an incomplete cycle (`TSQ-MUT-10`): it flickers and reverts, or does not roll back |

And the most misleading one: **S2**, a trigger switched off as a remedy. `refetchOnWindowFocus: false` erases the symptom and leaves `refetchOnMount` with the opposite policy on the same cache — two contradictory rules about the same data (`TSQ-CACHE-03`).

---

## Step 2 — Route by task

`references/por-tarefa.md`: reading data · freshness policy · writing and invalidating · optimistic update · paginated list · route loader · diagnosing the cache.

---

## Step 3 — Do not assume from memory

`references/nao-assumir-de-memoria.md`:

1. **The mutation callback signatures changed within v5.** The return of `onMutate` arrives as the **third argument**. Code written against the old form reads the wrong object, and the rollback **fails silently** (`TSQ-MUT-11`). The old form dominates the training material — it is what generated code produces by default.
2. **Optimism has two layers.** `useOptimistic` and the cache update solve the same problem in different places; using both creates two provisional states with independent rollbacks. In either of them, **the optimistic value is never the source of truth** (`REACT-FORM-07`).

---

## Step 4 — Diagnose by symptom

`references/diagnostico.md`, two tables: **"the screen does not update"** and **"too many requests"**. Start with the table, open **one** satellite.

**The fix is almost never switching off a trigger** — calibrate `staleTime` first (`TSQ-CACHE-03`).

---

## Step 5 — Closing

1. **If the data belongs to a route**, freshness is decided in **one** cache only: `defaultPreloadStaleTime: 0` (`TSR-LOAD-14`) — `tanstack-router`.
2. **If the client is Eden**, the `queryFn` has to **throw** (`ELYSIA-TYPE-09`), otherwise the query stays in `success` with the error inside `data` — `elysia-schema`.
3. **If the symptom is re-rendering**, check structural sharing (`TSQ-CACHE-04`) and tracked properties (`TSQ-CACHE-05`) before memoizing.
4. **Declare what you did not verify.**

---

## Example

An invoice listing with a filter in the URL, an approval mutation and an optimistic update: the key includes the filter; the mutation does `cancelQueries` → snapshot → immutable write → rollback in `onError` → `invalidateQueries` returning the Promise in `onSettled`. What habit would produce: a key without the filter, a rollback reading the wrong argument, and `refetchOnWindowFocus: false` to "solve" the excess requests.

Full case: `references/exemplo.md`.

---

## Related

- [TanStack Query](../../../knowledge-base/tanstack-query.md) — source of this skill: § 2, § 4, § 5, § 7
- `tanstack-router` — route data, and preloading
- `react-developer` · `react-review` — the component around it
- `elysia-schema` — the bridge with Eden
- `http-cache` — the server's cache layer
