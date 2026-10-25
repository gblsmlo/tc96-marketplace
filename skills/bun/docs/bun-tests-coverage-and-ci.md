---
titulo: Bun - Tests - Coverage and CI
Link: https://bun.com/docs/test/code-coverage
tags:
  - bun
  - testing
  - ci
  - agent-context
source: "Official documentation — https://bun.com/docs/test/code-coverage, /reporters"
verificado-em: 2026-08-20
---

# Bun - Tests - Coverage and CI

> Coverage as a gate, and the **two silent conditions** that keep the gate from closing · reporters (`text`, `lcov`, `dots`, `junit`) and what each one serves · automatic annotations on GitHub Actions · the complete workflow, with `--parallel`, `--shard` and `--changed` · where `tsc --noEmit` comes in.
>
> **Does not cover:** execution flags and `bunfig.toml` in general ([Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md)) · what `--parallel`/`--shard` do to isolation ([Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 4 and § 7) · installing dependencies in CI ([Bun - Package Manager](bun-package-manager.md)).

Entry point: [Bun - Tests](bun-tests.md) · Normative base: [Bun - Tests](bun-tests.md) § 6 · Family: `BUN-TEST-*` (this note owns `27`, `28`, `29`)

---

## 1. Concept: coverage detects absence, it does not attest presence

Coverage answers a narrow and useful question: **which lines no test executed.** It does not answer whether what was executed was verified — a file can have 100% coverage with zero `expect`, because `import`, call and execution all count.

Hence the two legitimate uses, and one illegitimate one:

- **Legitimate — finding what nobody tested.** Running `--coverage` and reading the red lines of a new module is the use that pays off.
- **Legitimate — preventing scope regression.** A threshold that fails the build prevents a large PR from adding 800 lines without a single test.
- **Illegitimate — the number as a goal.** Coverage chased as a number produces tests that execute without verifying: the worst kind, because it looks like protection and is not.

The threshold is only worth anything if it was **chosen from the real suite** — run `--coverage`, look at today's number, and set the gate slightly below it. Copying `0.9` from another project produces one of two things: a red build on adoption day, or a gate that never fires.

---

## 2. Running and reporting

```bash
bun test --coverage
bun test --coverage --coverage-reporter=lcov
bun test --coverage --coverage-reporter=text --coverage-reporter=lcov --coverage-dir=coverage
```

| Reporter | What it produces | What for |
| --- | --- | --- |
| `text` | summary in the console | human reading, and — outside `--parallel` — **the threshold check** (§ 3) |
| `lcov` | `lcov.info` in `coverageDir` | Codecov, Coveralls, GitLab, editor extension |

Default: `["text"]`. Persistent configuration:

```toml
[test]
coverage = true
coverageReporter = ["text", "lcov"]
coverageDir = "coverage"
coverageSkipTestFiles = true                 # default
coveragePathIgnorePatterns = ["**/*.gen.ts", "src/mocks/**"]
```

**Excluded from the report by default:** `node_modules`, files loaded by non-JS/TS loaders (`.css`, `.txt`, unless a custom loader), and the test files themselves (`coverageSkipTestFiles = true`). `coveragePathIgnorePatterns` adds exclusions by glob.

`coverageIgnoreSourcemaps` (default `false`) turns off sourcemap mapping — the source says you rarely want this outside an advanced case. In a TypeScript project, turning this key on makes the report point at lines of the transpiled code.

---

## 3. `coverageThreshold`: the gate, and the two conditions that silently turn it off

```toml
[test]
coverageThreshold = 0.9                                  # scalar: lines and functions
```

```toml
[test]
coverageThreshold = { lines = 0.9, functions = 0.85 }    # per metric
```

Values are a **fraction** (`0.9`), not a percentage (`90`). Declaring any key turns on the failure: `bun test --coverage` exits with a non-zero code when coverage falls below the threshold.

And here are the two traps that turn the gate into decoration — both verified in the source, both silent:

**1. `statements` is accepted and not enforced.** The key does not cause a configuration error; it is simply not checked. A project whose gate is `coverageThreshold = { statements = 0.95 }` has no gate at all, and nothing warns it. What is enforced is `lines` and `functions`.

**2. Outside `--parallel`, the threshold check only runs with the `text` reporter enabled.** The source states: runs that use only `--coverage-reporter=lcov` *"currently exit 0 regardless"*. It is the most natural CI configuration in the world — whoever only wants the file for Codecov turns off `text` — and it turns off the gate along with it.

```toml
# the safe form: text ALWAYS present, lcov alongside when needed
[test]
coverage = true
coverageReporter = ["text", "lcov"]
coverageThreshold = { lines = 0.85, functions = 0.85 }
```

Under `--parallel`, the coordinator merges the workers' coverage and evaluates the threshold on the merged result — it is the only configuration in which the dependency on the `text` reporter does not apply. Since this doc's CI recommendation **is** `--parallel`, the practical effect is that both paths end up correct; the risk lies with whoever runs coverage locally or in a sequential job.

| ID | Rule |
| --- | --- |
| `BUN-TEST-27` | `coverageThreshold` **MUST** be accompanied by the `text` reporter enabled in every run outside `--parallel` — with only `--coverage-reporter=lcov` the process exits `0` even below the threshold. |
| `BUN-TEST-28` | `coverageThreshold` **NEVER** depends on the `statements` key — it is accepted and **not** enforced; the real gate is `lines` and `functions`. |

---

## 4. Result reporters

| Reporter | How | When |
| --- | --- | --- |
| default | — | local reading |
| dots | `--dots` or `--reporter=dots` | large suite: one dot per test, full detail only on failures |
| JUnit XML | `--reporter=junit --reporter-outfile=./junit.xml` | GitLab, Jenkins, any CI that consumes JUnit |

```toml
[test.reporter]
junit = "junit.xml"
```

**`--reporter=junit` requires `--reporter-outfile`.** The normal output to stdout continues; the XML is written at the end, and includes environment information as `<properties>` (build, commit, hostname). Declared limitations: it does **not** include stdout/stderr of individual tests, nor a precise timestamp per case.

**GitHub Actions needs no configuration.** `bun test` detects that it is running there and emits annotations straight to the console — failures show up in the PR diff, on the right line, with no extra action.

A custom reporter is possible: Bun extends the WebKit Inspector Protocol with the `TestReporter` and `LifecycleReporter` domains (events `TestReporter.found`/`start`/`end`, `Console.messageAdded`, `LifecycleReporter.error`). It is a tooling surface, not a project one — unless you are building a dashboard, this is not where the time pays off.

| ID | Rule |
| --- | --- |
| `BUN-TEST-29` | `--reporter=junit` **MUST** be accompanied by `--reporter-outfile` — the source declares the pair mandatory. |

---

## 5. The workflow

### 5.1 The common case: one job

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v2
        with:
          bun-version: 1.4.0          # pinned — BUN-TEST-15
      - run: bun ci                   # frozen lockfile — BUN-PKG-02
      - run: bun run typecheck        # tsc --noEmit; bun test does NOT check types
      - run: bun test --parallel --coverage
```

Four decisions, and each one has an ID behind it:

- **Pinned version** (`BUN-TEST-15`): runner flags change between minors.
- **`bun ci`** and not `bun install` (`BUN-PKG-02`, [Bun - Package Manager](bun-package-manager.md)).
- **`typecheck` as its own step** (`BUN-TEST-18`): `expectTypeOf` is a no-op at runtime, and nothing else in `bun test` looks at types.
- **`--parallel`**: it is the only environment in which per-file isolation is mandatory, and it is what keeps the suite honest ([Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 4).

No `-u` on any line (`BUN-TEST-05`), and no global `--retry`.

### 5.2 Large suite: shard per machine

```yaml
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v2
        with: { bun-version: 1.4.0 }
      - run: bun ci
      - uses: actions/cache@v4
        with:
          path: .bun-timings.json
          key: bun-timings-${{ github.ref_name }}
      - run: bun test --shard=${{ matrix.shard }}/4 --timings=.bun-timings.json --parallel
```

`fail-fast: false` because you want the result of every shard, not that of the first one that broke. Caching the timings file is what makes `--timings` worth anything: without persistence, every run splits by file count ([Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 7).

### 5.3 Fast PR job

```yaml
      - run: bun test --changed=origin/${{ github.base_ref }} --parallel
```

Runs only the files whose import graph reaches the diff. **This speeds up feedback; it does not replace the whole suite at the merge gate** — the import graph does not see environment variables, migrations, fixtures or execution order (`BUN-TEST-15` and [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 3.4).

### 5.4 CI that consumes JUnit

```bash
bun test --parallel --coverage --reporter=junit --reporter-outfile=./junit.xml
```

Under `--parallel`, the coordinator merges coverage, XML and snapshot writing: one report, not one per worker.

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `coverageThreshold` with only `--coverage-reporter=lcov`, outside `--parallel` | the threshold is not checked; the process exits `0` below the number | keep `text` in the reporter list — `BUN-TEST-27` |
| `coverageThreshold = { statements = 0.95 }` | the key is accepted and not enforced: there is no gate | use `lines` and `functions` — `BUN-TEST-28` |
| `coverageThreshold = 90` | the value is a fraction, not a percentage; `90` is unreachable | `0.9` |
| Threshold copied from another project | red build on adoption day, or a gate that never fires | measure the suite and set the gate just below — § 1 |
| Coverage as a team goal | produces tests that execute without verifying | use coverage to find the untested — § 1 |
| `--reporter=junit` without `--reporter-outfile` | the source declares the pair mandatory | pass both — `BUN-TEST-29` |
| `coverageIgnoreSourcemaps = true` in a TypeScript project | the report starts pointing at lines of the transpiled code | leave it at the default `false` |
| `bun install` in CI | rewrites the lockfile and does not fail on divergence | `bun ci` — `BUN-PKG-02` |
| `bun@latest` in CI | runner flags change between minors; breaks without a commit | pin the version — `BUN-TEST-15` |
| CI without a `tsc --noEmit` step | nothing in `bun test` checks types | its own step — `BUN-TEST-18` |
| `--changed` as the merge gate | the import graph does not see env, migrations, fixtures or order | whole suite at merge — § 5.3 |
| `--shard` without caching the `--timings` file | the split goes back to being by file count | cache the file — § 5.2 |
| `-u` in the CI command | the snapshot starts recording any output | `-u` is a command for a person — `BUN-TEST-05` |

---

## Review checklist

- [ ] Does `coverageReporter` include `text` whenever there is a `coverageThreshold`? → `BUN-TEST-27`
- [ ] Does the threshold use `lines`/`functions`, not `statements`? → `BUN-TEST-28`
- [ ] Was the threshold number measured, not copied? → § 1
- [ ] Does `--reporter=junit` come with `--reporter-outfile`? → `BUN-TEST-29`
- [ ] Is the Bun version pinned? → `BUN-TEST-15`
- [ ] Is there a separate `tsc --noEmit` step? → `BUN-TEST-18`
- [ ] Is the CI command free of `-u` and of a global `--retry`? → `BUN-TEST-05`
- [ ] If there is `--shard`, is the timings file persisted? → § 5.2
- [ ] Does the merge gate run the whole suite, not `--changed`? → § 5.3
- [ ] Is the CI install `bun ci`? → `BUN-PKG-02`

---

## Related

- [Bun - Tests](bun-tests.md) — hub, mental model, API map, decision trees
- [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) · [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) · [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) · [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) · [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md)
- [Bun - Package Manager](bun-package-manager.md) — `bun ci`, lockfile, version pin
- `Github Actions` — workflows and matrix
- — what to test, before how

## Sources consulted

Verified on **2026-08-20**: [Code coverage](https://bun.com/docs/test/code-coverage) · [Test Reporters](https://bun.com/docs/test/reporters) · [Test configuration](https://bun.com/docs/test/configuration) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel) · [Bun 1.4](https://bun.com/blog/bun-v1.4).
