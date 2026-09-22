---
nome: tanstack-router
descricao: Work with routing in TanStack Router — defining and nesting routes, navigating with `<Link>`, typed and validated search params, loaders and cache integration, route context and code splitting — citing `TSR-*` IDs, with sixteen executable probes — use when the task is creating or nesting a route, building navigation, validating and reading search params, deciding between a loader and Query, guarding a route, or splitting the bundle. Do not use for the remote data itself, which is tanstack-query, nor for the inside of components, which is react-developer and react-review.
tipo: skill
familia: tanstack
idioma: en
fonte: "[TanStack Router](../../../knowledge-base/docs/tanstack-router.md)"
docs:
  - /websites/tanstack_router
tags:
  - skill
  - tanstack-router
  - react
---

# tanstack-router

> **Source of this skill:** [TanStack Router](../../../knowledge-base/docs/tanstack-router.md) and the ten satellites, loaded **one per task**.
> This skill **does not contain** technical API procedure — it routes by task, cites the rule and says what to check.
> **API surface:** resolve it through Context7 — `/websites/tanstack_router`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

> **What changed in this version.** The previous one carried a "doc status warning" saying the satellites were **under construction**, and for that reason **cited no ID at all** — it borrowed `REACT-*`. The ten satellites exist today and add up to **102 `TSR-*` rules**. The warning is gone; every task now has a citable family, and the map is generated from the docs.

---

## When to use

The question is about **routing, navigation, the URL or route loading**.

| Situation | Go to |
| --- | --- |
| the remote data itself: freshness, invalidation, optimism | `tanstack-query` |
| the inside of the component | `react-developer` · `react-review` |
| where the file lives in the feature | `react-structure` |
| a multi-step form (the **value** is the form's; the **step** is the URL's) | `react-hook-form` |

---

## Minimum loading

1. Identify **the task** in `references/por-tarefa.md`.
2. Load only the satellites in the "Load" column, in the order given.
3. Walk the "Check" items before calling the task done.

**Never load all ten satellites at once.**

References in this skill:

| File | What for |
| --- | --- |
| `references/por-tarefa.md` | the seven tasks: what to load and what to check |
| `references/regras-por-tarefa.md` | the `TSR-*` families per task, and the rules that decide most cases |
| `references/fronteira.md` | what belongs to React and not to the router |
| `references/mapa-de-ids.md` | the 102 `TSR-*` by satellite and section |
| `references/exemplo.md` | worked case |
| `scripts/sondas.sh` | sixteen probes over routing, navigation, search and loaders |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map from `Docs/TanStack Router*` |

---

## Step 1 — Probe

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tanstack-router/scripts/sondas.sh src
```

**The two that pay most:**

| Probe | What it reveals |
| --- | --- |
| **S5** — a route reading search **without `validateSearch`** | without a schema there is no type, no default and no guarantee of shape (`TSR-SEARCH-01`) |
| **S15** — a loader using Query **without `defaultPreloadStaleTime: 0`** | two caches deciding freshness (`TSR-LOAD-14`) — the symptom shows up as "stale data with Query apparently right" |

And the most frequent one in generated code: **S1**, `to` with an interpolated string (`TSR-NAV-01`) — a path param goes in `params`, a query in `search`.

---

## Step 2 — Route by task

`references/por-tarefa.md`: defining a route · understanding the match · navigating · search params · loading data · splitting the bundle · virtual tree.

The families and the decisive rules of each: `references/regras-por-tarefa.md`.

---

## Step 3 — The boundaries that decide the citation

- **`TSR-LOAD-01` is an alias of `REACT-EFFECT-06`** — fetching first-render data in a `useEffect` is the same defect, seen from the router. In a review that crosses docs, cite React's canonical one.
- **`TSR-NAV-08` is an alias of `TSR-LOAD-14`** — cite the canonical one.
- **The wizard's step belongs to the URL** (`REACT-PAT-10`); the fields' **values** belong to the form (`react-hook-form`).

---

## Step 4 — Closing

1. **If the loader uses Query**, freshness is decided in **one** cache — `defaultPreloadStaleTime: 0`.
2. **If the guard is in an effect**, it is in the wrong place: it is `throw redirect(...)` in `beforeLoad` (`TSR-LOAD-06`).
3. **If the route has a `loader`**, it needs an `errorComponent` (`TSR-LOAD-09`) — otherwise the failure rises to the root.
4. **Declare what you did not verify.** If the note the task requires is incomplete, consult the official docs, **declare the limitation** and record what was verified — do not fill a gap from memory.

---

## Example

A listing with a filter, page and sorting in the URL: `validateSearch` with `.catch`/`.default` per key, `loaderDeps` returning **only** the keys the loader reads, `<Link>` with `params`/`search` instead of an interpolated string, and `defaultPreloadStaleTime: 0` because the loader uses Query.

Full case: `references/exemplo.md`.

---

## Related

- [TanStack Router](../../../knowledge-base/docs/tanstack-router.md) — the hub, and the ten satellites
- `tanstack-query` — the other cache; `TSR-LOAD-14` is what reconciles them
- `react-developer` · `react-review` · `react-structure` — what stays inside the route
- `react-hook-form` — the wizard whose step lives in the URL
