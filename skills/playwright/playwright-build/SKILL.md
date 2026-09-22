---
nome: playwright-build
descricao: Escrever teste E2E novo com Playwright — locator na ordem de prioridade, asserção web-first, estrutura, e autoverificação executável de 12 itens antes de entregar, citando IDs `PW-*` da doc do vault — use quando a tarefa for escrever ou editar um `*.spec.ts`, cobrir uma jornada de usuário, montar page object ou fixture, preparar estado por API, ou substituir rede, relógio e sessão num teste. Não use para revisar suíte existente, que é playwright-review, para diagnosticar teste que já falha, que é playwright-diagnose, nem para decidir se o teste deveria ser E2E — essa decisão vem antes, em test-design.
tipo: skill
familia: playwright
fonte: "[Playwright - Locators](../../../knowledge-base/docs/playwright-locators.md)"
docs:
  - /microsoft/playwright
tags:
  - skill
  - playwright
  - testing
  - e2e
---

# playwright-build

> **Fonte desta skill:** [Playwright - Locators](../../../knowledge-base/docs/playwright-locators.md) e [Playwright - Assertions](../../../knowledge-base/docs/playwright-assertions.md), com o hub [Playwright](../../../knowledge-base/docs/playwright.md) como roteador. As 85 regras da família `PW-*` moram na § 6 do hub, com o corpo completo no satélite dono de cada ID.
> Esta skill **não contém** o texto das regras — ela diz o que carregar, em que ordem decidir e o que conferir antes de entregar.
> **Superfície de API:** resolva pelo Context7 — `/microsoft/playwright`. Assinatura, opção e comportamento por versão vêm de lá; a regra e o ID vêm da knowledge-base.

Contrato que esta skill implementa: [Playwright](../../../knowledge-base/docs/playwright.md) § 7 ("Contrato de skill").
Estrutura verificada contra playwright.dev em **2026-08-20**, sobre `@playwright/test` 1.62.1.

---

## Quando usar

Escrever ou editar teste que **vai existir**: um `*.spec.ts` novo, um caso a mais, um page object, uma fixture, um setup de autenticação.

| Situação | Vá para |
| --- | --- |
| revisar suíte que já existe | `playwright-review` |
| teste que falha, ou falha às vezes | `playwright-diagnose` — **leia o trace antes de editar** |
| decidir **se** isto deveria ser E2E | `test-design` — e a resposta costuma ser "não" |
| teste de unidade ou integração sob Bun | `bun-test-build` |
| estado visual de um componente | `storybook-story` · `storybook-test` |
| ligar agentes de teste no repositório | [Playwright - Agents, CLI e MCP](../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) |

**O corte que esta skill aplica antes de qualquer coisa:** se o que pode dar errado é uma **regra de negócio**, o teste não é E2E (`TS-CORE-02`). E2E cobre jornada crítica; regra vai para a camada mais barata.

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [Playwright](../../../knowledge-base/docs/playwright.md) § 0 | o piso de Node e a tabela de timeouts — `actionTimeout` é `0`, não 30 s |
| 2 | [Playwright](../../../knowledge-base/docs/playwright.md) § 2 | locator é consulta preguiçosa; a espera é da ferramenta |
| 3 | [Playwright](../../../knowledge-base/docs/playwright.md) § 6 e § 6.1 | as regras invioláveis e as críticas dos satélites |
| 4 | [Playwright - Locators](../../../knowledge-base/docs/playwright-locators.md) | nenhum teste existe sem locator |
| 5 | [Playwright - Assertions](../../../knowledge-base/docs/playwright-assertions.md) | o par inseparável do passo 4 |
| 6 | o satélite da superfície tocada | via § 4 do hub — rede, auth, fixture, snapshot |

**Nunca carregue os doze satélites.** Um teste de fluxo simples precisa de 1–5.

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/locator-e-assercao.md` | a ordem de prioridade, o que fazer com ambiguidade, a tabela de asserção |
| `references/ambiente-e-estrutura.md` | o que substituir, page object, fixture, as três invariantes |
| `references/autoverificacao.md` | os 12 itens e as três verificações que valem mais |
| `references/antipadroes.md` | 30 antipadrões com ID e satélite |
| `references/mapa-de-ids.md` | os 85 `PW-*` por satélite e seção, e os dois apelidos |
| `references/exemplo-pedido-na-lista.md` | caso trabalhado, das três perguntas à autoverificação |
| `scripts/autoverificar.sh` | roda os 12 itens sobre o arquivo que você acabou de escrever |

---

## Passo 1 — Três perguntas antes da primeira linha

| Pergunta | Se a resposta for… |
| --- | --- |
| **O que pode dar errado aqui?** | não sei dizer → o teste não deveria ser escrito ainda |
| **Isto é jornada, ou é regra?** | regra → não é E2E. Vá para `bun-test-build` |
| **Este estado já existe, ou preciso criá-lo?** | criar → **por API**, não pela UI (`PW-NET-06`) |

---

## Passo 2 — Locator, na ordem de prioridade

`getByRole` → `getByLabel`/`getByPlaceholder`/`getByAltText`/`getByText` → `getByTestId` (com dívida registrada) → CSS (com justificativa).

**Ambiguidade não se resolve com `.first`** (`PW-LOC-02`): `filter({ hasText })`, container, `filter({ has })`. Se `getByRole` não alcança, o achado costuma ser sobre o **componente**.

Detalhe: `references/locator-e-assercao.md`.

---

## Passo 3 — Asserção

**Afirme sobre a condição, nunca sobre um valor lido** (`PW-EXP-01`). E o defeito gêmeo, que passa **sempre**: asserção web-first sem `await` (`PW-CORE-04`) — a única defesa automática é `no-floating-promises`.

Nunca afirme ausência sozinha (`PW-EXP-06`). `toPass` sem `timeout` é achado (`PW-EXP-03`).

---

## Passo 4 — Ambiente: o que substituir

> **Se a dependência real divergisse, este teste deveria quebrar?** Sim → não substitua.

Rede de terceiro, API de browser, relógio e sessão se substituem; **estado de servidor se cria de verdade** via `request` (`PW-NET-06`). Shape de mock deriva do tipo do servidor (`PW-NET-04`). Tabela: `references/ambiente-e-estrutura.md`.

---

## Passo 5 — Estrutura

Page object para sequência de ações; fixture para setup com ciclo de vida; setup project para login. Três invariantes que geram retrabalho: page object **sem** asserção de negócio (`PW-STR-02`), page object devolve `Locator` e não `Promise<string>`, e `test`/`expect` de um **módulo único** do projeto (`PW-FIX-05`).

---

## Passo 6 — Autoverificar antes de entregar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/playwright-build/scripts/autoverificar.sh e2e/pedidos.spec.ts
```

Doze itens, mais as três que valem mais: **quebrar o código de propósito** e ver o teste ficar vermelho (`TS-TEC-08`), `--repeat-each=5`, e rodar a suíte inteira.

---

## Passo 7 — Fechar

1. **`--repeat-each=5`** no arquivo novo. Verde cinco vezes, não uma.
2. **A suíte inteira ainda passa** — teste novo que suja estado quebra o vizinho.
3. **Se precisou de `getByTestId` ou CSS**, registre a dívida (`PW-LOC-04`).
4. **Se ficou lento ou frágil**, a pergunta é de nível — `test-design`.
5. **Declare o que não cobriu** (`TS-TIPO-02`).

---

## Exemplo

*"O pedido criado aparece na lista."* A terceira pergunta do Passo 1 troca doze cliques por um `POST`, e o teste passa a falhar por **um** motivo. O locator é `getByRole('row').filter({ hasText })` — não `.nth(1)`; a asserção é web-first; a navegação é relativa.

Caso completo: `references/exemplo-pedido-na-lista.md`.

---

## Relacionados

- [Playwright - Locators](../../../knowledge-base/docs/playwright-locators.md) — fonte desta skill
- [Playwright - Assertions](../../../knowledge-base/docs/playwright-assertions.md) — a segunda fonte, inseparável da primeira
- [Playwright](../../../knowledge-base/docs/playwright.md) — o hub: § 0, § 2, § 5, § 6, § 7
- `playwright-review` · `playwright-diagnose` — as skills irmãs
- `test-design` — decide **se** o teste é E2E, antes desta skill começar
- `bun-test-build` · `storybook-test` — os outros níveis
