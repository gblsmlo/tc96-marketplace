# Worked example — invoice panel

Task: *"an invoice panel with a status filter and the total of what is selected"*.

The point of this example: the intuitive version of this screen has **four** `useState` and **two**
`useEffect`. None of them survives Step 1 — and none was necessary.

---

## Step 1 — the three questions, in writing

| Question | Answer | Consequence |
| --- | --- | --- |
| Whose data is this? | the **invoices** are the server's; the **filter** belongs to the URL; the **selection** is the panel's | three owners, three mechanisms |
| Who supplies the variable content? | the invoice row varies by context → `children`, not a boolean prop | the signature does not grow |
| Where should a failure or a wait stop? | at the feature's boundary, not at the root | an Error Boundary + `<Suspense>` in `features/invoices` |

Question 1 alone already eliminated two `useState` calls that habit would have created.

## Step 2 — the trees, one owner at a time

| Owner | Path in [React.js](../../../../knowledge-base/react-js.md) § 5 | Exit | Rule |
| --- | --- | --- | --- |
| invoices | "does the data come from the server?" → yes | [TanStack Query](../../../../knowledge-base/tanstack-query.md), not `useState` + `useEffect` | `REACT-PAT-03`, `REACT-EFFECT-06` |
| filter | it survives a refresh, is shareable by link, respects the back button | [TanStack Router](../../../../knowledge-base/tanstack-router.md) search params | `REACT-PAT-10` |
| selection | ephemeral, dies when leaving the screen | `useState` in the **nearest** common ancestor — the panel, not the root | `REACT-PAT-02` |
| total | derivable from invoices + selection | computed in the render, with no state and no Effect | `REACT-PAT-01` |

Three of the four exits have no Hook. That is the expected result.

## Step 3 — the code

```tsx
export function InvoicePanel({ children }: { children: ReactNode }) {
 const { status } = Route.useSearch; // filter: the URL
 const { data: invoices } = useSuspenseQuery(invoicesQuery({ status })); // remote: the cache
 const [selected, setSelected] = useState<Set<string>>(new Set);

 const total = invoices // derived, in the render
.filter((i) => selected.has(i.id))
.reduce((sum, i) => sum + i.amount, 0);

 function toggle(id: string) {
 setSelected((current) => { // updater: the previous value matters
 const next = new Set(current);
 next.has(id) ? next.delete(id) : next.add(id);
 return next; // a new Set, not a mutation of the state
 });
 }

 return (
 <section>
 <Total value={total} />
 <ul>
 {invoices.map((i) => (
 <InvoiceRow
 key={i.id} // the domain's id, never the index
 invoice={i}
 selected={selected.has(i.id)}
 onToggle={ => toggle(i.id)}
 />
 ))}
 </ul>
 {children}
 </section>
 );
}
```

And the boundary, one level above — a waiting **and** an error boundary, at the feature level:

```tsx
<ErrorBoundary fallback={<InvoicesFailure onRetry={reset} />}> {/* REACT-ASYNC-08, ASYNC-11 */}
 <Suspense fallback={<PanelSkeleton />}> {/* the same area as the content */}
 <InvoicePanel>
 <BulkActions /> {/* composition, not a boolean prop */}
 </InvoicePanel>
 </Suspense>
</ErrorBoundary>
```

## Step 4 — what the habits table prevented

| The habit that did not happen | Rule |
| --- | --- |
| `useEffect` + `fetch` to load the invoices | `REACT-EFFECT-06`, `REACT-ASYNC-03` |
| `useState` + `useEffect` for the total | `REACT-PAT-01` |
| `useState` for the filter | `REACT-PAT-10` |
| state lifted to the root "just in case" | `REACT-PAT-02` |
| `setSelected(new Set(selected))` without the updater | `REACT-STATE-01` |
| `showTotal` / `hideActions` instead of `children` | `REACT-PAT-04` |
| a `useMemo` on the `total` with no measurement | `REACT-PERF-01` |
| `key={i}` in the list | antipattern from [React - Patterns](../../../../knowledge-base/react-patterns.md) § 8 |
| an Error Boundary only at the root | `REACT-PAT-06` |

## Step 5 — self-check

- Pass 1: no conditional Hook, no side effect in the render, no mutation —
 the new `Set` inside the updater is construction, not a mutation of the previous state.
- Pass 2: sections 1–3 of `habitos-de-ia.md` are clean; 5–7 do not apply.
- Pass 3: the only `useState` is ephemeral and local; there is no `useEffect`; there is no memoization,
 so there is no memoization without measurement.
