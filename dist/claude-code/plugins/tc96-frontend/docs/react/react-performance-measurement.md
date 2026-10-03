---
titulo: React - Performance Measurement
Link: https://react.dev/reference/react/Profiler
tags:
  - react
  - performance
  - benchmark
  - agent-context
source: "Official React documentation — Profiler, memo; the field record of a DataGrid memoization refactor (2026-10-03)"
verificado-em: 2026-10-03
---

# React — Performance Measurement

> Baseline · public-API harness · render count · `<Profiler>` · wall time · noise · results file · README section
>
> `REACT-PERF-01` says memoization **MUST** have a measured justification. This note says what counts as a measurement: how it is taken, which number may block a merge, which number may only be reported, and where the result is written.

Entry: [React.js](react-js.md) · Optimization rules: [React - Performance and Concurrency](react-performance-and-concurrency.md)

---

## 1. Two kinds of number

A component benchmark produces two kinds of number, and they are never interchangeable.

| Kind | Examples | Same code, two runs | Used for |
| --- | --- | --- | --- |
| **deterministic** | how many times a consumer renderer ran; commits per interaction | identical | the gate: it can fail a build |
| **timing** | wall time around `act()`, `<Profiler>` `actualDuration`, heap delta | varies | the report: it can only inform |

Field record behind this split: in a 1000-row × 20-column grid, a focus move rendered the consumer's cell function 20000 times before the fix and 2 after, identical on every run. The **same** unchanged code mounted in 5.7 s on one run and 8.5 s on another. A gate on time would have failed unchanged code; a gate on render count never did.

**Render count is counted at the consumer level**: wrap the renderer functions the consumer passes in (`cell`, `renderItem`, a row component given as a prop) with a counter. That number is visible through the public API, so it survives any internal refactor, and it is what the user of the component pays for.

| ID | Rule |
| --- | --- |
| `REACT-PERF-11` | The pass/fail gate **MUST** be a deterministic metric — consumer renderer calls or commits per scenario. Timing **NEVER** fails a build; it is reported. |
| `REACT-PERF-12` | A timing delta below the noise threshold (10% by default, or the spread measured between two baseline runs if larger) is **NEVER** reported as an improvement or a regression. |

---

## 2. Order: baseline first

A baseline taken after the code changed is not a baseline. And a benchmark that imports the internals the refactor will move stops compiling halfway, so the "before" numbers can no longer be reproduced.

1. Write the harness against the **public API** only: the exported component or Hook, the props a consumer passes, and DOM queries on what the user sees (roles, `data-*` hooks the component documents).
2. Run it on the untouched code and save the results file — that is the baseline.
3. Make the change.
4. Run the **same** harness file, same machine, and compare against the saved file.

| ID | Rule |
| --- | --- |
| `REACT-PERF-13` | The baseline **MUST** be recorded before any performance change, with the same harness and on the same machine as the "after" run. |
| `REACT-PERF-14` | The harness **MUST** drive the component only through its public API and count renders through consumer-level wrappers; it **NEVER** imports internals the change may move or rename. |

If the harness itself has to change between before and after (a new scenario, a fixed counter), both runs are redone with the new harness. A comparison across harness versions compares the harnesses, not the code.

---

## 3. Iterations and statistics

| Measure | Minimum | Why |
| --- | --- | --- |
| interaction scenarios | 5 measured iterations + 1 warmup | the first run pays JIT and lazy initialization |
| mount | 3 measured iterations, no warmup, fresh container each | a warm mount is not what the user gets |
| a cold, one-off measure (a mount too expensive to repeat) | labelled `n=1`, never compared | one sample has no spread |
| render count | 1 is enough if every iteration agrees | if iterations disagree, the scenario is not deterministic — fix the scenario before gating on it |

Report the **median**. A p95 is only a p95 with at least 20 samples; below that, the nearest-rank p95 is simply the maximum, and the report says so (`p95 (= max, n=5)`). With `n ≤ 3` a "p95" column is the slowest run, nothing more.

| ID | Rule |
| --- | --- |
| `REACT-PERF-15` | A timing claim **MUST** come from at least 5 measured iterations after warmup (3 for mount, each on a fresh container), reported as the median; a percentile is **NEVER** named as such with fewer than 20 samples. |

---

## 4. What travels with the numbers

A number without its environment cannot be reproduced or compared. JSDOM has no layout; React's development build is several times slower than production; a different runtime version moves every timing.

Recorded with every run: date; runtime and version; DOM implementation and version (and that it has no layout, for JSDOM); React version; build mode (`NODE_ENV`); the data seed; iterations, mount iterations and warmup; CPU model and platform; harness version.

| ID | Rule |
| --- | --- |
| `REACT-PERF-16` | Every results file and every published table **MUST** carry the environment it was measured in: date, runtime and version, DOM implementation and version, React version, build mode, data seed, iteration counts, machine and harness version. |

---

## 5. The results file

The results are a file, not a terminal screenshot, so that the next run can be compared against it by a machine. One file per run, JSON, with this shape (the harness version is the schema version):

| Field | Content |
| --- | --- |
| `schema` | `bench-result/v1` |
| `harness` | the harness's version line, for example `bench-harness v1` |
| `name` | the benchmark's name |
| `environment` | the fields of § 4 |
| `config` | `iterations`, `mountIterations`, `warmup`, `threshold` |
| `results[]` | one entry per case × scenario: `case`, `scenario`, `kind` (`mount` or `interaction`), `n`, `wallMs` and `profilerMs` as `{ median, p95, min, max }`, `renders` as `{ <counter>: { median, min, max } }`, optional `heapMb` |

The key of a result is `case | scenario`. Renaming a scenario breaks the comparison on purpose: a renamed scenario has no baseline.

| ID | Rule |
| --- | --- |
| `REACT-PERF-17` | Results **MUST** be saved as a machine-comparable file in the `bench-result/v1` shape; the before/after comparison **MUST** be produced from two such files, never from numbers copied by hand. |

---

## 6. Correctness after memoization

A memo that makes the benchmark faster and the component wrong is a regression. The benchmark cannot see it: a stale cell renders *fewer* times, which the gate rewards. The failure modes found in practice:

| Failure | Why memo causes it | The test that catches it |
| --- | --- | --- |
| a renderer reads state that is not in the memoized props (table state, a store, `meta`) | the props did not change, so the renderer never re-runs and shows the old value | change that state, assert the rendered value changed |
| a consumer passes an inline callback | the prop changes identity on every render and the memo never skips (`REACT-PERF-03`) | render count stays at its post-fix value when the parent re-renders with a new inline function |
| a prop exists only to invalidate the memo (a version, a primitive copy of a selection) | someone removes it as "unused" and the memo stops refreshing | a test that **fails when the prop is removed** |
| a latest-callback wrapper reads a stale closure | the ref is updated during render (`REACT-REF-01`) or not at all | call the stable function after a prop change, assert it used the new value |

| ID | Rule |
| --- | --- |
| `REACT-PERF-18` | Every memoization added for performance **MUST** ship with a test per invalidation path — state read outside the memoized props, callbacks stabilized for consumers, props that exist only to invalidate — and each test **MUST** fail when that path is removed. |

---

## 7. The README section

The component's README carries the result, so that the next person changing it knows what the numbers were and how to reproduce them. Section `## Benchmark`, in this order:

1. **Reproduce** — the two commands: save the baseline, compare against it.
2. **Environment** — the § 4 fields in one paragraph, plus which code "before" and "after" are, and the noise threshold.
3. **Table** — case, scenario, wall before/after/Δ, profiler before/after/Δ, renders before/after, heap before/after.
4. **Reading** — two to four sentences: what moved beyond the noise, what stayed inside it, and anything that still renders more than expected, with the reason.

| ID | Rule |
| --- | --- |
| `REACT-PERF-19` | A performance change **MUST** update the component README's `## Benchmark` section with the reproduce commands, the environment, the before/after table and a short reading that separates real deltas from noise. |

---

## 8. Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| measuring after the change, "from memory" for before | no baseline exists | `REACT-PERF-13` |
| benchmark imports `components/row.tsx` | the refactor moves it; before can no longer run | `REACT-PERF-14` |
| CI fails on +12% wall time | same code varies more than that between runs | `REACT-PERF-11` |
| "mount got 4% slower" in the PR | inside the noise band | `REACT-PERF-12` |
| p95 from three runs | it is the max | `REACT-PERF-15` |
| a table with no date, no versions | cannot be reproduced or compared | `REACT-PERF-16` |
| numbers pasted from a terminal into the README | nothing can be re-compared | `REACT-PERF-17` |
| memo shipped without a stale-state test | the benchmark rewards the bug | `REACT-PERF-18` |

---

## Related

- [React - Performance and Concurrency](react-performance-and-concurrency.md) — what to change once the measurement points at a cause (`REACT-PERF-01..10`)
- [React.js](react-js.md) · [React - Patterns](react-patterns.md) · [React - Refs and DOM](react-refs-and-dom.md)

## Sources consulted

Verified on 2026-10-03:

- [Profiler](https://react.dev/reference/react/Profiler) — `onRender`, `actualDuration`, the overhead caveat
- [memo](https://react.dev/reference/react/memo) — shallow comparison, why one unstable prop cancels it
- Field record: a DataGrid refactor (rows and cells memoized, 200×10 to 1000×20 cases, JSDOM, `bun`), including two baseline runs of unchanged code and an independent review of the memoized code
