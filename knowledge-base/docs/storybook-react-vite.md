---
Link: https://storybook.js.org/docs/get-started/frameworks/react-vite
tags:
 - storybook
 - vite
 - react
 - agent-context
source: "Documentação oficial do Storybook — framework React & Vite; TanStack Router — History types"
verificado-em: 2026-08-19
---

# Storybook — React Vite

> Satélite de [Storybook](storybook.md). É um dos **dois caminhos de framework** da estrutura; o outro é [Storybook - TanStack React](storybook-tanstack-react.md). Escolha um — a árvore de decisão está na § 5.1 do hub e é resumida na § 2 desta nota.
>
> Cobre `@storybook/react-vite`: setup, opções, e — o assunto que domina a nota — **o que você passa a ter que fazer à mão** por não ter o embrulho automático de router.

---

## 1. O que este framework é

`@storybook/react-vite` é o framework React genérico sobre o builder Vite. Ele renderiza componentes React e nada mais: **não conhece rota, não conhece TanStack, não injeta contexto**.

Isso é uma qualidade, não uma falta. Se o Storybook cobre um design system de componentes puros, não há nada a embrulhar, e o framework genérico entrega o mesmo resultado com um piso de versão muito mais baixo.

| | `@storybook/react-vite` | `@storybook/tanstack-react` |
| --- | --- | --- |
| React | **≥ 16.8** | ≥ 18 |
| Vite | **≥ 5** | ≥ 7 |
| Router embrulhado por story | não | sim, em memória |
| Imports de `@tanstack/react-router` redirecionados | não | sim, e é **global** |
| Navegação vira spy | não | sim |
| Mock de server function do Start | não | sim |
| `parameters.tanstack.router` | **sem efeito** | é o controle de rota |

---

## 2. Quando este é o caminho certo

```
O Storybook vai renderizar alguma story cuja árvore de import
alcança @tanstack/react-router?
├── NÃO
│ → @storybook/react-vite
│ típico: Storybook exclusivo de packages/ui
└── SIM
 ├── e o projeto está em Vite ≥ 7 e React ≥ 18
 │ → @storybook/tanstack-react
 └── e o projeto NÃO alcança esses requisitos
 → @storybook/react-vite + decorator de router (§ 4)
 é o caminho de transição, não o destino
```

Dois cenários concretos:

1. **Storybook só de design system.** `packages/ui` não conhece rota por desenho — o princípio é `SB-RV-06` deste lado, `SB-TS-08` do outro (ver os pares por caminho na § 6.2 do hub). Um Storybook dedicado a ele não tem o que embrulhar, e `react-vite` é a escolha simples e certa.
2. **App em Vite 5 ou 6.** O requisito de Vite ≥ 7 do framework do TanStack é o mais alto de toda a estrutura. Enquanto a migração de build não acontece, `react-vite` + decorator manual é o que funciona.

> **No monorepo deste vault**, `apps/storybook` consome `packages/ui` **e** `apps/web` — então o caminho é o do TanStack. Esta nota existe para o cenário em que um consumidor do design system monta o próprio Storybook, ou para o Storybook separado que cobre só `packages/ui`.

---

## 3. Setup

```bash
npm create storybook@latest
# ou, manualmente:
npm install --save-dev @storybook/react-vite
```

```ts
//.storybook/main.ts
import type { StorybookConfig } from '@storybook/react-vite';

const config: StorybookConfig = {
 framework: '@storybook/react-vite',
 stories: ['../src/**/*.stories.@(ts|tsx)', '../src/**/*.mdx'],
 addons: ['@storybook/addon-docs', '@storybook/addon-a11y', '@storybook/addon-vitest'],
};

export default config;
```

```tsx
//.storybook/preview.tsx
import type { Preview } from '@storybook/react-vite';

const preview = {
 parameters: { layout: 'centered', a11y: { test: 'error' } },
 tags: ['autodocs'],
} satisfies Preview;

export default preview;
```

**O token de import muda, e é só isso, nos satélites temáticos.** `Meta`, `StoryObj`, `Preview` e `StorybookConfig` vêm de `@storybook/react-vite` (`SB-CORE-02`). Toda a superfície de [Storybook - Stories e Args](storybook-stories-e-args.md), [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) e [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) vale igual.

### 3.1 `framework` com opções

O campo aceita string ou objeto:

```ts
framework: {
 name: '@storybook/react-vite',
 options: {
 builder: { /* opções do builder Vite */ },
 },
},
```

`builder` é a opção compartilhada entre frameworks, documentada na referência de `main.ts`. **Opções específicas de `react-vite` — `strictMode`, `reactDocgen`, `reactDocgenTypescriptOptions` — não aparecem nas páginas verificadas aqui:** a referência de framework remete à documentação do próprio pacote no repositório. Se precisar de uma delas, confirme na fonte antes de escrever; a ausência aqui significa "não verificado", não "não existe".

### 3.2 O addon do Vitest funciona igual

O requisito do `@storybook/addon-vitest` é **um framework de Storybook que use Vite** — `react-vite` qualifica. Toda a § 4 de [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) vale sem alteração, incluindo o corte de config entre Vitest 3 e 4.

---

## 4. O router à mão

Esta é a diferença que gera trabalho. Sem embrulho automático, qualquer componente que use `<Link>`, `useNavigate`, `useSearch` ou `useParams` lança fora de contexto de router.

### 4.1 Duas formas, e a diferença entre elas importa

As APIs são do TanStack Router, não do Storybook. Mas há **duas montagens possíveis**, e escolher errado mata o painel de controles:

| Forma | O que renderiza | `args` e controles | Quando |
| --- | --- | --- | --- |
| **árvore mínima** | `<Story />`, dentro de uma rota criada para a story | **vivos** | default — é o que se quer quase sempre |
| **árvore real** (`routeTree.gen`) | o componente que a rota resolve; `<Story />` é ignorado | **mortos** | só quando a story existe para exercitar a resolução de rota em si |

A armadilha é a segunda: um decorator que devolve `<RouterProvider router={router} />` **não usa `Story`**. O componente aparece na tela — porque a rota o resolve — e mesmo assim `component`, `args` e o painel de controles ficam inertes. É o defeito que `SB-CSF-04` e `SB-DOC-05` descrevem, chegando por um caminho que não parece erro.

### 4.2 Árvore mínima — a forma default

A rota é criada para a story, e o componente dela é `<Story />`. Assim os hooks do router funcionam **e** os args continuam controláveis:

```tsx
// PaginaTarefa.stories.tsx
import type { Meta, StoryObj } from '@storybook/react-vite';
import {
 Outlet,
 RouterProvider,
 createMemoryHistory,
 createRootRoute,
 createRoute,
 createRouter,
} from '@tanstack/react-router';
import { PaginaTarefa } from './PaginaTarefa';

const meta = {
 title: 'Web/Páginas/PaginaTarefa',
 component: PaginaTarefa,
 parameters: { layout: 'fullscreen' },
 decorators: [
 (Story) => {
 const rootRoute = createRootRoute({ component: => <Outlet /> });

 const storyRoute = createRoute({
 getParentRoute: => rootRoute,
 path: '/tarefas/$id',
 component: => <Story />,
 });

 const router = createRouter({
 routeTree: rootRoute.addChildren([storyRoute]),
 history: createMemoryHistory({
 initialEntries: ['/tarefas/42?tab=detalhes'],
 }),
 });

 return <RouterProvider router={router} />;
 },
 ],
} satisfies Meta<typeof PaginaTarefa>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
```

Quatro pontos:

- **`<Story />` é o componente da rota.** É isso que mantém `args` e controles vivos.
- **`createMemoryHistory` é obrigatório.** History de browser numa story mexe na URL do próprio Storybook e vaza navegação entre stories (`SB-RV-02`).
- **Params e query entram como string em `initialEntries`.** `'/tarefas/42?tab=detalhes'` produz `useParams` → `{ id: '42' }` e `useSearch` → `{ tab: 'detalhes' }`. **Sem checagem de tipo** contra o path — errar o nome do segmento não é erro de compilação, é story que renderiza errado. É o custo direto de não estar no caminho TanStack.
- **O router é criado dentro do decorator**, uma instância por render (`SB-RV-03`).

A API de árvore em código — `createRootRoute`, `createRoute`, `getParentRoute`, `addChildren` — está documentada em [TanStack Router - Route Trees](tanstack-router-route-trees.md), incluindo `TSR-TREE-06`: a raiz vem de `createRootRoute`, nunca de `createRoute` com `id` inventado.

> **A tensão do `SB-RV-03`.** Recriar o router a cada render zera o estado de navegação. Para uma story que só renderiza, isso é o que se quer. Para uma story cuja `play` clica num `<Link>` e espera continuar na tela seguinte, é problema — e esta doc **não tem solução verificada** para o caso. Está registrado em [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md).

### 4.3 Árvore real — quando a story É a rota

```tsx
decorators: [
 => {
 const router = createRouter({
 routeTree, // de../routeTree.gen
 history: createMemoryHistory({ initialEntries: ['/tarefas/42'] }),
 });
 return <RouterProvider router={router} />;
 },
],
```

Aqui `Story` nem é declarado, porque não seria usado — e a ausência é deliberada, não descuido. Use esta forma só quando o objeto do teste é a resolução de rota. Aceite que o painel de controles fica vazio, e **não** declare `args` que ninguém vai ler.

Custo adicional: o `loader` real da rota roda. Ver § 4.4.

### 4.4 O que não existe deste lado

| Recurso do `tanstack-react` | Equivalente sob `react-vite` |
| --- | --- |
| `parameters.tanstack.router.route` | montar o router com a árvore real, ou uma árvore mínima |
| `params`, `query` tipados | string em `initialEntries`, sem checagem |
| `routeOverrides` para `loader` / `beforeLoad` | **não há**. Reduza a árvore (§ 4.2, que não tem `loader`) ou mocke o módulo que o `loader` chama — [Storybook - Mocking](storybook-mocking.md) |
| `routeOverrides.validateSearch` | **não há, e não há substituto**. `validateSearch` vive na definição da rota. Na árvore mínima você não o declara; na árvore real, o schema manda. Ver [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md) |
| `context` / `useRouterContext` | `createRouter({ context })`, na criação |
| navegação virando spy | não há. Para asseverar navegação, passe a ação por prop e observe com `fn` |
| stubs de server function do Start | não há |
| automock dos módulos `@tanstack/*` | mock explícito, se necessário (`SB-RV-07`) |

A linha de `routeOverrides` é a que mais custa: o `loader` real roda, então ou a árvore de rotas da story é reduzida, ou o módulo que ele chama é mockado.

### 4.5 Onde o decorator **não** deve ficar

Não coloque o decorator de router no `preview` global.

O motivo não é técnico, é de detecção. Um router global faz toda story renderizar, inclusive a de um componente de `packages/ui` que não deveria conhecer rota — e apaga o sinal. Mantendo o router no `meta` de quem realmente é página, o componente de design system acoplado a rota falha, e a falha é a informação (`SB-RV-06`, espelho de `SB-TS-08`).

### 4.6 Regras — `SB-RV-01` a `SB-RV-04`, `SB-RV-06`, `SB-RV-07`

| ID | Regra |
| --- | --- |
| `SB-RV-01` | Sob `react-vite`, componente que usa router **MUST** receber um router real por decorator — não há embrulho automático. |
| `SB-RV-02` | O router de uma story **MUST** usar `createMemoryHistory`. History de browser **NEVER**. |
| `SB-RV-03` | A instância de router **MUST** ser criada por render de story. Instância compartilhada no topo do módulo **NEVER**. † |
| `SB-RV-04` | `parameters.tanstack.*` **NEVER** tem efeito sob `react-vite` — falha em silêncio. |
| `SB-RV-06` | Componente de `packages/ui` que exige decorator de router **MUST** ser tratado como acoplamento a corrigir no componente. † |
| `SB-RV-07` | Mock de módulo `@tanstack/*` **MUST** ser explícito sob `react-vite` — não há camada automática. |

---

## 5. Trocar de caminho

### 5.1 `react-vite` → `tanstack-react`

```bash
npx storybook automigrate react-vite-to-tanstack-react
```

Manualmente: trocar a dependência, trocar `framework` em `main.ts`, trocar os imports de tipo em `preview.tsx` **e em todos os arquivos de story**, e — o passo que a automigração destaca — **remover os decorators de `RouterProvider`**. O framework passa a embrulhar sozinho, e o decorator remanescente cria um segundo router competindo (`SB-RV-05`, espelho de `SB-TS-03`).

Depois da troca, os decorators da § 4.2 viram `parameters.tanstack.router` — e aí `params` volta a ser checado contra o path da rota.

### 5.2 `tanstack-react` → `react-vite`

Não há automigração. O caminho é manual e vale a pena saber o custo antes: toda story que dependia de `parameters.tanstack.router` precisa de decorator próprio, e `routeOverrides` não tem substituto direto.

O motivo legítimo para voltar é um só: o piso de versão. Se o projeto não pode ir para Vite 7, `react-vite` é o que roda.

### 5.3 Regra — `SB-RV-05`

| ID | Regra |
| --- | --- |
| `SB-RV-05` | Ao migrar para `tanstack-react`, os decorators de `RouterProvider` **MUST** ser removidos. |

---

## 6. Antipadrões

### 6.1 Esperar que `parameters.tanstack.router` funcione

É o erro nº 1 de quem leu a doc do outro caminho. Sob `react-vite`, o parameter é ignorado — não há erro, a story só renderiza sem rota, e o rastro aponta para o componente (`SB-RV-04`).

### 6.2 Router criado no topo do módulo

```tsx
const router = createRouter({ routeTree, history: createMemoryHistory({ initialEntries: ['/'] }) }); // ❌

const meta = {
 decorators: [ => <RouterProvider router={router} />],
} satisfies Meta<typeof PaginaTarefa>;
```

A instância é compartilhada por todas as stories do arquivo. A segunda renderiza no path para onde a primeira navegou (`SB-RV-03`).

### 6.2.1 Decorator que descarta `<Story />` sem querer

```tsx
decorators: [
 (Story) => { // ❌ Story declarado e nunca usado
 const router = createRouter({ routeTree, history });
 return <RouterProvider router={router} />;
 },
],
```

O componente aparece na tela, então parece funcionar. Mas o painel de controles fica vazio e `args` não tem efeito — o sintoma que a § 5.6 do hub manda diagnosticar. Se a story precisa de args, é árvore mínima (§ 4.2). Se não precisa, não declare `Story` (§ 4.3).

### 6.3 Decorator de router no `preview`

Resolve todas as stories de uma vez e apaga o detector de acoplamento (`SB-RV-06`). Ver § 4.3.

### 6.4 History de browser numa story

`createBrowserHistory` altera a URL do Storybook. O sintoma é a sidebar perdendo a story selecionada ao interagir (`SB-RV-02`).

### 6.5 Adotar `react-vite` para fugir de um problema que é do componente

Se a única razão para não usar o framework do TanStack é "o componente de design system quebra sob ele", a causa é o componente conhecer rota. Trocar de framework esconde isso.

---

## Relacionados

- [Storybook](storybook.md) — hub, e a árvore de decisão de framework na § 5.1
- [Storybook - TanStack React](storybook-tanstack-react.md) — o outro caminho
- [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) — onde o decorator de router se encaixa
- [Storybook - Mocking](storybook-mocking.md) — o substituto de `routeOverrides` deste lado
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — vale igual nos dois caminhos
- [TanStack Router - Navegação](tanstack-router-navegacao.md) — `RouterProvider` e navegação no app real
- [TanStack Router - Route Trees](tanstack-router-route-trees.md) — `createRootRoute`, `createRoute`, `addChildren`: a árvore que o decorator monta
- [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md) — o que esta nota deixou em aberto

## Fontes consultadas

Verificadas diretamente em **2026-08-19**:

- [Storybook for React & Vite](https://storybook.js.org/docs/get-started/frameworks/react-vite)
- [main.ts — framework](https://storybook.js.org/docs/api/main-config/main-config-framework)
- [Storybook for TanStack React](https://storybook.js.org/docs/get-started/frameworks/tanstack-react) — para a comparação e a automigração
- [TanStack Router — History types](https://tanstack.com/router/latest/docs/framework/react/guide/history-types)

**Notas de verificação:**

- **`@storybook/react-vite` pede React ≥ 16.8 e Vite ≥ 5** — piso bem mais baixo que o do framework do TanStack.
- **`framework` aceita string ou `{ name, options }`**, e `builder` é a opção compartilhada entre frameworks.
- **As opções específicas de `react-vite` (`strictMode`, `reactDocgen`) não constam das páginas verificadas.** A referência remete à documentação do pacote no repositório. Não verificado aqui.
- **`createMemoryHistory`, `createRouter` e `RouterProvider` são do `@tanstack/react-router`**, não do Storybook. `createMemoryHistory({ initialEntries: ['/'] })` e `createRouter({ routeTree, history })` são a forma da fonte do TanStack.
- **Existem três tipos de history:** `createBrowserHistory` (default), `createHashHistory` e `createMemoryHistory`.
- **A automigração `react-vite-to-tanstack-react` existe e é unidirecional.** Não há automigração no sentido inverso.
- **O addon do Vitest exige um framework baseado em Vite**, e `react-vite` qualifica — a camada de teste é idêntica nos dois caminhos.
- **A montagem de árvore mínima usa API já verificada no vault** — `createRootRoute`, `createRoute`, `getParentRoute`, `addChildren`, em [TanStack Router - Route Trees](tanstack-router-route-trees.md). **Não** é padrão prescrito pela doc do Storybook: é composição desta doc a partir de duas fontes verificadas.
- **Que `initialEntries` aceita query string não foi verificado na fonte do TanStack** — a doc de history types só mostra path puro. Registrado em [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md).
