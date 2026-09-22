# Antipadrões mais frequentes, com ID

> Grade de varredura rápida. Confira o ID em `mapa-de-ids.md` antes de citar:
> `PW-ACT-07` e `PW-LOC-07` são **apelidos** — use `PW-CORE-05` e `PW-EXP-01`.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Asserção web-first sem `await` | `PW-CORE-04` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `expect(await x.isVisible)` | `PW-EXP-01` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `toPass` sem `timeout` | `PW-EXP-03` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `expect.timeout` global inflado | `PW-EXP-04` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `waitForTimeout` como espera | `PW-CORE-05` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `waitUntil: 'networkidle'` | `PW-ACT-04` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| Espera de evento armada depois da ação | `PW-ACT-03` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `force: true` para vencer overlay | `PW-ACT-01` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `dispatchEvent`/`focus` no lugar de `click`/`fill` | `PW-ACT-06` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `noWaitAfter` (deprecado, sem efeito) | `PW-ACT-05` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| Fluxo com `confirm` sem handler | § 7.4 do satélite | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `.first` para calar strict mode | `PW-LOC-02` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| Locator amarrado a classe utilitária | `PW-LOC-01` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `getByTestId` como locator default, sem dívida registrada | `PW-LOC-04` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `ElementHandle` em código novo | `PW-LOC-03` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| Seletor de layout (`:near`, `:right-of`) | `PW-LOC-05` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `_react`, `_vue`, `:light` (removidos na 1.58) | `PW-LOC-06` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `all` sem ancorar a lista | § 4 do satélite | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| Login em `beforeEach` | `PW-AUTH-01` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| `storageState` fora do `.gitignore` | `PW-AUTH-02` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| Uma conta para todos os workers em suíte que escreve | `PW-AUTH-03` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| `workerIndex` no lugar de `parallelIndex` | § 3 do satélite | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| Setup que grava `storageState` sem verificar o login | `PW-AUTH-06` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| Teste de visitante em project autenticado | `PW-AUTH-05` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| `route` registrado depois do `goto` | `PW-NET-02` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| Shape de resposta redigitado à mão | `PW-NET-04` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| Estado criado pela UI para testar outra coisa | `PW-NET-06` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| `page.request` e `playwright.request` tratados como iguais | `PW-NET-05` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| Mockar `fetch` na mão | § 9.3 do satélite | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| `beforeEach` copiado entre arquivos | `PW-FIX-01` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| `return` no lugar de `await use(v)` | `PW-FIX-03` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| Estado mutável em fixture worker-scoped | `PW-FIX-02` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| `process.env` como parâmetro de suíte | `PW-FIX-04` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| Misturar o `test` base e o derivado | `PW-FIX-05` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| `globalSetup` para login | `PW-CFG-03` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| Asserção de negócio no page object | `PW-STR-02` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| Page object que devolve `Promise<string>` | § 8.3 do satélite | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| Título que não informa (`test('test')`) | `PW-STR-04` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| Hook dentro do laço de parametrização | `PW-STR-06` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| `helpers.ts` que recebe `page` | `PW-STR-07` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| Teste que faz tudo (falha por seis motivos) | § 8.1 do satélite | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| Opção de runner dentro de `use` | `PW-CORE-07` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `forbidOnly` ausente | `PW-CFG-01` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `trace: 'off'` em CI | `PW-CFG-02` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| URL absoluta no teste | `PW-CFG-05` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `...devices[...]` depois das opções próprias | `PW-CFG-06` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `reuseExistingServer: true` em CI | `PW-CFG-04` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `geolocation` sem `permissions` | `PW-CFG-07` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| Um project por ambiente (staging/prod) | § 8.6 do satélite | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| `--shard` sem `fullyParallel` | `PW-RUN-01` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| `retries` alto para calar flake | `PW-RUN-03` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| Retry sem trace | `PW-RUN-02` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| `test.fail` no lugar de `test.fixme` | `PW-RUN-04` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| `test.describe.serial`/`.parallel` (descontinuados) | `PW-RUN-05` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| Shard sem `blob` + `merge-reports` | `PW-RUN-06` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| `mode: 'serial'` sem motivo escrito | `PW-RUN-07` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| Instalar os três browsers para rodar um | § 9.6 do satélite | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| `fail-fast` default na matriz de shard | § 9.7 do satélite | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) |
| Screenshot onde aria snapshot serviria | `PW-SNAP-01` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| Referência de screenshot de outro SO | `PW-SNAP-02` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| `maxDiffPixels` inflado | `PW-SNAP-04` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| Bloquear imagens numa suíte com screenshot | `PW-SNAP-06` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| `-u` como reflexo, sem revisar o patch | `PW-SNAP-03` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
| Saída do codegen commitada como teste | `PW-DBG-06` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) |
| `console.log` como diagnóstico versionado | `PW-DBG-04` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) |
| `slowMo` no config versionado | § 9.7 do satélite | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) |
| Teste gerado por agente aceito sem revisão | `PW-AGT-04` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |
| Healer que apagou asserção | `PW-AGT-05` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |
| Definições de agente desatualizadas | `PW-AGT-02` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |
| `browser_run_code_unsafe` contra alvo não confiável | `PW-AGT-03` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |
| Sessão persistente de MCP com credencial de produção | `PW-AGT-06` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |

