---
titulo: Playwright
Link: https://playwright.dev/docs
tags:
  - playwright
  - testing
  - e2e
  - frontend
  - agents
  - reference
  - agent-context
source: "Documentação oficial do Playwright — playwright.dev/docs, linha 1.62"
verificado-em: 2026-08-20
---
# Playwright — referência conduzida

> **O que esta nota é.** O ponto de entrada único para Playwright neste vault: para mim ao consultar, e para agentes de código ao escrever, revisar, executar ou consertar testes. Não é um resumo linear da documentação — é um **roteador**. Ela decide o que carregar, oferece o modelo mental que faz o resto fazer sentido, e expõe regras citáveis que uma skill ou um code review pode referenciar por ID.
>
> **O que não é.** Não substitui a fonte. Quando houver divergência, [playwright.dev/docs](https://playwright.dev/docs) vence, e esta nota deve ser corrigida.

Inventário verificado diretamente em playwright.dev em **2026-08-20**.
Ver [Fontes consultadas](#fontes-consultadas).

**Versões confirmadas no registry npm na mesma data:**

| Pacote | `latest` | Observação |
| --- | --- | --- |
| `@playwright/test` | **1.62.1** | o runner; é o que se instala |
| `playwright` | 1.62.1 | a Library; lockstep com o runner |
| `playwright-core` | 1.62.1 | dependência interna |
| `@playwright/experimental-ct-react` | 1.62.1 | ver a § 8 sobre component testing |
| `@playwright/cli` | **0.1.18** | binário `playwright-cli`; **versiona sozinho** |
| `@playwright/mcp` | **0.0.79** | servidor MCP; **versiona sozinho** |

`@playwright/test`, `playwright` e `playwright-core` publicam em lockstep — divergência entre eles no `package.json` é bug de instalação, não escolha. **`@playwright/cli` e `@playwright/mcp` não seguem esse número** e estão os dois abaixo de `1.0`: é a fronteira instável da ferramenta, e é justamente a fronteira que interessa a agentes. Ver [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md).

---

## 0. Antes de tudo

Três fatos que decidem se o projeto sobe, e que quase nunca são o que se supõe.

**1. Node ≥ 22.** A fonte declara suporte a **22.x, 24.x e 26.x**. Node 20 saiu da matriz. Isso conflita com o piso de outras estruturas deste vault — [Storybook](storybook.md) exige Node 20.19+/22.12+, o que é *compatível*, mas um projeto parado em Node 20 roda Storybook e **não** roda Playwright 1.62 (`PW-CORE-01`).

**2. Os defaults de timeout não são o que se assume.** Não existe timeout de ação de 30 s:

| Timeout | Default | Onde se ajusta |
| --- | --- | --- |
| **teste** | **30 000 ms** | `timeout` top-level, `test.setTimeout()`, `test.slow()` |
| **asserção** (`expect`) | **5 000 ms** | `expect: { timeout }`, ou opção da própria asserção |
| **ação** (`actionTimeout`) | **0 — sem timeout** | `use: { actionTimeout }`, ou opção da ação |
| **navegação** (`navigationTimeout`) | **0 — sem timeout** | `use: { navigationTimeout }`, ou opção do `goto` |
| **global** (`globalTimeout`) | **0 — sem timeout** | só no config |
| **`beforeAll`/`afterAll`** | 30 000 ms | `test.setTimeout()` dentro do hook |
| **fixture** | compartilha o do teste | `{ timeout }` na definição da fixture |

Ação e navegação **não têm limite próprio**: elas são limitadas apenas pelo teto de 30 s do teste. É por isso que um clique num elemento que nunca aparece falha com "Test timeout of 30000ms exceeded" e não com um erro de clique — o diagnóstico está no trace, não na mensagem. Ver a § 5.5.

**3. Existem três superfícies de agente, e elas não são a mesma coisa.** Confundi-las é o erro mais caro desta doc:

| Superfície | Pacote | O que é |
| --- | --- | --- |
| **Test Agents** | embutido (`npx playwright init-agents`) | planner / generator / healer — produzem e consertam **suíte versionada** |
| **Agent CLI** | `@playwright/cli` | comandos de browser para agente de código; **headless** por default, baixo custo de token |
| **MCP** | `@playwright/mcp` | servidor MCP; **headed** por default, custo de token maior |

A escolha está na § 5.7, e o detalhe em [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md).

---

## 1. Como usar esta doc

### Para um humano

Leia a § 2 (modelo mental) uma vez — ela é a diferença entre escrever um teste que só passa hoje e um que continua passando. Depois use a § 4 como índice e a § 5 quando estiver na dúvida entre duas APIs. Os satélites são leitura sob demanda, não em ordem.

Se o problema é "meu teste é flaky", vá direto à § 5.2. Ela é a razão principal desta estrutura existir.

### Para um agente de código

Carregue nesta ordem, parando assim que tiver o suficiente:

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (§ 0, § 2, § 5, § 6) | Sempre que a tarefa envolver Playwright |
| 2 | [Playwright - Locators](playwright-locators.md) | Sempre que for **escrever ou editar** um teste — nenhum teste existe sem locator |
| 3 | [Playwright - Assertions](playwright-assertions.md) | Junto com o passo 2, ao escrever teste novo |
| 4 | O satélite do domínio específico | Quando a tarefa toca uma superfície concreta — use a § 4 para descobrir qual |
| 5 | [Playwright - Debug e Trace](playwright-debug-e-trace.md) | Antes de alterar qualquer teste que **já falha** |

**Regra de economia de contexto:** nunca carregue todos os satélites. Escrever um teste de fluxo simples precisa de § 2 + § 6 + [Playwright - Locators](playwright-locators.md) + [Playwright - Assertions](playwright-assertions.md). Ver os recortes prontos na § 7.

**A regra que mais economiza retrabalho:** antes de consertar um teste que falha, leia o trace (`PW-DBG-01`). Editar o teste às cegas produz o padrão mais comum de dívida de suíte — um `waitForTimeout` que esconde o defeito real.

### Convenções e vocabulário

**Todos os exemplos são TypeScript** e importam de `@playwright/test`. Onde a fonte oferece variantes em Python, Java e .NET, esta doc cobre só Node.

Termos usados sem redefinição nos satélites:

| Termo | Significado nesta doc |
| --- | --- |
| **locator** | uma *consulta* por elemento, resolvida de novo a cada uso. Não é um elemento |
| **strict mode** | o comportamento default: locator que resolve para mais de um elemento faz a ação falhar |
| **actionability** | o conjunto de checagens (visível, estável, recebe eventos, habilitado, editável) que uma ação espera antes de agir |
| **asserção web-first** | `expect(locator).…` — reavalia e reespera até passar ou estourar o timeout |
| **fixture** | unidade de setup/teardown sob demanda, tipada e componível; a unidade de arquitetura da suíte |
| **worker** | processo do SO que executa testes; cada um tem seu próprio browser |
| **BrowserContext** | perfil isolado tipo aba anônima; barato de criar. A unidade de isolamento de um teste |
| **project** | grupo lógico de testes com a mesma configuração (um browser, um device, um papel) |
| **setup project** | project referenciado por `dependencies`, que roda antes e prepara estado |
| **`storageState`** | cookies + `localStorage` serializados; o veículo de "já estou logado" |
| **trace** | gravação navegável de uma execução: ações, snapshots de DOM, rede, console, fonte |
| **spec** (contexto de agente) | plano em Markdown produzido pelo planner, entrada do generator e do healer |

---

## 2. Modelo mental

Cinco afirmações. Quase todo teste flaky que um agente escreve viola uma delas.

**1. Um locator é uma consulta preguiçosa, não um elemento.** `page.getByRole('button')` não busca nada — ele descreve como buscar. A busca acontece a cada ação e a cada asserção, contra o DOM daquele instante. Duas consequências práticas: guardar um locator numa variável (ou numa propriedade de page object) é grátis e correto, e um locator não "envelhece" quando a página re-renderiza. É o oposto de um `ElementHandle`, que aponta para um nó específico e apodrece.

**2. A espera é da ferramenta, não do teste.** Toda ação roda actionability checks antes de agir; toda asserção web-first reespera até passar. O tempo que um teste bem escrito passa esperando é implícito e adaptativo. Um `waitForTimeout` no meio de um teste não é "uma espera": é a declaração de que quem escreveu não sabia o que estava esperando — e é, ao mesmo tempo, lento quando a máquina está rápida e insuficiente quando está lenta.

**3. Afirmar sobre a UI é sempre `expect(locator)`, nunca `expect(await …)`.** A diferença não é estilística. `expect(await locator.isVisible()).toBe(true)` lê um booleano de um instante e afirma sobre esse instante congelado — se o elemento aparece 40 ms depois, o teste falha e o defeito não existe. `expect(locator).toBeVisible()` afirma sobre a **condição**, e reespera. As duas linhas parecem equivalentes e têm confiabilidade oposta.

**4. Isolamento é por `BrowserContext`, e é barato.** Cada teste recebe um contexto novo — cookies, storage e cache próprios. Isso não é uma otimização: é o que permite paralelismo, retry e execução em qualquer ordem. Todo estado compartilhado entre testes é, portanto, uma decisão explícita que alguém tomou — via `storageState`, fixture worker-scoped ou `mode: 'serial'` — e que deve estar escrita. Estado compartilhado por acidente é a origem da falha que só acontece em CI.

**5. A fixture é a unidade de arquitetura; o hook é o caso degenerado.** `beforeEach` é local ao arquivo, invisível no relatório, não componível e roda mesmo quando o teste não precisa dele. Uma fixture é sob demanda (não roda se ninguém pedir), tipada, herdável entre arquivos, escopável por worker, e aparece no trace. Quase toda duplicação de setup entre arquivos de teste era uma fixture não extraída.

> **A inversão que importa.** É tentador ler o Playwright como uma biblioteca de automação de browser que ganhou um runner por cima. É o contrário: o produto é o **runner**, e é ele que converte automação em teste confiável — isolamento por contexto, retry em worker novo, trace, asserção com retry, projects. A Library (`playwright`) existe para automação que não é teste (scraping, geração de PDF, robô). Usá-la numa suíte de teste é abrir mão das quatro coisas que fazem a suíte valer algo (`PW-CORE-02`).

---

## 3. Fronteiras de pacote

Saber de onde algo vem evita a maior parte dos erros de import.

| Import | Contém |
| --- | --- |
| `@playwright/test` | `test`, `expect`, `defineConfig`, `devices`, `mergeTests`, `mergeExpects`, `chromium`/`firefox`/`webkit`, `request` |
| `@playwright/test/reporter` | tipos de reporter customizado: `Reporter`, `TestCase`, `TestResult`, `FullConfig`, `FullResult`, `Suite` |
| `playwright` | a **Library**: `chromium.launch()` e afins, sem runner. Não é para suíte de teste (`PW-CORE-02`) |
| `@playwright/experimental-ct-react` | component testing legado — **substituído** pelo modelo de stories da própria `@playwright/test` na 1.62. Ver § 8 |
| `@axe-core/playwright` | `AxeBuilder`, para varredura de acessibilidade. É pacote de terceiro, não do Playwright |
| `@playwright/cli` | binário `playwright-cli`, global. Não é dependência de projeto |
| `@playwright/mcp` | servidor MCP, executado via `npx`. Não é dependência de projeto |

**A confusão que mais custa:** `expect` do `@playwright/test` **não** é o `expect` do Jest nem do Vitest, embora a superfície genérica (`toBe`, `toEqual`) coincida. O que ele tem a mais são as asserções que reesperam, e é só isso que importa numa suíte de browser. Importar `expect` de outro lugar num teste de Playwright desliga silenciosamente o retry.

**Tipos vindos de `test`:** um `test` estendido por `test.extend` **substitui** o `test` base no arquivo. Misturar os dois no mesmo arquivo produz testes que não recebem as fixtures customizadas, sem erro de compilação (`PW-FIX-05`).

---

## 4. Mapa da API

Superfície ativa do que se usa em código novo. A coluna **Satélite** diz o que carregar.

**Deliberadamente fora deste mapa:** os bindings Python/Java/.NET; Android e Electron; `connectOverCDP` e grid remoto; WebView2; extensões de Chrome; Service Workers como assunto próprio (só aparece como causa de rede sumida, § 5.4); `page.screencast` e a API de vídeo além do que o config expõe; `browser.bind()`. Se a tarefa exigir um deles, consulte a fonte: a ausência aqui significa "não verificado nesta doc", não "não existe".

### 4.1 `playwright.config.ts` — nível superior

Opções do **runner**. A fonte é explícita: elas são top-level e **não** vão dentro de `use` (`PW-CORE-07`).

| Campo | Para que serve | Default | Satélite |
| --- | --- | --- | --- |
| `testDir` | onde os testes vivem | — | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `projects` | grupos de configuração | — | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `use` | opções de fixture/browser (§ 4.2) | — | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `webServer` | sobe o app antes dos testes | — | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `fullyParallel` | paraleliza também **dentro** do arquivo | `false` | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `workers` | processos concorrentes | metade dos núcleos lógicos | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `retries` | tentativas por teste | `0` | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `retryStrategy` | `'immediate'` ou `'isolated'` | `'immediate'` | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `forbidOnly` | falha se houver `test.only` | `false` | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `failOnFlakyTests` | falha se algum teste for flaky | `false` | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `maxFailures` | aborta depois de N falhas | `0` (desligado) | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `globalTimeout` | teto da suíte inteira | `0` (desligado) | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `timeout` | timeout por teste | `30_000` | § 0 |
| `expect` | `timeout` e defaults de `toHaveScreenshot`/`toMatchSnapshot`/`toMatchAriaSnapshot` | — | [Playwright - Assertions](playwright-assertions.md) |
| `reporter` | um ou vários reporters | `list` local, `dot` em CI | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `outputDir` | artefatos de execução | `test-results` | [Playwright - Debug e Trace](playwright-debug-e-trace.md) |
| `snapshotPathTemplate` | onde os snapshots moram | — | [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) |
| `updateSnapshots` | `'all'`/`'changed'`/`'missing'`/`'none'` | `'missing'` | [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) |
| `updateSourceMethod` | `'patch'`/`'3way'`/`'overwrite'` | `'patch'` | [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) |
| `testMatch`, `testIgnore` | filtro de descoberta | — | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `globalSetup`, `globalTeardown` | setup fora do runner — **não é o caminho recomendado** | — | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `tsconfig` | um `tsconfig` para todos os arquivos importados | — | — |
| `captureGitInfo` | grava info de git no metadata | — | — |

### 4.2 `use` — opções de fixture e browser

Valem em `use` top-level, em `projects[].use` e em `test.use()`, do mais geral para o mais específico.

| Grupo | Opções | Satélite |
| --- | --- | --- |
| **básico** | `baseURL`, `storageState` | [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) |
| **browser** | `browserName`, `channel`, `headless`, `launchOptions` | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| **emulação** | `viewport`, `deviceScaleFactor`, `isMobile`, `hasTouch`, `locale`, `timezoneId`, `geolocation`, `permissions`, `colorScheme`, `userAgent`, `javaScriptEnabled` | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| **rede** | `extraHTTPHeaders`, `httpCredentials`, `ignoreHTTPSErrors`, `offline`, `proxy`, `acceptDownloads`, `serviceWorkers`, `bypassCSP` | [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) |
| **gravação** | `trace`, `video`, `screenshot` | [Playwright - Debug e Trace](playwright-debug-e-trace.md) |
| **timeout** | `actionTimeout`, `navigationTimeout` | § 0 |
| **locator** | `testIdAttribute` | [Playwright - Locators](playwright-locators.md) |

Os valores completos de `trace`, `video` e `screenshot` — que são **sete, sete e quatro**, não três — estão em [Playwright - Debug e Trace](playwright-debug-e-trace.md) § 1.

### 4.3 Locators

| API | Para que serve | Satélite |
| --- | --- | --- |
| `getByRole` | **o default**: papel ARIA + nome acessível | [Playwright - Locators](playwright-locators.md) |
| `getByText`, `getByLabel`, `getByPlaceholder`, `getByAltText`, `getByTitle` | os outros locators voltados ao usuário | [Playwright - Locators](playwright-locators.md) |
| `getByTestId` | escape hatch estável, sem semântica de usuário | [Playwright - Locators](playwright-locators.md) |
| `locator(css \| xpath)` | último recurso | [Playwright - Locators](playwright-locators.md) |
| `filter({ hasText, hasNotText, has, hasNot, visible })` | estreitar sem quebrar strict mode | [Playwright - Locators](playwright-locators.md) |
| `and`, `or` | combinar condições | [Playwright - Locators](playwright-locators.md) |
| `first`, `last`, `nth`, `all`, `count` | listas e posição | [Playwright - Locators](playwright-locators.md) |
| `describe` | rótulo do locator no trace e no relatório | [Playwright - Debug e Trace](playwright-debug-e-trace.md) |

### 4.4 Asserções

| Grupo | Exemplos | Satélite |
| --- | --- | --- |
| **web-first, com retry** | `toBeVisible`, `toHaveText`, `toHaveCount`, `toHaveValue`, `toBeEnabled`, `toHaveURL`, `toHaveScreenshot`, `toMatchAriaSnapshot` | [Playwright - Assertions](playwright-assertions.md) |
| **genéricas, sem retry** | `toBe`, `toEqual`, `toContain`, `toHaveLength`, `toThrow` | [Playwright - Assertions](playwright-assertions.md) |
| **de resposta** | `toBeOK` | [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) |
| **utilitários** | `expect.soft`, `expect.poll`, `expect(fn).toPass`, `expect.configure`, `expect.extend`, `mergeExpects` | [Playwright - Assertions](playwright-assertions.md) |

### 4.5 CLI

| Comando | Para que serve | Satélite |
| --- | --- | --- |
| `npx playwright test` | roda a suíte; ~30 flags | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `npx playwright show-report` / `show-trace` | abre relatório HTML / trace | [Playwright - Debug e Trace](playwright-debug-e-trace.md) |
| `npx playwright codegen` | grava interação e gera teste | [Playwright - Debug e Trace](playwright-debug-e-trace.md) |
| `npx playwright install [--with-deps]` | baixa browsers e dependências de sistema | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `npx playwright merge-reports` | une `blob` de shards | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `npx playwright init-agents --loop=…` | instala definições de Test Agent | [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) |
| `npx playwright mcp` / `npx playwright cli` | as superfícies de agente, embutidas desde 1.62 | [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) |

---

## 5. Árvores de decisão

### 5.1 Qual locator usar

```
O elemento tem papel e nome acessível? (botão, link, campo rotulado, cabeçalho)
├─ SIM  → getByRole('papel', { name })            ← o default, e o caminho certo em >80% dos casos
└─ NÃO
   ├─ É um campo de formulário com <label>?       → getByLabel
   ├─ É um campo sem label, só com placeholder?   → getByPlaceholder
   │                                                 (e o achado real é o label ausente — ver § 8)
   ├─ É uma imagem?                               → getByAltText
   ├─ É texto puro, não interativo?               → getByText
   └─ Nada acima serve, e mexer no componente não é opção agora?
      → getByTestId  (e registre a dívida)
         └─ nem isso? → locator('css=…')  ← último recurso, justifique no código
```

Resolveu para mais de um elemento (strict mode violation)? **A resposta não é `.first()`.** É, nesta ordem: `filter({ hasText })`, encadear dentro de um container (`page.getByRole('listitem').filter(…).getByRole('button')`), ou `filter({ has: … })`. `nth`/`first`/`last` só quando a posição *é* o critério — "o primeiro resultado da busca" (`PW-LOC-02`).

### 5.2 O teste é flaky — o que fazer

Esta é a árvore mais usada da doc. Percorra na ordem; **não pule para o fim**.

```
1. Existe waitForTimeout no teste?
   → remova. É a causa, não o sintoma (PW-CORE-05)

2. Alguma asserção lê valor antes de afirmar?
   expect(await x.isVisible()).toBe(true) / expect(await x.textContent()).toBe('y')
   → troque por asserção web-first (PW-EXP-01)

3. O teste espera navegação/evento DEPOIS de disparar a ação?
   → arme a espera antes: const p = page.waitForEvent(…); await acao(); await p (PW-ACT-03)

4. Tem waitUntil: 'networkidle'?
   → remova. A fonte desencoraja explicitamente (PW-ACT-04)

5. O teste depende de dado que outro teste criou?
   → é dependência de ordem. Isole por fixture, ou declare mode:'serial' (PW-CORE-06)

6. Falha só em CI, passa local?
   ├─ é screenshot?          → SO/versão diferentes (PW-SNAP-02)
   ├─ é timing?              → CI é mais lento; o teto de 30 s do teste está sendo atingido
   │                            por espera legítima. Leia o trace antes de subir timeout
   └─ é estado de servidor?  → workers concorrendo pela mesma conta (PW-AUTH-03)

7. Falha só com paralelismo? (passa com --workers=1)
   → estado compartilhado: conta, registro no banco, arquivo, porta

8. Nada acima
   → LEIA O TRACE (PW-DBG-01). Não altere o teste antes disso.
```

**O que nunca é a resposta:** subir `retries`. Retry esconde flake, não conserta (`PW-RUN-03`). Ele existe para absorver a instabilidade *residual* de uma suíte já sã.

### 5.3 Onde colocar setup

```
Vale para UM arquivo, e é trivial?
└─ test.beforeEach no arquivo

Vale para vários arquivos, ou tem teardown, ou é tipado?
└─ fixture (test.extend)                              ← o caso normal (PW-FIX-01)
   ├─ precisa rodar por teste?     → escopo default
   ├─ é caro e reusável?           → { scope: 'worker' }
   ├─ deve rodar sempre?           → { auto: true }
   └─ é parâmetro de suíte?        → { option: true } + projects[].use

Precisa rodar UMA vez antes de tudo, e o resultado é estado externo?
└─ setup project + dependencies                       ← o recomendado pela fonte
   (login, semear banco, subir tenant)
   └─ e limpar depois? → teardown: 'nome-do-project'

Precisa rodar antes do runner existir?
└─ globalSetup/globalTeardown  ← último recurso: sem trace, sem fixture,
                                  não aparece no relatório (PW-CFG-03)
```

### 5.4 Como substituir o mundo externo

```
O que substituir?
├─ resposta HTTP de API
│  ├─ quero resposta inventada       → route.fulfill({ json })
│  ├─ quero a real, com um ajuste    → route.fetch() + fulfill({ response, json })
│  └─ quero congelar o tráfego real  → routeFromHAR (update:true grava, false replica)
├─ WebSocket                         → routeWebSocket
├─ API do browser (bateria, geo, …)  → page.addInitScript  ANTES do goto
├─ o tempo                           → page.clock (setFixedTime, ou install+pauseAt+fastForward)
└─ o estado do servidor
   └─ NÃO mocke: crie de verdade via request (APIRequestContext) — é mais fiel e mais rápido que UI

Os eventos de rede simplesmente não aparecem?
→ serviceWorkers: 'block'. É a causa mais comum e a menos óbvia (PW-NET-03)
```

### 5.5 Qual timeout mexer

O erro diz "Test timeout of 30000ms exceeded"? **Normalmente o problema não é o timeout.** Percorra:

```
A mensagem aponta uma ação ou asserção específica?
├─ SIM → o alvo nunca ficou acionável. Vá para a § 5.2. NÃO suba timeout
└─ NÃO → o teste é genuinamente longo (upload grande, job assíncrono, migração)
   ├─ é este teste só?          → test.setTimeout(n) ou test.slow()
   ├─ é toda a suíte?           → timeout no config
   ├─ é uma fixture caríssima?  → { timeout } na fixture (ela tem teto próprio)
   └─ é uma asserção que legitimamente demora?
      → opção da asserção: expect(x).toBeVisible({ timeout: 30_000 })
         NUNCA expect.timeout global — isso afrouxa a suíte inteira
```

`actionTimeout` e `navigationTimeout` são a exceção que raramente vale ligar: por default são `0`, e o teto do teste já os cobre. Ligá-los serve para obter **mensagem de erro melhor** (falha na ação, não no teste), não para deixar o teste mais rápido.

### 5.6 Qual snapshot usar

```
Quero verificar ESTRUTURA e semântica (o que um leitor de tela veria)?
└─ toMatchAriaSnapshot   ← preferir. Resistente a CSS, legível no diff,
                            e verifica acessibilidade de graça (PW-SNAP-01)

Quero verificar PIXEL (o layout renderizado)?
└─ toHaveScreenshot      ← exige SO/versão iguais aos do CI (PW-SNAP-02)
   └─ tem região não determinística? → stylePath ou mask, nunca maxDiffPixels inflado

Quero verificar texto ou dado serializável fora da UI?
└─ toMatchSnapshot

Quero verificar UMA condição precisa?
└─ nenhum snapshot: asserção comum. Snapshot para condição única
   é diff ruidoso com informação de menos
```

### 5.7 Qual superfície de agente

```
O objetivo é uma SUÍTE VERSIONADA que sobrevive ao agente?
└─ Test Agents: npx playwright init-agents --loop=claude
   planner → spec .md → generator → *.spec.ts → healer conserta quando quebra

O objetivo é um AGENTE DE CÓDIGO que às vezes precisa olhar o browser,
dentro de um repositório grande?
└─ @playwright/cli (playwright-cli)
   headless por default, saída concisa, skills sob demanda — menor custo de token

O objetivo é um LOOP AGÊNTICO exploratório, com o browser como ferramenta de primeira classe?
└─ @playwright/mcp
   headed por default, snapshot de acessibilidade no contexto — maior custo de token
```

As três podem coexistir. O que não pode é usar MCP para escrever suíte (o resultado não fica versionado) nem Test Agents para exploração livre (eles produzem arquivos). Ver [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md).

---

## 6. Regras normativas

Regras citáveis por ID. Uma skill, um prompt de revisão ou um comentário de PR pode referenciar `PW-LOC-02` sem repetir o texto. O corpo completo de cada família vive no satélite correspondente; aqui ficam as invioláveis.

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.
**Marcação de origem:** regras sem marca vêm de afirmação explícita da fonte. Regras marcadas **†** são decisão desta doc — coerentes com a fonte, mas não ditadas por ela. Uma revisão pode discutir uma regra †; não pode discutir as outras sem ir à fonte.

### `PW-CORE-*` — invariantes de projeto

| ID | Regra |
| --- | --- |
| `PW-CORE-01` | Node **MUST** ser 22.x, 24.x ou 26.x. Node 20 **NEVER** — saiu da matriz de suporte na linha 1.62. |
| `PW-CORE-02` | Suíte de teste **MUST** importar `test` e `expect` de `@playwright/test`. A Library `playwright` **NEVER** em teste — abre mão de isolamento, retry, trace e asserção com retry. |
| `PW-CORE-03` | `@playwright/test` e `playwright` **MUST** estar na mesma versão. |
| `PW-CORE-04` | Toda `expect` sobre `Locator`, `Page` ou `APIResponse` **MUST** ser aguardada com `await`. |
| `PW-CORE-05` | `page.waitForTimeout()` **NEVER** em teste versionado. † |
| `PW-CORE-06` | Um teste **NEVER** depende de outro ter rodado antes, salvo `mode: 'serial'` declarado explicitamente. † |
| `PW-CORE-07` | Opções de runner (`retries`, `workers`, `timeout`, `reporter`, `fullyParallel`) **MUST** ser top-level no config. Dentro de `use` **NEVER**. |

### 6.1 Regras críticas dos satélites

As famílias completas vivem nos satélites, mas **estas precisam viajar com o caminho mínimo** — são as que mais aparecem em código gerado e não podem depender de o agente ter aberto o satélite certo. O texto abaixo é reproduzido **verbatim** do satélite; o satélite é canônico.

| ID | Regra | Satélite |
| --- | --- | --- |
| `PW-LOC-01` | Locator **MUST** preferir papel e nome acessível (`getByRole`) a CSS ou XPath. | [Playwright - Locators](playwright-locators.md) |
| `PW-LOC-02` | `first()`/`last()`/`nth()` **NEVER** são a resposta a uma strict mode violation; a resposta é `filter()` ou encadeamento. Posição só quando a posição **é** o critério. | [Playwright - Locators](playwright-locators.md) |
| `PW-LOC-05` | Seletores de layout (`:right-of`, `:left-of`, `:above`, `:below`, `:near`) **NEVER** — a fonte os marca como deprecados. | [Playwright - Locators](playwright-locators.md) |
| `PW-ACT-01` | Ação **MUST** confiar nos actionability checks. `force: true` só com o motivo escrito no código. † | [Playwright - Ações e Auto-waiting](playwright-acoes-e-auto-waiting.md) |
| `PW-ACT-03` | Espera por evento **MUST** ser armada **antes** da ação que o dispara. | [Playwright - Ações e Auto-waiting](playwright-acoes-e-auto-waiting.md) |
| `PW-ACT-04` | `waitUntil: 'networkidle'` **NEVER** — a fonte o desencoraja explicitamente. | [Playwright - Ações e Auto-waiting](playwright-acoes-e-auto-waiting.md) |
| `PW-EXP-01` | Afirmação sobre a UI **MUST** usar asserção web-first (`expect(locator).…`). `expect(await locator.isVisible())` e formas equivalentes **NEVER**. | [Playwright - Assertions](playwright-assertions.md) |
| `PW-EXP-03` | `expect(fn).toPass()` **MUST** receber `timeout` explícito — o default é `0` e ele **não** herda `expect.timeout`. | [Playwright - Assertions](playwright-assertions.md) |
| `PW-CFG-02` | `trace` **MUST** ser no mínimo `'on-first-retry'`. `'off'` em CI **NEVER**. | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `PW-CFG-03` | Setup que precisa de fixture, trace ou visibilidade no relatório **MUST** ser setup project com `dependencies`, **NEVER** `globalSetup`. | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `PW-FIX-01` | Setup reusado entre arquivos **MUST** ser fixture, **NEVER** `beforeEach` copiado. | [Playwright - Fixtures](playwright-fixtures.md) |
| `PW-FIX-03` | Fixture **MUST** entregar o valor por `await use(valor)` e fazer teardown depois. `return` **NEVER**. | [Playwright - Fixtures](playwright-fixtures.md) |
| `PW-FIX-05` | O `test` derivado por `test.extend` **MUST** vir de um módulo único do projeto. Importar o `test` base e o derivado no mesmo arquivo **NEVER** — as fixtures customizadas somem sem erro de compilação. | [Playwright - Fixtures](playwright-fixtures.md) |
| `PW-NET-03` | Quando eventos de rede não aparecem, `serviceWorkers: 'block'` **MUST** ser a primeira hipótese verificada. | [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) |
| `PW-NET-05` | `page.request` e `playwright.request` **NEVER** são intercambiáveis: o primeiro compartilha cookies com o contexto do browser, o segundo é isolado. | [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) |
| `PW-AUTH-02` | O diretório de `storageState` **MUST** estar no `.gitignore`. Ele contém credencial de sessão viva. | [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) |
| `PW-AUTH-03` | Teste que altera estado de servidor **MUST** usar uma conta por worker, via fixture worker-scoped indexada por `parallelIndex`. | [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) |
| `PW-SNAP-01` | Verificação de estrutura de UI **MUST** preferir `toMatchAriaSnapshot` a `toHaveScreenshot`. | [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) |
| `PW-SNAP-02` | Screenshot de referência **MUST** ser gerado no mesmo SO e versão de browser do CI. | [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) |
| `PW-RUN-01` | `fullyParallel: true` **MUST** estar ligado para que `--shard` distribua por teste. Sem ele o shard distribui por **arquivo**, e a divisão fica desigual. | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `PW-RUN-03` | Teste flaky **NEVER** é considerado resolvido por aumento de `retries`. | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `PW-RUN-04` | `test.fail()` e `test.fixme()` **NEVER** são sinônimos: `fail` **roda** o teste e exige que ele falhe; `fixme` **não roda**. | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `PW-RUN-05` | `test.describe.serial` e `test.describe.parallel` **NEVER** em código novo — a fonte os marca como descontinuados em favor de `test.describe.configure()`. | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `PW-DBG-01` | Falha de CI **MUST** ser investigada pelo trace antes de qualquer alteração no teste. | [Playwright - Debug e Trace](playwright-debug-e-trace.md) |
| `PW-DBG-02` | `--debug` **NEVER** serve para medir tempo nem para rodar suíte: ele força `timeout=0` e `workers=1`. | [Playwright - Debug e Trace](playwright-debug-e-trace.md) |
| `PW-STR-02` | Page object **NEVER** contém asserção de regra de negócio. A asserção é do teste. † | [Playwright - Estrutura de Testes](playwright-estrutura-de-testes.md) |
| `PW-AGT-01` | Test Agents, `@playwright/cli` e `@playwright/mcp` **NEVER** são intercambiáveis. Ver a § 5.7 do hub antes de escolher. | [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) |
| `PW-AGT-03` | `browser_run_code_unsafe` **NEVER** habilitado contra alvo não confiável — é execução remota de código. | [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) |
| `PW-AGT-04` | Teste produzido por agente **MUST** passar pelas mesmas regras `PW-LOC-*` e `PW-EXP-*` de teste escrito à mão, mais a checklist da § 2.5. † | [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) |

### 6.2 IDs canônicos

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

### Famílias completas nos satélites

**85 regras**, em treze famílias — doze nos satélites, uma só aqui. O detalhamento existe porque contagem escrita à mão erra:

| Família | Regras | Satélite |
| --- | --- | --- |
| `PW-CORE-*` | 7 | — (só neste hub) |
| `PW-LOC-*` | 7 | [Playwright - Locators](playwright-locators.md) |
| `PW-ACT-*` | 7 | [Playwright - Ações e Auto-waiting](playwright-acoes-e-auto-waiting.md) |
| `PW-EXP-*` | 6 | [Playwright - Assertions](playwright-assertions.md) |
| `PW-CFG-*` | 7 | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| `PW-FIX-*` | 6 | [Playwright - Fixtures](playwright-fixtures.md) |
| `PW-NET-*` | 7 | [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) |
| `PW-AUTH-*` | 6 | [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) |
| `PW-SNAP-*` | 6 | [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) |
| `PW-RUN-*` | 7 | [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) |
| `PW-DBG-*` | 6 | [Playwright - Debug e Trace](playwright-debug-e-trace.md) |
| `PW-STR-*` | 7 | [Playwright - Estrutura de Testes](playwright-estrutura-de-testes.md) |
| `PW-AGT-*` | 6 | [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) |

Dois desses IDs são **apelidos** e não devem ser citados: `PW-ACT-07` e `PW-LOC-07` (§ 6.2). O caminho mínimo — o que a § 6 e a § 6.1 carregam sem abrir satélite — são **36 regras**.

---

## 7. Contrato de skill

Como uma skill de Playwright deve consumir esta doc. O contrato geral de skills deste vault está em `Skill`; o que segue é a parte específica.

### O que carregar

```
SEMPRE:   Playwright.md § 0 (os três fatos)
          Playwright.md § 2 (modelo mental)
          Playwright.md § 5 (árvores de decisão)
          Playwright.md § 6 + § 6.1 + § 6.2 (regras e IDs canônicos)

AO ESCREVER OU EDITAR um teste:
          Playwright - Locators.md
          Playwright - Assertions.md

ANTES DE ALTERAR um teste que já falha:
          Playwright - Debug e Trace.md      ← e leia o trace de verdade

AO CONFIGURAR o projeto:
          Playwright - Configuração e Projects.md
          Playwright - Execução, Retries e CI.md

AO DECIDIR arquitetura de suíte (setup, page object, parametrização):
          Playwright - Fixtures.md
          Playwright - Estrutura de Testes.md

SOB DEMANDA, via § 4 (mapa da API):
          o satélite da superfície tocada pela tarefa

NUNCA:    todos os satélites de uma vez
```

### Como citar

Achados de revisão citam o ID da regra e o satélite, não parafraseiam:

> `PW-EXP-01` — `expect(await page.getByRole('alert').isVisible()).toBe(true)` afirma sobre um instante congelado; se o alerta aparece depois, o teste falha sem defeito. Troque por `await expect(page.getByRole('alert')).toBeVisible()`.
> Ver [Playwright - Assertions](playwright-assertions.md).

### Invariantes que a skill deve fazer valer

1. **Verificar antes de afirmar.** Se uma API não está na § 4, ela não foi verificada nesta doc. Consulte playwright.dev e atualize a nota — não invente comportamento nem opção de configuração. Esta doc já corrigiu duas invenções assim; ver as notas de verificação.
2. **A fonte vence.** Divergência entre esta nota e a doc oficial é bug desta nota.
3. **Ler o trace antes de editar.** Um teste que falha é uma evidência, não um inconveniente. Alterar o teste antes de entender a falha é a forma mais eficiente de converter um bug de produto em teste verde (`PW-DBG-01`).
4. **Diagnóstico antes de timeout.** Nenhuma skill deve propor subir `timeout`, `retries` ou `expect.timeout` como primeira medida. A § 5.2 e a § 5.5 vêm antes.
5. **Locator é decisão de acessibilidade.** Quando `getByRole` não alcança o elemento, o achado costuma ser sobre o **componente**, não sobre o teste. Siga a ponte da § 8 em vez de descer para CSS.
6. **Preferir a ponte.** Quando a § 8 indica que o problema pertence a outra nota do vault (React, Query, Storybook, HTTP), seguir a ponte em vez de reinventar dentro do teste.
7. **Teste de agente é teste.** Código produzido por planner/generator/healer passa pela mesma revisão (`PW-AGT-04`). "Foi o agente que escreveu" não é atenuante.

### Recortes prontos para skills novas

Derive uma skill de **um** satélite, não desta nota inteira, e registre a fonte no topo — é o critério de `Skill`.

| Skill | Carrega | Fonte declarada |
| --- | --- | --- |
| "escrever teste E2E de um fluxo" | § 2 + § 6 + [Playwright - Locators](playwright-locators.md) + [Playwright - Assertions](playwright-assertions.md) | [Playwright - Locators](playwright-locators.md) |
| "diagnosticar teste flaky" | § 5.2 + § 5.5 + [Playwright - Debug e Trace](playwright-debug-e-trace.md) | [Playwright - Debug e Trace](playwright-debug-e-trace.md) |
| "revisar suíte de Playwright" | § 6 + § 6.1 + § 6.2 + o satélite do domínio | este hub |
| "configurar Playwright num app novo" | § 0 + § 5.3 + [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) + [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) | [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) |
| "montar autenticação da suíte" | § 5.3 + [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) + [Playwright - Fixtures](playwright-fixtures.md) | [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) |
| "ligar agentes de teste no repositório" | § 5.7 + [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) | [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) |

---

## 8. Pontes com o stack

O corpo desta doc é Playwright fiel à fonte. Mas no meu stack várias decisões de teste são decididas por outra nota, e os satélites marcam esses pontos como *ponte*.

| Problema dentro de um teste | O que **não** fazer | A ponte |
| --- | --- | --- |
| `getByRole` não alcança o elemento | descer para `locator('css=…')` | o defeito é o componente sem papel/nome acessível — [React - Patterns](react-patterns.md), e a auditoria de a11y de [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| Campo só localizável por placeholder | `getByPlaceholder` e seguir a vida | falta `<label>`; é achado de acessibilidade — [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| Componente busca dado remoto e o teste corre demais | `waitForTimeout` | asserção web-first no estado de carregado; e o estado de erro merece teste próprio — [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) |
| Estado de erro do BFF não dispara | `try/catch` no teste | nem `hc` (Hono) nem Eden Treaty lançam em status de erro — [Hono - Validação e RPC](hono-validacao-e-rpc.md), [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| Mock de resposta com shape redigitado à mão | duplicar o tipo no teste | reusar o tipo exportado do servidor — [Hono - Validação e RPC](hono-validacao-e-rpc.md), [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| Preparar dado de teste pela UI | clicar 12 vezes para criar um registro | criar via `request` (API), navegar depois — [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) § 5 |
| Semear e limpar banco entre execuções | `beforeEach` que apaga tabela | setup/teardown project + dado por worker — [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md), e |
| Cookie de sessão não persiste | recriar login em cada teste | `storageState`; e a semântica de `SameSite`/`__Host-` é de [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) |
| Teste de autorização por papel | um só usuário com tudo liberado | um `storageState` por papel — [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md), [WorkOS - RBAC](workos-rbac.md) |
| Asserção sobre status HTTP inesperado | afirmar `200` sempre | a semântica do status é contrato — [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |
| Requisição do teste barrada por origem | desligar CORS na aplicação | [HTTP - CORS](http-cors.md) |
| Suíte E2E cobrindo toda regra de negócio | um E2E por rota | E2E cobre jornada crítica; regra vai para camada mais barata — [Teste de Software](teste-de-software.md) |
| Teste acoplado a estado interno do componente | espiar hook ou render count | |
| CI lento com a suíte inteira em série | aumentar a máquina | `fullyParallel` + `--shard` + `merge-reports` — [Github Actions](github-actions.md) |

**A ponte que mais importa: Playwright e Storybook não competem, e a fronteira mudou na 1.62.** [Storybook](storybook.md) testa **componente** em browser real (via addon-vitest, que por baixo usa Playwright); o Playwright testa **jornada** atravessando rotas, rede e sessão. A regra prática: se o teste precisa de rota, login ou mais de uma tela, é Playwright; se ele varia props de um componente, é story.

O que mudou: a 1.62 tornou component testing não-experimental, com um modelo de **stories e galleries** (`*.story.tsx` + `window.mount()` + a fixture `mount()`) que substitui `@playwright/experimental-ct-react`. Isso põe as duas ferramentas em sobreposição real onde antes havia divisão limpa. **Esta doc não recomenda migrar** stories de Storybook para o modelo do Playwright num projeto que já tem [Storybook - Stories e Args](storybook-stories-e-args.md) funcionando: o Storybook entrega sidebar, docs, controles e a11y no mesmo arquivo, e o modelo do Playwright entrega teste. Registrado aqui como decisão desta doc, não da fonte.

**A ponte de runner.** O monorepo já tem dois runners por desenho (`bun test` para `apps/server`, `vitest --project=storybook` para stories — ver [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) `SB-TEST-05`). Playwright é o **terceiro**, e isso é deliberado: ele não roda sob `bun test` nem sob Vitest. O CI roda os três, e nenhum `--filter` do Bun alcança os outros dois — ver [Monorepo com Bun - estrutura e tooling](monorepo-com-bun-estrutura-e-tooling.md) § 4.

---

## Relacionados

- [Playwright - Locators](playwright-locators.md) — a superfície que todo teste toca
- [Playwright - Assertions](playwright-assertions.md) — como afirmar sem congelar o tempo
- [Playwright - Ações e Auto-waiting](playwright-acoes-e-auto-waiting.md) · [Playwright - Fixtures](playwright-fixtures.md) · [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md)
- [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) · [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) · [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md)
- [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) · [Playwright - Debug e Trace](playwright-debug-e-trace.md) · [Playwright - Estrutura de Testes](playwright-estrutura-de-testes.md)
- [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) — as três superfícies de agente
- [Teste de Software](teste-de-software.md) — a camada conceitual: que nível de teste, para que risco
- [Storybook](storybook.md) — o outro lado da fronteira componente × jornada
- ·
- [React.js](react-js.md) · [TanStack Query](tanstack-query.md) · [TanStack Router](tanstack-router.md) · [React Hook Form](react-hook-form.md)
- [HTTP](http.md) · [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) · [Github Actions](github-actions.md)
- [Monorepo com Bun - estrutura e tooling](monorepo-com-bun-estrutura-e-tooling.md) — onde a suíte E2E vive

## Fontes consultadas

Verificadas diretamente em **2026-08-20**:

- [Installation](https://playwright.dev/docs/intro) — requisitos de Node e SO
- [Writing tests](https://playwright.dev/docs/writing-tests) · [Best Practices](https://playwright.dev/docs/best-practices)
- [Locators](https://playwright.dev/docs/locators) · [Other locators](https://playwright.dev/docs/other-locators)
- [Actions](https://playwright.dev/docs/input) · [Auto-waiting](https://playwright.dev/docs/actionability) · [Navigations](https://playwright.dev/docs/navigations) · [Events](https://playwright.dev/docs/events)
- [Assertions](https://playwright.dev/docs/test-assertions)
- [Configuration](https://playwright.dev/docs/test-configuration) · [TestConfig (API)](https://playwright.dev/docs/api/class-testconfig) · [TestOptions (API)](https://playwright.dev/docs/api/class-testoptions) · [Projects](https://playwright.dev/docs/test-projects) · [Web server](https://playwright.dev/docs/test-webserver)
- [Fixtures](https://playwright.dev/docs/test-fixtures) · [Global setup and teardown](https://playwright.dev/docs/test-global-setup-teardown) · [Parameterize](https://playwright.dev/docs/test-parameterize)
- [Network](https://playwright.dev/docs/network) · [Mock APIs](https://playwright.dev/docs/mock) · [Mock browser APIs](https://playwright.dev/docs/mock-browser-apis) · [API testing](https://playwright.dev/docs/api-testing) · [Clock](https://playwright.dev/docs/clock)
- [Authentication](https://playwright.dev/docs/auth) · [Isolation](https://playwright.dev/docs/browser-contexts) · [Emulation](https://playwright.dev/docs/emulation)
- [Snapshot testing (aria)](https://playwright.dev/docs/aria-snapshots) · [Visual comparisons](https://playwright.dev/docs/test-snapshots) · [Accessibility testing](https://playwright.dev/docs/accessibility-testing)
- [Parallelism](https://playwright.dev/docs/test-parallel) · [Retries](https://playwright.dev/docs/test-retries) · [Sharding](https://playwright.dev/docs/test-sharding) · [Timeouts](https://playwright.dev/docs/test-timeouts) · [Reporters](https://playwright.dev/docs/test-reporters) · [Annotations](https://playwright.dev/docs/test-annotations) · [Command line](https://playwright.dev/docs/test-cli) · [Setting up CI](https://playwright.dev/docs/ci-intro)
- [Trace viewer](https://playwright.dev/docs/trace-viewer) · [UI Mode](https://playwright.dev/docs/test-ui-mode) · [Debugging](https://playwright.dev/docs/debug) · [Test generator](https://playwright.dev/docs/codegen)
- [Page object models](https://playwright.dev/docs/pom) · [Library](https://playwright.dev/docs/library) · [Component testing](https://playwright.dev/docs/test-components)
- [Test Agents](https://playwright.dev/docs/test-agents) · [Coding agents](https://playwright.dev/docs/getting-started-cli) · [Agent CLI — Introduction](https://playwright.dev/agent-cli/introduction) · [Agent CLI — Skills](https://playwright.dev/agent-cli/skills) · [MCP getting started](https://playwright.dev/docs/getting-started-mcp)
- [Release notes](https://playwright.dev/docs/release-notes) · [Locator (API)](https://playwright.dev/docs/api/class-locator) · [Test (API)](https://playwright.dev/docs/api/class-test) · [Page (API)](https://playwright.dev/docs/api/class-page)
- Versões: `npm view <pacote> dist-tags` em 2026-08-20

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **Node 20 não é suportado.** A matriz declarada é 22.x, 24.x e 26.x. Debian 11 também saiu (1.62), e macOS exige 14+.
- **`actionTimeout` e `navigationTimeout` são `0` por default** — não existe teto de ação. O único teto é o do teste, 30 s. É por isso que quase toda falha de espera se apresenta como "test timeout", e o diagnóstico exige trace.
- **`expect` tem timeout próprio de 5 s**, independente do teste. Subir o do teste não afrouxa a asserção, e vice-versa.
- **`trace`, `video` e `screenshot` têm mais valores do que a página de guia mostra.** A referência de API lista **sete** para `trace` e `video` (incluindo `retain-on-first-failure` e `retain-on-failure-and-retries`) e **quatro** para `screenshot` (incluindo `on-first-failure`); a página do Trace Viewer lista cinco. **É divergência dentro da própria documentação** — a referência de API é a mais completa.
- **`expect(fn).toPass()` tem timeout default `0` e não respeita `expect.timeout`.** É a única asserção com essa exceção, e ela produz teste que trava em vez de falhar.
- **Os seletores de layout (`:right-of`, `:near`, …) estão marcados como deprecados.**
- **Os seletores `_react` e `_vue` e o engine `:light` foram removidos na 1.58.** Código que os usa não roda mais — não é depreciação, é remoção.
- **`noWaitAfter` está deprecado e "não tem efeito"** em `click`, `check`, `clear`, `dblclick`, `dragTo` e afins.
- **`test.describe.serial` e `test.describe.parallel` estão marcados como descontinuados** na referência de API, em favor de `test.describe.configure()` — mas a página-guia de retries ainda os usa em exemplo.
- **`test.fail()` roda o teste e exige que ele falhe; `test.fixme()` não roda.** Os nomes sugerem o contrário do que fazem.
- **Sem `fullyParallel`, `--shard` distribui por arquivo, não por teste** — e a fonte avisa que a quantidade de testes por arquivo "pode influenciar muito" a distribuição.
- **`workers` default é metade dos núcleos lógicos**, não um por núcleo.
- **`--debug` implica `timeout=0` e `workers=1`.** Ele não é um modo de execução, é um modo de inspeção.
- **`--update-snapshots` grava *patch* por default** (`updateSourceMethod: 'patch'`), não sobrescreve o arquivo-fonte; e `updateSnapshots` default é `'missing'`, não `'all'`.
- **Setup project não roda automaticamente em UI mode** — a fonte descreve o procedimento manual de acionar o filtro. Suíte autenticada abre "deslogada" no UI mode na primeira vez.
- **`page.goto()` espera o evento `load`**, e segue redirecionamento de cliente. `networkidle` é desencorajado explicitamente.
- **Service Worker intercepta antes do `route`** — quando eventos de rede "desaparecem", a fonte manda tentar `serviceWorkers: 'block'` primeiro.
- **`page.request` e `playwright.request.newContext()` têm cookies diferentes:** o primeiro compartilha e atualiza os do contexto do browser, o segundo é isolado.
- **`storageState` é interoperável entre `BrowserContext` e `APIRequestContext`** — login por API serve para teste de UI, e vice-versa.
- **Component testing deixou de ser experimental na 1.62**, com um modelo de stories/galleries e uma fixture `mount()` que substituem `@playwright/experimental-ct-react`/`-vue`. É sobreposição nova com Storybook; ver a § 8.
- **`retryStrategy` (`'immediate'` | `'isolated'`) é da 1.62** e não aparece nas páginas-guia de retries.
- **Existem três superfícies de agente com ciclos de versão independentes**: Test Agents (embutido), `@playwright/cli` 0.1.18 e `@playwright/mcp` 0.0.79. A 1.62 passou a embutir as duas últimas via `npx playwright cli` e `npx playwright mcp`, mas os pacotes seguem versionando sozinhos, abaixo de 1.0.
- **A ferramenta `browser_run_code_unsafe` do MCP é execução remota de código** — a própria fonte marca o risco.
- **As definições geradas por `init-agents` precisam ser regeradas a cada atualização do Playwright**, porque embutem instruções e a lista de ferramentas MCP daquela versão.

**Duas afirmações do changelog que a referência de API não sustenta**, e que por isso **não** são citadas nesta doc:

- **`locator.normalize()`** aparece nas notas de release da 1.59 como conversão de locator para forma canônica, mas **não existe** na referência de `Locator`. Não use.
- **`page.localStorage` / `page.sessionStorage`** aparecem nas notas da 1.61 como Web Storage API, mas **não constam** da referência de `Page`. O caminho verificado para `sessionStorage` continua sendo `addInitScript` + `page.evaluate`, como a página de autenticação prescreve.

Nos dois casos, o changelog e a referência de API discordam. Esta doc segue a **referência de API**, e registra a discordância em vez de escolher em silêncio.
