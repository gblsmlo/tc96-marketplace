# Two points you do not assume from memory

### The mutation callback signatures changed within v5

**Check [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/tanstack-query-mutations-e-invalidacao.md) § 2 ("As assinaturas dos callbacks") every time you touch a mutation with `onMutate`, and always on an optimistic update.** Do not write it from memory and do not copy from an example found outside the vault.

What changes the outcome: **the return of `onMutate` arrives as the third argument**, and `context` became the last one and became something else. Code written against the old form reads the wrong object — the rollback receives `undefined` and **fails silently**: the mutation "handles" the error, the screen does not revert to the previous state, and nothing blows up.

Why this is here and not a doc detail: the old signature dominates the training material, so it is exactly what AI-generated code produces by default. TypeScript catches it — as long as the types are not loose at the callback.

Rules involved: `TSQ-MUT-11` (the snapshot travels through `onMutate`'s return) and `TSQ-MUT-10` (complete cycle). The satellite's checklist closes with that check as an item of its own.

### Optimism has two layers — pick one, and declare which

React's `useOptimistic` and the optimistic update over Query's cache solve the same problem at different layers. Using both in the same flow creates two provisional states that converge at different moments, with independent rollbacks.

| Criterion | Layer |
| --- | --- |
| The optimistic data appears in **one** place, inside a form/Action | `useOptimistic` — [React - Formulários e Actions](../../../../knowledge-base/react-formularios-e-actions.md) § 5 |
| It appears in more than one place, or has to survive navigation | Query's cache, complete cycle — `TSQ-MUT-10` |
| It is a single item in a list and the cache does not need touching | render the mutation's `variables` while `pending` — the version that cannot roll back wrongly ([TanStack Query - Mutations e Invalidação](../../../../knowledge-base/tanstack-query-mutations-e-invalidacao.md) § 5) |

In any of the three, **the optimistic value is never the source of truth** — `REACT-FORM-07`. Truth converges from the server: in React, at the end of the Action; in Query, at the invalidation in `onSettled`. One rollback is automatic (`useOptimistic`), the other is explicit with a snapshot (Query) — confusing the two is how a rollback that never runs gets written.
