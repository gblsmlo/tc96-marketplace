# Scenario catalog — what to measure, by view type

> Which scenarios a benchmark needs, how to drive each one through the public API, and what the
> render count should look like after a good fix. The rules behind it are in
> [React - Performance Measurement](../../docs/react-performance-measurement.md); this file does not restate them.

A scenario is one user action, repeated. It is driven through what a user or a consumer can reach:
DOM events on rendered elements, props, and the component's documented imperative API
(`REACT-PERF-14`). Each scenario has to be **deterministic**: every iteration leaves the component in
a state where the next iteration costs the same. If iterations disagree on the render count, the
harness marks the count with `~` and the scenario must be fixed before it can gate.

---

## 1. Always

| Scenario | How to drive it | Render count after a good fix |
| --- | --- | --- |
| **mount** | built in: a fresh container per iteration, no warmup | equal to the item count: mount never gets cheaper with memo (`REACT-PERF-09`) |
| **parent re-render** | a parent state change that does not touch the data (a counter button in the adapter, or `rerender` with the same props) | 0 consumer renders: proves the props are stable |

`parent re-render` is the cheapest proof that `memo` is effective at all. If it renders every item,
some prop changes identity on every render (`REACT-PERF-03`): look at probe 2 and probe 3.

---

## 2. By view type

| View | Scenario | Drive with | Expected after the fix |
| --- | --- | --- | --- |
| **grid / table** | focus move (keyboard) | `fire.keyDown(activeCell, { key: 'ArrowDown' })`, cycling the four arrows so the position returns | 2 cells (the one that lost focus, the one that gained it) |
| | select click | `fire.click(cell)` on a different cell each iteration; select one in `setup` first | 2 cells |
| | select shift-click | anchor in `setup`, then `fire.click(cell, { shiftKey: true })` with a moving end | cells entering or leaving the range |
| | sort toggle | the column header button, or the table's public `toggleSorting` | 0 when rows only reorder (keys stable) |
| | group collapse | the group row's toggle button | one group's worth: rows mounted or unmounted, nothing else |
| **list** | select click | `fire.click(option)` with a moving index | 2 items |
| | filter / search typing | `fire.input(input, value)`; alternate two values that give the **same** visible count, or type then clear inside one iteration | items entering the result, not all items |
| **kanban** | drag a card between columns | the drag library's keyboard sensor (Space, arrows, Space) via `fire.keyDown`; pointer drags need layout JSDOM does not have | the two columns touched |
| | move within a column | same, one arrow | the cards whose position changed |
| **virtualized** | scroll | set `scrollTop` on the scroll element, then dispatch `scroll`; JSDOM has no layout, so mock the element's size in `mount` | the rows entering the window; constant regardless of dataset size |
| **form / editable** | edit one field | `fire.input` on one field | that field (and its validation message) |
| **tree** | expand / collapse a node | the node's toggle | the node's children |

---

## 3. Cases: sizes that expose the problem

Pick at least two sizes, an order of magnitude apart, so that the shape of the cost shows: an
interaction whose render count grows with the size is the bug; one that stays constant is the fix.

| Component | Small | Large |
| --- | --- | --- |
| grid | 200 rows × 10 columns | 1000 rows × 20 columns |
| list | 100 items | 1000 items |
| kanban | 5 columns × 20 cards | 10 columns × 100 cards |
| grouped variants | same sizes, grouped into 10 | mount once (`n=1`) if one mount costs seconds |

Data comes from `seededRandom(seed)` so every run renders the same rows; the seed goes in the
results file (`REACT-PERF-16`).

---

## 4. What to count

| Counter | Wrap | Why |
| --- | --- | --- |
| the consumer's cell / item renderer | `countRenders(cell, 'cells')` in the column or prop the consumer passes | what the consumer pays for; survives internal refactors |
| a row component the consumer passes as a prop | `countRenders(RowFn, 'rows')` on the **inner** function, before any `memo` | a `memo` object is not a function and cannot be wrapped |
| `commits` | automatic when the case mounts through `tools.render` | one interaction should be one commit; two means a cascade (often an Effect that sets state, probe 8) |

**Drag scenarios.** A drag library's overlay re-renders the dragged item a varying number of times, and its
animation-frame timing adds or removes a commit. Count the consumer renderer for every item **except** the
dragged one, set `commits: false` on the scenario, and make each iteration drag and return, so the count is
"renders of the other items" and stays deterministic. The target is 0, plus items revealed or hidden by an
overflow (`+N`) the move changes.

Never count an internal component of the code under change: the refactor will move it and the
baseline stops running (`REACT-PERF-14`).

---

## Related

- `noise-and-stats.md` — iterations, thresholds, reading the table
- `memo-correctness.md` — the tests a passing benchmark cannot replace
- [React - Performance and Concurrency](../../docs/react-performance-and-concurrency.md) § 1 — computation, volume, re-render, DOM
