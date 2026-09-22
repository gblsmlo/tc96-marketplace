---
titulo: Storybook - TanStack React
Link: https://storybook.js.org/docs/get-started/frameworks/tanstack-react
tags:
 - storybook
 - tanstack
 - router
 - react
 - agent-context
source: "Documentação oficial do Storybook — framework TanStack React"
verificado-em: 2026-08-19
---

# Storybook — TanStack React

> Satélite de [Storybook](storybook.md). É um dos **dois caminhos de framework** da estrutura; o outro é [Storybook - React Vite](storybook-react-vite.md). Cobre o framework `@storybook/tanstack-react`: o que ele injeta automaticamente, `parameters.tanstack.router` campo a campo, a integração com TanStack Query, a migração vinda de `@storybook/react-vite`, e os limites declarados.
>
> Esta é a página que originou toda a estrutura. É também a que decide a configuração do projeto — por isso o contrato de skill do hub manda carregá-la **antes de configurar**, mesmo quando a tarefa é sobre design system.

---

## 1. O que o framework faz sozinho

Três coisas, e é importante saber que são automáticas:

1. **Embrulha cada story num TanStack Router em memória.** Não há servidor, não há URL de verdade — o router é *memory-backed*.
2. **Redireciona os imports de `@tanstack/react-router` para uma camada de mock.** `useNavigate`, `useSearch` e `useParams` continuam disponíveis dentro da story, e **tentativas de navegação viram spies do Storybook** — dá para asseverar que um clique tentou navegar.
3. **Faz stub dos entrypoints de servidor e de runtime do TanStack Start**, para que componente que usa server function consiga renderizar.

O ponto 2 é o que mais muda o dia a dia: uma story de `apps/web` que renderiza um `<Link>` simplesmente funciona, sem decorator, sem provider, sem rota falsa montada à mão.

**E o ponto 2 é global.** O redirecionamento vale para todas as stories do Storybook, inclusive as de `packages/ui` que não tocam rota. Não é opt-in por story.

### 1.1 TanStack Start não é requisito

A fonte é explícita: o framework atende **tanto SPA usando só `@tanstack/react-router` quanto app TanStack Start completo**. Os stubs de server function são a metade que só acende sob Start.

Num app SPA com BFF separado — o desenho de `Backend no runtime Bun` — essa metade fica inerte, e isso é o esperado, não sintoma de configuração errada. O que se aproveita é o router mockado, que já justifica sozinho.

---

## 2. Escolher entre `tanstack-react` e `react-vite`

A mesma comparação, vista do outro lado, está em [Storybook - React Vite](storybook-react-vite.md) § 1.

| | `@storybook/tanstack-react` | `@storybook/react-vite` |
| --- | --- | --- |
| React | ≥ **18** | ≥ 16.8 |
| Vite | ≥ **7** | ≥ 5 |
| Router embrulhado | sim, automático | não |
| Mock de server function do Start | sim | não |

O critério não é qual pacote a story documenta — é **o que a árvore de import da story alcança**. Um componente de `packages/ui` que importa `<Link>` já obriga o framework do TanStack, mesmo sendo "design system puro".

**Para o monorepo deste vault:** `apps/storybook` consome `packages/ui` **e** `apps/web`, e todo componente de página importa `Link`. Um Storybook único precisa de `@storybook/tanstack-react`.

> **O requisito de Vite ≥ 7 é a parte cara desta decisão.** É o requisito mais alto de toda a estrutura, e ele vem do framework, não do Storybook. Confirme a versão do Vite de `apps/web` antes de adotar: se estiver em 5 ou 6, a escolha é, na prática, agendar uma migração de Vite primeiro.

---

## 3. Setup

```bash
npm create storybook@latest
```

```ts
//.storybook/main.ts
import type { StorybookConfig } from '@storybook/tanstack-react';

const config: StorybookConfig = {
 framework: '@storybook/tanstack-react',
};

export default config;
```

```tsx
//.storybook/preview.tsx
import type { Preview } from '@storybook/tanstack-react';

const preview = {
 // configuração
} satisfies Preview;

export default preview;
```

Requisitos declarados: **React ≥ 18**, **Vite ≥ 7**, e `@tanstack/react-router` disponível no projeto.

Scripts: `storybook` para desenvolver, `build-storybook` para o build estático (`storybook-static`, configurável). Os nomes exatos estão em [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) § 4.1 — o `storybookScript` do addon-vitest depende deles.

### 3.1 Subpath exports

| Import | Contém |
| --- | --- |
| `@storybook/tanstack-react/react-router` | as APIs de mock do TanStack Router |
| `@storybook/tanstack-react/start` | os mocks do Start, incluindo `createServerFn` mockado |

---

## 4. `parameters.tanstack.router`

Todo o controle de rota da story passa por aqui.

### 4.1 Os campos

| Campo | Tipo | O que faz |
| --- | --- | --- |
| `route` | `AnyRoute` ou objeto de opções de rota | fornece a rota. Com um `Route` real, o Storybook extrai o componente React dele; com opções, cria uma rota temporária para a story |
| `params` | `ResolveParams<Path>` | interpola os params no path. Com file route tipada, o tipo é **restrito aos params declarados no path** (`/$id` → `{ id: string }`) |
| `path` | `string` | o path inicial do router da story. Aceita fragmento: `'/#secao'` |
| `query` | `Record<string, unknown>` | search params iniciais (`?tab=details&page=2`) |
| `context` | `Record<string, unknown>` | valores injetados no contexto do router |
| `routeOverrides` | `Partial<Record<string, RouteOverrideOptions>>` | sobrescritas por rota, **chaveadas por route ID**. `'__root__'` alveja a raiz. Cada entrada pode sobrescrever `loader`, `beforeLoad`, `validateSearch`, `loaderDeps` e `context` |
| `useRouterContext` | `({ storyContext }) => RouterContext` | calcula o contexto dinamicamente a partir do contexto da story |

### 4.2 Story de rota

```tsx
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import { Route } from './Page';

const meta = {
 parameters: {
 layout: 'fullscreen',
 tanstack: {
 router: {
 route: Route,
 params: { id: '42' },
 query: { tab: 'details' },
 },
 },
 },
} satisfies Meta<typeof Route>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
```

Note que o `meta` é tipado contra o `Route`, não contra um componente — o Storybook extrai o componente da rota. `layout: 'fullscreen'` é a escolha usual para story de página.

O ganho de tipo em `params` é real e vale usar: com file route tipada, passar `{ slug: 'x' }` numa rota `/$id` é erro de compilação, não descoberta em runtime (`SB-TS-02`). Isso depende da augmentation de tipo do router alcançar o programa TS do Storybook — a armadilha documentada em [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) § 4.2.

### 4.3 `routeOverrides`: neutralizar `loader` e `beforeLoad`

O `loader` de uma rota real chama a API. Numa story isso é rede em CI, lentidão e falha por motivo alheio ao componente:

```tsx
export const ComDadosCarregados: Story = {
 parameters: {
 tanstack: {
 router: {
 route: Route,
 params: { id: '42' },
 routeOverrides: {
 '/tarefas/$id': {
 loader: async => ({ tarefa: { id: '42', titulo: 'Revisar PR' } }),
 },
 '__root__': {
 beforeLoad: async => ({ usuario: { nome: 'Ada' } }),
 },
 },
 },
 },
 },
};
```

Isso substitui um `sb.mock` do módulo de API na maioria dos casos, e é mais direto: o ponto de substituição é a fronteira da rota, não um módulo interno (`SB-TS-07`).

`validateSearch` também é sobrescrevível — útil para uma story que quer exercitar search param inválido sem mexer no schema real. Ver [TanStack Router - Search Params](tanstack-router-search-params.md).

### 4.4 `context` e `useRouterContext`

`context` é valor estático. `useRouterContext` calcula a partir do contexto da story — serve quando o contexto depende de algo que a própria story já tem (um arg, um global de tema, o resultado de um loader).

---

## 5. TanStack Query dentro da story

O padrão da fonte, adaptado ao vault:

```tsx
//.storybook/preview.tsx
import type { Preview } from '@storybook/tanstack-react';
import { QueryClient } from '@tanstack/react-query';

const queryClient = new QueryClient({
 defaultOptions: {
 queries: {
 retry: false,
 staleTime: Infinity,
 },
 },
});

const preview = {
 beforeEach: => {
 queryClient.clear;
 },
 parameters: {
 tanstack: {
 router: {
 context: { queryClient },
 },
 },
 },
} satisfies Preview;

export default preview;
```

Três decisões, e nenhuma é cosmética:

- **`retry: false`.** Com o retry default, uma story de erro fica segundos tentando de novo antes de mostrar o estado que ela existe para mostrar — e no runner isso vira teste lento e instável (`SB-TS-05`).
- **`staleTime: Infinity`.** Elimina refetch por foco de janela e por remontagem. Numa story, refetch é ruído. Ver [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md).
- **`queryClient.clear` em `beforeEach`.** O client é único para todo o Storybook. Sem limpar, a segunda story renderiza com o cache da primeira, e o resultado depende de uma ordem que não é garantida (`SB-TS-04`, alias de `SB-CTX-04`).

O `queryClient` entra pelo **contexto do router**, que é onde o app real também o coloca — ver [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md). Isso mantém story e app com o mesmo formato de injeção.

---

## 6. Server functions do Start

Só sob TanStack Start. O framework já mocka `createServerFn`; a story define o comportamento:

```tsx
import { mocked } from 'storybook/test';
import { atualizarPerfil } from '../lib/atualizarPerfil';

export const Sucesso: Story = {
 beforeEach: async => {
 mocked(atualizarPerfil).mockResolvedValue({ ok: true, nome: 'Ada Lovelace' });
 },
};

export const Falha: Story = {
 beforeEach: async => {
 mocked(atualizarPerfil).mockRejectedValue(new Error('nome já em uso'));
 },
};
```

Mesmo contrato de [Storybook - Mocking](storybook-mocking.md) § 2.4: comportamento em `beforeEach`, via `mocked`.

---

## 7. Dependências server-only

O framework descreve três camadas:

1. **Mocks de framework** — automáticos para módulos `@tanstack/*`.
2. **Mock de aplicação** — `sb.mock` no preview, com `__mocks__` quando preciso.
3. **Identificação do módulo** — ler o stack trace do erro para achar qual dependência Node foi puxada.

```tsx
//.storybook/preview.tsx
import { sb } from 'storybook/test';
sb.mock(import('../src/db/client.ts'));
```

O detalhe completo está em [Storybook - Mocking](storybook-mocking.md) § 4, incluindo por que num app com BFF separado isso deveria ser raro — e por que a primeira suspeita é `import` de valor onde deveria ser `import type`.

---

## 8. Migração vinda de `@storybook/react-vite`

```bash
npx storybook automigrate react-vite-to-tanstack-react
```

Manualmente: trocar a dependência no `package.json`, trocar `framework` em `main.ts`, trocar o import de tipo em `preview.tsx`, e — o passo que se esquece — **remover os decorators de `RouterProvider` montados à mão**. O framework passa a embrulhar sozinho, e o decorator antigo cria um segundo router competindo com ele (`SB-TS-03`).

Sintoma de decorator sobrevivente: hooks de router lendo um estado que não corresponde ao `parameters.tanstack.router` da story — os `params` que você passou não chegam, porque o componente está lendo do router errado.

---

## 9. Limites declarados

| Limite | Consequência |
| --- | --- |
| **não suporta React Server Components** | extraia a parte cliente e faça story dela (`SB-TS-06`) |
| **router é em memória, sem runtime de servidor** | não há SSR nem loader rodando no servidor dentro da story |
| **módulo server-only precisa ser mockado** | senão quebra no browser — ver § 7 |

---

## 10. O que isso significa para `packages/ui`

Aqui a nota vira crítica de arquitetura, e de propósito.

O framework torna trivial dar rota a uma story. Isso é bom para `apps/web` e é uma **armadilha** para `packages/ui`: como passou a ser fácil, deixa de doer acoplar um componente de design system ao router.

**A story funciona como detector.** Se o componente de `packages/ui` só renderiza com `parameters.tanstack.router` configurado, ele conhece rota — e um design system que conhece rota não é reutilizável fora daquele app. O conserto é no componente, não na story: navegação entra por prop (`onSelecionar`, `href`, ou um `as`/`asChild` que o consumidor preenche com `Link`).

Isso é a mesma direção de dependência de `Monorepo com Bun - estrutura e tooling` § 2 vista de outro ângulo, e o mesmo critério de [React - Patterns](react-patterns.md) sobre o que pertence a um componente reutilizável (`SB-TS-08`).

---

## 11. Regras — `SB-TS-*`

| ID | Regra |
| --- | --- |
| `SB-TS-01` | Story que exercita uma rota **MUST** passar o `Route` real em `parameters.tanstack.router.route`. |
| `SB-TS-02` | `params` **MUST** casar com os segmentos declarados no path da rota. |
| `SB-TS-03` | Contexto do router **MUST** ser injetado por `context`/`useRouterContext`. `RouterProvider` manual em decorator **NEVER** sob `@storybook/tanstack-react`. |
| `SB-TS-04` | `QueryClient` compartilhado **MUST** ser limpo em `beforeEach` do preview. |
| `SB-TS-05` | `retry` **MUST** ser `false` no `QueryClient` do Storybook. |
| `SB-TS-06` | React Server Component **NEVER** renderiza no Storybook. Extraia a parte cliente. |
| `SB-TS-07` | `loader` ou `beforeLoad` que toca rede ou módulo server-only **MUST** ser sobrescrito por `routeOverrides`. |
| `SB-TS-08` | Componente de `packages/ui` que exige `parameters.tanstack.router` para renderizar **MUST** ser tratado como acoplamento a corrigir no componente. † |

---

## 12. Antipadrões

### 12.1 `RouterProvider` em decorator

Sobra de migração, ou hábito de `react-vite`. Cria dois routers, e o da story perde (`SB-TS-03`).

### 12.2 Deixar o `loader` real rodar

A story vira teste de integração com a API, falha em CI por rede e demora. É `routeOverrides` (`SB-TS-07`).

### 12.3 `QueryClient` novo por story, dentro de um decorator

Parece isolar, e desliga o que se queria testar: cache compartilhado entre componentes da mesma tela. O padrão da fonte é client único no preview, limpo em `beforeEach` (`SB-TS-04`).

### 12.4 Adotar o framework sem checar o Vite

Vite ≥ 7 é requisito. Descobrir isso no meio da configuração transforma "adicionar Storybook" numa migração de build.

### 12.5 Dar rota a componente de `packages/ui` para "fazer a story funcionar"

Trata o sintoma e fixa o acoplamento (`SB-TS-08`).

### 12.6 Esperar que server function funcione sem Start

Os stubs de `createServerFn` existem para app Start. Numa SPA com BFF, a chamada ao servidor é HTTP, e o mock é MSW — [Storybook - Mocking](storybook-mocking.md) § 3.

---

## Relacionados

- [Storybook](storybook.md) — hub, e a árvore de decisão de framework na § 5.1
- [Storybook - React Vite](storybook-react-vite.md) — o outro caminho
- [Storybook - Mocking](storybook-mocking.md) — `sb.mock`, MSW e módulos server-only
- [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) — requisitos de plataforma e a armadilha de augmentation
- [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md) — o contexto que a story injeta
- [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) — `loader` e `beforeLoad` no app real
- [TanStack Router - Search Params](tanstack-router-search-params.md) — `validateSearch`, sobrescrevível por `routeOverrides`
- [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) — `staleTime`, `retry` e invalidação
- `Backend no runtime Bun` — por que a metade Start fica inerte numa SPA com BFF
- `Monorepo com Bun - estrutura e tooling` — a direção de dependência que a § 10 invoca

## Fontes consultadas

Verificada diretamente em **2026-08-19**:

- [Storybook for TanStack React](https://storybook.js.org/docs/get-started/frameworks/tanstack-react)
- [Storybook for React & Vite](https://storybook.js.org/docs/get-started/frameworks/react-vite) — para a comparação de requisitos

**Notas de verificação:**

- **TanStack Start não é requisito.** A fonte declara suporte a SPA usando só `@tanstack/react-router`.
- **Requisitos: React ≥ 18, Vite ≥ 7**, e `@tanstack/react-router` no projeto — contra React ≥ 16.8 e Vite ≥ 5 do `react-vite`.
- **O redirecionamento de imports de `@tanstack/react-router` é automático e global**, não opt-in por story.
- **Tentativas de navegação viram spies do Storybook** — é possível asseverar navegação sem router real.
- **`routeOverrides` é chaveado por route ID**, e `'__root__'` alveja a rota raiz.
- **`routeOverrides` cobre `loader`, `beforeLoad`, `validateSearch`, `loaderDeps` e `context`.**
- **`params` é tipado contra o path da rota** quando o `route` é uma file route tipada.
- **`path` aceita fragmento de URL** (`'/#secao'`).
- **O `meta` do exemplo oficial é tipado contra o `Route`**, não contra um componente: o Storybook extrai o componente da rota.
- **`route` aceita tanto um `Route` quanto um objeto de opções**, caso em que uma rota temporária é criada para a story.
- **Não há suporte a React Server Components** — a orientação da fonte é extrair a parte cliente.
- **O router é em memória**, sem runtime de servidor.
- **Existe automigração dedicada:** `npx storybook automigrate react-vite-to-tanstack-react`, e a remoção dos decorators de `RouterProvider` é passo explícito da migração manual.
