# The six tasks

> Each cut assumes Minimum loading already happened and **names the satellite that is missing**.
> The satellite's content is not repeated here — it is cited.

## Task → note map

| The task is… | Satellite | Tree |
| --- | --- | --- |
| writing a test, choosing a matcher, modifier, snapshot | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/bun-testes-escrita-e-assercoes.md) | — |
| replacing a dependency: mock, spy, double | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/bun-testes-mocks-e-tempo.md) | § 5.2 |
| freezing a date, advancing a timer, timezone | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/bun-testes-mocks-e-tempo.md) | § 5.3 |
| testing a React component, DOM, interaction | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/bun-testes-dom-e-componentes.md) | § 5.6 |
| hooks, preload, setup scope | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/bun-testes-ciclo-de-vida-e-isolamento.md) | — |
| `bunfig.toml [test]`, discovery, filters | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/bun-testes-execucao-e-configuracao.md) | — |
| coverage, reporter, CI workflow | [Bun - Testes - Cobertura e CI](../../../../knowledge-base/bun-testes-cobertura-e-ci.md) | § 5.5 |
| a habit from Jest or Vitest | [Bun - Testes](../../../../knowledge-base/bun-testes.md) § 5.4 (equivalence map) | § 5.4 |

---

Six cuts. Each one assumes Minimum loading already happened and names the satellite that is missing — do not repeat the satellite's content here, cite it.

### 1. Write a new test

1. **File name first.** `*.test.ts`, `*_test.ts`, `*.spec.ts` or `*_spec.ts` — `BUN-TEST-01`. A file outside the pattern does not run and nothing warns.
2. **Import from `bun:test`**, do not rely on the globals: that is what passes `tsc --noEmit` without a global declaration.
3. **Name the `describe` after the unit under test** — its label is the address for `-t`.
4. **Every conditional assertion declares a count.** An `expect` inside a `catch`, callback or `if` requires `expect.assertions(n)` — `BUN-TEST-06`. For a Promise rejection, prefer `await expect(fn).rejects.toThrow(X)`.
5. **Pick the equality:** `toBe` for primitives and identity, `toEqual` for objects, `toStrictEqual` when the exact shape is the contract.
6. **`.toThrow` always with a class or a message** — without an argument, it accepts the `TypeError` you got from breaking the call.
7. **Async is `async`/`await`.** Never `done` — `BUN-TEST-17`.
8. **Declared instability uses `{ retry: N }` on the test**, never a global `--retry` — and `retry` with `repeats` is an invalid combination, `BUN-TEST-16`.
9. **A known bug is `test.failing`**, never `test.skip` — `BUN-TEST-11`. And no `.only` leaves your terminal — `BUN-TEST-08`.
10. **Snapshot only with deterministic fields**, or with property matchers — `BUN-TEST-19`.

### 2. Replace a dependency

Walk the tree in § 5.2 of the hub, in this order of preference:

1. **Does the code receive the dependency from outside?** Pass a double. No mock, no global scope, no restoration — it is the way out with nothing to leak.
2. **Is it a method on an object the test holds?** `spyOn`, **with guaranteed restoration** in the preload — `BUN-TEST-02`.
3. **Is it an imported module?** `mock.module`, and then two mandatory decisions:
 - if the goal is to prevent an import side effect (connection, listener, env at the top), the registration goes in `[test] preload` — `BUN-TEST-04`. There is no other way: the original has already been evaluated;
 - `mock.restore` does **not** undo it — the module stays mocked for the rest of the process — `BUN-TEST-03`.

Stop signal: if three files mock the same module, the dependency wanted to be a parameter. Say that instead of writing the fourth mock.

### 3. Control date and time

| I need | API | Rule |
| --- | --- | --- |
| a fixed date | `setSystemTime(new Date(...))` | `BUN-TEST-20` — `useFakeTimers` does **not** swap the `Date` constructor |
| time to pass (debounce, polling, retry) | `jest.useFakeTimers` + `advanceTimersByTime(ms)` | — |
| an assertion about a **formatted** date | set `TZ` explicitly | `BUN-TEST-21` |

`Bun.sleep` to wait on a timer does not belong in a test.

### 4. Test a React component

Check the full recipe in [Bun - Testes - DOM e Componentes](../../../../knowledge-base/bun-testes-dom-e-componentes.md) § 2 before writing the first line — it has four pieces, and three fail silently if missing:

1. `GlobalRegistrator.register` in a preload, never in the test file — `BUN-TEST-07`;
2. **two** preloads, in this order: happy-dom, then `@testing-library/*` — `BUN-TEST-25`;
3. `expect.extend(matchers)` from `@testing-library/jest-dom/matchers` — importing the package alone **registers nothing**, `BUN-TEST-12`;
4. `cleanup` in `afterEach` — `BUN-TEST-26`.

When writing: `await` on every `userEvent`, `findBy*` to wait for an element, `waitFor` only for a condition that is not "the element exists". Before asserting on an asset, `import.meta.env` or CSS, read § 4 of the satellite — that is the boundary with Vite, and the way out is usually to receive configuration through a prop.

### 5. Configure a project's suite

1. `bunfig.toml`, `[test]` section — the full surface is in [Bun - Testes - Execução e Configuração](../../../../knowledge-base/bun-testes-execucao-e-configuracao.md) § 5.
2. A preload with `afterEach( => mock.restore)`. It is the line that stops a file written by someone who did not read the docs from leaking a spy into the whole suite.
3. Scripts: `test` **with no mandatory flag** (the rest goes in `bunfig.toml`), `test:watch`, `test:changed`, `test:ci`, `typecheck`.
4. If there are components, the two DOM preloads (task 4).
5. `seed` only with `randomize = true` — `BUN-TEST-14`.
6. Scope with `root`/`pathIgnorePatterns`, not with a glob on the command line — `BUN-TEST-13`.
7. Setup declared in a preload is **idempotent and cheap, or parameterized per worker** — `BUN-TEST-24`. A server or a migration in the preload is the error that only shows up when someone turns on `--parallel`.

### 6. Assemble the CI command

Recipe in [Bun - Testes - Cobertura e CI](../../../../knowledge-base/bun-testes-cobertura-e-ci.md) § 5. The non-negotiable decisions:

- the Bun version **pinned** — `BUN-TEST-15`;
- `bun ci`, not `bun install` — `BUN-PKG-02`;
- `tsc --noEmit` as its own step — `BUN-TEST-18`, because `expectTypeOf` is a no-op at runtime;
- `--parallel`, and then external resources derived from `BUN_TEST_WORKER_ID` — `BUN-TEST-10`;
- no `-u` — `BUN-TEST-05` — and no global `--retry`;
- if there is a `coverageThreshold`, the `text` reporter stays in the list — `BUN-TEST-27` — and the threshold uses `lines`/`functions`, never `statements` — `BUN-TEST-28`;
- `--reporter=junit` always with `--reporter-outfile` — `BUN-TEST-29`;
- `--changed` in the PR job, **never** as a merge gate.

---

## Related

- [Bun - Testes](../../../../knowledge-base/bun-testes.md) § 5 — the decision trees
- `armadilhas-do-runner.md` — what you do not assume from memory
- `autoverificacao.md` — what to check before delivering
