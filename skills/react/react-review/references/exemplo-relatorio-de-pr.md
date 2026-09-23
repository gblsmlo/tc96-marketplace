# Worked example — reviewing a PR

PR: *"adds customer search with a filter and export"*. Three files touched.

---

## Step 1 — probes before opening any file

```
$ bash scripts/sondas.sh src

== 0. Environment
 "react": "^19.1.0"
 -- React Compiler: (nothing)
 -- lint net for REACT-HOOK-* and REACT-EFFECT-02/03:
 Biome present (biome.json), but the react domain is NOT switched on
 NO active net ← already a finding
 -- <StrictMode>: src/main.tsx
== 1. Fetch inside an Effect
 src/features/customers/CustomerList.tsx:31
== 2. State derived through an Effect
 src/features/customers/CustomerList.tsx:44
== 6. Memoization — inventory
 src/features/customers/CustomerList.tsx:3
== 7. index as a key
 src/features/customers/CustomerList.tsx:78
== 9. Suspense without an Error Boundary
 src/features/customers/route.tsx
== 12. Server Function — boundary validation
 no apparent validation: src/features/customers/export.ts
```

Five minutes, and the review already knows **which** files to read and in what order. None of those
six is a finding yet — they are candidates.

## Step 2 — reading, in the grid's order

Level 1 first. Reading `CustomerList.tsx` finds what the probe cannot see:

```tsx
export function CustomerList({ term }: { term: string }) {
 const [customers, setCustomers] = useState<Customer[]>([]);
 if (!term) return <Empty />; // ← early return
 const [page, setPage] = useState(1); // ← a Hook after it
 …
```

That changes the report's order: `REACT-HOOK-01` is blocking and comes before everything the probe found.

## Step 3 — the report

```markdown
## React review — PR #482 (customer search)

**Environment** (probe 0): react 19.1.0 · React Compiler absent ·
lint net **ABSENT** (Biome without the react domain) · StrictMode ok

### Blocking (1)

`REACT-HOOK-01` — src/features/customers/CustomerList.tsx:12
`useState(1)` is called after the early return on line 10; the Hook order changes between renders.
Fix: move both `useState` calls above the `if (!term)`.
See React - Rules of React.

### High (3)

`REACT-EFFECT-06` — src/features/customers/CustomerList.tsx:31
`fetch('/api/customers?q=' + term)` inside a `useEffect`, with no cancellation: two searches
in flight return out of order and the old one overwrites the new.
Fix: replace it with `useQuery(customersQuery(term))`; remove `customers`, `loading` and `error`.
See React - Efeitos e Sincronização.

`REACT-RSC-06` — src/features/customers/export.ts:4
The Server Function `exportCustomers(filter)` uses `filter` straight in the query, with no session and no validation.
Fix: read the session, validate `filter` with Zod in the function itself and filter by the session's `orgId`.
See React - Server Components e Diretivas.

`REACT-ASYNC-08` — src/features/customers/route.tsx:18
A `<Suspense>` at the data boundary with no Error Boundary: a query failure becomes a white screen.
Fix: wrap it with the feature's `<ErrorBoundary>`, with a retry button.
See React - Suspense e Assincronia.

### Medium (3)

`REACT-PAT-01` — src/features/customers/CustomerList.tsx:44
`totalPages` is state synchronized through an Effect from `customers.length`.
Fix: `const totalPages = Math.ceil(customers.length / PER_PAGE)` in the render; remove the state and the Effect.
See React - Patterns.

`REACT-PAT-10` — src/features/customers/CustomerList.tsx:13
`page` in `useState`: it does not survive a refresh and is not shareable by link.
Fix: move it to the route's search param (`Route.useSearch`).
See React - Patterns.

antipattern from React - Patterns § 8 — src/features/customers/CustomerList.tsx:78
`key={i}` in a list that is reordered by the sort selector.
Fix: `key={customer.id}`.

### Suggestions (no rule)

- `CustomerList.tsx` has 210 lines and three responsibilities. There is no ID for that;
 the extraction is only justified if each part has a domain name (`REACT-PAT-05` is about
 the opposite: extracting with no justification).

### Not verified

- `export.ts` uses the framework runtime's `after` — it is not in React.js § 4,
 so it has not been verified in this doc. I did not opine on its behavior.
- The project uses Biome with `recommended`, but **without the `react` domain**: `useHookAtTopLevel` and
 `useExhaustiveDependencies` do not run, and nothing warns. `REACT-HOOK-*` and part of
 `REACT-CALL-*` depend on human review. Switching on `linter.domains.react` is one line, and it is the
 highest-return item in this PR.
```

## What this example demonstrates

| Decision | Where the rule is |
| --- | --- |
| the `REACT-HOOK-01` finding came from **reading**, not from the probe | `sondas.md` § *What the probes do not catch* |
| the memoization from probe 6 did **not** become a finding — the `useMemo` had a comment with a measurement | `REACT-PERF-01` |
| the file's size went to "Suggestions", not to findings | `severidade-e-relatorio.md` § *The cut* |
| the unknown `after` became a declaration of limitation, not an opinion | [React.js](../../../../knowledge-base/react-js.md) § 7, invariant 1 |
| the absence of lint came in as the closing, not as a footnote | `severidade-e-relatorio.md` § *The report's structure* |
