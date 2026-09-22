---
titulo: Playwright - Agents, CLI e MCP
Link: https://playwright.dev/docs/test-agents
tags:
 - playwright
 - testing
 - agents
 - mcp
 - cli
 - agent-context
source: "Documentação oficial do Playwright — Test Agents, Coding agents, Agent CLI (introduction/skills), MCP getting started"
verificado-em: 2026-08-20
---

# Playwright — Agents, CLI e MCP

> Satélite de [Playwright](playwright.md). Cobre as **três** superfícies pelas quais um agente encosta no Playwright, o que cada uma produz, e como decidir. A árvore está na § 5.7 do hub.
>
> **Por que este satélite existe separado.** As três têm nomes parecidos, documentação em três lugares diferentes do site, e ciclos de versão independentes. Confundi-las produz o pior resultado possível: trabalho de agente que não fica versionado, ou suíte gerada que ninguém revisou.

---

## 1. As três superfícies

| | **Test Agents** | **Agent CLI** | **MCP** |
| --- | --- | --- | --- |
| Pacote | embutido no `@playwright/test` | `@playwright/cli` **0.1.18** | `@playwright/mcp` **0.0.79** |
| Binário / entrada | `npx playwright init-agents` | `playwright-cli` | servidor MCP |
| Produz | **arquivos versionados** (`.md` + `.spec.ts`) | efeito no browser + saída no terminal | chamadas de ferramenta no cliente |
| Modo default | — | **headless** | **headed** |
| Custo de token | médio (roda como agente) | **baixo** — saída concisa, skills sob demanda | **alto** — schema das ferramentas + snapshots no contexto |
| Melhor para | criar e manter suíte | agente de código em repositório grande | loop agêntico exploratório |

Desde a **1.62** as duas últimas vêm embutidas: `npx playwright cli` e `npx playwright mcp`. Mas os pacotes continuam versionando sozinhos, **abaixo de 1.0** — é a parte instável da ferramenta, e a que muda de forma entre versões (`PW-AGT-02`).

**O critério em uma frase:** Test Agents quando o resultado deve sobreviver ao agente; CLI quando o agente vive num repositório e só às vezes precisa do browser; MCP quando o browser é a ferramenta principal do loop.

---

## 2. Test Agents

Três agentes, encadeáveis ou independentes:

| Agente | Faz |
| --- | --- |
| **planner** | explora a aplicação e produz um **plano de teste em Markdown** |
| **generator** | transforma o plano em **arquivos de Playwright Test** |
| **healer** | executa a suíte e **conserta** os testes que falham |

### 2.1 Instalar

```bash
npx playwright init-agents --loop=claude
npx playwright init-agents --loop=vscode
npx playwright init-agents --loop=codex
npx playwright init-agents --loop=opencode
```

O `--loop` escolhe o cliente. Para VS Code, a fonte declara requisito **v1.105+**.

### 2.2 O que aparece no repositório

```
repo/
.github/ # definições dos agentes
 specs/ # planos de teste
 basic-operations.md
 tests/ # testes gerados
 seed.spec.ts
 create/add-valid-todo.spec.ts
 playwright.config.ts
```

Três convenções:

- **`seed.spec.ts` — o seed test.** Dá contexto inicial de página e ambiente. É por onde o planner descobre como chegar ao estado a partir do qual explorar: qual URL, qual login, qual dado. Um seed ruim faz o planner explorar a tela de login.
- **`specs/*.md` — o plano legível.** Cenários em linguagem humana, com passos, resultado esperado e dado.
- **`tests/**` — os testes gerados**, alinhados **um-a-um** com as specs sempre que possível, com locators e asserções verificados ao vivo contra a aplicação.

### 2.3 O ciclo, e onde ele ganha

```
seed.spec.ts ──▶ planner ──▶ specs/*.md ──▶ generator ──▶ tests/**/*.spec.ts
 ▲ │
 └────────── healer ◀───────────┘
```

**A spec em Markdown é a peça que faz isso valer.** Ela é o que um humano revisa (é mais rápido ler um plano do que 300 linhas de teste), e é a entrada do healer — quando um teste quebra, o healer tem a *intenção* declarada, não só o código que falhou. Sem a spec versionada, o healer só sabe que uma linha falhou, e "consertar" pode significar deletar a asserção (`PW-AGT-05`).

**O healer produz teste passando ou teste `skip`** — se ele conclui que a funcionalidade está quebrada, ele marca em vez de forçar verde. Isso é o desenho certo, e é exatamente onde a revisão humana entra: um `skip` novo é um bug relatado, não uma tarefa concluída.

### 2.4 A restrição operacional

As definições geradas por `init-agents` são *"coleções de instruções e ferramentas MCP fornecidas pelo Playwright"* e **devem ser regeradas sempre que o Playwright for atualizado**. Elas embutem a lista de ferramentas daquela versão; desatualizadas, o agente chama ferramenta que não existe mais (`PW-AGT-02`).

### 2.5 O que revisar num teste gerado

Um teste gerado por agente é código de terceiro entrando no repositório. A revisão é a mesma de código escrito à mão (`PW-AGT-04`), e nesta ordem:

| Ordem | Verificar | Regra |
| --- | --- | --- |
| 1 | locator por papel, não CSS estrutural | `PW-LOC-01` |
| 2 | `.first` usado para calar strict mode | `PW-LOC-02` |
| 3 | asserção web-first, com `await` | `PW-EXP-01`, `PW-CORE-04` |
| 4 | `waitForTimeout` | `PW-CORE-05` |
| 5 | título que descreve comportamento | `PW-STR-04` |
| 6 | URL absoluta em vez de `baseURL` | `PW-CFG-05` |
| 7 | asserção deletada por um healer anterior | — |
| 8 | `test.skip` novo sem issue associada | `PW-STR-05` |

Os itens 7 e 8 são específicos de suíte mantida por agente e não existem em revisão comum. O item 7 é o risco central: a forma mais fácil de fazer um teste passar é remover o que ele afirmava.

---

## 3. Agent CLI — `@playwright/cli`

Um CLI de automação de browser *"desenhado para agentes de código"*.

```bash
npm install -g @playwright/cli@latest
```

```bash
playwright-cli open https://demo.playwright.dev/todomvc --headed
playwright-cli type "Comprar café"
playwright-cli press Enter
playwright-cli check e21
playwright-cli screenshot
```

Note `e21`: os comandos operam sobre **referências de elemento** que o próprio CLI emite num snapshot — não sobre seletores. É o que mantém a saída curta.

### 3.1 O problema que ele resolve

A fonte é explícita sobre a motivação: **orçamento de contexto**. Um agente de código precisa *"equilibrar automação de browser com bases de código grandes e raciocínio dentro de janelas de contexto limitadas"*. Um servidor MCP carrega schema de ferramentas e snapshots no contexto de forma permanente; um CLI é uma linha de comando com saída concisa.

### 3.2 Superfície

Categorias documentadas, com 70+ comandos: **core**, **navegação**, **teclado/mouse**, **abas**, **storage**, **rede**, **DevTools**, **sessões**, **config**.

```bash
playwright-cli goto <url>
playwright-cli click <ref> [button]
playwright-cli fill <ref> <text>
playwright-cli snapshot
playwright-cli go-back / go-forward / reload
playwright-cli state-save [arquivo]
playwright-cli cookie-list / localstorage-list
playwright-cli console [min-level]
playwright-cli eval <func> [ref]
playwright-cli tracing-start / video-start
playwright-cli tab-list
playwright-cli show # dashboard das sessões ativas
playwright-cli --help
```

### 3.3 Sessões e config

```bash
playwright-cli -s=todo-app open http://localhost:3000
PLAYWRIGHT_CLI_SESSION=todo-app playwright-cli click e12
playwright-cli open --persistent https://exemplo.com
```

Sessão nomeada mantém o browser entre comandos — é o que permite uma sequência de invocações independentes formar um fluxo. `--persistent` usa perfil persistente.

Config opcional, carregado automaticamente:

```
.playwright/cli.config.json
```

Aceita opções de browser, de contexto e regras de rede.

### 3.4 Skills

```bash
playwright-cli install --skills
```

Instala arquivos de skill locais para o agente consultar sob demanda. Áreas documentadas:

execução de teste · controle de rede (mock) · execução de script · gerenciamento de sessão · persistência de estado (cookies, `localStorage`) · geração de teste a partir de interação · trace · vídeo · inspeção de elemento.

Integram com **Claude Code**, **GitHub Copilot**, **Cursor** e qualquer agente que suporte skills instaladas localmente. E há a alternativa sem skills: apontar o agente para `playwright-cli --help` e deixá-lo descobrir.

> **Nota de verificação.** A página de skills **não documenta os caminhos de arquivo criados** por `install --skills`, nem nomes de arquivo. Verifique localmente antes de versionar ou ignorar no `.gitignore`.

> **Ponte com este vault.** As skills do `playwright-cli` são *skills de operação de browser*: elas ensinam o agente a **dirigir** o Playwright. As skills de `Skill` são *skills de decisão*: elas dizem o que carregar, o que verificar e como citar. As duas são complementares e não se substituem — um agente com as skills do CLI sabe clicar, e não sabe que `.first` é achado. A § 5 fecha essa lacuna.

---

## 4. MCP — `@playwright/mcp`

Servidor MCP que expõe o browser a um modelo. Opera por **snapshot estruturado de acessibilidade**, não por visão — o modelo age sobre referências extraídas da árvore de acessibilidade.

### 4.1 Instalar

**Claude Code:**

```bash
claude mcp add playwright npx @playwright/mcp@latest
```

**VS Code:**

```bash
code --add-mcp '{"name":"playwright","command":"npx","args":["@playwright/mcp@latest"]}'
```

**Config JSON padrão:**

```json
{
 "mcpServers": {
 "playwright": {
 "command": "npx",
 "args": ["@playwright/mcp@latest"]
 }
 }
}
```

**Cursor:** Settings → MCP → Add new MCP Server, comando `npx @playwright/mcp@latest`.

### 4.2 Flags

| Flag | Efeito |
| --- | --- |
| `--headless` | sem GUI — **o default é headed** |
| `--browser=<chrome\|firefox\|webkit\|msedge>` | escolhe o browser |
| `--isolated` | sessão nova a cada vez (o default é perfil persistente) |
| `--storage-state` | carrega autenticação/sessão inicial |
| `--extension` | conecta a abas de um browser já aberto |
| `--port 8931` | roda como servidor HTTP |
| `--config <arquivo>` | configuração avançada |

Capacidades: navegação, clique, digitação, screenshot, teclado/mouse, diálogos, abas, monitoramento e mock de rede, cookies e `localStorage`.

### 4.3 As duas decisões de segurança

**1. `browser_run_code_unsafe` executa Playwright arbitrário.** A própria fonte marca o risco de **RCE**. Habilitá-la contra um alvo que não é totalmente confiável entrega execução de código à página (`PW-AGT-03`).

**2. O default é perfil persistente, e não isolado.** Isso significa que a sessão do MCP acumula cookies e credenciais entre execuções. Combinado com um agente que navega para onde o conteúdo mandar, é a superfície clássica de injeção de prompt: conteúdo de página é **dado**, não instrução. Use `--isolated`, e nunca aponte uma sessão persistente autenticada em produção para navegação exploratória (`PW-AGT-06`).

---

## 5. Como este vault consome as três

O objetivo declarado desta estrutura é ser a primeira parada de um agente e a base de skills. A divisão que funciona:

| Camada | Onde vive | Responde |
| --- | --- | --- |
| **operação** | skills do `playwright-cli`, ferramentas do MCP | como clicar, navegar, tirar snapshot |
| **decisão** | esta estrutura — `Docs/Playwright*.md` | qual locator, qual asserção, onde o setup mora, o que é achado |
| **procedimento** | `Skill/*.md` | em que ordem carregar, o que varrer, como reportar |

Uma skill deste vault para Playwright deve, no mínimo:

1. Declarar a nota-fonte no frontmatter (`fonte:`), como as demais de `Skill`.
2. Carregar § 0, § 2, § 5 e § 6 do hub — nunca todos os satélites.
3. Citar por ID (`PW-LOC-02`), não parafrasear.
4. **Ler o trace antes de alterar teste que falha** (`PW-DBG-01`).
5. Tratar teste gerado por agente com a checklist da § 2.5.

Três recortes que fazem sentido como skill, e que fecham a lacuna da § 3.4:

| Skill | Fonte | Faz |
| --- | --- | --- |
| `playwright-build` | [Playwright - Locators](playwright-locators.md) | escreve teste novo: locator, asserção, estrutura, autoverificação |
| `playwright-review` | [Playwright](playwright.md) | revisa suíte por ID, na ordem que falha mais, com a checklist da § 2.5 para código gerado |
| `playwright-diagnose` | [Playwright - Debug e Trace](playwright-debug-e-trace.md) | percorre a § 5.2 do hub sobre um teste flaky, lendo trace antes de editar |

---

## 6. Regras — `PW-AGT-01` a `PW-AGT-06`

| ID | Regra |
| --- | --- |
| `PW-AGT-01` | Test Agents, `@playwright/cli` e `@playwright/mcp` **NEVER** são intercambiáveis. Ver a § 5.7 do hub antes de escolher. |
| `PW-AGT-02` | Definições geradas por `init-agents` **MUST** ser regeradas quando o Playwright subir de versão. |
| `PW-AGT-03` | `browser_run_code_unsafe` **NEVER** habilitado contra alvo não confiável — é execução remota de código. |
| `PW-AGT-04` | Teste produzido por agente **MUST** passar pelas mesmas regras `PW-LOC-*` e `PW-EXP-*` de teste escrito à mão, mais a checklist da § 2.5. † |
| `PW-AGT-05` | A spec em Markdown **MUST** ser versionada junto do teste gerado — ela é a intenção que o healer usa, e sem ela "consertar" pode significar apagar a asserção. † |
| `PW-AGT-06` | Sessão persistente de `playwright-cli` ou de MCP **NEVER** carrega credencial de produção. Para exploração, `--isolated`. † |

---

## 7. Antipadrões

### 7.1 Usar MCP para escrever a suíte

O trabalho acontece no loop e não fica no repositório: sem spec, sem arquivo, sem histórico. Na semana seguinte é preciso refazer. Test Agents existem exatamente para isso (`PW-AGT-01`).

### 7.2 Aceitar teste gerado sem revisar

```ts
// ✗ gerado, mesclado, e agora é dívida de todo mundo
await page.locator('div.card > div:nth-child(2) button').first.click;
await page.waitForTimeout(2000);
expect(await page.locator('.total').textContent).toBe('R$ 42,00');
```

Quatro violações numa tela: `PW-LOC-01`, `PW-LOC-02`, `PW-CORE-05`, `PW-EXP-01`. Geração automática amplia tanto acerto quanto erro (`PW-AGT-04`).

### 7.3 Healer que apaga asserção

```diff
- await expect(page.getByText('Pedido confirmado')).toBeVisible;
+ // asserção removida: elemento não encontrado
```

O teste fica verde e deixa de verificar o que existia para verificar. É o item 7 da checklist da § 2.5, e a razão de `PW-AGT-05`.

### 7.4 Regenerar suíte em vez de consertar produto

Se o healer conserta o mesmo teste a cada release, o sinal é sobre a **aplicação** — locator instável significa markup sem semântica estável, e a correção é dar papel e nome acessível ao componente ([Playwright - Locators](playwright-locators.md) § 8.4).

### 7.5 MCP persistente e autenticado apontado para a web aberta

Ver § 4.3. Conteúdo de página é dado, não instrução (`PW-AGT-06`).

### 7.6 Definições de agente desatualizadas

```bash
# ✗ instalado na 1.59, projeto hoje na 1.62
```

O agente chama ferramenta que mudou de forma, e o erro não diz que a causa é a versão (`PW-AGT-02`).

### 7.7 Instalar as três superfícies "por garantia"

Três superfícies num projeto que precisa de uma significa três coisas para manter atualizadas, e um agente com três caminhos para o mesmo objetivo escolhendo o mais caro. Escolha pela § 5.7.

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 5.7 escolhe a superfície e a § 7 é o contrato de skill
- [Playwright - Debug e Trace](playwright-debug-e-trace.md) — os artefatos que o healer lê
- [Playwright - Locators](playwright-locators.md) · [Playwright - Assertions](playwright-assertions.md) — a revisão da § 2.5
- [Playwright - Estrutura de Testes](playwright-estrutura-de-testes.md) — o que o generator não faz: estrutura
- `Skill` — o contrato de skill deste vault
- — a camada de decisão, e por que ela é separada da de operação
- [Claude API Docs](claude-api-docs.md) — tool use, do outro lado da mesma fronteira
- [Teste de Software](teste-de-software.md) — o que faz sentido automatizar antes de automatizar a automação

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Test Agents](https://playwright.dev/docs/test-agents) — planner/generator/healer, `init-agents`, estrutura de arquivos, seed e spec
- [Coding agents](https://playwright.dev/docs/getting-started-cli) — os comandos do `playwright-cli`, sessões, config, `install --skills`
- [Agent CLI — Introduction](https://playwright.dev/agent-cli/introduction) — a motivação de orçamento de contexto e a comparação CLI × MCP
- [Agent CLI — Skills](https://playwright.dev/agent-cli/skills) — as áreas de skill e os clientes suportados
- [MCP getting started](https://playwright.dev/docs/getting-started-mcp) — instalação por cliente, JSON, flags, e o aviso sobre `browser_run_code_unsafe`
- [Release notes](https://playwright.dev/docs/release-notes) — Test Agents na 1.59; CLI e MCP embutidos na 1.62
- Versões: `npm view @playwright/cli dist-tags` e `npm view @playwright/mcp dist-tags` em 2026-08-20

**Notas de verificação:**

- **`@playwright/cli` (0.1.18) e `@playwright/mcp` (0.0.79) versionam independentemente do `@playwright/test` (1.62.1)**, e ambos estão abaixo de 1.0.
- **O default de modo difere entre as duas**: CLI é headless, MCP é headed. Um script que assume o contrário abre janela em CI ou não abre onde se esperava.
- **O default de sessão do MCP é perfil persistente**, não isolado — decisão de segurança, não de conveniência.
- **`browser_run_code_unsafe` é marcada pela própria fonte como risco de RCE.**
- **Test Agents suportam VS Code (v1.105+), Claude Code, Codex e OpenCode** via `--loop`.
- **As definições de agente devem ser regeradas a cada atualização do Playwright** — elas embutem a lista de ferramentas MCP daquela versão.
- **A página de skills do CLI não documenta os caminhos de arquivo criados** por `install --skills`. Registrado como não verificado.
