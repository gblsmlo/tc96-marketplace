# Most frequent antipatterns, with IDs

> Quick scan grid. Check the body of the rule through `id-map.md`:
> the whole family is declared in § 6 of the hub, and the body lives in the satellite.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| `expect` in a `catch` without an assertion count | `BUN-TEST-06` | [Bun - Tests - Writing and Assertions](../../../docs/bun/bun-tests-writing-and-assertions.md) |
| `spyOn` without guaranteed `mock.restore` | `BUN-TEST-02` | [Bun - Tests - Mocks and Time](../../../docs/bun/bun-tests-mocks-and-time.md) |
| Expecting `mock.restore` to undo `mock.module` | `BUN-TEST-03` | [Bun - Tests - Mocks and Time](../../../docs/bun/bun-tests-mocks-and-time.md) |
| `mock.module` in the test body to avoid the real module's connection | `BUN-TEST-04` | [Bun - Tests - Mocks and Time](../../../docs/bun/bun-tests-mocks-and-time.md) |
| `test.serial` for a dependency between **files** | `BUN-TEST-09` | [Bun - Tests - Lifecycle and Isolation](../../../docs/bun/bun-tests-lifecycle-and-isolation.md) |
| Database, port or directory shared under `--parallel` | `BUN-TEST-10` | [Bun - Tests - Lifecycle and Isolation](../../../docs/bun/bun-tests-lifecycle-and-isolation.md) |
| Expensive `beforeAll` in the preload with `--parallel` on | `BUN-TEST-24` | [Bun - Tests - Lifecycle and Isolation](../../../docs/bun/bun-tests-lifecycle-and-isolation.md) |
| `onTestFinished` in a concurrent test | `BUN-TEST-22` | [Bun - Tests - Lifecycle and Isolation](../../../docs/bun/bun-tests-lifecycle-and-isolation.md) |
| Concurrent test sharing mutable state | `BUN-TEST-23` | [Bun - Tests - Lifecycle and Isolation](../../../docs/bun/bun-tests-lifecycle-and-isolation.md) |
| `test.skip` for a known bug | `BUN-TEST-11` | [Bun - Tests - Writing and Assertions](../../../docs/bun/bun-tests-writing-and-assertions.md) |
| `.only` committed "to disable the rest" | `BUN-TEST-08` | [Bun - Tests - Writing and Assertions](../../../docs/bun/bun-tests-writing-and-assertions.md) |
| `-u` in the CI command, or `__snapshots__/` git-ignored | `BUN-TEST-05` | [Bun - Tests - Writing and Assertions](../../../docs/bun/bun-tests-writing-and-assertions.md) |
| Snapshot of an object with a random `id` or a `Date` | `BUN-TEST-19` | [Bun - Tests - Writing and Assertions](../../../docs/bun/bun-tests-writing-and-assertions.md) |
| `expectTypeOf` treated as an executed check | `BUN-TEST-18` | [Bun - Tests - Writing and Assertions](../../../docs/bun/bun-tests-writing-and-assertions.md) |
| `retry` and `repeats` on the same test | `BUN-TEST-16` | [Bun - Tests - Writing and Assertions](../../../docs/bun/bun-tests-writing-and-assertions.md) |
| Test with a `done` parameter | `BUN-TEST-17` | [Bun - Tests - Writing and Assertions](../../../docs/bun/bun-tests-writing-and-assertions.md) |
| `useFakeTimers` to pin `new Date` | `BUN-TEST-20` | [Bun - Tests - Mocks and Time](../../../docs/bun/bun-tests-mocks-and-time.md) |
| Assertion on a formatted date without a fixed timezone | `BUN-TEST-21` | [Bun - Tests - Mocks and Time](../../../docs/bun/bun-tests-mocks-and-time.md) |
| `import "@testing-library/jest-dom"` expecting the matchers | `BUN-TEST-12` | [Bun - Tests - DOM and Components](../../../docs/bun/bun-tests-dom-and-components.md) |
| `GlobalRegistrator.register` inside the test file | `BUN-TEST-07` | [Bun - Tests - DOM and Components](../../../docs/bun/bun-tests-dom-and-components.md) |
| Happy-dom and Testing Library in a single preload, with a static import | `BUN-TEST-25` | [Bun - Tests - DOM and Components](../../../docs/bun/bun-tests-dom-and-components.md) |
| `render` without `cleanup` in `afterEach` | `BUN-TEST-26` | [Bun - Tests - DOM and Components](../../../docs/bun/bun-tests-dom-and-components.md) |
| `user.click(...)` without `await` | § 3 of the satellite | [Bun - Tests - DOM and Components](../../../docs/bun/bun-tests-dom-and-components.md) |
| `coverageThreshold` with only the `lcov` reporter, outside `--parallel` | `BUN-TEST-27` | [Bun - Tests - Coverage and CI](../../../docs/bun/bun-tests-coverage-and-ci.md) |
| Coverage threshold declared on `statements` | `BUN-TEST-28` | [Bun - Tests - Coverage and CI](../../../docs/bun/bun-tests-coverage-and-ci.md) |
| `--reporter=junit` without `--reporter-outfile` | `BUN-TEST-29` | [Bun - Tests - Coverage and CI](../../../docs/bun/bun-tests-coverage-and-ci.md) |
| File named `*.tests.ts` or `teste*.ts` | `BUN-TEST-01` | [Bun - Tests - Execution and Configuration](../../../docs/bun/bun-tests-execution-and-configuration.md) |
| Glob in the positional argument, or a path without `./` | `BUN-TEST-13` | [Bun - Tests - Execution and Configuration](../../../docs/bun/bun-tests-execution-and-configuration.md) |
| `seed` without `randomize = true` | `BUN-TEST-14` | [Bun - Tests - Execution and Configuration](../../../docs/bun/bun-tests-execution-and-configuration.md) |
| `bun@latest` in CI | `BUN-TEST-15` | [Bun - Tests - Execution and Configuration](../../../docs/bun/bun-tests-execution-and-configuration.md) |
| `--changed` as a merge gate | § 3.4 of the satellite | [Bun - Tests - Execution and Configuration](../../../docs/bun/bun-tests-execution-and-configuration.md) |
| Global `--retry` in the CI command | § 4 of the satellite | [Bun - Tests - Execution and Configuration](../../../docs/bun/bun-tests-execution-and-configuration.md) |
| `Bun.sleep` waiting on a render or a timer | no ID — see Step 6 | [Bun - Tests - DOM and Components](../../../docs/bun/bun-tests-dom-and-components.md) |

