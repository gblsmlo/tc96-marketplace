# Probe overlaps and false positives that change an audit verdict

`audit.sh` runs four probe sets written for different jobs. Some rows measure the same pattern twice and some fire outside their scope. Read this before counting a row in the backlog.

## The same pattern, counted twice

| Rows | Pattern | Count it once as |
| --- | --- | --- |
| review#2 · rerender#8 · forms#9 | state set from other state in an Effect, or a `useState` mirroring a field | `REACT-PAT-01` |
| review#6 · rerender#1 | memoization inventory | `REACT-PERF-01`, and only when the Compiler is off |
| review#7 · forms#7 | `key={index}` | `RHF-ARRAY-01` when forms#7 also hits (it only scans files with `useFieldArray`); otherwise the index-key antipattern of [React - Patterns](../../docs/react-patterns.md) § 8 |
| review#1 · review#4 | an `async` Effect that fetches | `REACT-EFFECT-06` for the fetch, plus `REACT-EFFECT-12` for the async callback |

## Rows that fire outside their scope

| Row | Fires on | Confirm by |
| --- | --- | --- |
| forms#7 | a `key={index}` on a plain list in a file that also has a `useFieldArray` | checking the keyed list is the `fields` array |
| forms#3 | a `useForm` that receives `values` instead of `defaultValues` | reading the call |
| forms#9 | any `useState` in a file with a form | checking that the state mirrors a registered field |
| review#2 | an Effect that syncs an external system and starts with `set` | naming the external system; none → finding |
| review#10 | `.sort()` on a local copy (`[...xs].sort()`, `toSorted`) | checking the receiver came from props or state |
| review#13 | `createRoot` in a client-only SPA | only a finding over server-rendered HTML (`REACT-DOM-01`) |
| rerender#2 · rerender#3 | inline props in tests, stories or a cold path | the probes already skip tests and stories; a cold path is not a backlog item |
| structure#2 | an import that reaches a file the barrel already exports | checking whether the feature has an `index.ts`; no barrel → report `REACT-ARCH-02` for the feature **and** keep `REACT-ARCH-05` on each deep import |

## Rows that only mean something in context

- **review#9** (Suspense without an Error Boundary in the same file) is a finding only when no ancestor boundary covers it. Read the route or layout above.
- **review#11** (`'use client'`) is inventory: the finding is a directive placed higher than the interactive leaf (`REACT-RSC-03`).
- **rerender#11** (external store subscription) is never an audit fix. It is the `react-component-performance` circuit breaker; list it under "needs measurement".
