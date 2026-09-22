# Boundary with React

The router solves what plain React does not. When deciding between a React primitive and the router, use [React.js](../../../../knowledge-base/docs/react-js.md) § 8 (bridges with the stack):

| Problem | Do not use | Use |
| --- | --- | --- |
| Filter, tab, pagination, sorting | `useState` | the route's search params (`REACT-PAT-10`) |
| Navigation and history | `useState` + history | the router's navigation API |
| A screen's remote data | `useEffect` + `useState` | the route's loader and/or TanStack Query (`REACT-EFFECT-06`, `REACT-PAT-03`) |

When reviewing route code, the `REACT-*` IDs remain citable in `react-review`'s format: canonical ID + file:line + concrete fix + satellite link.
