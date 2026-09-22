---
gerado-por: skills/playwright/playwright-review/scripts/gerar-mapa-de-ids.sh
gerado-em: 2026-09-22
---

# ID map `PW-*`

> An index, not a copy: it says **where** the rule is declared, never what it says.
> Regenerate with `bash skills/playwright/playwright-review/scripts/gerar-mapa-de-ids.sh` —
> the same file is written into all three Playwright skills.

## Aliases and near-aliases


**Dois** princípios aparecem em mais de um satélite com IDs diferentes, porque cada satélite precisa se sustentar sozinho. **Para citar, use sempre o ID canônico** — o outro é apelido e não deve aparecer em revisão.

| Princípio | Canônico | Apelido |
| --- | --- | --- |
| Espera por tempo fixo é bug | `PW-CORE-05` | `PW-ACT-07` |
| Afirmação sobre UI é web-first | `PW-EXP-01` | `PW-LOC-07` |

> **Quatro regras que parecem apelido e não são**, e por isso continuam citáveis por ID próprio:
>
> - `PW-CORE-04` (aguardar a `expect` com `await`) **não** é `PW-EXP-01`. Uma asserção web-first sem `await` é um caso *distinto* de uma asserção não-web-first bem aguardada: a primeira não afirma nada e passa sempre; a segunda afirma sobre um instante congelado. Os dois defeitos exigem correções diferentes.
> - `PW-FIX-02` (fixture worker-scoped sem estado sujo) e `PW-AUTH-03` (uma conta por worker) são **complementares**: a primeira é higiene de escopo, a segunda é alocação de recurso externo. Um projeto pode violar uma e cumprir a outra.
> - `PW-CFG-02` (o valor de `trace` no config) e `PW-DBG-01` (ler o trace antes de mexer no teste) são configuração e processo. Ter trace ligado e não olhar é exatamente o caso comum.
> - `PW-SNAP-01` (preferir aria snapshot) não substitui `PW-SNAP-02` (paridade de SO): quem escolhe screenshot conscientemente ainda precisa da segunda.


## Full index

| ID | Satellite | Section |
| --- | --- | --- |
| `PW-ACT-01` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) | 8. Regras — `PW-ACT-01` a `PW-ACT-07` |
| `PW-ACT-02` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) | 8. Regras — `PW-ACT-01` a `PW-ACT-07` |
| `PW-ACT-03` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) | 8. Regras — `PW-ACT-01` a `PW-ACT-07` |
| `PW-ACT-04` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) | 8. Regras — `PW-ACT-01` a `PW-ACT-07` |
| `PW-ACT-05` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) | 8. Regras — `PW-ACT-01` a `PW-ACT-07` |
| `PW-ACT-06` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) | 8. Regras — `PW-ACT-01` a `PW-ACT-07` |
| `PW-ACT-07` | [Playwright - Ações e Auto-waiting](../../../../knowledge-base/docs/playwright-acoes-e-auto-waiting.md) | 8. Regras — `PW-ACT-01` a `PW-ACT-07` |
| `PW-AGT-01` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) | 6. Regras — `PW-AGT-01` a `PW-AGT-06` |
| `PW-AGT-02` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) | 6. Regras — `PW-AGT-01` a `PW-AGT-06` |
| `PW-AGT-03` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) | 6. Regras — `PW-AGT-01` a `PW-AGT-06` |
| `PW-AGT-04` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) | 6. Regras — `PW-AGT-01` a `PW-AGT-06` |
| `PW-AGT-05` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) | 6. Regras — `PW-AGT-01` a `PW-AGT-06` |
| `PW-AGT-06` | [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) | 6. Regras — `PW-AGT-01` a `PW-AGT-06` |
| `PW-AUTH-01` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) | 8. Regras — `PW-AUTH-01` a `PW-AUTH-06` |
| `PW-AUTH-02` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) | 8. Regras — `PW-AUTH-01` a `PW-AUTH-06` |
| `PW-AUTH-03` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) | 8. Regras — `PW-AUTH-01` a `PW-AUTH-06` |
| `PW-AUTH-04` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) | 8. Regras — `PW-AUTH-01` a `PW-AUTH-06` |
| `PW-AUTH-05` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) | 8. Regras — `PW-AUTH-01` a `PW-AUTH-06` |
| `PW-AUTH-06` | [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) | 8. Regras — `PW-AUTH-01` a `PW-AUTH-06` |
| `PW-CFG-01` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) | 7. Regras — `PW-CFG-01` a `PW-CFG-07` |
| `PW-CFG-02` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) | 7. Regras — `PW-CFG-01` a `PW-CFG-07` |
| `PW-CFG-03` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) | 7. Regras — `PW-CFG-01` a `PW-CFG-07` |
| `PW-CFG-04` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) | 7. Regras — `PW-CFG-01` a `PW-CFG-07` |
| `PW-CFG-05` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) | 7. Regras — `PW-CFG-01` a `PW-CFG-07` |
| `PW-CFG-06` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) | 7. Regras — `PW-CFG-01` a `PW-CFG-07` |
| `PW-CFG-07` | [Playwright - Configuração e Projects](../../../../knowledge-base/docs/playwright-configuracao-e-projects.md) | 7. Regras — `PW-CFG-01` a `PW-CFG-07` |
| `PW-CORE-01` | [Playwright](../../../../knowledge-base/docs/playwright.md) | 6. Regras normativas |
| `PW-CORE-02` | [Playwright](../../../../knowledge-base/docs/playwright.md) | 6. Regras normativas |
| `PW-CORE-03` | [Playwright](../../../../knowledge-base/docs/playwright.md) | 6. Regras normativas |
| `PW-CORE-04` | [Playwright](../../../../knowledge-base/docs/playwright.md) | 6. Regras normativas |
| `PW-CORE-05` | [Playwright](../../../../knowledge-base/docs/playwright.md) | 6. Regras normativas |
| `PW-CORE-06` | [Playwright](../../../../knowledge-base/docs/playwright.md) | 6. Regras normativas |
| `PW-CORE-07` | [Playwright](../../../../knowledge-base/docs/playwright.md) | 6. Regras normativas |
| `PW-DBG-01` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) | 7. Regras — `PW-DBG-01` a `PW-DBG-06` |
| `PW-DBG-02` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) | 7. Regras — `PW-DBG-01` a `PW-DBG-06` |
| `PW-DBG-03` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) | 7. Regras — `PW-DBG-01` a `PW-DBG-06` |
| `PW-DBG-04` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) | 7. Regras — `PW-DBG-01` a `PW-DBG-06` |
| `PW-DBG-05` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) | 7. Regras — `PW-DBG-01` a `PW-DBG-06` |
| `PW-DBG-06` | [Playwright - Debug e Trace](../../../../knowledge-base/docs/playwright-debug-e-trace.md) | 7. Regras — `PW-DBG-01` a `PW-DBG-06` |
| `PW-EXP-01` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) | 9. Regras — `PW-EXP-01` a `PW-EXP-06` |
| `PW-EXP-02` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) | 9. Regras — `PW-EXP-01` a `PW-EXP-06` |
| `PW-EXP-03` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) | 9. Regras — `PW-EXP-01` a `PW-EXP-06` |
| `PW-EXP-04` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) | 9. Regras — `PW-EXP-01` a `PW-EXP-06` |
| `PW-EXP-05` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) | 9. Regras — `PW-EXP-01` a `PW-EXP-06` |
| `PW-EXP-06` | [Playwright - Assertions](../../../../knowledge-base/docs/playwright-assertions.md) | 9. Regras — `PW-EXP-01` a `PW-EXP-06` |
| `PW-FIX-01` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) | 9. Regras — `PW-FIX-01` a `PW-FIX-06` |
| `PW-FIX-02` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) | 9. Regras — `PW-FIX-01` a `PW-FIX-06` |
| `PW-FIX-03` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) | 9. Regras — `PW-FIX-01` a `PW-FIX-06` |
| `PW-FIX-04` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) | 9. Regras — `PW-FIX-01` a `PW-FIX-06` |
| `PW-FIX-05` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) | 9. Regras — `PW-FIX-01` a `PW-FIX-06` |
| `PW-FIX-06` | [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) | 9. Regras — `PW-FIX-01` a `PW-FIX-06` |
| `PW-LOC-01` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) | 7. Regras — `PW-LOC-01` a `PW-LOC-07` |
| `PW-LOC-02` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) | 7. Regras — `PW-LOC-01` a `PW-LOC-07` |
| `PW-LOC-03` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) | 7. Regras — `PW-LOC-01` a `PW-LOC-07` |
| `PW-LOC-04` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) | 7. Regras — `PW-LOC-01` a `PW-LOC-07` |
| `PW-LOC-05` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) | 7. Regras — `PW-LOC-01` a `PW-LOC-07` |
| `PW-LOC-06` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) | 7. Regras — `PW-LOC-01` a `PW-LOC-07` |
| `PW-LOC-07` | [Playwright - Locators](../../../../knowledge-base/docs/playwright-locators.md) | 7. Regras — `PW-LOC-01` a `PW-LOC-07` |
| `PW-NET-01` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) | 8. Regras — `PW-NET-01` a `PW-NET-07` |
| `PW-NET-02` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) | 8. Regras — `PW-NET-01` a `PW-NET-07` |
| `PW-NET-03` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) | 8. Regras — `PW-NET-01` a `PW-NET-07` |
| `PW-NET-04` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) | 8. Regras — `PW-NET-01` a `PW-NET-07` |
| `PW-NET-05` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) | 8. Regras — `PW-NET-01` a `PW-NET-07` |
| `PW-NET-06` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) | 8. Regras — `PW-NET-01` a `PW-NET-07` |
| `PW-NET-07` | [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) | 8. Regras — `PW-NET-01` a `PW-NET-07` |
| `PW-RUN-01` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) | 8. Regras — `PW-RUN-01` a `PW-RUN-07` |
| `PW-RUN-02` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) | 8. Regras — `PW-RUN-01` a `PW-RUN-07` |
| `PW-RUN-03` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) | 8. Regras — `PW-RUN-01` a `PW-RUN-07` |
| `PW-RUN-04` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) | 8. Regras — `PW-RUN-01` a `PW-RUN-07` |
| `PW-RUN-05` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) | 8. Regras — `PW-RUN-01` a `PW-RUN-07` |
| `PW-RUN-06` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) | 8. Regras — `PW-RUN-01` a `PW-RUN-07` |
| `PW-RUN-07` | [Playwright - Execução, Retries e CI](../../../../knowledge-base/docs/playwright-execucao-retries-e-ci.md) | 8. Regras — `PW-RUN-01` a `PW-RUN-07` |
| `PW-SNAP-01` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) | 6. Regras — `PW-SNAP-01` a `PW-SNAP-06` |
| `PW-SNAP-02` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) | 6. Regras — `PW-SNAP-01` a `PW-SNAP-06` |
| `PW-SNAP-03` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) | 6. Regras — `PW-SNAP-01` a `PW-SNAP-06` |
| `PW-SNAP-04` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) | 6. Regras — `PW-SNAP-01` a `PW-SNAP-06` |
| `PW-SNAP-05` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) | 6. Regras — `PW-SNAP-01` a `PW-SNAP-06` |
| `PW-SNAP-06` | [Playwright - Snapshots e Visual](../../../../knowledge-base/docs/playwright-snapshots-e-visual.md) | 6. Regras — `PW-SNAP-01` a `PW-SNAP-06` |
| `PW-STR-01` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) | 7. Regras — `PW-STR-01` a `PW-STR-07` |
| `PW-STR-02` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) | 7. Regras — `PW-STR-01` a `PW-STR-07` |
| `PW-STR-03` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) | 7. Regras — `PW-STR-01` a `PW-STR-07` |
| `PW-STR-04` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) | 7. Regras — `PW-STR-01` a `PW-STR-07` |
| `PW-STR-05` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) | 7. Regras — `PW-STR-01` a `PW-STR-07` |
| `PW-STR-06` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) | 7. Regras — `PW-STR-01` a `PW-STR-07` |
| `PW-STR-07` | [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md) | 7. Regras — `PW-STR-01` a `PW-STR-07` |
