---
titulo: Bun - Tests - Execution and Configuration
Link: https://bun.com/docs/test
tags:
  - bun
  - testing
  - agent-context
source: "Official documentation — https://bun.com/docs/test (test runner), /discovery, /configuration, /runtime-behavior"
verificado-em: 2026-08-20
---

# Bun - Tests - Execution and Configuration

> How the runner **finds** the file, **filters** what runs and **where it takes** configuration from · discovery and exclusions · positional filter × `-t` × `--only` × `--todo` × `--changed` · `bunfig.toml [test]` key by key · the environment the runner imposes (`NODE_ENV`, `TZ`, exit code) · watch, hot, inspect, randomize, bail, retry, timeout.
>
> **Does not cover:** what to write inside the file ([Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md)) · isolation, `--parallel`, `--shard` ([Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md)) · coverage and reporters ([Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md)) · general runtime flags outside tests ([Bun - Runtime and APIs](bun-runtime-and-apis.md)).

Entry: [Bun - Tests](bun-tests.md) · Normative base: [Bun - Tests](bun-tests.md) § 6 · Family: `BUN-TEST-*` (this note owns `01`, `13`, `14`, `15`)

---

## 1. Concept: the runner is a mode of the runtime, not a separate tool

`bun test` is neither a binary nor a package: it is the same runtime that executes `bun ./index.ts`, switched into a mode that discovers files, injects test globals and reports results. Three practical consequences fall out of that, and they explain almost every difference from Jest and Vitest:

1. **There is no transformation step to configure.** TypeScript, JSX, `paths` from `tsconfig.json`, `.env` — everything the runtime already resolves, the runner resolves the same way. `ts-jest`, `babel-jest`, `@swc/jest` and the `transform` block have no equivalent because they have no function ([Bun - Runtime and APIs](bun-runtime-and-apis.md) § 1).
2. **Test configuration lives where the runtime's does**: `bunfig.toml`, not a parallel `jest.config.js`. And what the runner reads is the `[test]` section — plus the top-level keys (`define`, `loader`), which apply to any execution.
3. **What the runtime does not resolve, the runner does not either.** A Vite plugin, `resolve.alias` from `vite.config.ts`, turning an SVG into a component: none of that exists here, because none of it existed in the runtime ([Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 4).

The decision left to you is **the cut**: which files come in, which run in this invocation, and which environment they see. That is the subject of this note.

---

## 2. Discovery: what enters the suite

`bun test` scans the working directory recursively for four patterns:

- `*.test.{js|jsx|ts|tsx|mjs|cjs|mts|cts}`
- `*_test.{…}`
- `*.spec.{…}`
- `*_spec.{…}`

And it excludes, without you asking: `node_modules`, hidden directories (starting with `.`) and files that are not JavaScript/TypeScript.

**A file outside the pattern does not run and does not warn.** It is the cheapest failure mode to avoid and the most irritating to discover: `pedidos.tests.ts` (plural), `testePedidos.ts`, `pedidos-test.ts` (hyphen) — none of them match. The suite stays green because the file never existed for the runner.

Two scope cuts, and the difference between them matters:

| Option | Where | What it does |
| --- | --- | --- |
| `root` | `bunfig.toml` | limits **where the runner scans**. Outside that root, the file is not even considered |
| `pathIgnorePatterns` | `bunfig.toml` (`--path-ignore-patterns` on the CLI) | removes from discovery paths that would match, by glob |

```toml
[test]
root = "src"
pathIgnorePatterns = ["**/fixtures/**", "**/*.e2e.test.ts"]
```

`root` is the structural cut (monorepo, package); `pathIgnorePatterns` is the cut by category (fixtures that look like tests, an e2e suite that runs in another job). Using `pathIgnorePatterns` to exclude an entire folder works, but it hides the intent — if the suite only lives in `src`, declare `root`.

| ID | Rule |
| --- | --- |
| `BUN-TEST-01` | A test file **MUST** match one of the discovery patterns (`*.test.*`, `*_test.*`, `*.spec.*`, `*_spec.*`) — a file outside the pattern does not run and produces no warning. |

---

## 3. Filters: what runs in this invocation

Five independent mechanisms, and they combine.

```bash
bun test                              # everything discovery found
bun test pedidos api                  # filter by path SUBSTRING
bun test ./src/pedidos.test.ts        # specific file — the ./ is mandatory
bun test -t "calcula frete"           # filter by test NAME (regex)
bun test --only                       # only what is marked test.only/describe.only
bun test --todo                       # includes the test.todo in the run
bun test --changed                    # only files reached by what changed in git
```

### 3.1 Positional: path substring, not glob

The positional argument matches a **piece of the path**. `bun test utils` runs `src/utils/string.test.ts` and `lib/utils/array_test.js`. Glob is **not** supported: `bun test "src/**/*.test.ts"` does not do what it looks like.

To point at a file, the path must start with `./` or `/`. Without the prefix, `pedidos.test.ts` is read as a substring — which, by coincidence, usually works, and that is exactly why the rule goes unnoticed until the day two files match.

### 3.2 `-t`: regex against the full name

`-t` / `--test-name-pattern` matches against the test name **prefixed by the labels of the `describe`s that contain it**, separated by spaces. A `test("soma corretamente")` inside `describe("Operações de matemática")` is reached by `-t "Operações de matemática soma"` — and also by `-t "soma"`, because it is a partial regex.

Design consequence: **the `describe` text is an address.** Renaming a `describe` breaks the filter of whoever was debugging that block, and a generic `describe` (`"testes"`, `"unit"`) helps nobody filter anything.

### 3.3 `--only` and `--todo`: the two filters that invert the habit

- **`test.only` only takes effect with `bun test --only`.** In Jest, a forgotten `.only` silences the rest of the file. Here, it filters nothing without the flag — and the practical effect inverts: the forgotten `.only` does not break CI, but it also did not do what the author thought it did. And if someone adds `--only` to the CI command, the whole suite disappears at once.
- **`test.todo` does not run by default.** With `bun test --todo`, the todos execute, a todo failing is **not** an error, and a todo that **passes** is marked as a failure — to force removing the mark or fixing the test.

> **Divergence between pages of the source, recorded.** The API reference describes `only` as *"Skips all other tests, except this test"*, while the writing-tests page shows `bun test --only` as the command that runs only the marked ones. The two statements do not coincide. This note follows the writing-tests page — the flag is the trigger — and the operational consequence (`BUN-TEST-08`) is the same on both sides: do not commit `.only`.

### 3.4 `--changed`: filter by import graph

`bun test --changed` runs only the test files whose **import graph reaches** a file that git reports as modified. `--changed=main` or `--changed=HEAD~1` compares against a branch, tag or commit instead of the working tree.

```bash
bun test --changed --watch     # development loop: only what your diff affects
bun test --changed=main        # pre-commit / fast PR job
```

It is the filter that replaces naming convention and manual configuration: editing a deep utility and running `bun test --changed` brings in the tests that depend on it transitively, without you knowing which they are.

**What it is not:** a merge gate. A test can break from a change the import graph does not see — environment variable, database migration, fixture, execution order. `--changed` speeds up the loop and the PR job; the whole suite is still what authorizes the merge (`BUN-TEST-15`, and the recipe in [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 5).

---

## 4. Execution modes and behavior flags

```bash
bun test --watch                 # reruns on save
bun test --hot                   # preserves state between runs, more aggressive
bun test --timeout 10000         # per test; default 5000
bun test --bail                  # stops at the first failure (default 1)
bun test --bail=5                # stops at the fifth
bun test --retry 2               # repeats what failed; { retry: N } per test overrides
bun test --rerun-each 10         # runs each file 10 times — flaky hunting
bun test --randomize             # random order
bun test --randomize --seed 42   # reproduces the order that revealed the failure
bun test --inspect               # opens the inspector; --inspect-brk pauses at the start
bun test --smol                  # reduces memory use
```

Usage calibration — the difference between the flag existing and it being good for something:

| Symptom | Flag | Why this one |
| --- | --- | --- |
| "passes alone, fails in the suite" | `--randomize`, then `--seed <n>` | exposes order dependency and makes it reproducible |
| "fails once every twenty runs" | `--rerun-each 20` | repeats the file until the failure shows up, without depending on CI |
| slow CI and the first failure already decides | `--bail` | does not spend minutes on files that will not change the result |
| legitimately unstable network test | `{ retry: N }` **in the test**, not global `--retry` | global `--retry` hides real flakiness from the rest of the suite |
| debug a specific test | `-t "name"` + `--inspect-brk` | does not require editing the file, and leaves no `.only` behind |

**Global `--retry` is anesthesia.** It exists, and it turns "sometimes fails" into "almost always passes" — including for the test that was right to fail. Retry belongs to the test that has a declared reason to be unstable (real network call, clock, external concurrency), not to the command.

`--watch` and `--hot` have the same difference as outside tests: `--watch` restarts the process, `--hot` tries to preserve state. For tests, `--watch` is the sensible default — state preserved between runs is exactly what a suite does not want ([Bun - Runtime and APIs](bun-runtime-and-apis.md) § 6).

---

## 5. `bunfig.toml [test]` — the complete surface

Everything below was verified on the configuration page. Where the source declares a default, it is in the column.

| Key | Default | What it does |
| --- | --- | --- |
| `root` | project root | directory the runner scans |
| `preload` | — | scripts loaded before the tests (array) |
| `pathIgnorePatterns` | — | excludes paths from discovery, by glob |
| `smol` | `false` | lower memory use mode |
| `concurrentTestGlob` | — | files matching the glob run with concurrent execution on |
| `randomize` | `false` | random execution order |
| `seed` | — | seed for a reproducible order — **requires `randomize = true`** |
| `retry` | `0` | default retry for all tests |
| `rerunEach` | — | reruns each file N times |
| `coverage` | `false` | turns coverage on by default |
| `coverageReporter` | `["text"]` | report formats |
| `coverageDir` | `"coverage"` | output directory |
| `coverageSkipTestFiles` | `true` | excludes the test files themselves from the report |
| `coverageThreshold` | — | coverage threshold (fraction `0.0`–`1.0`) — see [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 3 |
| `coveragePathIgnorePatterns` | — | excludes paths from the coverage calculation |
| `coverageIgnoreSourcemaps` | `false` | ignores sourcemaps in the calculation — advanced case |
| `[test.reporter] junit` | — | path of the JUnit XML ([Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) § 4) |

```toml
# bunfig.toml
[test]
root = "src"
preload = ["./test/happydom.ts", "./test/setup.ts"]
pathIgnorePatterns = ["**/fixtures/**"]
coverage = true
coverageReporter = ["text", "lcov"]
coverageThreshold = { lines = 0.85, functions = 0.85 }

# outside [test]: apply to any execution of the runtime
loader = { ".css" = "text" }
define = { "process.env.FEATURE_X" = "\"off\"" }
```

> **One more key, not verified.** [Bun - Runtime and APIs](bun-runtime-and-apis.md) § 5 also records `onlyFailures` in `[test]`, verified on 2026-08-15. The configuration page consulted on 2026-08-20 **does not list it**, and the CLI flag listing does not bring `--only-failures` either. The key probably exists (there is published work on the flag); what does not exist is a declaration from the source that I have seen today. Treat it as not verified and confirm with `bun test --help` before committing.

**A command-line option always wins over the configuration file.** That is what allows having `coverage = true` in `bunfig.toml` for CI and still running without coverage locally.

**`seed` without `randomize` does nothing.** The source is explicit, and the failure is silent: you commit the seed thinking you pinned the order, and the order is still the discovery order.

| ID | Rule |
| --- | --- |
| `BUN-TEST-13` | A positional filter that points at a **file** **MUST** start with `./` or `/` — without the prefix it is a filter by path substring, and glob is **NEVER** accepted. |
| `BUN-TEST-14` | `seed` in `bunfig.toml` **MUST** come with `randomize = true` — without it there is no effect, and the failure is silent. |

---

## 6. The environment the runner imposes

The runner changes the process environment before running any test. Two variables, and both change the behavior of the code under test:

| Variable | Value | Condition |
| --- | --- | --- |
| `NODE_ENV` | `"test"` | only if not already defined in the environment or in a loaded `.env` |
| `TZ` | `Etc/UTC` | unless `TZ` is already defined — keeps dates deterministic across machines |

```bash
NODE_ENV=development bun test        # explicit override
TZ=America/Sao_Paulo bun test        # test the behavior in a local time zone
```

`TZ=Etc/UTC` is a determinism decision with a side effect: a test that formats a date passes on your machine and in CI, and **would fail** in an environment that defines `TZ`. Whoever asserts on a formatted date should pin the time zone explicitly instead of inheriting the default (`BUN-TEST-21`, in [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 5).

### Injected globals

Available without import: `test`, `it`, `describe`, `expect`, `beforeAll`, `beforeEach`, `afterAll`, `afterEach`, `jest`, `vi`. All of them are also importable from `bun:test`:

```ts
import { test, describe, expect, beforeEach, mock, spyOn } from "bun:test";
```

**Prefer the import.** The global exists for compatibility and for quick tests; the explicit import is what makes the file work under `tsc --noEmit` without depending on a global declaration, and it is what makes it obvious, in review, that this `mock` is the runner's. Imports from `vitest` and from `@jest/globals` are rewritten internally to `bun:test`, which is the reason many Vitest suites run without edits ([Bun - Tests](bun-tests.md) § 5.4).

### Exit code: what makes CI red

| Code | When |
| --- | --- |
| `0` | all tests passed **and** no unhandled error appeared |
| `1` | there was a test failure **or** an unhandled error/rejection |

The second half of the `1` line is the one that surprises: **an unhandled error or a rejected promise outside any test brings the run down, even if every test passes.** A `setInterval` that fires after the last `afterEach`, a listener that rejects, a cleanup that throws — all of that becomes exit `1` with no red test in the report. It is correct behavior, and it is the reason the report and the exit code disagree now and then.

Your own handlers are possible (`process.on("uncaughtException")`, `process.on("unhandledRejection")`), and **they are almost always the wrong decision in a test**: they turn the signal into silence.

### Runtime flags that apply in tests

`--define`, `--loader`, `--tsconfig-override`, `--env-file`, `--preload`, `--smol`. They are the same as the runtime's, and their place is usually `bunfig.toml`, not the command — the command is for what varies per invocation.

---

## 7. Recipe: the scripts a project needs

```json
{
  "scripts": {
    "test": "bun test",
    "test:watch": "bun test --watch",
    "test:changed": "bun test --changed --watch",
    "test:ci": "bun test --parallel --coverage --reporter=junit --reporter-outfile=./junit.xml",
    "typecheck": "tsc --noEmit"
  }
}
```

Four decisions embedded there, all defensible in writing:

- **`test` with no flag at all.** It is the command anyone (or any agent) runs without reading documentation. If it needs flags to work, they belong in `bunfig.toml`.
- **`test:changed` is the development loop**, not the verification one.
- **`test:ci` is the only place with `--parallel`**, because it is the only environment where per-file isolation is mandatory ([Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 4).
- **`typecheck` is a separate step and not optional.** `bun test` checks no types at all: a file full of `expectTypeOf` passes without verifying anything (`BUN-TEST-18`).

| ID | Rule |
| --- | --- |
| `BUN-TEST-15` | A CI pipeline **MUST** pin the Bun version (`oven-sh/setup-bun` with a fixed `bun-version`, or a tagged image) — runner flags and defaults change between minors, and `latest` turns that into a failure with no commit. † |

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `pedidos.tests.ts`, `testePedidos.ts`, `pedidos-test.ts` | matches no discovery pattern; never runs, and nothing warns | `pedidos.test.ts` — `BUN-TEST-01` |
| `bun test "src/**/*.test.ts"` | glob is not supported; the argument becomes a path substring | a path with `./`, or `root`/`pathIgnorePatterns` — `BUN-TEST-13` |
| `bun test pedidos.test.ts` (without `./`) | it is a substring filter; matches any path containing the text | `bun test ./src/pedidos.test.ts` — `BUN-TEST-13` |
| `seed = 12345` in `bunfig.toml` without `randomize = true` | has no effect, and nothing warns; the order is still the discovery order | declare both keys — `BUN-TEST-14` |
| `--retry 3` in the CI test command | hides real flakiness and masks the test that was right to fail | `{ retry: N }` in the test that has a declared reason |
| `--changed` as a merge gate | the import graph does not see env, migration, fixture or order | `--changed` in the PR job; whole suite on merge — `BUN-TEST-15` |
| `describe("testes", …)` | the `describe` label is the address for `-t`; a generic one addresses nothing | name the `describe` after the unit under test |
| `bun test` without `tsc --noEmit` in CI | the runner checks no types; `expectTypeOf` is a no-op at runtime | separate typecheck step — `BUN-TEST-18` |
| `bun@latest` in CI | runner flags change between minors; the suite breaks with no commit | pin the version — `BUN-TEST-15` |
| `process.on("unhandledRejection")` to silence an error in a test | turns the signal into silence and returns exit `0` from a defective process | let it blow up; the exit `1` is the information |

---

## Review checklist

- [ ] Does every test file match one of the discovery patterns? → `BUN-TEST-01`
- [ ] Is the suite's cut in `root`/`pathIgnorePatterns`, not in a glob on the command? → `BUN-TEST-13`
- [ ] If there is a `seed`, is there `randomize = true`? → `BUN-TEST-14`
- [ ] Is the Bun version pinned in CI? → `BUN-TEST-15`
- [ ] Does the `test` script run without a mandatory flag (the rest is in `bunfig.toml`)?
- [ ] Is there a separate `tsc --noEmit` step? → `BUN-TEST-18`
- [ ] No global `--retry` in the CI command?
- [ ] Does an assertion on a date pin the time zone, instead of inheriting `TZ=Etc/UTC`? → `BUN-TEST-21`

---

## Related

- [Bun - Tests](bun-tests.md) — hub, mental model, API map, decision trees
- [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) · [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) · [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) · [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) · [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md)
- [Bun - Runtime and APIs](bun-runtime-and-apis.md) — `bunfig.toml`, `.env`, `paths`, `--watch` × `--hot`
- [Bun - Package Manager](bun-package-manager.md) — installation in CI, version pin
- — what to test, before how

## Sources consulted

Verified on **2026-08-20**: [Test runner](https://bun.com/docs/test) · [Finding tests](https://bun.com/docs/test/discovery) · [Test configuration](https://bun.com/docs/test/configuration) · [Runtime behavior](https://bun.com/docs/test/runtime-behavior) · [Writing tests](https://bun.com/docs/test/writing-tests) · [Bun 1.4](https://bun.com/blog/bun-v1.4) (for `--changed`).
