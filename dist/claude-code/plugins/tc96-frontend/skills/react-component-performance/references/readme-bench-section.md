# The README `## Benchmark` section — template

> What `REACT-PERF-19` asks the component README to carry, in the order it asks for it
> ([React - Performance Measurement](../../../docs/react/react-performance-measurement.md) § 7). Fill it from two
> `bench-result/v1` files, never from numbers typed by hand (`REACT-PERF-17`).

---

## Template

````markdown
## Benchmark

Reproduce from the repo root:

```bash
bun bench/<component>.bench.ts --json bench/<component>.base.json     # before your change
bun bench/<component>.bench.ts --compare bench/<component>.base.json --gate
```

Environment: <date>, <runtime> <version>, JSDOM <version> (no layout), React <version> development
build, data seed <seed>, <iterations> iterations per scenario (mount: <n>, fresh container, no
warmup; <warmup> warmup elsewhere), medians, harness `bench-harness v1`. "Before" is <commit or
description>, "after" is <commit or description>; both from the same harness on the same machine.
<Counter> counts how many times the consumer's <renderer> ran. Differences under <threshold>% are
noise: <the measured spread, e.g. "the same code mounted in 5.7 s and 7.3 s in two baseline runs">.

| Case | Scenario | Wall before (ms) | Wall after (ms) | Δ wall | Profiler before (ms) | Profiler after (ms) | Δ profiler | Renders before | Renders after | Heap before (MB) | Heap after (MB) |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| … | mount | … | … | … | … | … | … | … | … | … | … |
| … | <interaction> | … | … | … | … | … | … | … | … | - | - |

Reading the table: <what moved beyond the noise and why>; <what stayed inside the noise band —
usually mount>; <anything that still renders more than expected, with the reason>.
````

---

## Filling it

| Field | Source |
| --- | --- |
| date, runtime, JSDOM, React, seed, iterations | `environment` and `config` of the **after** file; if before and after differ, the comparison is invalid — re-run |
| before / after numbers | the `median` of each `wallMs`, `profilerMs`; each `renders.<counter>.median`; `heapMb` |
| Δ | `bench-compare` prints them; copy, do not recompute |
| the noise sentence | the spread between two baseline runs, if you measured it (`noise-and-stats.md` § 4); otherwise the threshold |

**Reading** is two to four sentences. It never says "faster" for a delta inside the threshold, and
it explains every render count that is not the expected one from `scenario-catalog.md` (a group
collapse that renders one group's worth is expected; say why).

---

## Example (field record)

From a DataGrid memoization refactor, two rows of fourteen:

| Case | Scenario | Wall before (ms) | Wall after (ms) | Δ wall | Profiler before (ms) | Profiler after (ms) | Δ profiler | Cell renders before | Cell renders after | Heap before (MB) | Heap after (MB) |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1000x20 | mount | 7343.7 | 7877.2 | +7% | 6762.7 | 7232.4 | +7% | 20000 | 20000 | 334.8 | 361.5 |
| 1000x20 | focus move | 1456.3 | 49.5 | -97% | 768.6 | 21.0 | -97% | 20000 | 2 | - | - |

Reading: interactions re-render a handful of cells instead of the whole page; mount is +7%, inside
the ~10% noise band, so it is reported as unchanged.

---

## Related

- `noise-and-stats.md` — what a delta may claim
- `scenario-catalog.md` — the expected render count per scenario
