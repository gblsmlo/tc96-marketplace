# Most frequent antipatterns, with IDs

> Quick scan grid. Check the ID in `mapa-de-ids.md` before citing:
> `PW-ACT-07` and `PW-LOC-07` are **aliases** — use `PW-CORE-05` and `PW-EXP-01`.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Web-first assertion without `await` | `PW-CORE-04` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `expect(await x.isVisible)` | `PW-EXP-01` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `toPass` without a `timeout` | `PW-EXP-03` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| An inflated global `expect.timeout` | `PW-EXP-04` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `waitForTimeout` as a wait | `PW-CORE-05` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `waitUntil: 'networkidle'` | `PW-ACT-04` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| An event wait armed after the action | `PW-ACT-03` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `force: true` to beat an overlay | `PW-ACT-01` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `dispatchEvent`/`focus` instead of `click`/`fill` | `PW-ACT-06` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `noWaitAfter` (deprecated, no effect) | `PW-ACT-05` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| A flow with `confirm` and no handler | § 7.4 do satélite | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `.first` to silence strict mode | `PW-LOC-02` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| A locator tied to a utility class | `PW-LOC-01` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `getByTestId` as the default locator, with no debt recorded | `PW-LOC-04` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `ElementHandle` in new code | `PW-LOC-03` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| A layout selector (`:near`, `:right-of`) | `PW-LOC-05` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `_react`, `_vue`, `:light` (removed in 1.58) | `PW-LOC-06` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `all` without anchoring the list | § 4 do satélite | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| Login in `beforeEach` | `PW-AUTH-01` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| `storageState` outside `.gitignore` | `PW-AUTH-02` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| One account for every worker in a suite that writes | `PW-AUTH-03` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| `workerIndex` instead of `parallelIndex` | § 3 do satélite | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| Setup that writes `storageState` without verifying the login | `PW-AUTH-06` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| A guest test in an authenticated project | `PW-AUTH-05` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| `route` registered after the `goto` | `PW-NET-02` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| A response shape retyped by hand | `PW-NET-04` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| State created through the UI to test something else | `PW-NET-06` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| `page.request` and `playwright.request` treated as the same | `PW-NET-05` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| Mocking `fetch` by hand | § 9.3 do satélite | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| `beforeEach` copied between files | `PW-FIX-01` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| `return` instead of `await use(v)` | `PW-FIX-03` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| Mutable state in a worker-scoped fixture | `PW-FIX-02` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| `process.env` as a suite parameter | `PW-FIX-04` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| Mixing the base `test` and the derived one | `PW-FIX-05` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| `globalSetup` for login | `PW-CFG-03` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| A business assertion in the page object | `PW-STR-02` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| A page object returning `Promise<string>` | § 8.3 do satélite | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| An uninformative title (`test('test')`) | `PW-STR-04` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| A hook inside the parameterization loop | `PW-STR-06` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| A `helpers.ts` that takes `page` | `PW-STR-07` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| A test that does everything (fails for six reasons) | § 8.1 do satélite | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| A runner option inside `use` | `PW-CORE-07` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `forbidOnly` absent | `PW-CFG-01` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `trace: 'off'` in CI | `PW-CFG-02` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| An absolute URL in the test | `PW-CFG-05` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `...devices[...]` after your own options | `PW-CFG-06` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `reuseExistingServer: true` in CI | `PW-CFG-04` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `geolocation` without `permissions` | `PW-CFG-07` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| One project per environment (staging/prod) | § 8.6 do satélite | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `--shard` without `fullyParallel` | `PW-RUN-01` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| High `retries` to silence flakiness | `PW-RUN-03` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| Retry without a trace | `PW-RUN-02` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| `test.fail` instead of `test.fixme` | `PW-RUN-04` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| `test.describe.serial`/`.parallel` (discontinued) | `PW-RUN-05` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| A shard without `blob` + `merge-reports` | `PW-RUN-06` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| `mode: 'serial'` with no written reason | `PW-RUN-07` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| Installing all three browsers to run one | § 9.6 do satélite | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| The default `fail-fast` in the shard matrix | § 9.7 do satélite | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| A screenshot where an aria snapshot would do | `PW-SNAP-01` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| A screenshot reference from another OS | `PW-SNAP-02` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| An inflated `maxDiffPixels` | `PW-SNAP-04` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| Blocking images in a suite with screenshots | `PW-SNAP-06` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| `-u` by reflex, without reviewing the patch | `PW-SNAP-03` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| Codegen output committed as a test | `PW-DBG-06` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) |
| `console.log` as committed diagnostics | `PW-DBG-04` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) |
| `slowMo` in the committed config | § 9.7 do satélite | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) |
| An agent-generated test accepted without review | `PW-AGT-04` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |
| A healer that erased an assertion | `PW-AGT-05` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |
| Outdated agent definitions | `PW-AGT-02` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |
| `browser_run_code_unsafe` against an untrusted target | `PW-AGT-03` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |
| A persistent MCP session with a production credential | `PW-AGT-06` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |

