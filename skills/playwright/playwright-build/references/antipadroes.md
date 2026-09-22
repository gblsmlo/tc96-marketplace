# Antipatterns this skill prevents, with IDs

> Check grid. Check the ID in `mapa-de-ids.md` before citing: `PW-ACT-07` and
> `PW-LOC-07` are **aliases** (use `PW-CORE-05` and `PW-EXP-01`).

| Antipattern | ID | Satellite |
| --- | --- | --- |
| E2E written by default, to verify a business rule | `PW-STR-*` + `TS-CORE-02` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| `waitForTimeout` as a wait | `PW-CORE-05` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `expect(await x.isVisible)` | `PW-EXP-01` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| web-first assertion without `await` | `PW-CORE-04` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `.first` to silence strict mode | `PW-LOC-02` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| a locator tied to a utility class | `PW-LOC-01` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `getByText` to click a button | `PW-LOC-01` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `ElementHandle` to "keep" the element | `PW-LOC-03` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| iterating with `all` without anchoring the list | § 4 of the satellite | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) |
| `force: true` to beat an overlay | `PW-ACT-01` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| an event wait armed after the action | `PW-ACT-03` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `waitUntil: 'networkidle'` | `PW-ACT-04` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `pressSequentially` as the default | `PW-ACT-02` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| a flow with `confirm` and no dialog handler | § 7.4 of the satellite | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) |
| `toPass` without a `timeout` | `PW-EXP-03` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `not.toBeVisible` as the only evidence | `PW-EXP-06` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) |
| `route` registered after the `goto` | `PW-NET-02` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| a response shape retyped by hand | `PW-NET-04` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| creating data through the UI to test something else | `PW-NET-06` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) |
| login in `beforeEach` | `PW-AUTH-01` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) |
| `beforeEach` copied between files | `PW-FIX-01` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| `return` instead of `await use(v)` | `PW-FIX-03` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| mixing the base `test` and the derived one | `PW-FIX-05` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) |
| a business assertion in the page object | `PW-STR-02` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| a page object returning `Promise<string>` | § 8.3 of the satellite | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| a hook inside the parameterization loop | `PW-STR-06` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| a `helpers.ts` that takes `page` | `PW-STR-07` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) |
| an absolute URL in the test | `PW-CFG-05` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) |
| codegen output committed as a test | `PW-DBG-06` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) |
| a screenshot where an aria snapshot would do | `PW-SNAP-01` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) |
