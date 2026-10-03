---
nome: react-component-performance
descricao: Diagnose and fix a React component already confirmed slow, with a measurement that proves it, citing `REACT-PERF-*` IDs — eleven re-render hazard probes, a baseline taken before any change with a copyable JSDOM benchmark harness that drives only the public API, render counts of consumer renderers as the deterministic gate and Profiler and wall time as the report, fixes in the order the performance rules set, a before/after comparison, the correctness tests memoization needs, and the README Benchmark section — use when a grid, list, kanban, tree or form is measurably slow on mount, focus, selection, sort, scroll or typing, when a memo, useMemo or useCallback needs the measurement REACT-PERF-01 demands, or when a performance refactor needs a CI gate. Do not use to review code for rule violations, which is react-review, to write a new component, which is react-developer, to decide where files live, which is react-structure, nor for slowness that comes from the network or the data cache, which is tanstack-query.
tipo: skill
familia: react
idioma: en
fonte: "[React - Performance Measurement](../docs/react-performance-measurement.md)"
docs:
  - /reactjs/react.dev
tags:
  - skill
  - react
  - performance
---

# react-component-performance

> **Circuit breaker, before anything else:** if a fix requires changing how an external store or table subscribes (`useSyncExternalStore`, a table's state atoms, a selector library), **stop and return** with the measurement and the proposal. That is an architecture decision with its own blast radius, not a memo. Probe 11 shows where it applies.

> **Source of this skill:** [React - Performance Measurement](../docs/react-performance-measurement.md) (`REACT-PERF-11..19`, how to measure), with [React - Performance and Concurrency](../docs/react-performance-and-concurrency.md) (`REACT-PERF-01..10`, what to change) and the [React.js](../docs/react-js.md) hub as the router.
> This skill **does not contain** the rules — it says what to run, in what order, and how to report. For a rule's text, open the doc.
> **API surface:** resolve it through Context7 — `/reactjs/react.dev` (`<Profiler>`, `memo`, `useDeferredValue`). The rule and the ID come from the family's docs.

Contract this skill implements: [React.js](../docs/react-js.md) § 7 ("Skill contract").

---

## When to use

A component that **already exists** and is **measurably slow**, or a memoization that needs the measurement `REACT-PERF-01` demands.

| If the question is… | Go to |
| --- | --- |
| is this code correct? a rule violation, including memo without measurement | `react-review` |
| writing a **new** component or Hook | `react-developer` |
| where the file lives, who imports whom | `react-structure` |
| slow because of requests, waterfalls, refetching | `tanstack-query` |
| a slow form: re-render per keystroke, `watch` everywhere | `react-hook-form` (`RHF-*` has its own performance rules) |

"It feels slow" is not yet this skill: Step 0 turns it into a scenario and a number, or ends the task.

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [React - Performance Measurement](../docs/react-performance-measurement.md) | how to measure; the IDs this skill cites most |
| 2 | [React - Performance and Concurrency](../docs/react-performance-and-concurrency.md) § 1 | the order of attack and the computation × volume × re-render × DOM diagnosis |
| 3 | `references/id-map.md` | where each `REACT-PERF-*` is declared |
| 4 | the reference the current step names | only that one |

**Never load all the satellites.** The hub's context-economy rule.

| File | What for |
| --- | --- |
| `references/scenario-catalog.md` | which scenarios per view type, how to drive them, the expected render count after a good fix |
| `references/noise-and-stats.md` | iterations, the noise band, reading median, p95 and render counts |
| `references/memo-correctness.md` | the four ways memo goes stale, a test for each, the checklist |
| `references/readme-bench-section.md` | the README `## Benchmark` template and a filled example |
| `references/id-map.md` | generated: `REACT-PERF-*` → doc → section |
| `scripts/probes.sh` | the eleven re-render hazard probes |
| `scripts/bench-harness.ts` · `scripts/bench-compare.ts` | the harness and the comparator; consumers copy both |
| `scripts/bench-result.schema.json` | JSON Schema of the results file |
| `scripts/example/bench-example.ts` | a runnable adapter against a tiny list |

---

## Step 0 — Confirm the slowness

Name **one** user action, the size where it hurts, and how it was observed (DevTools recording, a user report with steps, a frame-drop trace). No action and no size → no task: report that and stop. Check two exits before measuring anything:

- **React Compiler active** (`REACT-PERF-02`) → hand-written memo is the wrong lever; measure, but expect the fix to be elsewhere.
- **The cost is volume** — thousands of nodes on screen — → virtualization or pagination (`REACT-PERF-09`); memo never makes a mount cheaper.

---

## Step 1 — Probe

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-component-performance/scripts/probes.sh src/features/orders
```

Block 0 reads the environment (React version, Compiler, virtualization library, an existing harness or results file). Blocks 1–11 point at inline props to components, render functions, linear lookups inside `.map`, unstable keys, components declared inside components, Effects that set state, and store subscriptions. **A probe is a lead for the Profiler, not a finding** — nothing gets fixed in this step.

---

## Step 2 — Baseline, before touching the code

Install the harness in the project — copy, not import, so the project owns it:

```bash
mkdir -p bench
cp ${CLAUDE_PLUGIN_ROOT}/skills/react-component-performance/scripts/bench-harness.ts bench/
cp ${CLAUDE_PLUGIN_ROOT}/skills/react-component-performance/scripts/bench-compare.ts bench/
```

Requirements: `bun`, and `react`, `react-dom`, `jsdom` resolvable from `bench/` (dev dependencies). Keep the `bench-harness v1` line at the top of both files.

Write `bench/<component>.bench.ts`, modeled on `scripts/example/bench-example.ts`:

1. **Public API only** (`REACT-PERF-14`): import the component from its public entry, never from the folders the fix may move.
2. **Count at the consumer level** (`REACT-PERF-11`): wrap the renderer the consumer passes (`cell`, `renderItem`, a row function) with `countRenders(fn, 'cells')`.
3. **Mount through `tools.render`** so the `<Profiler>` and the `commits` counter are wired.
4. **Scenarios from `references/scenario-catalog.md`**: always `mount` and `parent re-render`, plus the action named in Step 0. Two sizes, an order of magnitude apart; data from `seededRandom(seed)`.

Run it on the untouched code and keep the file (`REACT-PERF-13`, `REACT-PERF-17`):

```bash
bun bench/<component>.bench.ts --json bench/<component>.base.json
```

If a scenario prints a render count with `~`, it is not deterministic: fix the scenario now, not after the change.

---

## Step 3 — Diagnose

Read the baseline table with [React - Performance and Concurrency](../docs/react-performance-and-concurrency.md) § 1:

| What the table shows | Cause | Lever |
| --- | --- | --- |
| interaction renders **every** item (`cells=20000` on a focus move) | unnecessary re-render | state placement → composition → stable props → `memo` |
| `parent re-render` > 0 | a prop changes identity every render (probes 2–4) | stabilize the prop; latest-callback for consumer callbacks |
| `commits=2` for one action | a cascade, usually an Effect setting state (probe 8) | derive during render (`REACT-PAT-01`) |
| few renders, high profiler time | computation | `useMemo` on the computation, or a Map/Set instead of a lookup inside `.map` (probe 6) |
| mount is the problem | volume | `REACT-PERF-09` |
| wall ≫ profiler | cost outside render: handlers, Effects, DOM | profile the handler, not React |

For a single interaction, the React DevTools profiler ("why did this render?") on the same scenario confirms which prop changed.

---

## Step 4 — Fix, in the order the rules set

The order of attack in [React - Performance and Concurrency](../docs/react-performance-and-concurrency.md) § 1, cheapest first: no unnecessary state → state in the right place → composition → less rendered volume → concurrency → memoization. Every `memo`, `useMemo` and `useCallback` that remains must point at a scenario in the table (`REACT-PERF-01`), with its props stabilized (`REACT-PERF-03`).

Iterate quickly with `BENCH_ITERATIONS=1 BENCH_WARMUP=0` while you watch render counts only.

---

## Step 5 — Compare

```bash
bun bench/<component>.bench.ts --compare bench/<component>.base.json --gate --json bench/<component>.after.json
```

`--gate` exits 1 if any render counter rose in any scenario, or a scenario disappeared (`REACT-PERF-11`). Timing above the threshold prints a warning and never fails (`REACT-PERF-12`); environment drift between the two files prints a warning too. Claims about time follow `references/noise-and-stats.md`.

---

## Step 6 — Correctness after memo

`references/memo-correctness.md`: for every memo added, a test per invalidation path — state read outside the memoized props, consumer callbacks (inline allowed, latest one called), invalidation-only props — and each one **fails when the path is removed** (`REACT-PERF-18`). Delete the path once and watch it fail. The existing suite passes unchanged.

---

## Step 7 — Record

Fill the component README's `## Benchmark` section from the two results files, using `references/readme-bench-section.md` (`REACT-PERF-19`). Commit the baseline and after files next to the bench script if the project wants the gate in CI (`--compare <committed baseline> --gate`).

---

## Self-check before delivering

| # | Check | ID |
| --- | --- | --- |
| 1 | the baseline file predates the first code change, same harness, same machine | `REACT-PERF-13` |
| 2 | the bench imports only the public API; counters wrap consumer renderers | `REACT-PERF-14` |
| 3 | `--compare --gate` exits 0; every render count is equal or lower | `REACT-PERF-11` |
| 4 | no timing delta inside the threshold is called an improvement or a regression | `REACT-PERF-12` |
| 5 | timing claims come from ≥ 5 iterations (mount ≥ 3); no "p95" with n < 20 | `REACT-PERF-15` |
| 6 | the environment is in the results file and the README | `REACT-PERF-16` |
| 7 | the comparison came from two `bench-result/v1` files | `REACT-PERF-17` |
| 8 | every memo has its stale-state tests, each seen failing once | `REACT-PERF-18` |
| 9 | the README `## Benchmark` section is updated, reading included | `REACT-PERF-19` |
| 10 | every remaining memo maps to a measured scenario, props stable; Compiler checked | `REACT-PERF-01` · `REACT-PERF-03` · `REACT-PERF-02` |
| 11 | no external store subscription changed — or the task stopped and returned | circuit breaker |

---

## Example

A 1000-row × 20-column grid lags on arrow keys. Probes: rows are not memoized, a column menu passes inline callbacks, the table subscribes through its own atoms (probe 11 — the fix must not change that). Baseline with a harness that imports only `DataGrid`, `useDataGrid` and the public cell renderer, wrapping each column's `cell` in `countRenders`: focus move `cells=20000`, mount 7.3 s. Diagnosis: unnecessary re-render. Fix: focus and selection passed as primitives to the one row that owns them, rows and cells memoized, consumer `onCellValueChange` behind a latest-callback. Compare: focus move `cells=2`, select click `2`, sort `0`, group collapse one group's worth; mount +7%, inside the noise band, reported as unchanged. Review found a cell renderer reading sorting state outside its props: documented as a renderer contract and covered by a test. README section filled from the two files.

Runnable miniature: `scripts/example/bench-example.ts` — `EXAMPLE_NO_MEMO=1` removes the row memo, and `--compare --gate` fails with `renderItem rose 2 -> 1000`.

---

## Related

- `react-review` — a rule review; hands a confirmed slowness to this skill
- `react-developer` — writing the component; this skill measures it afterwards
- [React - Performance Measurement](../docs/react-performance-measurement.md) — source of this skill
- [React - Performance and Concurrency](../docs/react-performance-and-concurrency.md) — what to change
- [React.js](../docs/react-js.md) — the hub and the skill contract
