# Correctness after memo — the tests a green benchmark cannot replace

> A stale component renders *fewer* times, so the benchmark rewards it. Every memoization added for
> performance ships with the tests below (`REACT-PERF-18` in
> [React - Performance Measurement](../../docs/react-performance-measurement.md)). Each test must
> **fail when the path it protects is removed** — check that by deleting the line once.

The four failure modes come from an independent review of a memoized DataGrid; all four were real.

---

## 1. State read outside the memoized props

**The bug.** A memoized row or cell renders a consumer renderer that reads something the memo does
not compare: table state (sorting, filters, pagination), a store, `table.options.meta`, a ref. The
props did not change, so the renderer never re-runs and shows the old value.

**Fix options**, in order: pass the value as a prop (a primitive is best); or pass a version number
that changes with it (then see § 3); or document that renderers must derive only from their own
arguments, and make the component enforce it.

**Test.**

```tsx
test('cell re-renders when meta changes', () => {
  const { rerender } = render(<Grid meta={{ currency: 'BRL' }} />)
  expect(cell(0, 'amount')).toHaveTextContent('R$')
  rerender(<Grid meta={{ currency: 'USD' }} />)
  expect(cell(0, 'amount')).toHaveTextContent('$')
})
```

---

## 2. Inline callbacks from the consumer

**The bug.** The consumer writes `onChange={(v) => save(v)}`. Every parent render creates a new
function, `memo` compares it, and the whole list re-renders anyway (`REACT-PERF-03`). The opposite
mistake — dropping the callback from the comparison — calls a stale closure.

**Fix.** The component accepts the inline function and wraps it once in a latest-callback: a stable
function that calls the most recent prop. The ref is written in an Effect, never during render
(`REACT-REF-01`), and `useEffectEvent` is not a substitute because it cannot be passed as a prop
(`REACT-EFFECT-07`):

```ts
function useLatestCallback<A extends unknown[], R>(callback: (...args: A) => R) {
  const ref = useRef(callback)
  useLayoutEffect(() => { ref.current = callback })
  return useCallback((...args: A) => ref.current(...args), [])
}
```

`useLayoutEffect` here keeps the ref current before any event that follows the commit; that is the
justification `REACT-EFFECT-10` asks for.

**Tests** — two, one per direction:

```tsx
test('inline onChange does not re-render rows', async () => {
  let renders = 0
  const cell = (context: CellContext) => { renders += 1; return renderCell(context) }
  const { rerender } = render(<Grid cell={cell} onChange={() => {}} />)
  renders = 0
  rerender(<Grid cell={cell} onChange={() => {}} />)
  expect(renders).toBe(0)
})

test('the stable onChange calls the latest prop', async () => {
  const first = mock(), second = mock()
  const { rerender } = render(<Grid onChange={first} />)
  rerender(<Grid onChange={second} />)
  await editCell(0, 'name', 'Ana')
  expect(first).not.toHaveBeenCalled()
  expect(second).toHaveBeenCalledWith(expect.objectContaining({ value: 'Ana' }))
})
```

---

## 3. Props that exist only to invalidate

**The bug.** A row receives `isFocused`, `selectionVersion` or `sortIndex` that its own JSX never
reads: they are there so `memo` sees a change. A later cleanup removes the "unused prop" and the
row stops refreshing. Nothing else fails.

**Fix.** Keep the prop, and pin it with a test named after its job.

**Test.**

```tsx
test('row refreshes when focus moves into it (focus prop is an invalidation key)', async () => {
  render(<Grid />)
  await click(cell(0, 'name'))
  await keyDown('ArrowDown')
  expect(cell(1, 'name')).toHaveAttribute('data-focused', 'true')
  expect(cell(0, 'name')).not.toHaveAttribute('data-focused')
})
```

Delete the invalidation prop and run it: it must fail. If it still passes, the prop was not doing
the job, or the test does not reach it.

---

## 4. The comparison itself

**The bug.** A custom `arePropsEqual` that compares a subset, or a `memo` whose parent passes a new
array/object built from the same data each render (probe 2), so memo never skips; or keys that
change on sort (probe 9), so rows remount instead of moving.

**Test.** The benchmark's `parent re-render` scenario at 0 renders, and `sort toggle` with 0 consumer
renders when rows only reorder. These are gate scenarios, not unit tests: keep them in the
harness.

---

## Checklist before delivering

| # | Check | Test that proves it |
| --- | --- | --- |
| 1 | every value a memoized renderer reads is a prop, or its version is | § 1, one per value |
| 2 | consumer callbacks may be inline without re-rendering, and the latest one is called | § 2, both tests |
| 3 | every invalidation-only prop has a test that fails without it | § 3, verified by deleting the prop once |
| 4 | `parent re-render` = 0 and `sort` = 0 consumer renders in the benchmark | § 4, gate scenarios |
| 5 | the full existing suite still passes, unchanged | — a changed assertion is a behavior change: justify it |

---

## Related

- `scenario-catalog.md` — the gate scenarios of § 4
- [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) § 3 — `memo`, `useCallback`, why one unstable prop cancels memo
- [React - Refs and DOM](../../docs/react-refs-and-dom.md) — `REACT-REF-01`, refs outside render

These tests live in the component's own test suite (`bun test` with its DOM setup), not in the benchmark: the harness is for measuring, not for asserting behavior.
