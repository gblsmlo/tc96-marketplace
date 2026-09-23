# Worked example

Task: *"the invoice listing has to filter by status, and the filter has to survive a refresh and the back button"*.

This skill routes; it does **not** write the code. The example below is about using it — which notes to load, in what order, and what to check before calling the task done.

**1. Identify the task.** "A filter that survives a refresh and the back button" is state that belongs to the URL, not to the component. In the "How to use" table, that is **handling search params** — and, because the listing also fetches data, **loading route data**. Two tasks, in this order.

**2. Load, in the table's order:**

| Order | Note | To answer |
| --- | --- | --- |
| 1 | [TanStack Router - Search Params](../../../../knowledge-base/tanstack-router-search-params.md) | how to declare and validate `status` |
| 2 | [TanStack Router - Navegação](../../../../knowledge-base/tanstack-router-navegacao.md) | how to change the filter without stacking history on every keystroke |
| 3 | [TanStack Router - Carregamento de Dados](../../../../knowledge-base/tanstack-router-carregamento-de-dados.md) | whether the loader participates, or the data is the cache's |

Do not load [TanStack Router - Routing Concepts](../../../../knowledge-base/tanstack-router-routing-concepts.md) nor [TanStack Router - File-Based Routing](../../../../knowledge-base/tanstack-router-file-based-routing.md): the route already exists. That is the context-economy rule.

**3. Walk each task's "Check".** What that pass produces as real decisions:

- `status` is **validated** on the route, not read as a loose string — that is what gives the type to everything else;
- changing the filter **replaces** history instead of stacking it, otherwise the back button walks through every typed letter;
- the remote data still belongs to [TanStack Query](../../../../knowledge-base/tanstack-query.md); the route owns the **filter**, not the invoices — the boundary is in [TanStack Router - Carregamento de Dados](../../../../knowledge-base/tanstack-router-carregamento-de-dados.md), and the loader × Query decision is theirs;
- the component does **not** keep the filter in `useState` (`REACT-PAT-10`) — if it did, there would be two owners of the same data diverging.

**4. The honesty rule, in action.** If [TanStack Router - Search Params](../../../../knowledge-base/tanstack-router-search-params.md) is absent or incomplete at the time of reading — which the warning above admits is possible — **declare the limitation** and go to the official TanStack Router documentation. Then record what was verified in the note. What you do not do is fill the gap from memory and present the assumption as fact.

**The boundary this example marks out:** three skills touch this screen and none invades another — this one decides the filter belongs to the URL, `tanstack-query` decides the invoices' cache, and `react-developer` writes the component that consumes both.
