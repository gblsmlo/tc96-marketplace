# Noise and statistics — what a number may claim

> How many iterations, how to read the median and the p95, and when a delta is real. The rules are
> `REACT-PERF-11`, `REACT-PERF-12` and `REACT-PERF-15` in
> [React - Performance Measurement](../../../docs/react/react-performance-measurement.md).

---

## 1. Field record: how noisy is noisy

Same machine, same commit, same harness, JSDOM, `bun`:

| Measure | Run A | Run B | Spread |
| --- | ---: | ---: | ---: |
| 1000×20 grid, mount wall time | 5.7 s | 8.5 s (another day: 7.3 s) | up to ~45% |
| 1000-item list, mount wall time (example harness) | 59.5 ms | 66.5 ms | +12% |
| 1000×20 grid, focus move, cell renders | 20000 | 20000 | 0 |
| 1000-item list, select click, item renders | 2 | 2 | 0 |

Unchanged code moved 12% to 45% in time and 0 in render count. That is the whole argument for
gating on renders and only reporting time.

---

## 2. Iterations

| Env var | Default | Minimum for a timing claim |
| --- | --- | --- |
| `BENCH_ITERATIONS` | 5 | 5 measured, after warmup |
| `BENCH_WARMUP` | 1 | 1 |
| `BENCH_MOUNT_ITERATIONS` | 3 | 3, each on a fresh container, no warmup |
| `BENCH_THRESHOLD` | 10 | — the noise band in percent |

Lower them (`BENCH_ITERATIONS=1 BENCH_WARMUP=0`) to iterate quickly on a fix while you only watch
render counts — those need one deterministic sample. Restore the defaults for the numbers that go
in the README.

A mount that costs seconds can be measured once (`mount: { iterations: 1 }` or a dedicated case)
and labelled `n=1`; it is reported, never compared.

---

## 3. Reading the table

| Column | Reads as |
| --- | --- |
| `n` | measured samples (warmup excluded) |
| `wall med` | median wall time around `act()`: render + commit + Effects + the JSDOM work. The closest thing to "what the user waited", minus paint |
| `prof med` | median `<Profiler>` `actualDuration` sum: React render time of the profiled subtree only |
| `p95` | nearest rank; **with n < 20 it is the slowest sample**, and the harness prints that footnote |
| `renders` | median of each counter; a `~` suffix means iterations disagreed |
| `heap MB` | median heap delta of a mount after a forced GC; only when the runtime exposes GC |

Wall time much larger than profiler time means the cost is outside React's render: DOM work,
Effects, layout reads, the event handler itself. Profiler time close to wall time means render is
the cost — that is where memoization or less volume helps
([React - Performance and Concurrency](../../../docs/react/react-performance-and-concurrency.md) § 1).

---

## 4. When a delta is real

| Delta | Verdict |
| --- | --- |
| render count changed | real, every time — explain it |
| timing within ±threshold | noise; write "no change" (`REACT-PERF-12`) |
| timing beyond threshold, render count unchanged | re-run the baseline and the current back to back; if it holds twice, report it as "possible", with both runs |
| timing beyond threshold **and** render count moved the same way | real; the render count is the explanation |

To measure the noise band of a specific machine, run the baseline twice before changing anything
and compare the two files: the largest timing delta between them is the floor for that machine. If
it is above 10%, use it as `--threshold`.

---

## 5. Environment drift

`bench-compare` warns when runtime, DOM, React, `NODE_ENV` or CPU differ between the two files.
Timing across a drift is not comparable; render counts usually still are (a React upgrade can
change commit counts — re-baseline after one).

Development build only: `act` does not exist in React's production build, and the harness refuses
to run with `NODE_ENV=production`. Absolute times are therefore development-build times; say so in
the README environment line.

---

## Related

- `scenario-catalog.md` — making a scenario deterministic
- `readme-bench-section.md` — how the numbers are published
