---
titulo: Bun - Tests
Link: https://bun.com/docs/test
tags:
  - bun
  - testing
  - reference
  - agent-context
source: "Official documentation — bun.com/docs/test (test runner), Testing Library and migration guides"
verificado-em: 2026-08-20
---

# Bun - Tests — guided reference

> **What this note is.** The single entry point for `bun test` in this vault: for me when consulting, and for coding agents when writing, fixing or reviewing a test. It is not a linear summary of the documentation — it is a **router**. It decides what to load, offers the mental model that makes the rest make sense, and exposes citable rules that a skill or a code review can reference by ID.
>
> **What it is not.** It does not replace the source. When they diverge, [bun.com/docs/test](https://bun.com/docs/test) wins, and this note must be corrected. And it does not decide **what** to test: that is.
>
> **A self-contained family.** These notes live inside the `bun` skill family, not in the tc96 knowledge base, so the family can ship on its own. Names in code spans — `Bun - HTTP e Servidor`, `Bun - Dados e Persistência`, `Monorepo com Bun - estrutura e tooling`, `Storybook - Testes e Interações`, `Elysia`, `Hono` — and IDs from other families (`TS-*`, `SB-*`, `PW-*`, `DRZ-*`) belong to the tc96 knowledge base: useful context when it is installed, never required to apply a `BUN-*` rule.

Inventory verified directly on bun.com on **2026-08-20**, against **Bun 1.4.0** (`latest` on npm on the same date).
See [Sources consulted](#sources-consulted).

---

## 1. How to use this doc

### For a human

Read § 2 once — it is five statements, and three of them contradict the habit brought over from Jest or Vitest. Then use § 4 as an index and § 5 when you are torn between two APIs. The satellites are on-demand reading, never in order.

### For a coding agent

Load in this order, stopping as soon as you have enough:

| Step | Load | When |
| --- | --- | --- |
| 1 | This note (§ 2, § 3, § 5, § 6) | whenever the task involves testing in Bun |
| 2 | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) | whenever you are going to **write or edit** a test file |
| 3 | The satellite of the domain touched | when the task touches mocks, isolation, DOM, coverage — use § 4 to find out which |
| 4 | [Bun](bun.md) § 2 and § 3 | when the test touches a runtime API (`Bun.file`, `Bun.serve`, `bun:sqlite`) |

**Context economy rule:** never load the six satellites. Writing a unit test needs § 2 + § 6 + [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md). Diagnosing "passes alone, fails in the suite" needs § 5.1 + [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) — and nothing else. The three ready-made cuts are in § 7.

### Conventions and vocabulary

All examples are TypeScript and import from `bun:test` explicitly, even where the global would exist (§ 3).

| Term | Meaning in this doc |
| --- | --- |
| **runner** | the `bun test` mode of the same binary that runs the application — it is not a separate package |
| **preload** | script declared in `[test] preload` / `--preload`, evaluated **before** the test files |
| **execution scope** | what lives for the whole invocation: preload hooks, `mock.module()`. It is not reset between files |
| **file scope** | what lives per file: top-level `beforeAll`, module state. It is only reset with `--isolate` |
| **isolation** | a new `globalThis` per file (`--isolate`, implicit in `--parallel`) |
| **worker** | process that receives files under `--parallel`; identified by `BUN_TEST_WORKER_ID` |
| **concurrency** | tests from the **same** file overlapping on a single thread (`test.concurrent`) — it is not parallelism |
| **shard** | deterministic slice of the suite, to split across CI machines (`--shard=i/n`) |
| **false positive** | a green test whose assertion did not execute. It is the category of defect this doc fights the most |

---

## 2. Mental model

Five statements. Almost every mistake an agent makes in `bun test` violates one of them.

**1. The runner is a mode of the runtime, not a tool.** TypeScript, JSX, `paths`, `.env` and loaders already worked before the test existed — there is no transformation step to configure, which is why `ts-jest`, `babel-jest` and the `transform` block have no equivalent. The other side of the same coin: **what the runtime does not resolve, the test does not either** — a Vite plugin, `resolve.alias`, SVG as a component.

**2. The default is one global shared by all files.** One process, one `globalThis`, every file inside it. State left behind by one file is visible in the next. Jest and Vitest do the opposite by default, and that difference is where most of the "passes alone, fails in the suite" comes from. Isolation exists (`--isolate`, implicit in `--parallel`) and **does not fix** the test: it exposes the bill.

**3. Green means "the assertions that ran passed" — not that they ran.** An assertion inside a `catch` that was never reached, a forgotten `await` on a `userEvent`, an `expectTypeOf` that is a no-op, a snapshot re-recorded by reflex: four forms of a green test that verifies nothing. `expect.assertions(n)` exists for that class of defect, and it is the only mechanism that catches it.

**4. A mock has scope, and the scope is rarely what you want.** The three cleanups do different things, and `mock.restore()` does **not** undo `mock.module()` — a module mock is process state. Since the default is one shared global, "leaked" does not mean "affected the next test": it means "affected the rest of the suite".

**5. Test configuration lives in `bunfig.toml`, and the command is only what varies per invocation.** If plain `bun test` does not work in the project, the configuration is in the wrong place. This matters more here than in other runners, because it is the command anyone — or any agent — runs without reading documentation.

> **The inversion that matters.** It is tempting to read `bun test` as "faster Jest, no config". The speed and the absence of config are real, but they come from an architecture choice — one process, one global — that changes what **you** need to guarantee. Jest gave you isolation for free and charged you in configuration and time. Bun gives you speed and zero configuration, and charges you in state discipline. Switching runners without switching discipline is the road to a suite that passes by accident.

---

## 3. Import and environment boundaries

**What comes from `bun:test`:**

```ts
import {
  test, it, describe, expect,
  beforeAll, beforeEach, afterEach, afterAll, onTestFinished,
  mock, spyOn, jest, vi,
  setSystemTime, expectTypeOf,
} from "bun:test";
```

All of this also exists as a global. **Prefer the import**: it is what makes the file pass `tsc --noEmit` without depending on a global declaration, and what makes it explicit, in review, that this `mock` is the runner's.

| Boundary | Rule |
| --- | --- |
| `import { … } from "vitest"` | **rewritten internally** to `bun:test`. Much Vitest test code runs without edits — what does not migrate is the configuration (§ 5.4) |
| `import { … } from "@jest/globals"` | likewise |
| `jest.*` and `vi.*` | exist as compatibility objects; the verified surface is in [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 6 |
| `document`, `window` | **do not exist** by default. They come in via preload, as code ([Bun - Tests - DOM and Components](bun-tests-dom-and-components.md)) |
| `vite.config.ts` / `vitest.config.ts` | **are not read**. Neither `resolve.alias`, nor `define`, nor plugins |
| `jest.config.js` | is not read. The equivalent is `[test]` in `bunfig.toml` |

**Environment imposed by the runner:** `NODE_ENV="test"` (if not already set) and `TZ="Etc/UTC"` (if `TZ` is not set). And the exit code includes a condition that surprises: **an unhandled error outside any test makes the process exit `1` even with every test green** ([Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 6).

---

## 4. API map

Surface verified on bun.com/docs. The **Satellite** column says what to load, **and in which section**.

**This table is a routing index, not an allow-list.** An API absent from here means "not verified in this doc" — consult the source and update the note. When adding an API to a satellite, add the row here.

### Execution, discovery and configuration

| API / flag | What it is for | Satellite |
| --- | --- | --- |
| `bun test` and the four name patterns | what enters the suite | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 2 |
| `root`, `pathIgnorePatterns` | trimming the suite | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 2 |
| positional filter, `-t`/`--test-name-pattern` | running a subset | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 3 |
| `--only`, `--todo` | enabling `test.only` / running the `test.todo` | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 3.3 |
| `--changed[=<ref>]` | only the tests the diff reaches, by import graph | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 3.4 |
| `--watch`, `--hot`, `--inspect`, `--inspect-brk` | development loop and debugging | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 4 |
| `--randomize`, `--seed`, `--rerun-each` | hunting order dependency and flaky tests | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 4 |
| `--timeout`, `--bail`, `--retry`, `--smol` | execution behavior | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 4 |
| `bunfig.toml [test]` (17 keys) | persistent configuration | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 5 |
| `NODE_ENV`, `TZ`, exit code | the environment the runner imposes | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 6 |

### Writing and assertion

| API | What it is for | Satellite |
| --- | --- | --- |
| `test`, `it`, `describe` | file structure | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 2 |
| third timeout argument, `{ retry }`, `{ repeats }` | per-test control | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 3 |
| `test.skip`/`todo`/`failing`/`only`/`if`/`skipIf`/`todoIf` | modifiers, and what each one communicates | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 4 |
| `test.each`, `describe.each`, `%p`/`%s`/`$prop` | table of cases | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 5 |
| matcher catalog, and what is **not** implemented | assertion | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 6.1 |
| `toBe` × `toEqual` × `toStrictEqual` | choosing the right equality | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 6.2 |
| `.toThrow`, `.rejects`, `.resolves` | testing errors | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 6.3 |
| `expect.assertions`, `expect.hasAssertions` | guaranteeing the assertion ran | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 7 |
| `expect.extend` | custom matcher | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 8.1 |
| `expectTypeOf` | type expectation (no-op at runtime) | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 8.2 |
| `toMatchSnapshot`, `toMatchInlineSnapshot`, property matchers, `-u` | snapshots | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 9 |

### Mocks and time

| API | What it is for | Satellite |
| --- | --- | --- |
| `mock()`, `jest.fn()`, `vi.fn()` | observable function | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 2 |
| `spyOn(obj, "metodo")` | spying (and optionally replacing) | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 2 |
| `.mock.calls`/`.results`/`.lastCall`, `mockReturnValueOnce`, `mockResolvedValue` | inspection and return script | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 2 |
| `mock.clearAllMocks()`, `jest.resetAllMocks()`, `mock.restore()` | **the three cleanups, and what each one does not do** | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 3 |
| `mock.module(especificador, factory)` | module mock — process scope | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 4 |
| `setSystemTime()`, `jest.now()` | freezing the date | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 5 |
| `useFakeTimers`, `advanceTimersByTime`, `runAllTimers`, `getTimerCount` | making time pass | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 5 |
| `TZ` / `process.env.TZ` in a test | time zone in a date assertion | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 5 |
| `vi` object | Vitest compatibility surface | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 6 |

### Lifecycle, isolation and parallelism

| API / flag | What it is for | Satellite |
| --- | --- | --- |
| `beforeAll`, `beforeEach`, `afterEach`, `afterAll` | lifecycle, scoped by the place of declaration | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 2 |
| `onTestFinished` | cleanup registered at the point of use | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 2 |
| `[test] preload` as execution scope | global setup — and what changes under isolation | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 3 |
| `--parallel`, `--isolate`, `--no-isolate` | isolation and parallelism between files | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 4 |
| `BUN_TEST_WORKER_ID`, `JEST_WORKER_ID` | external resource per worker | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 4 |
| `test.concurrent`, `test.serial`, `--concurrent`, `--max-concurrency`, `concurrentTestGlob` | concurrency inside the file | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 5 |
| `--shard=i/n`, `--timings`, `--update-timings` | splitting across CI machines | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 7 |

### DOM and components

| API | What it is for | Satellite |
| --- | --- | --- |
| `GlobalRegistrator.register()` (happy-dom) | injecting `document`/`window` | [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 2 |
| `expect.extend(matchers)` from `jest-dom` | registering `toBeInTheDocument` and friends | [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 2 |
| `matchers.d.ts`, `/// <reference lib="dom" />` | types | [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 2 |
| `cleanup()` | clearing the `document` between tests | [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 2 |
| `userEvent`, `findBy*`, `waitFor`, `act` | interaction and waiting | [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 3 |
| loaders, `import.meta.env`, `paths` in the test | what Vite used to do and here is something else | [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 4 |
| stubs for `ResizeObserver`, `matchMedia` | what happy-dom does not implement | [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 5 |

### Coverage, reporters and CI

| API / flag | What it is for | Satellite |
| --- | --- | --- |
| `--coverage`, `--coverage-reporter`, `coverageDir` | measuring coverage | [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 2 |
| `coverageThreshold` | **the gate — and the two conditions that silently turn it off** | [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 3 |
| `--reporter=junit`, `--reporter-outfile`, `--dots` | output format | [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 4 |
| GitHub Actions annotations | failure on the PR line, with no configuration | [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 4 |
| workflow with `--parallel`, `--shard`, `--changed` | CI recipe | [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 5 |

**Deliberately outside this map:** custom reporter via the WebKit Inspector Protocol (mentioned in [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 4, without detail), compatibility with `node:test`, and the full list of `expectTypeOf` matchers. They exist in the source; their absence here means **"not verified in this doc"**.

---

## 5. Decision trees

### 5.1 "Passes alone, fails in the suite"

The most common symptom, and the one with the most distinct causes.

```
Does the test pass in isolation and fail together with the others?
├── Fails only when another file runs first
│   → state in the shared global. Detect: bun test --randomize
│     ├── Is it an unrestored spy?        → mock.restore() in the preload — BUN-TEST-02
│     ├── Is it mock.module()?            → process scope; register it in the preload — BUN-TEST-03
│     └── Is it module/fixture state?     → move the setup inside the file — BUN-TEST-09
│        (test.serial does NOT solve it: it sequences inside the file)
├── Fails only with --parallel
│   ├── Two tests fight over a database/port/directory → derive from BUN_TEST_WORKER_ID — BUN-TEST-10
│   └── The preload brings up something expensive (server, migration) → preload hooks wrap EACH file — BUN-TEST-24
├── Fails only when another test from the SAME file runs first
│   ├── Is there test.concurrent / --concurrent?  → state shared between concurrent tests — BUN-TEST-23
│   └── Component: the DOM has leftovers from the previous test → cleanup() in afterEach — BUN-TEST-26
└── Fails intermittently, with no order pattern
    → bun test --rerun-each 20; suspect a missing await and a real timer
```

Detail in [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 6.

### 5.2 "I need to replace a dependency"

```
Does the code under test receive the dependency from outside (parameter, constructor, context)?
├── YES  → pass a double. No mock, no global scope, no restoration.
│          It is the preferred form. [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 4
└── NO
    ├── Is the dependency a method of an object the test has in hand?
    │   → spyOn(obj, "metodo")  +  guaranteed mock.restore() — BUN-TEST-02
    └── Is it an imported module?
        ├── Does importing the original have a side effect (connection, listener, env)?
        │   → mock.module() in [test] preload — BUN-TEST-04 (there is no other way)
        └── No side effect?
            → mock.module() works, but it is PROCESS scope — BUN-TEST-03
              If three files mock the same module, the dependency wanted to be a parameter.
```

### 5.3 "I need to control time"

```
Do I need a fixed date (new Date(), Date.now(), Intl)?
└── setSystemTime(new Date("…"))         — it is NOT useFakeTimers — BUN-TEST-20

Do I need time to PASS (setTimeout, debounce, polling, retry with backoff)?
└── jest.useFakeTimers() + jest.advanceTimersByTime(ms)

Do I need both?
└── the two combine; setSystemTime works together with timer advancement

Will I assert on a FORMATTED date or time?
└── pin the time zone: TZ=… on the command, or process.env.TZ in the test — BUN-TEST-21
    (the runner's Etc/UTC only holds while TZ is not in the environment)

Am I tempted to use sleep?
└── never. In a component: findBy*/waitFor. In a timer: fake timers.
```

### 5.4 "I came from Jest / from Vitest"

Test code almost always runs without edits — imports from `vitest` and from `@jest/globals` are rewritten to `bun:test`, and the `vi` object exists. **What does not migrate is the configuration**, because it lived in a file Bun does not read.

| Vitest / Jest | In `bun test` | Note |
| --- | --- | --- |
| `setupFiles` / `setupFilesAfterEnv` / `test.setupFiles` | `[test] preload` | same role; the **scope** differs under `--parallel` — `BUN-TEST-24` |
| `globals: true` | does not exist, and is not needed | globals already exist **and** are importable from `bun:test` |
| `environment: "jsdom"` / `"happy-dom"` | happy-dom via `GlobalRegistrator` in the preload | it is not a config key; it is code — `BUN-TEST-07` |
| `testEnvironment: "jsdom"` (Jest) | likewise. **jsdom is not offered as a supported alternative** | [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 1 |
| `vi.mock("./mod", factory)` | `mock.module("./mod", factory)` (`vi.mock` exists) | **do not assume hoisting** — `BUN-TEST-04` |
| `vi.fn()` / `vi.spyOn()` | `mock()` / `spyOn()` — the `vi.*` forms also exist | |
| `vi.resetAllMocks()` / `vi.restoreAllMocks()` | see the table of the three cleanups | the scopes do **not** match Vitest's |
| `vi.useFakeTimers()` | `jest.useFakeTimers()` | the `Date` constructor is **not** swapped — `BUN-TEST-20` |
| `testTimeout` | `--timeout <ms>` (default `5000`) | becomes a flag, not config |
| `bail` | `--bail` | **file** granularity |
| `coverage.*` | `[test] coverage*` | the threshold is a **fraction** (`0.9`), and has two silent conditions — `BUN-TEST-27`, `BUN-TEST-28` |
| `testPathIgnorePatterns` / `test.exclude` | `[test] pathIgnorePatterns` | |
| `rootDir` / `test.root` | `[test] root` | |
| `transform`, `extensionsToTreatAsEsm`, `haste`, `watchman`, `verbose` | **do not exist** | irrelevant: TS and JSX are native |
| `resolve.alias` from `vite.config.ts` | **ignored** | Bun reads `compilerOptions.paths` |
| `define` from `vite.config.ts` | `define` at the top of `bunfig.toml` | `import.meta.env.VITE_*` is a separate case |
| Vite plugins (SVGR, CSS Modules…) | **do not exist** | it is the real gap — [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 4 |
| `/// <reference types="bun-types/test-globals" />` | option to type the globals in a project file | or import from `bun:test`, which is the preferred form here |

### 5.5 "How do I assemble the CI command"

```
Small suite (< ~2 min)?
└── bun test --parallel --coverage
    + separate step of tsc --noEmit — BUN-TEST-18

Large suite?
└── matrix of --shard=i/n, with --timings cached between runs
    (without the cache, the split goes back to being by file count)

Want fast feedback on the PR?
└── extra job with --changed=origin/<base>
    Never as a merge gate: the import graph does not see env, migration or fixture

Need a report for the CI (GitLab, Jenkins)?
└── --reporter=junit --reporter-outfile=./junit.xml — BUN-TEST-29
    On GitHub Actions, the annotations come out with no configuration at all

Going to turn on a coverage threshold?
└── keep "text" among the reporters — BUN-TEST-27
    and do not trust "statements" — BUN-TEST-28
```

Full recipe in [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 5.

### 5.6 "The component test does not work"

```
"document is not defined"
└── the happy-dom preload is missing — BUN-TEST-07

"toBeInTheDocument is not a function"
└── expect.extend(matchers) is missing — BUN-TEST-12
    (import "@testing-library/jest-dom" alone does NOT register anything)

"Cannot find name 'document'" (only in tsc)
└── /// <reference lib="dom" /> at the top of the file

"screen.getByRole found multiple elements"
└── cleanup() in afterEach is missing — BUN-TEST-26

The assertion runs before the re-render
└── await on the userEvent; and prefer findBy* over waitFor + getBy*

The component imports SVG/CSS/import.meta.env and breaks
└── it is the boundary with Vite — [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 4
    The way out that skips the list: pure component, configuration by prop

Depends on size, layout or scrolling
└── happy-dom does not measure. Browser test — `Storybook - Testes e Interações`
```

---

## 6. Normative rules

Rules citable by ID. A skill, a review prompt or a PR comment can reference `BUN-TEST-27` without repeating the text. **There are 29 rules** — the whole `BUN-TEST-*` family, distributed as follows: Execution 4 · Writing 8 · Mocks 5 · Lifecycle 5 · DOM 4 · Coverage 3.

**Convention:** `MUST` / `NEVER` are normative. A violation is a bug, not a matter of style.
**Origin marking:** a rule without a mark comes from an explicit statement in the source. A rule marked **†** is a decision of this doc — consistent with the source, but not dictated by it. A review may argue a † rule; it may not argue the others without going to the source.

> **The satellite is canonical.** The rows below reproduce the satellite's text **verbatim**. In any divergence, the satellite wins and this table is the bug — § 7 requires citing by ID without paraphrasing, and two divergent copies of a normative rule make that impossible.

### `01`, `13`–`15` — execution and configuration · [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md)

| ID | Rule |
| --- | --- |
| `BUN-TEST-01` | A test file **MUST** match one of the discovery patterns (`*.test.*`, `*_test.*`, `*.spec.*`, `*_spec.*`) — a file outside the pattern does not run and produces no warning. |
| `BUN-TEST-13` | A positional filter that points to a **file** **MUST** start with `./` or `/` — without the prefix it is a path-substring filter, and a glob is **NEVER** accepted. |
| `BUN-TEST-14` | `seed` in `bunfig.toml` **MUST** come together with `randomize = true` — without it, it has no effect, and the failure is silent. |
| `BUN-TEST-15` | A CI pipeline **MUST** pin the Bun version (`oven-sh/setup-bun` with a fixed `bun-version`, or a tagged image) — the runner's flags and defaults change between minors, and `latest` turns that into a failure with no commit. † |

### `05`, `06`, `08`, `11`, `16`–`19` — writing and assertions · [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md)

| ID | Rule |
| --- | --- |
| `BUN-TEST-05` | `--update-snapshots` (`-u`) **NEVER** appears in the CI test command, and the `__snapshots__/` directory **MUST** be versioned — a snapshot outside the repository is not an assertion. |
| `BUN-TEST-06` | A test whose assertion lives in a `catch`, callback or conditional branch **MUST** declare `expect.assertions(n)` or `expect.hasAssertions()`. |
| `BUN-TEST-08` | `test.only` is **NEVER** used as a way to disable the other tests — without `bun test --only` it filters nothing. |
| `BUN-TEST-11` | A test that documents a known bug **MUST** use `test.failing`, **NEVER** `test.skip` — `failing` warns when the bug is fixed. |
| `BUN-TEST-16` | `retry` and `repeats` **NEVER** coexist in the same test — the source declares the combination invalid. |
| `BUN-TEST-17` | An asynchronous test **MUST** use `async`/`await`. The `done` parameter **NEVER** in new code — if declared and not called, the test hangs until the timeout and fails for the wrong reason. † |
| `BUN-TEST-18` | `expectTypeOf` **NEVER** counts as an executed check — it is a no-op at runtime, and the CI **MUST** run `tsc --noEmit` in a separate step. |
| `BUN-TEST-19` | A snapshot of an object with a non-deterministic field (generated id, date, hash) **MUST** declare property matchers (`{ id: expect.any(String) }`) — without them the snapshot always fails and the team starts running `-u` by reflex. † |

### `02`–`04`, `20`, `21` — mocks and time · [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md)

| ID | Rule |
| --- | --- |
| `BUN-TEST-02` | `spyOn` **MUST** have guaranteed restoration (`mock.restore()` in `afterEach` or in the preload) — without it the spy leaks into the following tests. |
| `BUN-TEST-03` | `mock.module()` is **NEVER** undone by `mock.restore()`; a module mock **MUST** be registered in `--preload` or treated as global state of the test process. |
| `BUN-TEST-04` | A mock whose purpose is to prevent an import side effect (connection, listener, top-level env read) **MUST** be registered in `--preload` — mocking after the import does not undo what already ran. |
| `BUN-TEST-20` | Freezing the date **MUST** use `setSystemTime` — `useFakeTimers` does not swap the `Date` constructor in `bun:test`, unlike Jest. |
| `BUN-TEST-21` | An assertion on a **formatted** date or time **MUST** pin the time zone explicitly (`TZ` on the command, or `process.env.TZ` in the test) — the runner's `Etc/UTC` only holds while `TZ` is not set in the environment. † |

### `09`, `10`, `22`–`24` — lifecycle and isolation · [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md)

| ID | Rule |
| --- | --- |
| `BUN-TEST-09` | A test that depends on state left by **another file** **MUST** be fixed by moving the setup inside the file itself — `test.serial` **NEVER** solves this (it sequences inside the file) and no flag restores the shared global under `--isolate`; detection is `bun test --randomize`. |
| `BUN-TEST-10` | A test that uses a shared external resource (database, port, directory) **MUST** derive it from `BUN_TEST_WORKER_ID` when the suite runs with `--parallel`. |
| `BUN-TEST-22` | `onTestFinished` **NEVER** in a concurrent test — the source declares it is not supported; use `test.serial`. |
| `BUN-TEST-23` | A test marked `concurrent` (or a suite under `--concurrent`) **NEVER** shares mutable state with another test in the same file — whatever depends on order or on shared state **MUST** be `test.serial`. † |
| `BUN-TEST-24` | Setup declared in `preload` **MUST** be idempotent and cheap, or parameterized per worker — under `--parallel`/`--isolate` the preload-level hooks wrap **each file**, not the run. |

### `07`, `12`, `25`, `26` — DOM and components · [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md)

| ID | Rule |
| --- | --- |
| `BUN-TEST-07` | DOM registration (`GlobalRegistrator.register()`) **MUST** happen in `[test] preload`, **NEVER** inside a test file. |
| `BUN-TEST-12` | A `@testing-library/jest-dom` matcher **MUST** be registered with `expect.extend` in a preload — the package `import` alone registers nothing in `bun:test`. |
| `BUN-TEST-25` | `GlobalRegistrator.register()` and the `@testing-library/*` packages **MUST** live in separate preloads, in this order — in a single file, the packages **MUST** be loaded by `await import()` after the registration. |
| `BUN-TEST-26` | A file that renders a component **MUST** have `cleanup()` in `afterEach` (preferably in the preload) — the `document` is shared between the file's tests. |

### `27`–`29` — coverage and CI · [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md)

| ID | Rule |
| --- | --- |
| `BUN-TEST-27` | `coverageThreshold` **MUST** come together with the `text` reporter enabled in every run outside `--parallel` — with only `--coverage-reporter=lcov` the process exits `0` even below the threshold. |
| `BUN-TEST-28` | `coverageThreshold` **NEVER** depends on the `statements` key — it is accepted and **not** applied; the real gate is `lines` and `functions`. |
| `BUN-TEST-29` | `--reporter=junit` **MUST** come together with `--reporter-outfile` — the source declares the pair mandatory. |

### 6.1 The minimum path

These seven **travel with any test task**, even when the corresponding satellite was not loaded. Entry criterion: the violation is **silent** — there is no error in dev, and the test stays green.

| ID | Why it is silent |
| --- | --- |
| `BUN-TEST-02` | the spy leaks and the defect shows up in another file, hours later |
| `BUN-TEST-03` | the module stays mocked for the rest of the process, with no warning |
| `BUN-TEST-05` | the snapshot starts recording the regression instead of catching it |
| `BUN-TEST-06` | the test passes **without executing any assertion at all** |
| `BUN-TEST-09` | the suite passes in today's order and breaks in tomorrow's |
| `BUN-TEST-27` | the coverage gate exits `0` below the threshold |
| `BUN-TEST-28` | the declared threshold does not exist |

---

## 7. Skill contract

How a Bun test skill should consume this doc.

### What to load

```
ALWAYS:   Bun - Tests.md § 2 (mental model)
          Bun - Tests.md § 3 (import boundaries)
          Bun - Tests.md § 6.1 (the minimum path)

WHEN WRITING a new test:
          Bun - Tests - Writing and Assertions.md

WHEN REPLACING a dependency (mock, spy, double) or controlling time:
          Bun - Tests - Mocks and Time.md   +   § 5.2 / § 5.3

WHEN DIAGNOSING "passes alone, fails in the suite" or flaky:
          § 5.1   +   Bun - Tests - Lifecycle and Isolation.md

WHEN TESTING a React component:
          Bun - Tests - DOM and Components.md

WHEN TOUCHING CI, coverage or reporters:
          Bun - Tests - Coverage and CI.md

WHEN CONFIGURING the project from scratch:
          Bun - Tests - Execution and Configuration.md § 5
          + Bun - Tests - DOM and Components.md § 2 (if there is a component)

DO NOT:   load the six satellites at once
          invent a flag, a bunfig key or a matcher signature
          — whatever is not in § 4 MUST be checked on bun.com/docs
```

Three ready-made cuts, for the most frequent tasks:

| Task | Load |
| --- | --- |
| "write tests for this module" | § 2 + § 6.1 + Writing and Assertions |
| "this test is flaky" | § 5.1 + Lifecycle and Isolation |
| "configure testing in this project" | § 3 + Execution and Configuration § 5 + (DOM § 2 if there is a component) |

### How to cite

Review findings cite the ID and the satellite, and do not paraphrase:

> `BUN-TEST-27` — `coverageThreshold` declared with `coverageReporter = ["lcov"]`. Outside `--parallel`, the threshold is not checked and the job exits `0` below the number.
> See [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md).

### Invariants the skill must enforce

1. **An assertion that may not run needs a count.** Every `expect` inside a `catch`, callback or `if` comes with `expect.assertions(n)` (`BUN-TEST-06`). It is the invariant that catches generated code the most.
2. **Every `spyOn` has guaranteed restoration**, and the guarantee lives in the preload, not in the file (`BUN-TEST-02`).
3. **A module mock is process state.** If the skill writes `mock.module()`, it has decided on an effect that lasts the whole run — and that needs to be intentional (`BUN-TEST-03`, `BUN-TEST-04`).
4. **No `sleep`.** Waiting is `findBy*`, `waitFor` or fake timers. `Bun.sleep` in a test is a finding.
5. **Type checking is a separate step.** No delivery is verified without `tsc --noEmit` (`BUN-TEST-18`).
6. **Verify before asserting.** A flag, a `bunfig.toml` key or a matcher that is not in § 4 was not verified in this doc: consult bun.com/docs and **update the note**.
7. **Confirm the version.** `bun --version` before assuming a flag exists; the doc has already been ahead of the published binary (see [Sources consulted](#sources-consulted)).

### When creating a new skill

Derive it from **one** satellite, not from this whole note: a component-test skill loads [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) + § 2 + § 6.1, and nothing else. Record at the start of the skill which satellite is its source, so that a doc update propagates. It is the same contract as [Bun](bun.md) § 7 and `React.js` § 7.

---

## 8. Bridges to the stack

| Boundary | Where the decision lives |
| --- | --- |
| **What to test, and whether it is worth testing** | — the runner does not decide that, and this doc does not try |
| **External integration: mock, double or real service** | — § 5.2 chooses the *mechanism*, not the *strategy* |
| **What to assert in a component** | — an available DOM does not imply testing the implementation |
| **Component in a real browser** | `Storybook - Testes e Interações` — the addon-vitest runs in Playwright and does **not** run under `bun test`; the monorepo keeps two runners by design |
| **HTTP server under test** | `Bun - HTTP e Servidor` — `Bun.serve` in `beforeAll`, `server.stop()` in `afterAll`, port per worker (`BUN-TEST-10`) |
| **Database in tests** | `Bun - Dados e Persistência` — in-memory `bun:sqlite` for unit; database per worker for integration |
| **Installation and version pin in CI** | [Bun - Package Manager](bun-package-manager.md) — `bun ci`, versioned lockfile |
| **Typed route handler under test** | `Hono - Validação e RPC` · `Elysia - Schema e Eden` — `app.request()` / Eden skip bringing up a server |
| **Mutation and cache on the frontend** | `TanStack Query - Mutations e Invalidação` — new `QueryClient` per test, `retry: false` |
| **Trunk-based and test gate** | |

---

## Related

- [Bun](bun.md) — runtime hub; this structure is its `BUN-TEST-*` family
- [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) · [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) · [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) · [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) · [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) · [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md)
- [Bun - Runtime and APIs](bun-runtime-and-apis.md) · [Bun - Package Manager](bun-package-manager.md) · `Bun - HTTP e Servidor` · `Bun - Dados e Persistência`
- · ·
- `Storybook - Testes e Interações` · `React.js` · `TypeScript` · `Github Actions`

## Sources consulted

Verified on **2026-08-20**, against `bun` **1.4.0** (`npm view bun dist-tags` → `latest: 1.4.0`):

- [Test runner](https://bun.com/docs/test) · [Writing tests](https://bun.com/docs/test/writing-tests) · [Test configuration](https://bun.com/docs/test/configuration)
- [Runtime behavior](https://bun.com/docs/test/runtime-behavior) · [Finding tests](https://bun.com/docs/test/discovery) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel)
- [Lifecycle hooks](https://bun.com/docs/test/lifecycle) · [Mocks](https://bun.com/docs/test/mocks) · [Snapshots](https://bun.com/docs/test/snapshots) · [Dates and times](https://bun.com/docs/test/dates-times)
- [DOM testing](https://bun.com/docs/test/dom) · [Code coverage](https://bun.com/docs/test/code-coverage) · [Test Reporters](https://bun.com/docs/test/reporters)
- [Using Testing Library with Bun](https://bun.com/docs/guides/test/testing-library) · [Migrate from Jest](https://bun.com/docs/guides/test/migrate-from-jest)
- API reference: [`jest` object](https://bun.com/reference/bun/test/jest) · [`vi`](https://bun.com/reference/bun/test/vi) · [`useFakeTimers`](https://bun.com/reference/bun/test/jest/useFakeTimers) · [`advanceTimersByTime`](https://bun.com/reference/bun/test/jest/advanceTimersByTime) · [`Test.only`](https://bun.com/reference/bun/test/Test/only)
- [Bun 1.4](https://bun.com/blog/bun-v1.4) and [Bun v1.3.6](https://bun.com/blog/bun-v1.3.6) — `--parallel`, `--isolate`, `--shard`, `--timings`, `--changed`, fake timers
- [Jest compatibility tracking issue](https://github.com/oven-sh/bun/issues/1825) — cited by the doc itself as the status reference

### What the verification contradicted

- **The default is a single global shared by all files**, in a single process. Per-file isolation only exists with `--isolate` (implicit in `--parallel`). It is the opposite of what Jest and Vitest train you to expect.
- **`coverageThreshold` has two silent conditions nobody assumes:** the `statements` key is **accepted and not applied**, and **outside `--parallel` the check only runs with the `text` reporter enabled** — runs with only `--coverage-reporter=lcov` exit `0` regardless of the number. A project may have a coverage gate that never closed.
- **`mock.restore()` does not undo `mock.module()`.** It is written in the source, and it is the easiest scope difference in the API to violate.
- **The three cleanups do different things:** `clearAllMocks` preserves the implementation, `resetAllMocks` removes it but does not restore the spy's original, only `restore` restores.
- **`useFakeTimers` does not swap the `Date` constructor** in `bun:test` — the source says it is to avoid Jest's `Date !== Date` bug. Freezing the date is `setSystemTime`.
- **`test.only` requires `bun test --only`.** And here the source pages diverge: the API reference describes `only` as already skipping the other tests; the writing-tests page shows the flag as the trigger.
- **A `test.todo` that passes is reported as a failure** under `--todo`, to force removal of the mark.
- **`--shard` is described in two ways in the source itself:** contiguous slice by path (parallelism page) and deterministic round-robin (1.4 release post). Do not depend on locality.
- **The positional filter does not accept a glob**, and a file path needs to start with `./` or `/`.
- **`-t` matches against the name prefixed by the `describe` labels**, separated by a space — the `describe` text is an address.
- **`seed` in `bunfig.toml` does nothing without `randomize = true`.**
- **`bun test` sets `TZ=Etc/UTC`** unless overridden, and `NODE_ENV=test` unless already set.
- **An unhandled error outside any test makes the process exit `1`**, even with every test green.
- **A timeout throws an uncatchable exception and kills the child processes** created by the test with `Bun.spawn`, `Bun.spawnSync` or `node:child_process`.
- **A `beforeAll` that throws skips every test in the scope** — the failure arrives disguised as a "skip", not as an error.
- **`repeats: N` runs N+1 times**, and `retry` with `repeats` is an invalid combination.
- **If the test declares `done`, it needs to call it — or it hangs** until the timeout.
- **`expect.addSnapshotSerializer()` is not implemented.** A custom snapshot serializer does not exist.
- **`expectTypeOf` is a no-op at runtime.** The check requires `tsc` in a separate step.
- **`onTestFinished` does not work in a concurrent test.**
- **`--isolate` re-runs the preload scripts for each file**, besides creating a new `globalThis`, clearing the module registries, closing servers/sockets/watchers/subprocesses and cancelling timers.
- **Preload-level hooks wrap each file under `--parallel`** — "once per run" stops holding exactly where it hurts most.
- **`import "@testing-library/jest-dom"` is not enough**, and the two source pages diverge: the DOM page shows the plain import, the Testing Library guide uses `expect.extend(matchers)`. The one that works is the guide's.
- **The order of the preloads matters:** `@testing-library/*` needs to be evaluated after `GlobalRegistrator.register()`.
- **At runtime, `import logo from "./logo.svg"` resolves to the absolute path on disk**, not to a URL as in Vite.
- **jsdom is not offered as an alternative.** happy-dom is the documented path.
- **Imports from `vitest` and from `@jest/globals` are rewritten to `bun:test`.** Much Vitest test code runs without edits; what does not migrate is the configuration.
- **`--reporter=junit` requires `--reporter-outfile`**, and the XML includes neither per-test stdout/stderr nor a precise timestamp per case.
- **On GitHub Actions, the annotations come out with no configuration at all.**

### What changed since the previous verification (2026-08-15)

- **The doc × binary divergence is resolved.** On 2026-08-15, the `--parallel` page showed output labeled `bun test v1.4.0` while npm's `latest` was 1.3.14; today `latest` **is** 1.4.0. The `--parallel`, `--isolate`, `--shard` and `--timings` flags are in the published binary. The operational warning goes away; the rule to **pin the version** stays (`BUN-TEST-15`), because it was the one that absorbed the lesson.
- **`--changed` entered the map** (filter by import graph, introduced in 1.4) — and with it the boundary between a PR job and a merge gate.
- **The two silent conditions of `coverageThreshold`** were not recorded: the previous note treated `statements` as a valid metric and the threshold as an unconditional gate. Both statements were wrong.
- **The structure went from a 717-line note to hub + six satellites**, and the `BUN-TEST-*` family went from 12 to 29 rules. IDs `01`–`12` **keep their text and meaning**: old citations remain valid, and § 6 says which satellite owns each one.

### What was not verified (declared, not invented)

- **`import "./Botao.css"` and CSS Modules under `bun test`**: the source documents `css` as a loader and the behavior in the bundler, and does not declare the behavior at runtime. [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 4 gives the probe and the way out.
- **`IntersectionObserver` in happy-dom**: the source stubs `ResizeObserver` and `matchMedia` and does not mention this one.
- **Idempotency and cost of `GlobalRegistrator.register()` under per-file re-execution**: it is happy-dom behavior, not declared by Bun's doc. Measure before assuming `--parallel` speeds up a DOM suite.
- **Hoisting of `mock.module`/`vi.mock`**: the source does not declare that they are hoisted as in Vitest. Treat them as not hoisted.
- **Detail of the custom reporter protocol** (`TestReporter` and `LifecycleReporter` domains): it exists, and was not explored here.
- **`--only` does not appear in the CLI flag list** the source publishes, although the writing-tests page uses it. Behavior treated as verified by the prose; the listing, as incomplete.
