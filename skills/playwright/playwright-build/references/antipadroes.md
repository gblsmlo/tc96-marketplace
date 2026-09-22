# Antipadrões que esta skill evita, com ID

> Grade de conferência. Confira o ID em `mapa-de-ids.md` antes de citar: `PW-ACT-07` e
> `PW-LOC-07` são **apelidos** (use `PW-CORE-05` e `PW-EXP-01`).

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| E2E escrito por default, para verificar regra de negócio | `PW-STR-*` + `TS-CORE-02` | [[Playwright - Estrutura de Testes]] |
| `waitForTimeout` como espera | `PW-CORE-05` | [[Playwright - Ações e Auto-waiting]] |
| `expect(await x.isVisible())` | `PW-EXP-01` | [[Playwright - Assertions]] |
| asserção web-first sem `await` | `PW-CORE-04` | [[Playwright - Assertions]] |
| `.first()` para calar strict mode | `PW-LOC-02` | [[Playwright - Locators]] |
| locator amarrado a classe utilitária | `PW-LOC-01` | [[Playwright - Locators]] |
| `getByText` para clicar em botão | `PW-LOC-01` | [[Playwright - Locators]] |
| `ElementHandle` para "guardar" o elemento | `PW-LOC-03` | [[Playwright - Locators]] |
| iterar com `all()` sem ancorar a lista | § 4 do satélite | [[Playwright - Locators]] |
| `force: true` para vencer overlay | `PW-ACT-01` | [[Playwright - Ações e Auto-waiting]] |
| espera de evento armada depois da ação | `PW-ACT-03` | [[Playwright - Ações e Auto-waiting]] |
| `waitUntil: 'networkidle'` | `PW-ACT-04` | [[Playwright - Ações e Auto-waiting]] |
| `pressSequentially` como default | `PW-ACT-02` | [[Playwright - Ações e Auto-waiting]] |
| fluxo com `confirm()` sem handler de diálogo | § 7.4 do satélite | [[Playwright - Ações e Auto-waiting]] |
| `toPass()` sem `timeout` | `PW-EXP-03` | [[Playwright - Assertions]] |
| `not.toBeVisible()` como única evidência | `PW-EXP-06` | [[Playwright - Assertions]] |
| `route` registrado depois do `goto` | `PW-NET-02` | [[Playwright - Rede e Mocking]] |
| shape de resposta redigitado à mão | `PW-NET-04` | [[Playwright - Rede e Mocking]] |
| criar dado pela UI para testar outra coisa | `PW-NET-06` | [[Playwright - Rede e Mocking]] |
| login em `beforeEach` | `PW-AUTH-01` | [[Playwright - Autenticação e Isolamento]] |
| `beforeEach` copiado entre arquivos | `PW-FIX-01` | [[Playwright - Fixtures]] |
| `return` no lugar de `await use(v)` | `PW-FIX-03` | [[Playwright - Fixtures]] |
| misturar o `test` base e o derivado | `PW-FIX-05` | [[Playwright - Fixtures]] |
| asserção de negócio no page object | `PW-STR-02` | [[Playwright - Estrutura de Testes]] |
| page object que devolve `Promise<string>` | § 8.3 do satélite | [[Playwright - Estrutura de Testes]] |
| hook dentro do laço de parametrização | `PW-STR-06` | [[Playwright - Estrutura de Testes]] |
| `helpers.ts` que recebe `page` | `PW-STR-07` | [[Playwright - Estrutura de Testes]] |
| URL absoluta no teste | `PW-CFG-05` | [[Playwright - Configuração e Projects]] |
| saída do codegen commitada como teste | `PW-DBG-06` | [[Playwright - Debug e Trace]] |
| screenshot onde aria snapshot serviria | `PW-SNAP-01` | [[Playwright - Snapshots e Visual]] |
