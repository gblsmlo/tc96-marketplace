# Most frequent antipatterns, with IDs

> Quick scan grid. Check the body of the rule through `mapa-de-ids.md`:
> the whole family is declared in § 6 of the hub, and the body lives in the satellite.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| `expect` in a `catch` without an assertion count | `BUN-TEST-06` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/bun-testes-escrita-e-assercoes.md) |
| `spyOn` without guaranteed `mock.restore` | `BUN-TEST-02` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/bun-testes-mocks-e-tempo.md) |
| Expecting `mock.restore` to undo `mock.module` | `BUN-TEST-03` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/bun-testes-mocks-e-tempo.md) |
| `mock.module` in the test body to avoid the real module's connection | `BUN-TEST-04` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/bun-testes-mocks-e-tempo.md) |
| `test.serial` for a dependency between **files** | `BUN-TEST-09` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/bun-testes-ciclo-de-vida-e-isolamento.md) |
| Database, port or directory shared under `--parallel` | `BUN-TEST-10` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/bun-testes-ciclo-de-vida-e-isolamento.md) |
| Expensive `beforeAll` in the preload with `--parallel` on | `BUN-TEST-24` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/bun-testes-ciclo-de-vida-e-isolamento.md) |
| `onTestFinished` in a concurrent test | `BUN-TEST-22` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/bun-testes-ciclo-de-vida-e-isolamento.md) |
| Concurrent test sharing mutable state | `BUN-TEST-23` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/bun-testes-ciclo-de-vida-e-isolamento.md) |
| `test.skip` for a known bug | `BUN-TEST-11` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/bun-testes-escrita-e-assercoes.md) |
| `.only` committed "to disable the rest" | `BUN-TEST-08` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/bun-testes-escrita-e-assercoes.md) |
| `-u` in the CI command, or `__snapshots__/` git-ignored | `BUN-TEST-05` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/bun-testes-escrita-e-assercoes.md) |
| Snapshot of an object with a random `id` or a `Date` | `BUN-TEST-19` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/bun-testes-escrita-e-assercoes.md) |
| `expectTypeOf` treated as an executed check | `BUN-TEST-18` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/bun-testes-escrita-e-assercoes.md) |
| `retry` and `repeats` on the same test | `BUN-TEST-16` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/bun-testes-escrita-e-assercoes.md) |
| Test with a `done` parameter | `BUN-TEST-17` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/bun-testes-escrita-e-assercoes.md) |
| `useFakeTimers` to pin `new Date` | `BUN-TEST-20` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/bun-testes-mocks-e-tempo.md) |
| Assertion on a formatted date without a fixed timezone | `BUN-TEST-21` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/bun-testes-mocks-e-tempo.md) |
| `import "@testing-library/jest-dom"` expecting the matchers | `BUN-TEST-12` | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/bun-testes-dom-e-componentes.md) |
| `GlobalRegistrator.register` inside the test file | `BUN-TEST-07` | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/bun-testes-dom-e-componentes.md) |
| Happy-dom and Testing Library in a single preload, with a static import | `BUN-TEST-25` | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/bun-testes-dom-e-componentes.md) |
| `render` without `cleanup` in `afterEach` | `BUN-TEST-26` | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/bun-testes-dom-e-componentes.md) |
| `user.click(...)` without `await` | § 3 of the satellite | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/bun-testes-dom-e-componentes.md) |
| `coverageThreshold` with only the `lcov` reporter, outside `--parallel` | `BUN-TEST-27` | [Bun - Testes - Cobertura e CI](../../../../knowledge-base/bun-testes-cobertura-e-ci.md) |
| Coverage threshold declared on `statements` | `BUN-TEST-28` | [Bun - Testes - Cobertura e CI](../../../../knowledge-base/bun-testes-cobertura-e-ci.md) |
| `--reporter=junit` without `--reporter-outfile` | `BUN-TEST-29` | [Bun - Testes - Cobertura e CI](../../../../knowledge-base/bun-testes-cobertura-e-ci.md) |
| File named `*.tests.ts` or `teste*.ts` | `BUN-TEST-01` | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/bun-testes-execucao-e-configuracao.md) |
| Glob in the positional argument, or a path without `./` | `BUN-TEST-13` | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/bun-testes-execucao-e-configuracao.md) |
| `seed` without `randomize = true` | `BUN-TEST-14` | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/bun-testes-execucao-e-configuracao.md) |
| `bun@latest` in CI | `BUN-TEST-15` | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/bun-testes-execucao-e-configuracao.md) |
| `--changed` as a merge gate | § 3.4 of the satellite | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/bun-testes-execucao-e-configuracao.md) |
| Global `--retry` in the CI command | § 4 of the satellite | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/bun-testes-execucao-e-configuracao.md) |
| `Bun.sleep` waiting on a render or a timer | no ID — see Step 6 | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/bun-testes-dom-e-componentes.md) |

