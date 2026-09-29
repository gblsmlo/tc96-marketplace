---
titulo: TanStack Router - Route Context e Code Splitting
Link: https://tanstack.com/router/latest/docs/framework/react/guide/router-context
tags:
  - tanstack-router
  - context
  - code-splitting
  - agent-context
source: "Documentação oficial — https://tanstack.com/router/latest/docs/framework/react/"
verificado-em: 2026-08-14
---

# TanStack Router - Route Context e Code Splitting

> Contexto: `createRootRouteWithContext` · opção `context` do `createRouter` · `beforeLoad` retornando contexto · herança e merge pai→filho · `useRouteContext` · injeção de `queryClient` e de auth · `router.invalidate()` após mudança de contexto.
> Splitting: `.lazy.tsx` · `createLazyFileRoute` · `createLazyRoute` + `.lazy()` · `autoCodeSplitting` · `codeSplittingOptions` (`defaultBehavior`, `splitBehavior`) · configuração crítica vs. não-crítica · `getRouteApi`.
>
> Não cobre: `loader`, `loaderDeps`, preloading e integração com TanStack Query — [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md); convenções de nome de arquivo — [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md); rotas virtuais definidas em código — [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md).

Entrada: [TanStack Router](tanstack-router.md) · Conceitos de rota: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Conceito: contexto é injeção de dependência tipada por rota

A fonte diz literalmente que o router context serve para "dependency injection among many other things". Não é o React Context com outro nome — a diferença é onde ele vive e quem consegue lê-lo.

React Context é um mecanismo **de render**: só existe dentro da árvore de componentes, só é lido por hooks. Mas `beforeLoad` e `loader` **não são componentes** e rodam **antes** de qualquer render. O caveat da fonte é categórico:

> "You can't use hooks in a non-React function, so you can't use hooks in your `beforeLoad` or `loader` functions."

O route context resolve exatamente esse buraco: é um objeto que o router carrega pela árvore de rotas, disponível em `beforeLoad`, em `loader` e em componentes (via `useRouteContext`). É por onde `queryClient`, cliente de API e estado de auth entram no pipeline de carregamento.

E ele é **por rota**, com herança: o contexto que uma rota vê é o do pai, mesclado com o que o `beforeLoad` dela devolveu. Cada nível pode acrescentar; nenhum precisa repassar.

| ID | Regra |
| --- | --- |
| `TSR-CTX-01` | `beforeLoad` e `loader` **NEVER** chamam hooks do React. Valores que vêm de hooks entram pelo contexto do router. |

---

## 2. Definindo o contexto raiz

Duas peças precisam concordar: o tipo na raiz e o valor no `createRouter`.

```tsx
// src/routes/__root.tsx
import { createRootRouteWithContext, Outlet } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'

export interface MyRouterContext {
  queryClient: QueryClient
}

export const Route = createRootRouteWithContext<MyRouterContext>()({
  component: () => <Outlet />,
})
```

Note a **dupla chamada**: `createRootRouteWithContext<T>()(options)`. O primeiro par de parênteses fecha o genérico; o segundo recebe as opções. Escrever `createRootRouteWithContext<T>(options)` não compila.

```tsx
// src/router.tsx
const router = createRouter({
  routeTree,
  context: { queryClient },
})
```

O que entra em `MyRouterContext`, verificado literalmente:

> "MyRouterContext only needs to contain content that will be passed directly to createRouter below. All other context added in beforeLoad will be inferred."

Isso é o oposto do instinto: não se declara na interface tudo o que o app vai ter em contexto. Só o que é **injetado de fora**. Tudo que `beforeLoad` acrescenta é inferido pelo TypeScript ao longo da árvore.

Sobre a obrigatoriedade: propriedades obrigatórias na interface fazem o TypeScript acusar erro se `context` for omitido no `createRouter`; se todas forem opcionais, o parâmetro `context` vira opcional. Contexto ausente é `{}`.

| ID | Regra |
| --- | --- |
| `TSR-CTX-02` | Projeto que passa `context` ao `createRouter` **MUST** declarar a raiz com `createRootRouteWithContext<T>()`, **NEVER** com `createRootRoute()`. |
| `TSR-CTX-03` | A interface do contexto raiz **MUST** conter apenas o que é passado no `createRouter`; o que `beforeLoad` acrescenta **NEVER** é declarado ali (é inferido). |

---

## 3. `beforeLoad` estende o contexto

O retorno de `beforeLoad` é **mesclado** ao contexto do pai. Não substitui, não precisa de spread.

```tsx
// __root.tsx  →  context: { foo: true }

export const Route = createFileRoute('/posts')({
  beforeLoad: () => ({ bar: true }),
  loader: ({ context }) => {
    context.foo // true — herdado da raiz
    context.bar // true — desta rota
  },
})
```

E um exemplo com função:

```tsx
export const Route = createFileRoute('/posts')({
  beforeLoad: () => ({
    fetchPosts: () => console.info('foo'),
  }),
  loader: ({ context: { fetchPosts } }) => {
    fetchPosts() // 'foo'
  },
})
```

O merge é o que torna o contexto tipado útil: uma rota pathless `_authed` pode fazer `beforeLoad` devolver `{ user }`, e **toda** rota filha passa a ter `context.user` tipado, sem repetir nada. Ver [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) para rotas pathless.

Devolver `{ ...context, bar: true }` de dentro do `beforeLoad` não é só redundante — infla o objeto de contexto e confunde a inferência sobre o que aquela rota realmente contribui.

| ID | Regra |
| --- | --- |
| `TSR-CTX-04` | `beforeLoad` **MUST** retornar apenas o delta de contexto; **NEVER** espalhar o contexto do pai (`...context`) no retorno — o merge é feito pelo router. |

Lembrete de [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) § 7: `beforeLoad` roda também no preload especulativo (hover), então efeito colateral ali dispara sem navegação — `TSR-LOAD-12`.

---

## 4. Os dois padrões que justificam o mecanismo

### 4.1 `queryClient` — a dependência que não é um hook

```tsx
export interface MyRouterContext {
  queryClient: QueryClient
}

const router = createRouter({
  routeTree,
  context: { queryClient },
  defaultPreloadStaleTime: 0,
})
```

```tsx
export const Route = createFileRoute('/posts')({
  loader: ({ context }) => context.queryClient.ensureQueryData(postsQueryOptions),
})
```

Poderia-se importar o `queryClient` de um módulo global e pular o contexto. Funciona no browser e quebra em SSR: o `queryClient` precisa ser **por request**, e um singleton de módulo vaza cache entre usuários. O contexto é o canal que permite instanciar por request e injetar.

### 4.2 Auth — a dependência que **é** um hook

Aqui o contexto não é opcional, é a única saída. O estado de auth vem de um hook (`useAuth`), e `beforeLoad` não pode chamar hooks. A solução da fonte: ler o hook num componente e passar o resultado pelo `RouterProvider`.

```tsx
// __root.tsx
export const Route = createRootRouteWithContext<{ auth: AuthState }>()({
  component: () => <Outlet />,
})
```

```tsx
// main.tsx
const router = createRouter({
  routeTree,
  context: { auth: undefined! }, // preenchido no InnerApp
})

function InnerApp() {
  const auth = useAuth()
  return <RouterProvider router={router} context={{ auth }} />
}

function App() {
  return (
    <AuthProvider>
      <InnerApp />
    </AuthProvider>
  )
}
```

O `undefined!` no `createRouter` é um placeholder deliberado: o valor real só existe dentro do provider React. Se o `context={{ auth }}` do `RouterProvider` for esquecido, **não há erro de tipo** — o `!` já silenciou o TypeScript — e o guard quebra em runtime.

Com isso no lugar, a guarda vira o que já está em [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) § 4:

```tsx
export const Route = createFileRoute('/_authed')({
  beforeLoad: ({ context, location }) => {
    if (!context.auth.isAuthenticated) {
      throw redirect({ to: '/login', search: { redirect: location.href } })
    }
  },
})
```

E o limite, citado da fonte: guardas de rota protegem **UI**; endpoints precisam autorizar por conta própria, porque podem ser chamados fora da camada de roteamento.

| ID | Regra |
| --- | --- |
| `TSR-CTX-05` | Valor derivado de hook (auth, i18n, tema) **MUST** entrar pelo `context` do `<RouterProvider>`, **NEVER** ser lido de singleton de módulo dentro de `beforeLoad`. |
| `TSR-CTX-06` | Contexto declarado com placeholder (`undefined!`) no `createRouter` **MUST** ter `context` correspondente no `<RouterProvider>` — o `!` remove a checagem de tipo. |
| `TSR-CTX-07` | Guarda de rota baseada em contexto **NEVER** substitui autorização no backend. |

---

## 5. Invalidação quando o contexto muda

O contexto do router é lido em `beforeLoad`/`loader`, que rodam fora do ciclo de render. Trocar o valor no `RouterProvider` **não** reexecuta nada por si só.

> Call `router.invalidate()` when context state changes, triggering router recomputation across all routes.

```tsx
function InnerApp() {
  const auth = useAuth()

  useEffect(() => {
    router.invalidate()
  }, [auth.isAuthenticated])

  return <RouterProvider router={router} context={{ auth }} />
}
```

O caso clássico: logout. Sem `invalidate()`, as rotas já casadas continuam com o contexto antigo, os guards não reavaliam e a tela protegida permanece.

| ID | Regra |
| --- | --- |
| `TSR-CTX-08` | Mudança de valor no contexto do router (login, logout, troca de tenant) **MUST** ser seguida de `router.invalidate()`. |

### Contexto acumulado

Como cada match guarda o próprio contexto, dá para percorrer `router.state.matches` e coletar contribuições — o uso citado na fonte é breadcrumbs e títulos de página dinâmicos, filtrando matches que expõem algo como `getTitle()` no contexto.

---

## 6. Conceito: splitting só pode remover o que não é necessário antes de renderizar

O router precisa de certas informações **antes** de renderizar qualquer coisa: para casar a URL ele precisa parsear params e validar search; para começar a buscar dados ele precisa do `beforeLoad` e do `loader`. Nada disso pode chegar depois — chegaria tarde demais para a decisão que motivou o carregamento.

Daí a divisão da documentação em **crítico** e **não-crítico**. Não é uma preferência de organização; é uma consequência da ordem de execução descrita em [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) § 1.

| Crítico — fica no route file | Não-crítico — pode ser lazy |
| --- | --- |
| Path parsing / serialization | `component` |
| Search param validation (`validateSearch`) | `errorComponent` |
| `loader` | `pendingComponent` |
| `beforeLoad` | `notFoundComponent` |
| Route context | |
| Static data, links, scripts, styles | |
| "All other route configuration not listed as non-critical" | |

A lista de não-críticos é fechada: são quatro componentes. Tudo o mais é crítico por definição.

| ID | Regra |
| --- | --- |
| `TSR-SPLIT-01` | `loader`, `beforeLoad`, `validateSearch`, parsing de params e contexto **MUST** permanecer no route file crítico; **NEVER** em arquivo `.lazy.tsx`. |
| `TSR-SPLIT-02` | Arquivo `.lazy.tsx` **MUST** exportar apenas `component`, `errorComponent`, `pendingComponent` e `notFoundComponent`. |

---

## 7. `.lazy.tsx` e `createLazyFileRoute`

O route file guarda o crítico; o irmão `.lazy.tsx` guarda os componentes.

```tsx
// src/routes/posts.tsx  — crítico
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/posts')({
  loaderDeps: ({ search: { page } }) => ({ page }),
  loader: ({ deps: { page } }) => fetchPosts({ page }),
})
```

```tsx
// src/routes/posts.lazy.tsx  — não-crítico
import { createLazyFileRoute } from '@tanstack/react-router'

export const Route = createLazyFileRoute('/posts')({
  component: Posts,
})

function Posts() {
  const posts = Route.useLoaderData()
  return <PostList posts={posts} />
}
```

Os dois arquivos declaram **o mesmo path** (`'/posts'`) e ambos exportam `Route`. É assim que o router costura os pedaços. Divergência de path ou nome de export quebra a associação.

Se o route file crítico ficar vazio depois do split, a fonte manda **apagá-lo**: o router gera uma rota virtual automaticamente para ancorar o arquivo lazy. Manter um arquivo `createFileRoute('/posts')({})` vazio só adiciona ruído. Ver [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) e [TanStack Router - Route Trees](tanstack-router-route-trees.md) para como a árvore é montada.

Há também o padrão de encapsular em diretório: mover `posts.tsx` para `posts/route.tsx` e manter `posts/route.lazy.tsx`, `posts/-components/...` juntos — sem configuração adicional.

| ID | Regra |
| --- | --- |
| `TSR-SPLIT-03` | Arquivo `.lazy.tsx` **MUST** usar `createLazyFileRoute`, **NEVER** `createFileRoute`. |
| `TSR-SPLIT-04` | O path passado a `createLazyFileRoute` **MUST** ser idêntico ao do `createFileRoute` correspondente. |
| `TSR-SPLIT-05` | Route file crítico que ficou sem nenhuma opção **MUST** ser deletado — a rota virtual ancora o arquivo lazy. |

### Componentes em arquivos próprios: `getRouteApi`

Splitting espalha componentes por arquivos. Importar a `Route` de volta cria ciclo. A saída verificada é `getRouteApi`:

```tsx
// src/routes/-components/post-body.tsx
import { getRouteApi } from '@tanstack/react-router'

const route = getRouteApi('/posts/$postId')

export function PostBody() {
  const post = route.useLoaderData()
  const { postId } = route.useParams()
  return <article id={postId}>{post.body}</article>
}
```

Métodos disponíveis, verificados: `useLoaderData`, `useLoaderDeps`, `useMatch`, `useParams`, `useRouteContext`, `useSearch`. É a mesma regra `TSR-LOAD-07`.

---

## 8. Code-based routing: `createLazyRoute` + `.lazy()`

Quando as rotas são definidas em código, não há sufixo de arquivo para o plugin ler — o link é explícito.

```tsx
// posts.lazy.tsx
export const Route = createLazyRoute('/posts')({
  component: MyComponent,
})
```

```tsx
// app.tsx
const postsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/posts',
}).lazy(() => import('./posts.lazy').then((d) => d.Route))
```

`.lazy()` recebe uma função que devolve a `Route` lazy — o `.then((d) => d.Route)` não é opcional, o import default não serve.

---

## 9. Automatic code splitting

Disponível **apenas** com file-based routing e um bundler suportado.

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import { tanstackRouter } from '@tanstack/router-plugin/vite'

export default defineConfig({
  plugins: [
    tanstackRouter({
      autoCodeSplitting: true,
    }),
  ],
})
```

Com isso, o plugin separa crítico de não-crítico sozinho — sem `.lazy.tsx` escrito à mão.

### `codeSplittingOptions`

Aqui está a diferença que a verificação revelou: no modo automático, **as propriedades splittáveis são cinco, não quatro** — `component`, `errorComponent`, `pendingComponent`, `notFoundComponent` **e `loader`**. Splitting manual via `.lazy.tsx` nunca aceitou `loader`; o plugin aceita, sob demanda explícita.

```ts
tanstackRouter({
  autoCodeSplitting: true,
  codeSplittingOptions: {
    defaultBehavior: [
      ['component', 'pendingComponent', 'errorComponent', 'notFoundComponent'],
    ], // um único chunk com toda a UI
  },
})
```

```ts
codeSplittingOptions: {
  splitBehavior: ({ routeId }) => {
    if (routeId.startsWith('/posts')) {
      return `'loader', 'component'`
    }
    // demais rotas caem no defaultBehavior
  },
}
```

Cada array interno é um **grupo que vira um chunk**. `[['a','b'],['c']]` gera dois chunks. `splitBehavior` que não retorna nada delega ao `defaultBehavior`.

### Por que não separar o `loader`

O aviso é explícito nas duas páginas:

> "Moving the `loader` into its own chunk is a **performance trade-off**. It introduces an additional trip to the server before the data can be fetched, which can lead to slower initial page loads."

> "We highly discourage splitting the `loader` unless you have a specific use case that requires it."

E na página de code splitting manual:

> "Be warned!!! Splitting a route loader is a dangerous game."

O raciocínio é aritmético: um loader em chunk próprio precisa ser **baixado** antes de poder **buscar**. Duas viagens em série onde havia uma. Pior, é justamente o que o preload por `intent` (hover) tenta adiantar — o ativo mais valioso para pré-carregar vira o mais tardio. Loaders também raramente são o que pesa no bundle; componentes é que são.

Note que ``'loader', 'component'`` **não** é o mesmo que separar o loader: agrupa os dois no mesmo chunk. O antipadrão é o loader isolado, ou o loader importado via `lazyFn`.

| ID | Regra |
| --- | --- |
| `TSR-SPLIT-06` | `loader` **NEVER** vai para um chunk isolado — nem via `codeSplittingOptions`, nem via `lazyFn`. Agrupá-lo junto com `component` no mesmo chunk é permitido. |
| `TSR-SPLIT-07` | Em code-based routing, splitting **MUST** usar `createLazyRoute` + `.lazy()` — `autoCodeSplitting` só funciona com file-based routing. |

---

## Antipadrões

```tsx
// ERRADO — hook em beforeLoad. Não roda em contexto de render.
export const Route = createFileRoute('/_authed')({
  beforeLoad: () => {
    const { user } = useAuth()   // inválido
    if (!user) throw redirect({ to: '/login' })
  },
})

// CERTO — o hook roda no componente; o valor entra pelo contexto
function InnerApp() {
  const auth = useAuth()
  return <RouterProvider router={router} context={{ auth }} />
}
export const Route = createFileRoute('/_authed')({
  beforeLoad: ({ context }) => {
    if (!context.auth.user) throw redirect({ to: '/login' })
  },
})
```

```tsx
// ERRADO — spread do contexto do pai: redundante e ofusca a contribuição da rota
beforeLoad: ({ context }) => ({ ...context, permissions: getPermissions() })

// CERTO — só o delta; o router faz o merge
beforeLoad: () => ({ permissions: getPermissions() })
```

```tsx
// ERRADO — loader no arquivo lazy: o router precisa dele antes de renderizar
// posts.lazy.tsx
export const Route = createLazyFileRoute('/posts')({
  loader: () => fetchPosts(),   // não é export suportado em .lazy
  component: Posts,
})

// CERTO — crítico em posts.tsx, componente em posts.lazy.tsx
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| `createRootRoute()` com `context` no `createRouter` | contexto sem tipo; `context.x` vira `any` ou erro | `createRootRouteWithContext<T>()` (`TSR-CTX-02`) |
| Interface de contexto declarando o que vem de `beforeLoad` | duplica o que o TS já infere e obriga a passar valores falsos no `createRouter` | declarar só o injetado (`TSR-CTX-03`) |
| `undefined!` sem `context` no `RouterProvider` | o `!` remove a checagem: quebra em runtime, não em build | passar `context={{ auth }}` (`TSR-CTX-06`) |
| `queryClient` importado de módulo global | singleton vaza cache entre requests em SSR | injetar por contexto (`TSR-CTX-05`) |
| Troca de auth sem `router.invalidate()` | matches mantêm o contexto antigo; guards não reavaliam | `invalidate()` na mudança (`TSR-CTX-08`) |
| `validateSearch` em `.lazy.tsx` | search é validado durante o match, antes do chunk existir | manter no route file (`TSR-SPLIT-01`) |
| `createFileRoute` dentro de `.lazy.tsx` | duplica a definição crítica em vez de estendê-la | `createLazyFileRoute` (`TSR-SPLIT-03`) |
| Route file crítico vazio mantido | ruído; a rota virtual já ancora o lazy | deletar o arquivo (`TSR-SPLIT-05`) |
| `loader` em chunk próprio | fetch do chunk + fetch do dado, em série; anula o preload por intent | não isolar o loader (`TSR-SPLIT-06`) |

---

## Checklist de revisão

- [ ] Algum hook do React sendo chamado em `beforeLoad`/`loader`? → `TSR-CTX-01`
- [ ] Raiz usa `createRootRouteWithContext<T>()` quando há `context` no router? → `TSR-CTX-02`
- [ ] A interface do contexto raiz declara só o que é injetado no `createRouter`? → `TSR-CTX-03`
- [ ] `beforeLoad` retorna só o delta, sem espalhar o contexto do pai? → `TSR-CTX-04`
- [ ] Valores vindos de hook chegam pelo `context` do `RouterProvider`? → `TSR-CTX-05`
- [ ] Todo `undefined!` no contexto tem o `context` correspondente no `RouterProvider`? → `TSR-CTX-06`
- [ ] Existe autorização no backend além do guard de rota? → `TSR-CTX-07`
- [ ] Login/logout/troca de tenant chamam `router.invalidate()`? → `TSR-CTX-08`
- [ ] Nenhum `loader`/`beforeLoad`/`validateSearch` em arquivo `.lazy.tsx`? → `TSR-SPLIT-01`
- [ ] O `.lazy.tsx` exporta só os quatro componentes permitidos? → `TSR-SPLIT-02`
- [ ] O `.lazy.tsx` usa `createLazyFileRoute`? → `TSR-SPLIT-03`
- [ ] Os paths do arquivo crítico e do lazy são idênticos? → `TSR-SPLIT-04`
- [ ] Route file crítico ficou vazio e continua no repo? → `TSR-SPLIT-05`
- [ ] `codeSplittingOptions` isola o `loader` em chunk próprio? → `TSR-SPLIT-06`
- [ ] Code-based routing usa `createLazyRoute` + `.lazy()`? → `TSR-SPLIT-07`

---

## Relacionados

- [TanStack Router](tanstack-router.md) · [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md)
- [TanStack Router - Search Params](tanstack-router-search-params.md) — `validateSearch` fica na parte crítica, nunca no chunk lazy
- [TanStack Router - Navegação](tanstack-router-navegacao.md) — `redirect()` a partir de `beforeLoad`, onde o contexto é montado
- [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) · [TanStack Router - Route Trees](tanstack-router-route-trees.md) · [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) · [TanStack Router - Route Matching](tanstack-router-route-matching.md)
- · [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)
- [React.js](react-js.md) · [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md)

## Fontes consultadas

Verificadas em 2026-08-14:

- [Router Context](https://tanstack.com/router/latest/docs/framework/react/guide/router-context)
- [Code Splitting](https://tanstack.com/router/latest/docs/framework/react/guide/code-splitting)
- [Automatic Code Splitting](https://tanstack.com/router/latest/docs/framework/react/guide/automatic-code-splitting)
- [Authenticated Routes](https://tanstack.com/router/latest/docs/framework/react/guide/authenticated-routes)
- [External Data Loading](https://tanstack.com/router/latest/docs/framework/react/guide/external-data-loading)
- [RouteOptions (API)](https://tanstack.com/router/latest/docs/framework/react/api/router/RouteOptionsType)

### O que a verificação contrariou

- **O `loader` é splittável — mas só no modo automático.** A página de Code Splitting lista quatro exports permitidos em `.lazy.tsx` (`component`, `errorComponent`, `pendingComponent`, `notFoundComponent`) e classifica o `loader` como crítico. Já a página de Automatic Code Splitting lista **cinco** propriedades splittáveis, incluindo `loader`. As duas listas não coincidem: o que `.lazy.tsx` não aceita, o plugin aceita — e desaconselha explicitamente.
- **`codeSplittingOptions` é agrupamento, não flags.** `defaultBehavior`/`splitBehavior` recebem arrays de arrays; cada array interno é um chunk. ``'loader','component'`` **junta** os dois num chunk, o oposto de separar o loader.
- **O nome do plugin Vite é `tanstackRouter`, importado de `@tanstack/router-plugin/vite`** — não `TanStackRouterVite`, forma comum em material mais antigo.
- **`createRootRouteWithContext` é chamada dupla:** `createRootRouteWithContext<T>()({ ... })`.
- **O contexto tipado não deve descrever o app inteiro.** A fonte é explícita: só o que vai direto para o `createRouter`; o resto é inferido a partir dos `beforeLoad`.
- **Não verificado:** o comportamento de combinar `autoCodeSplitting: true` com arquivos `.lazy.tsx` escritos à mão no mesmo projeto não é abordado nas páginas consultadas.
