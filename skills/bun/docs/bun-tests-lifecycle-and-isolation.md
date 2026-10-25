---
titulo: Bun - Tests - Lifecycle and Isolation
Link: https://bun.com/docs/test/lifecycle
tags:
  - bun
  - testing
  - agent-context
source: "Official documentation — https://bun.com/docs/test/lifecycle, /parallel"
verificado-em: 2026-08-20
---

# Bun - Tests - Lifecycle and Isolation

> **When the code runs and what it shares.** The five hooks and the scope defined by the place of declaration · the full order in a nested tree · the preload as execution scope — and what happens to it under `--isolate` · `--parallel`, `--isolate`, `--no-isolate` and the list of what isolation resets · concurrency inside the file (`test.concurrent`, `test.serial`, `--max-concurrency`) · order dependency between files, which no flag fixes · `--shard` and `--timings` for CI.
>
> **What it is not:** discovery and filter flags ([Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md)) · restoring mocks ([Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 3) · the complete CI recipe ([Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 5).

Entry: [Bun - Tests](bun-tests.md) · Normative base: [Bun - Tests](bun-tests.md) § 6 · Family: `BUN-TEST-*` (this note owns `09`, `10`, `22`, `23`, `24`)

---

## 1. Concept: the default is the opposite of what Jest trained you to expect

With no flag at all, `bun test` runs **every file in the same process, with a single shared `globalThis`**. There is no per-file isolation. State left behind by `a.test.ts` — a spy, a mocked module, a module variable, an open connection — is there when `b.test.ts` starts.

Jest and Vitest do the opposite by default (one environment per file), and that difference is where most of the "passes alone, fails in the suite" of those who migrate comes from. Two wrong readings, both common:

- **"This is a Bun bug."** It is not: it is the reason the runner is fast. One process, one global, no cost of rebuilding the environment per file.
- **"So just turn on `--isolate` and forget about it."** Also not: `--isolate` makes the leak between files stop existing, and **exposes** the test that only passed because of it. The flag does not fix the test — it shows the bill.

The mental map that organizes this entire note: there are **three scopes**, and each mechanism belongs to one.

| Scope | Who lives in it | How it is restarted |
| --- | --- | --- |
| **Test** | `beforeEach`/`afterEach`, `onTestFinished` | on every test, always |
| **File** | `beforeAll`/`afterAll` at the top of the file, module state | only with `--isolate` (implied by `--parallel`) |
| **Execution** | hooks declared in `preload`, `mock.module()` | never, within one invocation |

---

## 2. The five hooks

| Hook | Scope |
| --- | --- |
| `beforeAll` / `afterAll` | once per **scope where it was declared**: `describe`, file, or — in a preload — the entire execution |
| `beforeEach` / `afterEach` | before/after each test of the scope |
| `onTestFinished` | after **all** the `afterEach` of one specific test |

**The scope is the place of declaration, not a configuration option.** A `beforeAll` at the top of the file covers the file; inside a `describe`, it covers the block; in a preload, it covers the execution.

### Order in a nested tree

With hooks in the file, in an outer `describe` and in an inner one, the source declares this sequence for each test:

```
1.  beforeAll   of the file
2.  beforeAll   of the outer describe
3.  beforeAll   of the inner describe
4.  beforeEach  of the outer
5.  beforeEach  of the inner
6.  test body
7.  afterEach   of the inner
8.  afterEach   of the outer
9.  afterAll    of the inner
10. afterAll    of the outer
11. afterAll    of the file
```

`before*` goes from the outside in, `after*` from the inside out. That is what allows the common pattern: database in the file's `beforeAll`, transaction in the `describe`'s `beforeEach`, rollback in the `afterEach`.

### Two verified behaviors that change decisions

- **A `beforeAll` that throws skips every test in its scope.** The report shows skipped tests, not failed ones — and you have to read the hook's output to know why. Setup that can fail for an environmental reason (port in use, database down) deserves an explicit error message, because the failure will arrive disguised as a "skip".
- **`onTestFinished` is not supported in a concurrent test.** The source says to use `test.serial` in that case.

```ts
import { test, onTestFinished } from "bun:test";

test("cria e limpa o arquivo temporário", async () => {
  const caminho = await criarTemp();
  onTestFinished(async () => { await rm(caminho); });   // registered at the point of use
  expect(await Bun.file(caminho).exists()).toBe(true);
});
```

`onTestFinished` exists for cleanup **registered where the resource is created** — which avoids the distance between `beforeEach` and `afterEach` when only one test needs that resource.

| ID | Rule |
| --- | --- |
| `BUN-TEST-22` | `onTestFinished` **NEVER** in a concurrent test — the source declares it is not supported; use `test.serial`. |

---

## 3. Preload: the only execution scope — and what `--isolate` does to it

```ts
// test/setup.ts
import { beforeAll, afterAll } from "bun:test";

let servidor: ReturnType<typeof Bun.serve>;

beforeAll(async () => { servidor = await subirServidorDeTeste(); });
afterAll(async () => { await servidor.stop(); });
```

```toml
[test]
preload = ["./test/setup.ts"]
```

> **This example stops being "once" the moment you turn on `--parallel`. Read before copying it.**
>
> "Declared in a preload, covers the entire execution" holds in the **default** (single process, shared global). With `--parallel` — the CI recommendation of § 4 — the source is explicit: *"Preload-level `beforeAll`/`afterAll` hooks still wrap every file, since a worker never knows which file is its last."* The `beforeAll` above starts running **once per test file**: fifty files, fifty servers brought up and torn down, probably fighting over the same port.
>
> The three ways out, in order of preference:
>
> | Way out | How | Cost |
> | --- | --- | --- |
> | Setup **per file and isolated** | keep it in the preload, but derive port/database/directory from `BUN_TEST_WORKER_ID` (§ 4) | repeated startup, no collision — it is the path that scales |
> | Setup **idempotent and cheap** | `globalThis.__servidor ??= await subir()` — works under `--no-isolate`, **not** under `--isolate`, which wipes the global between files | works in only one configuration |
> | Resource **outside** the runner | `docker compose up` or a CI service before `bun test`; the preload only connects | more infra, zero surprise — |
>
> The rule that remains: **preload setup is idempotent and cheap, or parameterized by worker.** Expensive, one-time setup has nowhere to fit.

| ID | Rule |
| --- | --- |
| `BUN-TEST-24` | Setup declared in `preload` **MUST** be idempotent and cheap, or parameterized by worker — under `--parallel`/`--isolate` the preload-level hooks wrap **each file**, not the execution. |

---

## 4. `--parallel`, `--isolate` and what isolation resets

```bash
bun test --parallel                 # one worker per core; IMPLIES --isolate
bun test --parallel=4               # four workers
bun test --parallel --no-isolate    # one global per worker, not per file
bun test --isolate                  # fresh global per file, without parallelizing
```

| Flag | What it does | When |
| --- | --- | --- |
| `--parallel[=N]` | distributes the **files** across N worker processes (default: number of cores); files enter the queue of whichever worker becomes free | CI, and a large local suite |
| `--isolate` | fresh `globalThis` per file, in the same process | diagnosing dependency between files without changing the parallelization |
| `--no-isolate` | files share the global and the module registry within the worker | a suite of many small files, when you **know** there is no leak |

### What `--isolate` resets between files

The sequence declared by the source:

1. creates a fresh `globalThis`;
2. clears the ESM and CommonJS module registries;
3. closes servers, sockets, file watchers and subprocesses;
4. cancels timers and restores fake timers;
5. **re-runs the `--preload` scripts** in the fresh global.

Bun keeps the transpiled source and the bytecode cached across globals, so the cost is not reparsing everything — it is re-evaluating modules and preloads.

Item 3 deserves a note: **isolation closes leaked resources.** A test that forgets a server running does not hang the suite under `--isolate`. That is a safety net, not a license — the leak is still a bug, and without `--isolate` it hangs the process.

### Worker: what each one receives

Each worker receives `BUN_TEST_WORKER_ID` and `JEST_WORKER_ID` (1-based index). That is how each worker is given its own database, port or directory:

```ts
const id = process.env.BUN_TEST_WORKER_ID ?? "1";
export const dbName = `app_test_${id}`;
export const porta = 3100 + Number(id);
```

Without this, `--parallel` turns a correct test into an intermittent failure: two workers writing to the same table, or fighting over the same port.

### What the coordinator does

- **`--bail` has file granularity:** once the limit is reached, the coordinator does not start new files; the ones already running finish.
- **Coverage, JUnit XML and snapshot writing are merged.** `--parallel --coverage --reporter=junit --reporter-outfile=junit.xml` produces **one** report ([Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 4).
- The execution flags are passed through to the workers.

| ID | Rule |
| --- | --- |
| `BUN-TEST-10` | A test that uses a shared external resource (database, port, directory) **MUST** derive it from `BUN_TEST_WORKER_ID` when the suite runs with `--parallel`. |

---

## 5. Concurrency **inside** the file

`--parallel` parallelizes files across processes. Concurrency is something else: tests of the **same** file that overlap, cooperatively, on a single thread and a single global.

```ts
test.concurrent("busca A", async () => { … });
test.concurrent("busca B", async () => { … });   // overlaps with A
test.serial("aplica migração", async () => { … }); // never overlaps
```

```bash
bun test --concurrent               # treats ALL tests as concurrent
bun test --max-concurrency=8        # ceiling of simultaneous tests (default 20)
```

```toml
[test]
concurrentTestGlob = "**/*.integration.test.ts"   # concurrency only where it pays off
```

**What concurrency buys:** I/O wait time. Ten tests that each wait 200 ms of network finish in ~200 ms, not in 2 s. **What it does not buy:** CPU — it is a single thread. A test that computes does not get faster by being concurrent.

**What it charges:** concurrent tests share the global. Two tests that write to the same module variable, the same table or the same `document` start interfering in a time-dependent way — the worst category of flaky. `test.serial` is the opt-out for the test that needs order, and a global `--concurrent` is only safe in a suite written for it.

And the detail that bites: **`onTestFinished` does not work in a concurrent test** (`BUN-TEST-22`).

| ID | Rule |
| --- | --- |
| `BUN-TEST-23` | A test marked `concurrent` (or a suite under `--concurrent`) **NEVER** shares mutable state with another test of the same file — whatever depends on order or on shared state **MUST** be `test.serial`. † |

---

## 6. Order dependency: two problems with the same name

It is worth separating them, because the remedy for one does not work for the other:

| Symptom | Scope | Remedy |
| --- | --- | --- |
| Tests of the **same file** interfere with each other under concurrency | inside the file | `test.serial` |
| A file only passes because **another file** ran before and left state in the global | between files | **fix the test** — there is no flag |

`test.serial` sequences **inside** the file. Applying it to a test that depends on another file changes nothing: the problem is not the internal order, it is that the shared global has disappeared. And **there is no flag that restores the shared global under `--isolate`** — that is exactly what `--isolate` removes. `--parallel --no-isolate` gives one global per *worker*, but the distribution of files across workers is not your test's order: it makes the failure intermittent instead of solving it, which is worse.

How it is detected, before CI:

```bash
bun test --randomize            # random order; the suite needs to pass this way
bun test --randomize --seed 42  # reproduces the order that revealed the failure
bun test --isolate              # fresh global per file, without parallelizing — isolates the cause
bun test --rerun-each 10        # repeats each file; catches flaky that is not about order
```

The fix always has the same shape: **move the state the file depends on inside it** — `beforeAll`/`beforeEach` in the file itself, or a fixture that builds what the test needs. If the cost of that is high, the signal is that the setup belongs in the preload, and then it needs to be idempotent (`BUN-TEST-24`).

| ID | Rule |
| --- | --- |
| `BUN-TEST-09` | A test that depends on state left by **another file** **MUST** be fixed by moving the setup inside the file itself — `test.serial` **NEVER** solves this (it sequences inside the file) and no flag restores the shared global under `--isolate`; detection is `bun test --randomize`. |

---

## 7. `--shard` and `--timings`: splitting across machines

```bash
bun test --shard=1/4        # first of four deterministic slices
bun test --update-timings   # records the duration per file
bun test --timings=.timings.json --shard=2/4
```

- **`--shard=i/n`** runs the i-th of n slices, with no coordinator between machines: each runner decides on its own what belongs to it, deterministically, with a 1-based index (the same convention as Jest and Vitest).
- **`--timings=<file>`** reads each file's duration from previous runs and cuts the slices by **total time**, not by file count. `--update-timings` records it. Combined with `--shard`, each shard writes only its own files — the outputs are disjoint and combine without a merge. Paths that do not yet exist in the table are ignored.

Without `--timings`, four shards with the same number of files can take very different times: one integration file is worth thirty unit ones. That is the concrete gain, and it requires the timings file to be **persisted between CI runs** (runner cache, or a committed artifact).

> **Recorded source divergence.** The parallelism page describes the `--shard` distribution as *files sorted by path, with each machine taking a contiguous slice*; the 1.4 release post describes the same flag as *deterministic round-robin*. Both forms are deterministic and require no coordination — the practical consequence (you can run independent shards and the union covers the suite) is identical. What changes is **locality**: under a contiguous slice, neighboring files land on the same machine; under round-robin, they do not. Do not count on locality in either reading, and do not assume that an entire folder runs in the same shard.

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| Expensive `beforeAll` in the preload (bringing up a server, migrating a database) with `--parallel` on | the preload hooks wrap **each file**; it becomes one server per file, fighting over the port | derive from `BUN_TEST_WORKER_ID`, make it idempotent, or bring it up outside the runner — `BUN-TEST-24` |
| Tests sharing the same table or port when turning on `--parallel` | the workers collide and the failure looks flaky | derive the resource from the worker id — `BUN-TEST-10` |
| `test.serial` on a test that depends on another **file** | `serial` sequences inside the file; the dependency between files remains | move the setup inside the file — `BUN-TEST-09` |
| `--parallel --no-isolate` to "fix" an order-dependent test | gives back one global per worker, but not your order; the failure becomes intermittent | fix the test — `BUN-TEST-09` |
| Global `--concurrent` in a suite that was not written for it | tests of the same file start interfering by timing | concurrency via `concurrentTestGlob` or per test — `BUN-TEST-23` |
| `onTestFinished` inside `test.concurrent` | not supported; the cleanup does not run | `test.serial`, or `afterEach` — `BUN-TEST-22` |
| Relying on the declaration order between files ("the setup one runs first") | discovery order is not a contract, and `--parallel` destroys it | explicit fixture in the file that needs it |
| `--shard` without `--timings` in a suite with very uneven files | one shard takes 8 minutes and another 40 seconds | record and cache timings — § 7 |
| Assuming an entire folder lands in the same shard | the distribution guarantees no locality in either of the source's two readings | do not depend on locality — § 7 |
| Leaked global state "that bothers nobody" | without `--isolate` it travels to every following file | `mock.restore()` in the preload and per-file fixtures — [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 3 |

---

## Review checklist

- [ ] Does the suite pass with `--randomize`? If not, there is order dependency — and `test.serial` is not the remedy. → `BUN-TEST-09`
- [ ] Are external resources derived from `BUN_TEST_WORKER_ID`? → `BUN-TEST-10`
- [ ] No `onTestFinished` in a concurrent test? → `BUN-TEST-22`
- [ ] Do concurrent tests not share mutable state? → `BUN-TEST-23`
- [ ] No expensive, non-idempotent setup in the preload, with `--parallel` on? → `BUN-TEST-24`
- [ ] Does the suite pass with `--isolate` (that is, without depending on the shared global)?
- [ ] If CI uses `--shard`, is the `--timings` file persisted between runs?
- [ ] Are hooks declared in the narrowest scope that solves the problem?

---

## Related

- [Bun - Tests](bun-tests.md) — hub, mental model, API map, decision trees
- [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) · [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) · [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) · [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) · [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md)
- — bringing a dependency up outside the runner
- — what to test, before how

## Sources consulted

Verified on **2026-08-20**: [Lifecycle hooks](https://bun.com/docs/test/lifecycle) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel) · [Test configuration](https://bun.com/docs/test/configuration) · [Test runner](https://bun.com/docs/test) · [Bun 1.4](https://bun.com/blog/bun-v1.4).
