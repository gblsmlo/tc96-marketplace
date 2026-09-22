# Boundary with the other skills

| The question is about | Skill |
| --- | --- |
| The remote data: key, freshness, invalidation, optimism, query shape | this one |
| The route: where the loader lives, URL matching, search params, navigation, code splitting | `tanstack-router` |
| A component that already exists: purity, Hooks, structure, finding severity | `react-review` |
| A new component: state ownership, composition, failure and waiting boundaries | `react-developer` |

Overlaps resolved:

- **Remote data in `useState`** shows up in all four. `REACT-PAT-03` is the ID to cite; the fix belongs to this skill (it becomes a query).
- **`fetch` in `useEffect`** is `REACT-EFFECT-06`; the fix is a query, or a loader if the data belongs to the route — task 6.
- **Optimistic updates** are a boundary with `react-developer`: the choice of layer sits above, and `REACT-FORM-07` holds in both.
- **Pagination and filtering** are a boundary with `tanstack-router`: the value belongs to the URL (`REACT-PAT-10`), the cache belongs to the key (`TSQ-PATTERN-04`). Both, not one of the two.

When reporting a finding in a review, use `react-review`'s format — canonical ID + `file:line` + concrete fix + satellite link. The `TSQ-*` IDs fit that format just as the `REACT-*` ones do.

**Honesty rule:** if the API you touched appears neither in [TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) § 4 nor in the satellites, it has not been verified in this doc. Declare the limitation, consult [tanstack.com/query](https://tanstack.com/query/latest/docs/framework/react/overview) and propose updating the note — do not assert behavior and do not invent an ID ([TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) § 7).
