---
Link: https://storybook.js.org/docs
tags:
 - storybook
 - react
 - frontend
 - testing
 - reference
 - agent-context
source: "Documentação oficial do Storybook — storybook.js.org/docs, linha 10.x"
verificado-em: 2026-08-19
---
# Storybook — referência conduzida

> **O que esta nota é.** O ponto de entrada único para Storybook neste vault: para mim ao consultar, e para agentes de código ao escrever, revisar ou testar stories. Não é um resumo linear da documentação — é um **roteador**. Ela decide o que carregar, oferece o modelo mental que faz o resto fazer sentido, e expõe regras citáveis que uma skill ou um code review pode referenciar por ID.
>
> **O que não é.** Não substitui a fonte. Quando houver divergência, [storybook.js.org/docs](https://storybook.js.org/docs) vence, e esta nota deve ser corrigida.

Inventário verificado diretamente em storybook.js.org em **2026-08-19**.
Ver [Fontes consultadas](#fontes-consultadas).

**Versões confirmadas no registry npm na mesma data:**

| Pacote | `latest` |
| --- | --- |
| `storybook` | **10.5.10** |
| `@storybook/tanstack-react` | 10.5.10 |
| `@storybook/react-vite` | 10.5.10 |
| `@storybook/addon-vitest` | 10.5.10 |
| `@tanstack/react-router` | 1.170.30 |
| `@tanstack/react-start` | 1.168.47 |
| `vitest` | 4.1.11 |

Os pacotes do monorepo do Storybook publicam em lockstep: o `latest` do core e o de qualquer `@storybook/*` são o mesmo número. Divergência entre eles no `package.json` é bug de instalação, não escolha.

---

## 1. Como usar esta doc

### Antes de tudo: escolher o caminho

Esta estrutura tem **dois caminhos de framework**, e quase tudo que vem depois pressupõe que um deles foi escolhido:

| Caminho | Nota | Para quem |
| --- | --- | --- |
| **`@storybook/tanstack-react`** | [Storybook - TanStack React](storybook-tanstack-react.md) | o Storybook renderiza stories que alcançam `@tanstack/react-router`, e o projeto está em React ≥ 18 / Vite ≥ 7 |
| **`@storybook/react-vite`** | [Storybook - React Vite](storybook-react-vite.md) | Storybook só de design system, ou projeto abaixo daquele piso de versão |

A árvore de decisão completa está na § 5.1. **Escolha antes de ler o resto** — e leia só a nota do caminho escolhido; as duas juntas confundem mais do que informam.

**O que muda entre os caminhos, e o que não muda:**

| Camada | Diverge? |
| --- | --- |
| CSF, `args`, `argTypes`, `render`, tags | **não** — só o token de import |
| `parameters`, `globals`, `loaders`, `beforeEach` | **não** |
| `play`, `storybook/test`, addon-vitest, a11y | **não** |
| autodocs, doc blocks, MDX | **não** |
| `main.ts`: valor de `framework`, requisitos de versão | **sim** |
| como a story ganha um router | **sim** — é a divergência principal |
| mock automático de módulos `@tanstack/*` | **sim** |

**Convenção de import nos satélites temáticos.** Os exemplos escrevem `@storybook/tanstack-react`. Sob o outro caminho, troque o token por `@storybook/react-vite` e nada mais muda — a fonte prescreve o pacote do **framework**, seja qual for (`SB-CORE-02`).

### Para um humano

Leia a seção 2 (modelo mental) uma vez — ela é a diferença entre escrever stories que servem de teste e escrever demos que só enfeitam a sidebar. Depois use a seção 4 como índice e a seção 5 quando estiver na dúvida entre duas APIs. Os satélites são leitura sob demanda, não em ordem.

### Para um agente de código

Carregue nesta ordem, parando assim que tiver o suficiente:

| Passo | Carregar | Quando |
| ----- | -------- | ------ |
| 1 | Esta nota (§ 2, § 5, § 6) | Sempre que a tarefa envolver Storybook |
| 2 | [Storybook - Stories e Args](storybook-stories-e-args.md) | Sempre que for **escrever ou editar** um arquivo `*.stories.tsx` |
| 3 | O satélite do domínio específico | Quando a tarefa toca uma superfície concreta — use a § 4 para descobrir qual |
| 4 | A nota do **caminho** escolhido — [Storybook - TanStack React](storybook-tanstack-react.md) ou [Storybook - React Vite](storybook-react-vite.md) | Antes de configurar o projeto, e sempre que a story tocar rota, router ou `queryClient` |

**Regra de economia de contexto:** nunca carregue todos os satélites. Escrever uma story de componente de design system precisa de § 2 + § 6 + [Storybook - Stories e Args](storybook-stories-e-args.md) — mais [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) se a story também alimenta a página de docs, que num design system é o caso normal. Ver os três recortes prontos na § 7.

### Convenções e vocabulário

**Todos os exemplos são TypeScript**, e escrevem o token `@storybook/tanstack-react` por convenção. Sob o outro caminho, troque por `@storybook/react-vite` — ver a tabela de divergência acima.

**O caso guia é `packages/ui`**, o pacote de design system do monorepo descrito em `Monorepo com Bun - estrutura e tooling`: componentes puros, reutilizáveis, sem acoplamento a rota. Stories acopladas a rota são o assunto de [Storybook - TanStack React](storybook-tanstack-react.md).

Termos usados sem redefinição nos satélites:

| Termo | Significado nesta doc |
| --- | --- |
| **story** | um estado nomeado e reproduzível de um componente. Não é um exemplo de uso: é um caso de teste que também renderiza |
| **CSF** | Component Story Format — o formato do arquivo: `export default` é o `meta`, cada named export é uma story |
| **meta** | o default export do arquivo de stories; carrega o que é comum a todas as stories daquele componente |
| **args** | as entradas do componente que o Storybook controla e o leitor pode editar ao vivo. Na prática, as props |
| **argTypes** | metadado *sobre* os args: que controle renderizar, que opções oferecer, como mapear valor não serializável. **Descrição não** — ela vem do JSDoc do componente (`SB-DOC-02`) |
| **parameters** | metadado estático que configura o Storybook e seus addons — não chega ao componente |
| **globals** | valores de ambiente que o leitor troca pela toolbar (tema, locale, a11y manual). Valem para toda a sidebar |
| **decorator** | função que embrulha a story em markup ou contexto extra |
| **loader** | função assíncrona que roda **antes** do render e cujo retorno entra no contexto da story |
| **play** | função assíncrona que roda **depois** do render e interage com o componente. É o corpo do teste |
| **canvas** | o escopo de queries do Testing Library limitado à raiz da story renderizada |
| **spy** | função observável criada por `fn`, que registra chamadas para asserção |
| **tag** | rótulo que decide onde a story aparece: sidebar (`dev`), runner (`test`), página de docs (`autodocs`) |
| **docgen** | extração automática de tipos e JSDoc do componente para alimentar a tabela de props |
| **automock** | substituição de todos os exports de um módulo por mocks, registrada com `sb.mock` |
| **portable story** | story importada e executada fora da UI do Storybook, via `composeStories` |
| **browser mode** | modo do Vitest que roda o teste num browser real (Playwright), não em JSDOM |

---

## 2. Modelo mental

Cinco afirmações. Quase todo erro de Storybook que um agente comete viola uma delas.

**1. Uma story é um estado, não um exemplo.** O nome da story descreve a *condição* do componente — `Loading`, `WithLongLabel`, `Disabled`, `ErrorFromServer` — não o que o leitor deveria aprender. Se o nome não descreve um estado, provavelmente não é uma story: é documentação, e o lugar dela é uma página de docs.

**2. O arquivo é declarativo, e a estrutura é fixa.** Um `export default` (o `meta`) e um named export por story. Nada é registrado imperativamente, nada roda no corpo do módulo. É por isso que `title` precisa ser literal estático e que uma story não pode depender de outra ter rodado antes: o Storybook lê o arquivo estaticamente para montar o índice, sem executá-lo.

**3. Toda anotação existe em três níveis, e a resolução é conhecida.** Projeto (`.storybook/preview.tsx`) → componente (`meta`) → story. O mais específico vence. Mas *como* vence depende do tipo:

| Anotação | Como combina |
| --- | --- |
| `args`, `parameters`, `globals` | **merge por chave.** Sobrescrever uma subchave não derruba as irmãs |
| `decorators` | **aninham.** Global é o mais externo, story é o mais interno |
| `tags` | **acumulam**, e `'!tag'` remove uma herdada |
| `loaders`, `beforeEach` | **acumulam**, todos rodam |

Saber isso elimina a maior fonte de configuração duplicada: quase tudo que aparece repetido em vários arquivos de story pertencia ao `preview`.

**4. Args são a única entrada controlada; tudo o mais é ambiente.** Se o que distingue duas stories é uma prop, é `args` — e o leitor consegue editar, o runner consegue variar, a tabela de docs consegue documentar. Se o que distingue é *o mundo em volta* (tema, provider, rota, resposta de rede, relógio), é ambiente, e ambiente se injeta por decorator, loader, `beforeEach` ou mock. Codificar estado dentro de `render` é o antipadrão que mata as três coisas de uma vez.

**5. O mesmo arquivo alimenta sidebar, docs e runner — e é o runner que cobra o preço.** A story renderizada é um smoke test de graça; a `play` transforma ela em teste de interação; o addon de a11y varre a mesma árvore. Escrever story pensando em "demo" produz teste inútil. Escrever pensando em estado produz os dois de graça.

> **A inversão que importa.** É tentador ler o Storybook como ferramenta de documentação que ganhou testes por acaso. É o contrário: em 10.x o produto é um runner de componente em browser real, e a documentação é o subproduto barato. Quem escreve story como catálogo paga o custo do runner sem receber o benefício.

---

## 3. Fronteiras de pacote

Saber de onde algo é importado evita a maior parte dos erros de import — e aqui há uma armadilha de nome.

| Import | Contém |
| --- | --- |
| `storybook` | o CLI (`storybook dev`, `storybook build`) |
| `storybook/test` | `expect`, `fn`, `mocked`, `userEvent`, `sb` |
| `storybook/preview-api` | `useArgs`, `useGlobals` |
| `@storybook/tanstack-react` | `StorybookConfig`, `Preview`, `Meta`, `StoryObj` — os tipos do framework, **caminho TanStack** |
| `@storybook/react-vite` | os mesmos tipos, **caminho Vite genérico**. Um projeto usa um ou outro, nunca os dois |
| `@storybook/tanstack-react/react-router` | APIs de mock do TanStack Router |
| `@storybook/tanstack-react/start` | mocks do TanStack Start, incluindo `createServerFn` mockado |
| `@storybook/addon-vitest/vitest-plugin` | `storybookTest`, o plugin que transforma story em teste |
| `@storybook/addon-a11y` | o addon; a configuração é por `parameters.a11y` |
| `@storybook/addon-docs` | doc blocks (`Title`, `Description`, `Controls`, `Stories`…) |
| `@storybook/addon-themes` | decorators de tema. **API não verificada nesta doc** — a fonte de estilo só linka `withThemeFromJSXProvider` |
| `msw-storybook-addon/csf3` | `mswLoader` |

**A armadilha:** os utilitários de teste vivem em **`storybook/test`, sem `@`**. O pacote `@storybook/test` é anterior à linha 9 e não deve aparecer em código novo (`SB-CORE-01`).

**O critério de `satisfies` × anotação.** `Meta` e `Preview` usam `satisfies`, porque o tipo literal do objeto alimenta inferência depois (`StoryObj<typeof meta>` lê os `args` declarados; `preview.args`/`globals` entram no merge). `StorybookConfig` usa anotação — é a forma da fonte, e nada infere a partir dele. Ver [Storybook - Stories e Args](storybook-stories-e-args.md) § 2.1.

**A segunda armadilha:** `Meta` e `StoryObj` vêm do **pacote do framework**, não do renderer. A doc oficial escreve `@storybook/your-framework` como placeholder e pede substituição pelo seu framework — aqui, `@storybook/tanstack-react`. Alguns exemplos da fonte aparecem já resolvidos como `@storybook/react` por causa do template de renderer da página; não é a forma prescrita (`SB-CORE-02`).

---

## 4. Mapa da API

Superfície ativa do que se usa em código novo. A coluna **Satélite** diz o que carregar.

**Deliberadamente fora deste mapa:** o builder Webpack e `@storybook/addon-styling-webpack` (o stack é Vite); os renderers não-React; `test-runner` (a própria doc recomenda migrar para `addon-vitest`); Chromatic e teste visual pago; composição por `refs`; `indexers` e CSF Next, ambos marcados como experimentais/preview. Se a tarefa exigir um deles, consulte a fonte: a ausência aqui significa "não verificado nesta doc", não "não existe".

### 4.1 `.storybook/main.ts` — `StorybookConfig`

| Campo | Para que serve | Satélite |
| --- | --- | --- |
| `framework` | **obrigatório.** Qual framework/builder usar | [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) |
| `stories` | globs de descoberta, relativos ao `.storybook/` | [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) |
| `addons` | lista de addons | [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) |
| `staticDirs` | diretórios servidos como estáticos | [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) |
| `viteFinal` | hook para modificar a config do Vite | [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) |
| `docs` | `defaultName`, `docsMode` | [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) |
| `typescript` | tratamento de TS e opções de docgen — **existe, não coberto nesta doc** | — |
| `tags` | configuração de tags no nível do projeto — **existe, não coberto nesta doc**; tags em `preview`/`meta`/story são outro campo | [Storybook - Stories e Args](storybook-stories-e-args.md) § 6 |
| `previewHead`, `previewBody`, `managerHead` | injeção de HTML — **existem, não cobertos nesta doc**. O arquivo `preview-head.html` é outro mecanismo | [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) § 2.1 |
| `core`, `build`, `env`, `features`, `logLevel` | ajustes de plataforma — **existem, não cobertos nesta doc** | — |

### 4.2 Anotações de CSF

Valem em `meta` e em story, salvo indicação. A coluna **Nível** diz onde a anotação é aceita: `P` projeto (`preview`), `C` componente (`meta`), `S` story.

| Anotação | Nível | Para que serve | Satélite |
| --- | --- | --- | --- |
| `component` | C | o componente documentado; habilita docgen e auto-título | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `title` | C | posição na sidebar; **MUST** ser literal estático | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `id` | C | URL estável da story | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `args` | P C S | as entradas controladas | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `argTypes` | P C S | controle, opções, `mapping` | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `render` | C S | render customizado quando `args` + `component` não bastam | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `name` | S | rótulo na sidebar, quando o nome do export não serve | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `tags` | P C S | `dev`, `test`, `autodocs`, `manifest`, e as próprias | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `includeStories`, `excludeStories` | C | filtrar exports que não são stories | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `decorators` | P C S | embrulhar a story em markup ou contexto | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `parameters` | P C S | configurar Storybook e addons | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `globals` | P C S | ambiente controlado pelo leitor | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `initialGlobals` | P | valor inicial dos globals | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `loaders` | P C S | carregar dado assíncrono antes do render | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `beforeEach` | P C S | setup antes do render, com cleanup opcional no retorno | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `subcomponents` | C | documentar componentes relacionados na mesma página | [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) |
| `play` | C S | interagir e asseverar depois do render | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |

### 4.3 `storybook/test`

| Export | Para que serve | Satélite |
| --- | --- | --- |
| `expect` | asserção; **MUST** ser `await` | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| `fn` | spy para callback em `args` | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| `userEvent` | simular interação do usuário | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| `mocked` | acesso tipado ao mock de um módulo | [Storybook - Mocking](storybook-mocking.md) |
| `sb` | `sb.mock` — registro de automock, **só no preview** | [Storybook - Mocking](storybook-mocking.md) |

### 4.4 `parameters` mais usados

| Parameter | Para que serve | Satélite |
| --- | --- | --- |
| `layout` | `'centered'`, `'padded'`, `'fullscreen'` | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `backgrounds` | opções de fundo do canvas | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `a11y` | `context`, `config`, `options`, `test` | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| `docs` | `page`, `toc`, `description` | [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) |
| `controls` | comportamento do painel de controles | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `tanstack.router` **(só caminho TanStack)** | `route`, `params`, `path`, `query`, `context`, `routeOverrides`, `useRouterContext`. Sob `react-vite` **não tem efeito e falha em silêncio** (`SB-RV-04`) | [Storybook - TanStack React](storybook-tanstack-react.md) |

---

### 4.5 Execução, cobertura e CI

Não é API de story, e por isso ficava fora do mapa até 2026-08-21. Cobre-se em [Storybook - Cobertura e CI](storybook-cobertura-e-ci.md).

| Superfície | Para que serve |
| --- | --- |
| testing widget (sidebar) | disparar testes, watch, cobertura, a11y |
| `@vitest/coverage-v8` · `@vitest/coverage-istanbul` | provider de cobertura — **não vem embutido** |
| `coverage.watermarks` | limiares que colorem o número na UI |
| `storybookScript` | subir um Storybook para o teste usar — **watch mode** |
| `storybookUrl` | apontar para um Storybook publicado — **CI** |
| imagem de CI com Playwright | `mcr.microsoft.com/playwright:v1.58.2-noble` |

---

## 5. Árvores de decisão

### 5.1 Qual framework: `tanstack-react` ou `react-vite`

```
O Storybook vai renderizar ALGUMA story que importe @tanstack/react-router
(direta ou transitivamente — um Link dentro de um componente conta)?
├── NÃO, e nunca vai
│ → @storybook/react-vite → [Storybook - React Vite](storybook-react-vite.md)
│ requisitos menores: React ≥ 16.8, Vite ≥ 5
│ típico: Storybook exclusivo de packages/ui
└── SIM, ou muito provavelmente vai
 ├── o projeto está em React ≥ 18 E Vite ≥ 7?
 │ ├── SIM → @storybook/tanstack-react → [Storybook - TanStack React](storybook-tanstack-react.md)
 │ │ ganho: router em memória embrulhando toda story,
 │ │ imports de @tanstack/react-router redirecionados
 │ │ para a camada de mock, navegação virando spy
 │ │ custo: o redirecionamento é GLOBAL, vale também para as
 │ │ stories de packages/ui que não tocam rota
 │ └── NÃO → @storybook/react-vite + decorator de router à mão
 │ → [Storybook - React Vite](storybook-react-vite.md) § 4
 │ é caminho de transição, não destino: sem params
 │ tipados, sem routeOverrides, sem spy de navegação
 └── (a migração de Vite é pré-requisito do caminho TanStack,
 não detalhe de configuração)
```

**Para o monorepo deste vault a resposta é `@storybook/tanstack-react`,** e a razão não é `packages/ui` — é que `apps/storybook` consome também `apps/web`, onde todo componente de página importa `Link`. Um único Storybook cobrindo os dois pacotes precisa do framework que sabe embrulhar rota.

**TanStack Start não é requisito.** A doc afirma explicitamente que o framework atende tanto SPA usando só `@tanstack/react-router` quanto app Start completo; os stubs de server function e de entrypoint de runtime só entram em jogo sob Start. Numa SPA com BFF separado — o desenho de `Backend no runtime Bun` — essa metade do framework fica inerte, e isso é esperado, não sintoma.

### 5.2 Onde colocar a anotação

```
A anotação vale para QUANTOS componentes?
├── todos →.storybook/preview.tsx
│ típico: provider de tema, CSS global, decorator de layout,
│ reset de queryClient, tags: ['autodocs']
├── todas as stories de UM componente → meta
│ típico: component, args comuns, argTypes, parameters.layout
└── uma story só → a própria story
 típico: args que definem o estado, play, parameters.a11y.test
```

> **Teste de cheiro:** a mesma anotação aparecendo em três arquivos de story pertencia ao `preview`. Como `parameters` fazem merge por chave (`SB-CTX-01`), subir para o projeto **não** impede uma story de sobrescrever um detalhe.

### 5.3 Como injetar ambiente

```
O que a story precisa que o componente não recebe por prop?
├── markup ou provider em volta → decorator
├── dado assíncrono antes do render → loader
├── setup imperativo com desfazer
│ (relógio, comportamento de mock) → beforeEach (retorna cleanup)
├── configuração de addon → parameters
├── variação que o LEITOR troca
│ (tema, locale) → globals + toolbar
└── resposta de rede ou módulo do servidor → ver 5.4
```

### 5.4 Como mockar

```
O que precisa ser substituído?
├── um callback que a story quer asseverar
│ → fn em meta.args, asserção via args.onX
├── um módulo do projeto (lib, client de db, sessão)
│ → sb.mock(import('../src/lib/x.ts')) no preview
│ comportamento por story em beforeEach, via mocked
│ precisa manter a implementação real rodando? { spy: true }
├── uma requisição HTTP que o componente dispara
│ → MSW (mswLoader + beforeEach({ msw }))
├── um módulo que só existe no servidor e quebra no browser
│ → sb.mock, obrigatoriamente. Ver 5.6
└── loader / beforeLoad de uma rota do TanStack Router
 ├── caminho tanstack-react
 │ → parameters.tanstack.router.routeOverrides
 └── caminho react-vite
 → routeOverrides NÃO existe. Duas saídas:
 monte uma árvore mínima de rotas na story
 (Storybook - React Vite § 4.2), ou mocke o
 módulo que o loader chama
```

### 5.5 Onde o teste roda

```
Preciso executar a play function fora da UI do Storybook?
├── não, quero rodar no Storybook e em CI
│ → @storybook/addon-vitest
│ exige Vitest e browser mode com Playwright
│ script: vitest --project=storybook
└── sim, quero a story dentro de um teste que já existe
 → portable stories: composeStories + setProjectAnnotations
```

> **A restrição do monorepo.** O addon-vitest exige **Vitest**. Ele não roda sob `bun test`, que é o runner do backend em `Bun - Testes`. O monorepo convive com dois runners por desenho: `bun test` para `apps/server`, `vitest --project=storybook` para as stories. Não é duplicação a resolver — é a fronteira entre teste de runtime Bun e teste de componente em browser real (`SB-TEST-05`).

### 5.6 A story não renderiza

```
Qual é o erro?
├── "Cannot find module 'node:fs'" ou similar de módulo Node
│ → algo na árvore de import da story alcança código server-only.
│ Leia o stack trace para achar QUAL módulo, e sb.mock nele.
│ Não trate o erro: o módulo não pode existir no bundle do browser.
├── hook do router lançando fora de contexto
│ ├── caminho tanstack-react → RouterProvider manual em decorator
│ │ competindo com o router do framework (SB-TS-03)
│ └── caminho react-vite → falta o decorator de router.
│ É esperado: sob react-vite nada é embrulhado
│ automaticamente. Ver Storybook - React Vite § 4
├── componente é Server Component
│ → não há suporte. Extraia a parte cliente e faça story dela
├── "title must be statically readable"
│ → title computado. Use literal, ou remova e deixe o auto-título
└── a story renderiza, mas o painel de controles está vazio
 → falta component no meta, ou o docgen não achou os tipos
```

---

## 6. Regras normativas

Regras citáveis por ID. Uma skill, um prompt de revisão ou um comentário de PR pode referenciar `SB-MOCK-01` sem repetir o texto. O corpo completo de cada família vive no satélite correspondente; aqui ficam as invioláveis.

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.
**Marcação de origem:** regras sem marca vêm de afirmação explícita da fonte. Regras marcadas **†** são decisão desta doc — coerentes com a fonte, mas não ditadas por ela. Uma revisão pode discutir uma regra †; não pode discutir as outras sem ir à fonte.

### `SB-CORE-*` — invariantes de projeto

| ID | Regra |
| --- | --- |
| `SB-CORE-01` | Utilitários de teste **MUST** vir de `storybook/test`. `@storybook/test` **NEVER** em código novo — é o pacote pré-9. |
| `SB-CORE-02` | `Meta` e `StoryObj` **MUST** ser importados do pacote do framework (`@storybook/tanstack-react`), não do renderer. |
| `SB-CORE-03` | `.storybook/main.ts` e presets **MUST** ser ESM válido. `require` **NEVER** — a linha 10 é ESM-only. |
| `SB-CORE-04` | Node **MUST** ser ≥ 20.19 ou ≥ 22.12. |
| `SB-CORE-05` | Uma story **NEVER** depende de outra story ter rodado antes. † |
| `SB-CORE-06` | O corpo do módulo de story **NEVER** contém efeito colateral nem valor não-determinístico (`await`, I/O, `Math.random`, `Date.now`). Computação pura e determinística é permitida. † |

### 6.1 Regras críticas dos satélites

As famílias completas vivem nos satélites, mas **estas precisam viajar com o caminho mínimo** — são as que mais aparecem em código gerado e não podem depender de o agente ter aberto o satélite certo. O texto abaixo é reproduzido **verbatim** do satélite; o satélite é canônico.

| ID | Regra | Satélite |
| --- | --- | --- |
| `SB-CSF-02` | `meta` **MUST** ser declarado com `satisfies Meta<typeof Componente>`, e o tipo da story derivado por `StoryObj<typeof meta>`. | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `SB-CSF-04` | O que distingue uma story de outra **MUST** ser `args`. Estado embutido em `render` **NEVER**. | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `SB-CSF-07` | Hooks do Storybook **NEVER** são misturados com Hooks do React no mesmo `render`. | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `SB-CTX-01` | `parameters` fazem merge por chave: sobrescrever uma subchave **NEVER** derruba as irmãs. | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `SB-CTX-04` | Estado mutável compartilhado entre stories **MUST** ser resetado em `beforeEach`. | [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) |
| `SB-TEST-01` | Toda chamada a `expect` dentro de `play` **MUST** ser aguardada com `await`. | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| `SB-TEST-02` | `play` que precisa rodar código **antes** do render **MUST** desestruturar `mount` e chamá-lo. | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| `SB-TEST-04` | Violação de a11y só quebra CI se `parameters.a11y.test` for `'error'`. `'todo'` **NEVER** produz saída em CI. | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| `SB-TEST-05` | O addon-vitest exige Vitest e browser mode. `bun test` **NEVER** executa stories. | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| `SB-TEST-11` | O número de cobertura **MUST** ser lido como cobertura **das stories**, não do código do projeto. Tratá-lo como cobertura de base de código **NEVER**. | [Storybook - Cobertura e CI](storybook-cobertura-e-ci.md) |
| `SB-TEST-16` | Em CI, o link de depuração **MUST** vir de `storybookUrl` apontando para um Storybook publicado — em CI não há Storybook ativo. | [Storybook - Cobertura e CI](storybook-cobertura-e-ci.md) |
| `SB-MOCK-01` | `sb.mock` **MUST** ser chamado apenas em `.storybook/preview.*`. Em arquivo de story, **NEVER**. | [Storybook - Mocking](storybook-mocking.md) |
| `SB-MOCK-03` | Arquivo em `__mocks__` **MUST** ser JavaScript com ESM. TypeScript ou CJS **NEVER**. | [Storybook - Mocking](storybook-mocking.md) |
| `SB-DOC-01` | A página de docs **MUST** ter a tag `autodocs` alcançando o arquivo — herdada do `preview` (a forma prescrita), ou declarada no `meta` ou numa story. | [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) |
| `SB-TS-03` | Contexto do router **MUST** ser injetado por `context`/`useRouterContext`. `RouterProvider` manual em decorator **NEVER** sob `@storybook/tanstack-react`. | [Storybook - TanStack React](storybook-tanstack-react.md) |
| `SB-TS-06` | React Server Component **NEVER** renderiza no Storybook. Extraia a parte cliente. | [Storybook - TanStack React](storybook-tanstack-react.md) |
| `SB-RV-01` | Sob `react-vite`, componente que usa router **MUST** receber um router real por decorator — não há embrulho automático. | [Storybook - React Vite](storybook-react-vite.md) |
| `SB-RV-04` | `parameters.tanstack.*` **NEVER** tem efeito sob `react-vite` — falha em silêncio. | [Storybook - React Vite](storybook-react-vite.md) |

### 6.2 IDs canônicos

**Dois** princípios aparecem em mais de um satélite com IDs diferentes, porque cada satélite precisa se sustentar sozinho. **Para citar, use sempre o ID canônico** — o outro é apelido e não deve aparecer em revisão.

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| Estado nomeado é `args`, não código | `SB-CSF-04` | `SB-DOC-05` |
| Estado compartilhado entre stories é resetado | `SB-CTX-04` | `SB-TS-04` |

**Pares por caminho.** Dois princípios têm um ID em cada caminho, e **nenhum dos dois é apelido do outro** — citar o ID do caminho errado é achado inválido (ver a nota sob as famílias). Use o que corresponde ao `framework` do projeto:

| Princípio | Sob `tanstack-react` | Sob `react-vite` |
| --- | --- | --- |
| Não embrulhar o que o framework já embrulha | `SB-TS-03` | `SB-RV-05` |
| Design system que exige rota é acoplamento a corrigir | `SB-TS-08` | `SB-RV-06` |

> **Quatro regras que parecem apelido e não são**, e por isso continuam citáveis por ID próprio:
>
> - `SB-CTX-05` (globals não é `args`) exprime um achado que `SB-CSF-04` não exprime — "usou global onde devia ser arg" não é "pôs estado no `render`".
> - `SB-TEST-07` carrega a exceção do `fn`, que `SB-CTX-04` não carrega.
> - `SB-MOCK-04` é a **metade complementar** de `SB-MOCK-01`, não seu sinônimo: uma diz onde registra, a outra onde comporta. E as duas vivem no mesmo satélite, o que já as tira do critério de apelido.
> - `SB-CTX-06` é **condicional ao framework** e por isso mais ampla que `SB-TS-03`: sob `react-vite` ela continua valendo e simplesmente não é acionada.

### Famílias completas nos satélites

`SB-CSF-*` · `SB-CFG-*` · `SB-CTX-*` · `SB-TEST-*` · `SB-MOCK-*` · `SB-DOC-*` · `SB-TS-*` · `SB-RV-*`

**`SB-TEST-*` mora em dois satélites**, e é a única família dividida: `01`–`10` em [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) (escrever o teste), `11`–`17` em [Storybook - Cobertura e CI](storybook-cobertura-e-ci.md) (operá-lo). Os IDs `01`–`10` **mantêm texto e significado** — citação anterior a 2026-08-21 continua válida.

As duas últimas são **exclusivas de um caminho**: `SB-TS-*` só se aplica sob `@storybook/tanstack-react`, `SB-RV-*` só sob `@storybook/react-vite`. Citar uma delas contra um projeto do outro caminho é achado inválido.

---

## 7. Contrato de skill

Como uma skill de Storybook deve consumir esta doc.

### O que carregar

```
SEMPRE: Docs/Storybook.md § 2 (modelo mental)
 Docs/Storybook.md § 5 (árvores de decisão)
 Docs/Storybook.md § 6 + § 6.1 (regras normativas e críticas)

AO ESCREVER/EDITAR arquivo de stories:
 Docs/Storybook - Stories e Args.md

ANTES DE QUALQUER COISA, para descobrir o caminho do projeto:
 leia o campo `framework` de.storybook/main.ts

AO CONFIGURAR o projeto, ou em qualquer story que toque rota:
 Docs/Storybook - TanStack React.md (se framework = @storybook/tanstack-react)
 Docs/Storybook - React Vite.md (se framework = @storybook/react-vite)

SOB DEMANDA, via § 4 (mapa da API):
 o satélite da superfície tocada pela tarefa

NUNCA: todos os satélites de uma vez
```

### Como citar

Achados de revisão citam o ID da regra e o satélite, não parafraseiam:

> `SB-MOCK-01` — `sb.mock` chamado dentro do arquivo de story. O registro pertence a `.storybook/preview.tsx`; a story só define comportamento, via `mocked` em `beforeEach`.
> Ver [Storybook - Mocking](storybook-mocking.md).

### Invariantes que a skill deve fazer valer

1. **Verificar antes de afirmar.** Se uma API não está na § 4, ela não foi verificada nesta doc. Consulte storybook.js.org e atualize a nota — não invente comportamento nem opção de configuração.
2. **A fonte vence.** Divergência entre esta nota e a doc oficial é bug desta nota.
3. **Estado antes de estética.** Antes de melhorar o visual de uma story, checar se ela expressa um estado nomeado por `args` (`SB-CSF-04`). Uma story bonita que não é controlável é pior que uma feia que é.
4. **Uma story é um teste.** Ao criar story nova, decidir explicitamente: ela precisa de `play`? Precisa de `a11y.test: 'error'`? O default de não decidir é uma story que só faz smoke test — o que é aceitável, mas deve ser escolha.
5. **Preferir a ponte.** Quando a § 8 indica que o problema pertence a outra nota do vault (React, Query, RHF), seguir a ponte em vez de reinventar dentro da story.
6. **Não misturar os caminhos.** Antes de sugerir `parameters.tanstack.router` ou um decorator de `RouterProvider`, confirmar o `framework` em `main.ts`. Prescrever o do caminho errado produz código que falha em silêncio (`SB-RV-04`) ou que cria um segundo router (`SB-TS-03`).

### Ao criar uma nova skill de React que envolva Storybook

Derive-a de um satélite, não desta nota inteira. Três recortes que funcionam:

| Skill | Carrega |
| --- | --- |
| "escrever story de componente de design system" | § 2 + § 6 + [Storybook - Stories e Args](storybook-stories-e-args.md) + [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) |
| "escrever teste de interação a partir de story" | § 2 + § 6 + [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) + [Storybook - Mocking](storybook-mocking.md) |
| "montar o CI das stories, ou interpretar a cobertura" | § 6 + [Storybook - Cobertura e CI](storybook-cobertura-e-ci.md) |
| "configurar Storybook num app novo" | § 5.1 + [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) + a nota do caminho escolhido |

Registre no início da skill qual satélite é a fonte, para que a atualização da doc propague.

---

## 8. Pontes com o stack

O corpo desta doc é Storybook fiel à fonte. Mas no meu stack várias decisões de story são decididas por outra nota, e os satélites marcam esses pontos como *ponte*.

| Problema dentro de uma story | O que **não** fazer | A ponte |
| --- | --- | --- |
| Componente busca dado remoto | mockar `fetch` na mão | `QueryClient` por story com `retry: false` — [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) |
| Componente usa `Link` ou `useNavigate` — **caminho tanstack-react** | embrulhar em `RouterProvider` manual | `parameters.tanstack.router` — [Storybook - TanStack React](storybook-tanstack-react.md) |
| Componente usa `Link` ou `useNavigate` — **caminho react-vite** | esperar `parameters.tanstack` funcionar (é no-op, `SB-RV-04`) | decorator com árvore mínima — [Storybook - React Vite](storybook-react-vite.md) § 4 |
| Componente lê search param tipado — **caminho tanstack-react** | passar prop fake | `query` + `routeOverrides.validateSearch` — [TanStack Router - Search Params](tanstack-router-search-params.md) |
| Componente lê search param tipado — **caminho react-vite** | passar prop fake | query string em `initialEntries`; `validateSearch` **não é sobrescrevível** — [Storybook - React Vite](storybook-react-vite.md) § 4.2 |
| Story de formulário complexo | disparar `change` em cada input | `play` com `userEvent` + `fn` no `onSubmit` — [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| Componente com `useEffect` de fetch | escrever a story em volta do defeito | o defeito é o `useEffect` — `REACT-EFFECT-06` em [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| Tema e tokens | `style` inline na story | decorator global de tema — `Tailwindcss` |
| Erro esperado (400 de validação) | lançar para o Error Boundary | é estado, e merece story própria — `REACT-ASYNC-09` |
| Resposta do BFF tipada | duplicar o tipo no mock | reusar o tipo exportado do servidor — `Hono - Validação e RPC`, `Elysia - Schema e Eden` |

**A ponte que mais importa: `packages/ui` não conhece rota, e isso é o desenho.** Um componente de design system que precisa de `parameters.tanstack.router` para renderizar está acoplado a rota e deveria receber a navegação por prop. A story serve como detector desse acoplamento: se a story de um componente de `packages/ui` precisa de rota, o achado é sobre o componente, não sobre a story. Ver a direção de dependência em `Monorepo com Bun - estrutura e tooling`.

**A ponte de runner.** `bun test` cobre `apps/server`; `vitest --project=storybook` cobre as stories. São dois runners por desenho (`SB-TEST-05`). O CI roda os dois, e o filtro do Bun não alcança o segundo — ver a armadilha de `--filter` negado em `Monorepo com Bun - estrutura e tooling` § 4.

---

## Relacionados

- [Storybook - Stories e Args](storybook-stories-e-args.md) — o formato do arquivo e a superfície de `args`
- [Storybook - TanStack React](storybook-tanstack-react.md) — caminho A: o framework do TanStack
- [Storybook - React Vite](storybook-react-vite.md) — caminho B: o framework genérico, e o router à mão
- [React.js](react-js.md) — o hub de React; esta doc pressupõe o modelo mental de lá
- [React - Patterns](react-patterns.md) — decide o que é componente de design system e o que não é
- [TanStack Query](tanstack-query.md) · [TanStack Router](tanstack-router.md) · [React Hook Form](react-hook-form.md) · `Tailwindcss`
- `Bun - Testes` — o outro runner do monorepo
- `Monorepo com Bun - estrutura e tooling` — onde `apps/storybook` vive e por que é folha

## Fontes consultadas

Verificadas diretamente em **2026-08-19**:

- [Storybook for TanStack React](https://storybook.js.org/docs/get-started/frameworks/tanstack-react) — a página que originou esta estrutura
- [Storybook for React & Vite](https://storybook.js.org/docs/get-started/frameworks/react-vite) — o segundo caminho
- [main.ts — framework](https://storybook.js.org/docs/api/main-config/main-config-framework)
- [TanStack Router — History types](https://tanstack.com/router/latest/docs/framework/react/guide/history-types) — o router à mão do caminho Vite
- [Writing Stories](https://storybook.js.org/docs/writing-stories) · [Args](https://storybook.js.org/docs/writing-stories/args) · [Parameters](https://storybook.js.org/docs/writing-stories/parameters) · [Decorators](https://storybook.js.org/docs/writing-stories/decorators) · [Play function](https://storybook.js.org/docs/writing-stories/play-function) · [Tags](https://storybook.js.org/docs/writing-stories/tags)
- [CSF API](https://storybook.js.org/docs/api/csf) · [main.ts config](https://storybook.js.org/docs/api/main-config/main-config)
- [Writing Tests](https://storybook.js.org/docs/writing-tests) · [Interaction testing](https://storybook.js.org/docs/writing-tests/interaction-testing) · [Accessibility testing](https://storybook.js.org/docs/writing-tests/accessibility-testing) · [Vitest addon](https://storybook.js.org/docs/writing-tests/integrations/vitest-addon) · [Portable stories (Vitest)](https://storybook.js.org/docs/api/portable-stories/portable-stories-vitest)
- [Mocking modules](https://storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-modules) · [Mocking network requests](https://storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-network-requests)
- [Autodocs](https://storybook.js.org/docs/writing-docs/autodocs) · [Styling and CSS](https://storybook.js.org/docs/configure/styling-and-css)
- [Migration guide](https://storybook.js.org/docs/releases/migration-guide)
- Versões: `npm view <pacote> dist-tags` em 2026-08-19

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **TanStack Start não é requisito do `@storybook/tanstack-react`.** A doc afirma suporte a SPA usando só `@tanstack/react-router`; os stubs de server function são a metade que só acende sob Start.
- **O framework `tanstack-react` cobra requisito maior que o `react-vite`:** React ≥ 18 e **Vite ≥ 7**, contra React ≥ 16.8 e Vite ≥ 5.
- **O redirecionamento de `@tanstack/react-router` para a camada de mock é global**, não opt-in por story. Vale também para stories que não tocam rota.
- **Os utilitários de teste são `storybook/test`, sem `@`.** `useArgs` vive em `storybook/preview-api`.
- **`sb.mock` só pode ser registrado em `.storybook/preview.*`.** A doc é explícita: o registro é de projeto, "para garantir mocking consistente e performante em todas as stories". A story controla só comportamento.
- **Arquivos em `__mocks__` precisam ser JavaScript com ESM** — não TypeScript, não CJS.
- **O addon de a11y desabilita a regra `region` por padrão**, para evitar falso **positivo** em story de componente isolado — um botão fora de landmark é o normal do Storybook, não defeito.
- **`parameters.a11y.test: 'todo'` não produz nada em CI** — nem erro, nem warning, nem saída. Só `'error'` falha.
- **`mount` é obrigatório na `play`** quando há código a rodar antes do render; sem desestruturá-lo, o Storybook já começou a renderizar.
- **Mocks `fn` não precisam de restauração manual** — o Storybook reseta entre stories.
- **A config do addon-vitest é breaking entre Vitest 3 e 4:** `provider: 'playwright'` (string) virou `provider: playwright({})`, importado de `@vitest/browser-playwright`. O `latest` do npm hoje é Vitest 4.1.11, então o exemplo de string está desatualizado para instalação nova.
- **O addon-vitest roda em browser real com Playwright**, não em JSDOM — e exige Vitest, logo não roda sob `bun test`.
- **`msw-storybook-addon` v3 trocou a API:** `mswLoader` de `msw-storybook-addon/csf3` mais `beforeEach({ msw })`, no lugar do antigo `parameters.msw.handlers`.
- **Storybook 10 é ESM-only** e exige Node 20.19+/22.12+; `main.ts` com `require` não sobe.
- **A doc oficial recomenda migrar de `test-runner` para `addon-vitest`** — o test-runner é o caminho legado, ainda documentado.
- **As tags `dev`, `test` e `manifest` são aplicadas por padrão**; `autodocs` não é. Existem ainda `play-fn` e `test-fn` aplicadas automaticamente.
- **Os exemplos de código da fonte são templados por renderer** e às vezes aparecem resolvidos como `@storybook/react` mesmo quando a prescrição textual é "o pacote do seu framework". A forma prescrita é a do framework.
