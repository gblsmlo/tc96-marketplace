---
titulo: TanStack Router - Carregamento de Dados
Link: https://tanstack.com/router/latest/docs/framework/react/guide/data-loading
tags:
 - tanstack-router
 - data-loading
 - agent-context
source: "Documentação oficial — https://tanstack.com/router/latest/docs/framework/react/"
verificado-em: 2026-08-14
---

# TanStack Router - Carregamento de Dados

> `loader` · `loaderDeps` · `useLoaderData` · `getRouteApi` · `beforeLoad` · `pendingComponent` / `pendingMs` / `pendingMinMs` · `errorComponent` · `notFoundComponent` · `defaultPreload` · `staleTime` / `gcTime` / `preloadStaleTime` / `preloadGcTime` · `shouldReload` · `staleReloadMode` · `router.invalidate` · integração com TanStack Query via `ensureQueryData`.
>
> Não cobre: definição e hierarquia de rotas — [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md); convenções de arquivo — [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md); ordem de precedência no match — [TanStack Router - Route Matching](tanstack-router-route-matching.md); contexto do router e code splitting — [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md).

Entrada: [TanStack Router](tanstack-router.md) · Conceitos de rota: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Conceito: o loader existe para matar o waterfall

O padrão que o React ensinou por uma década é: monta o componente, aí o efeito dispara o fetch, aí aparece o spinner. Isso encadeia rede **depois** de render. Componente pai carrega, renderiza, monta o filho, o filho carrega — cada nível adiciona uma viagem serial. É o waterfall de fetch-on-render.

O `loader` inverte a ordem. Ele é declarado **na rota**, não no componente. O router conhece a árvore de rotas casadas antes de renderizar qualquer coisa, então dispara todos os loaders da árvore **em paralelo** e só então renderiza. O componente já nasce com dado.

A documentação de external data loading lista os três ganhos textualmente:

> "No 'flash of loading' states"
>
> "No waterfall data fetching, caused by component based fetching"
>
> "Better for SEO. If your data is available at render time, it will be indexed"

Isso é a contraparte concreta de [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) § 3 — `REACT-EFFECT-06` proíbe `fetch` em `useEffect` em código novo. No TanStack Router, o substituto não é "outro hook": é mover a busca para fora do componente, para a rota. E se o dado é cache de servidor com política de frescor, o loader delega para a camada que já faz isso — ver § 8 e.

| ID | Regra |
| --- | --- |
| `TSR-LOAD-01` | Dado necessário para a primeira renderização de uma rota **MUST** vir do `loader` (ou de `beforeLoad`), e **NEVER** de `fetch` em `useEffect` no componente da rota. Apelido de `REACT-EFFECT-06`. |

### O ciclo, na ordem

A fonte descreve a sequência em três blocos:

1. **Route Matching (top-down)** — `route.params.parse`, `route.validateSearch`.
2. **Route Pre-Loading (serial)** — `route.beforeLoad`, com tratamento de erro.
3. **Route Loading (parallel)** — preload do componente, `route.loader`, componentes de pending e de erro.

O que importa dessa ordem: **`beforeLoad` é serial e top-down; `loader` é paralelo**. Colocar uma busca de dados de tela em `beforeLoad` transforma paralelo em fila — é reintroduzir o waterfall dentro da própria solução que existe para eliminá-lo.

---

## 2. `loader`

O loader recebe **um único objeto**. Campos verificados na fonte:

| Campo | O que é |
| --- | --- |
| `params` | path params da rota |
| `deps` | o retorno de `loaderDeps` |
| `context` | união do contexto do pai com o que este `beforeLoad` devolveu |
| `abortController` | "its signal is cancelled after the invocation becomes outdated" |
| `cause` | `'enter'` \| `'preload'` \| `'stay'` |
| `preload` | `true` quando a rota está sendo pré-carregada |
| `location` | location atual |
| `parentMatchPromise` | promise do `RouteMatch` pai |
| `route` | a definição da rota |

```tsx
// src/routes/posts.$postId.tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/posts/$postId')({
 loader: ({ params: { postId }, abortController }) =>
 fetchPostById(postId, { signal: abortController.signal }),
 component: PostPage,
})

function PostPage {
 const post = Route.useLoaderData
 return <article>{post.body}</article>
}
```

O `abortController` é o que torna a race condition estruturalmente impossível: quando a invocação fica obsoleta (o usuário navegou de novo), o sinal é cancelado. É a mesma correção de `REACT-EFFECT-06`, só que o router faz o bookkeeping.

| ID | Regra |
| --- | --- |
| `TSR-LOAD-02` | Requisição de rede feita **diretamente** dentro de um `loader` **MUST** repassar `abortController.signal`. |

**Escopo da regra, para não conflitar com a integração com Query.** `TSR-LOAD-02` vale quando o `loader` chama `fetch` ou um cliente HTTP por conta própria. Quando ele **delega** para TanStack Query — `context.queryClient.ensureQueryData(...)` — o cancelamento é da Query: a `queryFn` recebe o próprio `signal` no `QueryFunctionContext`, e é lá que ele deve ser repassado. Não há encadeamento documentado entre o `abortController` do router e o da Query, e não é preciso inventar um: cada camada cancela o que ela iniciou. Ver § 8.

Na prática: `loader: ({ context }) => context.queryClient.ensureQueryData(opts)` satisfaz `TSR-LOAD-02` por vacuidade — não há requisição direta ali. A obrigação migra para a `queryFn`, sob `TSQ-SSR-10`.

### A forma de objeto

O `loader` aceita duas formas — a função direta e um objeto com `handler`:

```tsx
loader: => fetchPosts

loader: {
 handler: => fetchPosts,
 staleReloadMode: 'background', // ou 'blocking'
}
```

`staleReloadMode` só entra em jogo quando **já existe dado stale bem-sucedido** no match. Citando:

> "Controls what happens when a matched route already has stale successful data. Use `'background'` for stale-while-revalidate, or `'blocking'` to wait for the stale loader reload to finish before continuing."

> "By default, stale successful matches use stale-while-revalidate behavior. That means the router can render with the existing `loaderData` immediately and then refresh it in the background."

---

## 3. `loaderDeps` — a chave de cache que você escreve à mão

O router faz cache SWR keyed pelo pathname totalmente parseado (`/posts/1` ≠ `/posts/2`). **Search params não entram nessa chave automaticamente.** Se o loader lê um search param, você tem que declará-lo em `loaderDeps`.

```tsx
export const Route = createFileRoute('/posts')({
 loaderDeps: ({ search: { offset, limit } }) => ({ offset, limit }),
 loader: ({ deps: { offset, limit } }) => fetchPosts({ offset, limit }),
})
```

> "When these deps change from navigation to navigation, it will cause the route to reload regardless of `staleTime`s."

E o erro que a fonte marca explicitamente:

> "A common mistake is returning the entire `search` object... This causes the route to reload whenever ANY search param changes, even params not used in the loader."

```tsx
// ERRADO — qualquer search param (inclusive `?tab=comments`) refaz o fetch da lista
loaderDeps: ({ search }) => search

// CERTO — só o que o loader realmente consome
loaderDeps: ({ search: { offset, limit } }) => ({ offset, limit })
```

`loaderDeps` precisa ser **determinística e serializável** — é uma chave de cache. Um `Date.now`, um objeto novo a cada chamada ou uma função ali dentro quebram o cache silenciosamente (a chave nunca bate) e o loader roda em toda navegação.

| ID | Regra |
| --- | --- |
| `TSR-LOAD-03` | `loaderDeps` **MUST** retornar apenas os search params efetivamente lidos pelo loader; **NEVER** retornar o objeto `search` inteiro. |
| `TSR-LOAD-04` | Search param consumido pelo loader **MUST** estar declarado em `loaderDeps`; o loader **NEVER** lê o search da `location` diretamente. |

---

## 4. `beforeLoad`

Assinatura verificada:

```
beforeLoad: (opts) => Promise<TRouteContext> | TRouteContext | void
```

Três usos legítimos, e só três: **produzir contexto**, **guardar acesso** e **redirecionar**.

```tsx
export const Route = createFileRoute('/_authed')({
 beforeLoad: ({ context, location }) => {
 if (!context.auth.isAuthenticated) {
 throw redirect({ to: '/login', search: { redirect: location.href } })
 }
 },
})
```

Guardar em `beforeLoad` e não no componente importa porque `beforeLoad` roda **antes** dos loaders dos filhos: o redirect acontece sem que nenhum loader protegido dispare. Um guard em `useEffect` roda depois de tudo já ter sido buscado e renderizado.

O aviso da fonte que precisa sobreviver a qualquer revisão:

> Route guards protect UI only. Backend endpoints must independently authorize requests, since they can be called outside the routing layer.

| ID | Regra |
| --- | --- |
| `TSR-LOAD-05` | `beforeLoad` **MUST** conter apenas contexto, guarda e redirect; a busca dos dados de tela **NEVER** fica ali (é serial e bloqueia os loaders paralelos). |
| `TSR-LOAD-06` | Guarda de acesso **MUST** ser `throw redirect(...)` em `beforeLoad`, **NEVER** um `navigate` dentro de componente ou efeito. |

Para o lado tipado disso — de onde vem `context.auth` — ver [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md) § 1.

---

## 5. Consumir o dado: `useLoaderData` e `getRouteApi`

```tsx
// Dentro do arquivo da rota
const post = Route.useLoaderData

// Em arquivo separado, sem importar a Route (evita ciclo de import)
import { getRouteApi } from '@tanstack/react-router'
const route = getRouteApi('/posts/$postId')

function PostBody {
 const post = route.useLoaderData
}
```

Opções do hook, verificadas: `from` (route id do match pai mais próximo — recomendado para type-safety), `strict` (default `true`; `false` afrouxa o tipo quando `from` é omitido), `select` (`(loaderData) => TSelected`, re-renderiza por igualdade rasa) e `structuralSharing`.

`getRouteApi(id)` expõe `useLoaderData`, `useLoaderDeps`, `useMatch`, `useParams`, `useRouteContext` e `useSearch`. É o mecanismo que permite manter tipos em componentes fora do route file — o que casa diretamente com code splitting (ver o satélite de contexto/splitting).

| ID | Regra |
| --- | --- |
| `TSR-LOAD-07` | Componente em arquivo separado do route file **MUST** acessar dados via `getRouteApi('<id>')`; **NEVER** importar a `Route` de volta (ciclo de import). |

**E se esse componente precisa navegar?** `getRouteApi` expõe leitura (`useLoaderData`, `useLoaderDeps`, `useMatch`, `useParams`, `useRouteContext`, `useSearch`) mas **não** `fullPath` — o que aparentemente colide com `TSR-NAV-04`, que exige `from` vindo de `Route.fullPath` em vez de string literal repetida. A colisão é aparente: o que `TSR-NAV-04` proíbe é **repetir** o literal em cada JSX, não usar o id da rota. Declare-o uma vez e reúse:

```tsx
// -components/FiltroAvaliacoes.tsx
const ROTA = '/produtos/$produtoId' as const
const api = getRouteApi(ROTA)

export function FiltroAvaliacoes {
 const filtro = api.useSearch
 const navigate = useNavigate({ from: ROTA }) // uma única fonte do literal
 //...
}
```

Uma constante por arquivo satisfaz as duas regras. A alternativa — manter no route file o componente que escreve no search — também é válida e costuma ser mais simples quando ele é pequeno.

---

## 6. Pending, erro e not found

### `pendingComponent`, `pendingMs`, `pendingMinMs`

Defaults verificados na tabela de `RouteOptions`:

| Opção | Default |
| --- | --- |
| `pendingMs` | `routerOptions.defaultPendingMs` — `1000` |
| `pendingMinMs` | `routerOptions.defaultPendingMinMs` — `500` |

Ou seja: **o pending component só aparece se o loader passar de 1 segundo**, e uma vez que apareceu fica no mínimo 500ms.

> "The minimum amount of time in milliseconds that the pending component will be shown for if it is shown"

Os dois números são um par. `pendingMs` evita mostrar spinner para uma resposta de 80ms; `pendingMinMs` evita o flash de um spinner que apareceu e sumiu em 30ms. Baixar `pendingMs` para perto de zero sem manter `pendingMinMs` produz exatamente o piscar que o default existe para prevenir.

```tsx
export const Route = createFileRoute('/posts')({
 loader: => fetchPosts,
 pendingComponent: => <PostsSkeleton />,
 pendingMs: 300,
 pendingMinMs: 500,
})
```

| ID | Regra |
| --- | --- |
| `TSR-LOAD-08` | Ao reduzir `pendingMs` abaixo do default, `pendingMinMs` **MUST** permanecer maior que `0`. |

Relação com Suspense: `wrapInSuspense` existe como opção de rota. O modelo mental de fronteira assíncrona é o de [React - Suspense e Assincronia](react-suspense-e-assincronia.md) — o router só decide **onde** a fronteira cai.

### `errorComponent` e `onError`

```tsx
export const Route = createFileRoute('/posts')({
 loader: => fetchPosts,
 onError: ({ error }) => reportError(error),
 errorComponent: ({ error, reset }) => (
 <div role="alert">
 <p>{error.message}</p>
 <button onClick={reset}>Tentar de novo</button>
 </div>
 ),
})
```

Defaults de router correspondentes: `defaultErrorComponent`, `defaultOnCatch`. Há também `onCatch: (error: Error, errorInfo: ErrorInfo) => void`.

Caveat da fonte sobre recuperação: para **erros de loader**, `reset` sozinho não basta — é `router.invalidate` que coordena o reload do loader com o reset do error boundary.

| ID | Regra |
| --- | --- |
| `TSR-LOAD-09` | Rota com `loader` **MUST** ter `errorComponent` própria ou `defaultErrorComponent` configurado no router. |
| `TSR-LOAD-10` | Recuperação de erro de loader **MUST** chamar `router.invalidate`, não apenas o `reset` do `errorComponent`. |

### `notFoundComponent` e `notFound`

```tsx
import { createFileRoute, notFound } from '@tanstack/react-router'

export const Route = createFileRoute('/posts/$postId')({
 loader: async ({ params }) => {
 const post = await fetchPostById(params.postId)
 if (!post) throw notFound
 return post
 },
})
```

`notFound` aceita `routeId` para escolher a boundary (`throw notFound({ routeId: '/_pathlessLayout' })`) e `data`, que chega ao `notFoundComponent`. O `notFoundComponent` tem acesso a `useParams`, `useSearch` e `useRouteContext`; disponibilidade de loader data depende de qual rota lançou.

O caveat estrutural, literal:

> "Leaf-node routes (routes without children) will never render an `Outlet` and therefore are not able to handle not-found errors."

E:

> "`notFound` function and `notFoundComponent` will not work when using `NotFoundRoute`."

O router tem `notFoundMode`: `'fuzzy'` (default — acha a rota casada mais próxima que tenha `notFoundComponent`) ou `'root'` (tudo cai na raiz).

| ID | Regra |
| --- | --- |
| `TSR-LOAD-11` | `notFoundComponent` **NEVER** é declarado em rota folha — ela não renderiza `Outlet` e nunca exibirá o componente. |

---

## 7. Frescor e retenção: `staleTime`, `gcTime`, preload

Defaults verificados:

| Opção | Default | Significado |
| --- | --- | --- |
| `staleTime` | `0` | por quanto tempo o dado de navegação é considerado fresco |
| `preloadStaleTime` | `30_000` | frescor de dado **pré-carregado** |
| `gcTime` | 5 min | retenção antes de virar elegível a poda |
| `preloadGcTime` | 5 min | retenção do dado pré-carregado |

> "By default, `staleTime` for accepted navigation data is `0`ms, while `preloadStaleTime` is 30 seconds."

`staleTime: 0` significa que **toda navegação revalida** — mas, por causa do SWR, revalidar não é esperar: o match stale renderiza com o `loaderData` existente e atualiza em background. Essa distinção entre *frescor* (quando revalidar) e *retenção* (quando descartar) é a mesma de; os nomes colidem — `staleTime` e `gcTime` existem nos dois, com donos e defaults diferentes.

### Preloading

`defaultPreload` no `createRouter` aceita quatro valores verificados:

| Valor | Gatilho |
| --- | --- |
| `'intent'` | hover e touch sobre o `<Link>` |
| `'viewport'` | Intersection Observer — o link fica visível |
| `'render'` | assim que o `<Link>` monta no DOM |
| `false` | desligado |

```tsx
const router = createRouter({
 routeTree,
 defaultPreload: 'intent',
 defaultPreloadDelay: 50,
})
```

> "By default, intent focus/hover and viewport preloading start after 50ms."
>
> "Touch intent preloads immediately."

`<Link preload="...">` e `preloadDelay` sobrescrevem por link.

Detalhe que muda como se raciocina sobre isso — a *lane* especulativa:

> "Client-side preloading runs each route's `beforeLoad` with `preload: true`."
>
> "The speculative lane is never promoted into router state."
>
> "`preloadStaleTime` controls whether the retained loader result can be reused without another loader call."

**Preload executa `beforeLoad` e o `loader`.** É por isso que existe `preloadStaleTime`: há um *resultado de loader* retido para reaproveitar. O que a lane especulativa **não** faz é entrar no estado do router — a navegação depois roda sua própria cadeia de `beforeLoad` e reaproveita (ou se junta a) o trabalho de loader já em voo.

> **A exceção, que é fácil ler como regra geral:** *"If a route has `preload: false`, its speculative lane still runs `beforeLoad`, but skips that route's loader."* Isso vale **quando a rota declara `preload: false`** — não é o comportamento padrão. Uma leitura apressada dessa frase inverte o modelo inteiro.

Duas consequências práticas, e as duas importam:

1. **Efeito colateral em `beforeLoad` dispara em hover** — analytics, log, escrita em store. Trate `beforeLoad` como puro (`TSR-LOAD-12`).
2. **Cada link com preload ativo é uma requisição real potencial**, porque o loader roda. Com `defaultPreload: 'render'` numa lista longa, é uma execução de loader por item montado (`TSR-NAV-07`).

### `shouldReload` + `gcTime` — o comportamento estilo Remix

> "Similar to Remix's default functionality, you may want to configure a route to only load on entry or when critical loader deps change. You can do this by using the `gcTime` option combined with the `shouldReload` option."

`shouldReload` é `boolean | ((args) => boolean)`. `shouldReload: false` + `gcTime: Infinity` dá "carrega ao entrar e quando as deps mudam, nunca mais".

### Invalidação

> "`router.invalidate` selects matching committed, cached, and in-flight loader generations for invalidation and retires matching active preload lanes."

| ID | Regra |
| --- | --- |
| `TSR-LOAD-12` | `beforeLoad` **NEVER** tem efeito colateral observável (analytics, escrita em store) — ele roda em preload por hover. |
| `TSR-LOAD-13` | Mutação que invalida dado servido pelo loader nativo **MUST** chamar `router.invalidate`. |

---

## 8. External data loading: quando delegar para TanStack Query

A fonte posiciona o router como **coordenador**, não como camada de cache definitiva: "any data fetching library that supports asynchronous promises can be used with TanStack Router" — TanStack Query, SWR, RTK Query, Apollo, Zustand, Redux.

### O critério

| Situação | Use |
| --- | --- |
| Dado pertence a uma rota, consumido só ali, sem revalidação sofisticada | `loader` nativo |
| Mesmo dado consumido por várias rotas ou por componentes fora da rota | TanStack Query |
| Precisa de mutação + invalidação seletiva, retry, refetch em foco/reconexão, paginação, optimistic update | TanStack Query |
| Precisa de dehydrate/hydrate no SSR | qualquer um — o router expõe callbacks `dehydrate` / `hydrate` |

Não é "ou um ou outro". O padrão oficial usa **os dois**: o router chama o cache do Query no loader para eliminar o waterfall, e o componente lê do cache do Query para ter reatividade.

### O padrão `ensureQueryData`

```tsx
import { queryOptions, useSuspenseQuery } from '@tanstack/react-query'
import { createFileRoute } from '@tanstack/react-router'

const postsQueryOptions = queryOptions({
 queryKey: ['posts'],
 queryFn: => fetchPosts,
})

export const Route = createFileRoute('/posts')({
 loader: ({ context }) => context.queryClient.ensureQueryData(postsQueryOptions),
 component: Posts,
})

function Posts {
 const { data: posts } = useSuspenseQuery(postsQueryOptions)
 return <PostList posts={posts} />
}
```

Duas coisas fazem isso funcionar, e ambas são fáceis de quebrar:

1. **O mesmo objeto `queryOptions` nos dois lados.** Se o loader usa `['posts']` e o componente usa `['posts', {}]`, são duas entradas de cache: o loader aquece uma e o componente busca a outra. O waterfall volta, silenciosamente, e ninguém vê erro.
2. **`ensureQueryData` (não `fetchQuery`)** — ele respeita o cache: se já há dado fresco, resolve na hora. `fetchQuery` busca sempre.

O `queryClient` chega ao loader por injeção no contexto do router — o mecanismo está em [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md) § 2.

### O ajuste de preload que quase todo mundo esquece

Quando o cache é externo, **quem decide frescor é o Query, não o router**. A fonte de preloading:

> When using external caching systems, set `defaultPreloadStaleTime` to `0` to let the external cache determine freshness while the Router handles retention.

```tsx
const router = createRouter({
 routeTree,
 context: { queryClient },
 defaultPreload: 'intent',
 defaultPreloadStaleTime: 0, // obrigatório com TanStack Query
})
```

Sem isso, o router considera o resultado do preload fresco por 30 segundos e **não chama o loader** — logo não chama `ensureQueryData` — e o `staleTime` configurado no Query nunca é consultado. O sintoma é dado velho aparecendo depois de uma mutação, com o Query "certo" e o router segurando.

Para erros com Suspense, a fonte aponta `useQueryErrorResetBoundary` para resetar as queries antes de re-renderizar.

| ID | Regra |
| --- | --- |
| `TSR-LOAD-14` | Com TanStack Query no loader, o router **MUST** ser criado com `defaultPreloadStaleTime: 0`. Canônico para este princípio; `TSR-NAV-08` é apelido. |
| `TSR-LOAD-15` | Loader e componente **MUST** compartilhar o mesmo objeto `queryOptions` (mesma `queryKey` e mesma `queryFn`), **NEVER** duas construções paralelas. |
| `TSR-LOAD-16` | No loader, aquecimento de cache do Query **MUST** usar `ensureQueryData` (ou `prefetchQuery` quando o bloqueio não é desejado), **NEVER** `fetchQuery`. |

---

## Antipadrões

```tsx
// ERRADO — o waterfall que o loader existe para eliminar
export const Route = createFileRoute('/posts/$postId')({
 component: Post,
})
function Post {
 const { postId } = Route.useParams
 const [post, setPost] = useState(null)
 useEffect( => { fetchPostById(postId).then(setPost) }, [postId])
 if (!post) return <Spinner />
 return <article>{post.body}</article>
}

// CERTO
export const Route = createFileRoute('/posts/$postId')({
 loader: ({ params, abortController }) =>
 fetchPostById(params.postId, { signal: abortController.signal }),
 component: Post,
})
function Post {
 const post = Route.useLoaderData
 return <article>{post.body}</article>
}
```

```tsx
// ERRADO — beforeLoad serial buscando dado de tela: refaz o waterfall
beforeLoad: async ({ params }) => ({ post: await fetchPostById(params.postId) })

// CERTO — beforeLoad dá contexto; loader busca, em paralelo com os irmãos
beforeLoad: ({ context }) => ({ api: context.api.forPost }),
loader: ({ context, params }) => context.api.getPost(params.postId),
```

```tsx
// ERRADO — chaves diferentes: o loader aquece um cache que o componente não lê
loader: ({ context }) => context.queryClient.ensureQueryData({
 queryKey: ['posts'], queryFn: fetchPosts,
}),
component: => { useSuspenseQuery({ queryKey: ['posts', {}], queryFn: fetchPosts }) }

// CERTO — um único queryOptions compartilhado
const postsQueryOptions = queryOptions({ queryKey: ['posts'], queryFn: fetchPosts })
loader: ({ context }) => context.queryClient.ensureQueryData(postsQueryOptions),
component: => { useSuspenseQuery(postsQueryOptions) }
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| `loaderDeps: ({ search }) => search` | qualquer search param, mesmo irrelevante, refaz o fetch | listar só os campos lidos (`TSR-LOAD-03`) |
| Loader lendo search sem `loaderDeps` | a chave de cache não inclui o param: dado errado servido do cache | declarar em `loaderDeps` (`TSR-LOAD-04`) |
| `loaderDeps` retornando algo não determinístico | a chave nunca bate; o loader roda em toda navegação | retornar só primitivos derivados do search |
| `notFoundComponent` em rota folha | rota sem filhos não renderiza `Outlet` | subir a boundary para a rota pai (`TSR-LOAD-11`) |
| Analytics em `beforeLoad` | `defaultPreload: 'intent'` dispara em hover | mover para event handler ou para o `loader` filtrando `cause` (`TSR-LOAD-12`) |
| TanStack Query no loader sem `defaultPreloadStaleTime: 0` | router segura preload por 30s e nunca reconsulta o Query | ajustar no `createRouter` (`TSR-LOAD-14`) |
| `pendingMs: 0` | spinner pisca em toda navegação rápida | manter os defaults ou preservar `pendingMinMs` (`TSR-LOAD-08`) |

---

## Checklist de revisão

- [ ] Existe `fetch`/`useEffect` buscando dado de rota dentro do componente? → `TSR-LOAD-01`
- [ ] Requisições do loader recebem `abortController.signal`? → `TSR-LOAD-02`
- [ ] `loaderDeps` lista só os search params usados, e não o `search` inteiro? → `TSR-LOAD-03`
- [ ] Todo search param lido pelo loader está em `loaderDeps`? → `TSR-LOAD-04`
- [ ] `beforeLoad` está buscando dado de tela em vez de só contexto/guarda? → `TSR-LOAD-05`
- [ ] Guarda de auth é `throw redirect` e não `navigate` em efeito? → `TSR-LOAD-06`
- [ ] Componentes fora do route file usam `getRouteApi`? → `TSR-LOAD-07`
- [ ] `pendingMs` customizado mantém `pendingMinMs > 0`? → `TSR-LOAD-08`
- [ ] Rota com loader tem `errorComponent` (própria ou default)? → `TSR-LOAD-09`
- [ ] Retry de erro de loader chama `router.invalidate`? → `TSR-LOAD-10`
- [ ] `notFoundComponent` está em rota com filhos? → `TSR-LOAD-11`
- [ ] `beforeLoad` está livre de efeito colateral (roda em hover)? → `TSR-LOAD-12`
- [ ] Mutações invalidam o loader nativo? → `TSR-LOAD-13`
- [ ] Com TanStack Query: `defaultPreloadStaleTime: 0` no router? → `TSR-LOAD-14`
- [ ] Loader e componente usam o mesmo `queryOptions`? → `TSR-LOAD-15`
- [ ] Aquecimento no loader usa `ensureQueryData`, não `fetchQuery`? → `TSR-LOAD-16`

---

## Relacionados

- [TanStack Router](tanstack-router.md) · [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md)
- [TanStack Router - Search Params](tanstack-router-search-params.md) — `loaderDeps` lê search params; a validação deles acontece antes do loader
- [TanStack Router - Navegação](tanstack-router-navegacao.md) — `redirect` em `beforeLoad`, e o custo de preload disparado por `<Link>`
- [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) · [TanStack Router - Route Trees](tanstack-router-route-trees.md) · [TanStack Router - Route Matching](tanstack-router-route-matching.md)
- [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) · [React - Suspense e Assincronia](react-suspense-e-assincronia.md) · [React.js](react-js.md)
- · · [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)

## Fontes consultadas

Verificadas em 2026-08-14:

- [Data Loading](https://tanstack.com/router/latest/docs/framework/react/guide/data-loading)
- [External Data Loading](https://tanstack.com/router/latest/docs/framework/react/guide/external-data-loading)
- [Preloading](https://tanstack.com/router/latest/docs/framework/react/guide/preloading)
- [Not Found Errors](https://tanstack.com/router/latest/docs/framework/react/guide/not-found-errors)
- [Authenticated Routes](https://tanstack.com/router/latest/docs/framework/react/guide/authenticated-routes)
- [RouteOptions (API)](https://tanstack.com/router/latest/docs/framework/react/api/router/RouteOptionsType)
- [useLoaderData (API)](https://tanstack.com/router/latest/docs/framework/react/api/router/useLoaderDataHook)

### O que a verificação contrariou

- **`loader` aceita forma de objeto.** Além de `loader: =>...`, existe `loader: { handler, staleReloadMode }`. A opção `staleReloadMode` (`'background'` default, `'blocking'`) não aparece na maioria dos exemplos de terceiros.
- **`staleTime` default é `0`, mas `preloadStaleTime` é `30_000`.** É comum supor um único número; são dois, com defaults diferentes, e é o segundo que quebra a integração com TanStack Query quando não é zerado.
- **Preload roda `beforeLoad` E o `loader`** — e `beforeLoad` roda em hover, o que torna efeito colateral ali um bug silencioso. A frase da fonte *"its speculative lane still runs `beforeLoad`, but skips that route's loader"* é **condicionada a `preload: false` na rota**; lida fora de contexto, inverte o modelo. O que a lane especulativa nunca faz é ser promovida ao estado do router.
- **`pendingComponent` não aparece por padrão em carregamentos rápidos.** `defaultPendingMs` é `1000` — quem espera ver o skeleton em toda navegação vai achar que a opção não funciona.
- **Não verificado:** não foi possível abrir `guide/route-matching` (a rota retornou `isNotFound`); a ordem de lifecycle citada aqui vem da própria página de Data Loading.
