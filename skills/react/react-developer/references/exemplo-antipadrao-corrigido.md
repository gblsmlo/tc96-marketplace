# Worked example — antipattern and fix

The component below is what comes out by default when Step 1 is skipped. It **works**
in development, with little data and no reordering. It fails in the four situations that
matter: a slow connection, a refresh, navigating back, and a reordered list.

---

## Before

```tsx
function Search({ term }: { term: string }) {
 const [query, setQuery] = useState(term); // 1
 const [results, setResults] = useState<Item[]>([]);
 const [loading, setLoading] = useState(false);
 const [error, setError] = useState<string | null>(null);
 const [count, setCount] = useState(0);

 useEffect( => { setQuery(term) }, [term]); // 2

 useEffect( => { // 3
 setLoading(true);
 fetch(`/api/search?q=${query}`)
.then((r) => r.json)
.then((d) => { setResults(d); setLoading(false) })
.catch( => { setError('failed'); setLoading(false) });
 }, [query]);

 useEffect( => { setCount(results.length) }, [results]); // 4

 const sorted = useMemo( => results.sort((a, b) => a.name.localeCompare(b.name)), [results]); // 5

 if (loading) return <Spinner />;
 return <ul>{sorted.map((r, i) => <li key={i}>{r.name}</li>)}</ul>; // 6
}
```

## The six defects

| # | Defect | Concrete consequence | Rule |
| --- | --- | --- | --- |
| 1 | `query` mirrors the `term` prop in state | two owners of the same value | `REACT-PAT-01` |
| 2 | an Effect just to resynchronize the prop | one more render, and the window in which the two diverge | `REACT-PAT-01` |
| 3 | a `fetch` in an Effect | with no cancellation: two searches in flight return out of order and the old one overwrites the new | `REACT-EFFECT-06` |
| 3 | manual `loading`/`error` | states that admit an impossible combination (`loading && error`) | `REACT-STATE-06` |
| 4 | `count` derived through an Effect | it is `results.length` | `REACT-PAT-01` |
| 5 | `.sort` over the state's array | `sort` **mutates** — the array came from the state and already went into the JSX | `REACT-PURE-03`, `REACT-PURE-05` |
| 5 | a `useMemo` with no measurement | cost with no proven benefit | `REACT-PERF-01` |
| 6 | `key={i}` | on reorder, the row's internal state goes to the wrong item | [React - Patterns](../../../../knowledge-base/react-patterns.md) § 8 |

Defect 3 costs most and shows least: the race condition only manifests
with variable latency, exactly where nobody is watching.

## After

```tsx
function Search({ term }: { term: string }) {
 const { data: results } = useSuspenseQuery(searchQuery(term)); // 3 → the cache

 const sorted = [...results].sort((a, b) => // 5 → a copy, in the render
 a.name.localeCompare(b.name)
 );

 return (
 <>
 <p>{results.length} results</p> {/* 4 → derived */}
 <ul>
 {sorted.map((r) => <li key={r.id}>{r.name}</li>)} {/* 6 → the domain's id */}
 </ul>
 </>
 );
}
```

And the waiting and the failure leave the component, for the feature's boundary:

```tsx
<ErrorBoundary fallback={<SearchFailure onRetry={reset} />}> {/* REACT-ASYNC-08 */}
 <Suspense fallback={<ListSkeleton />}> {/* REACT-ASYNC-02 */}
 <Search term={term} />
 </Suspense>
</ErrorBoundary>
```

## The scoreboard

| | Before | After |
| --- | --- | --- |
| `useState` | 5 | 0 |
| `useEffect` | 3 | 0 |
| memoization | 1 with no measurement | 0 |
| race condition | unhandled | resolved by the cache |
| a refresh preserves the search | no | yes, if `term` comes from the URL (`REACT-PAT-10`) |

No line was removed out of taste: each one left because of a rule with an ID.
