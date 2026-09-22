---
Link: https://tanstack.com/router/latest/docs/framework/react/routing/routing-concepts
tags:
 - tanstack-router
 - routing
 - agent-context
source: "Documentação oficial — https://tanstack.com/router/latest/docs/framework/react/"
verificado-em: 2026-08-14
---

# TanStack Router - Routing Concepts

> Os **tipos de rota** e o que cada um significa: root route, basic, index, dynamic segment, optional param, prefixo/sufixo de segmento, splat, layout route, pathless layout, non-nested, arquivos excluídos e route groups. É a base normativa das outras quatro notas de roteamento.
>
> **Não cobre:** a topologia da árvore e o modo code-based ([TanStack Router - Route Trees](tanstack-router-route-trees.md)) · a tabela mecânica de tokens de arquivo e a configuração do plugin ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · qual rota ganha quando duas casam ([TanStack Router - Route Matching](tanstack-router-route-matching.md)) · definir rotas por código em vez de por arquivo ([TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)) · `Link`/`navigate` ([TanStack Router - Navegação](tanstack-router-navegacao.md)) · `validateSearch` ([TanStack Router - Search Params](tanstack-router-search-params.md)) · `loader` ([TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md)) · `context` e code splitting ([TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md)).

Entrada: [TanStack Router](tanstack-router.md) · Base normativa: esta nota (`TSR-ROUTE-*`)

---

## 1. Conceito: a rota é um nó, não uma tela

O erro de modelo mental mais caro no TanStack Router é pensar "rota = página". Uma rota é um **nó de uma árvore** que, quando a URL casa com ele, contribui três coisas ao mesmo tempo:

1. um pedaço do path da URL (ou nenhum);
2. um nível na árvore de componentes renderizada;
3. um ponto onde `loader`, `beforeLoad`, `validateSearch` e `context` rodam antes dos filhos.

Os "tipos de rota" desta nota são combinações de duas perguntas independentes:

| | contribui segmento à URL | não contribui |
| --- | --- | --- |
| **renderiza um nível de componente** | basic, dynamic, splat, layout route | pathless layout (`_prefixo`) |
| **não renderiza nada por si** | route group `(nome)` | arquivo excluído `-nome` |

Separar as duas perguntas resolve quase toda confusão entre `_` prefixo, `_` sufixo e `(parênteses)` — são respostas a perguntas diferentes, não variações do mesmo recurso.

Um detalhe que a documentação afirma e que muda como se lê o código:

> "Paths are automatically written and managed by the router for you via the TanStack Router Bundler Plugin or Router CLI."

O literal em `createFileRoute('/posts/$postId')` **não é onde você declara a rota**. Ele é o resultado de a rota já ter sido declarada pelo nome do arquivo, escrito de volta no arquivo pelo gerador para dar type safety. Editá-lo à mão é editar um artefato gerado.

| ID | Regra |
| --- | --- |
| `TSR-ROUTE-01` | O literal de path passado a `createFileRoute` **NEVER** é escrito ou corrigido à mão — ele é gerado a partir do nome do arquivo. Para mudar o path, renomeie o arquivo. |

---

## 2. Root route

A raiz da árvore. Três propriedades, citadas da fonte:

> "It has no path" · "It is **always** matched" · "Its `component` is **always** rendered"

Em file-based ela mora em um arquivo com nome fixo:

> "The root route file must be named `__root.tsx` and must be placed in the root of the configured `routesDirectory`."

```tsx
// src/routes/__root.tsx
import { Outlet, createRootRoute } from '@tanstack/react-router'

export const Route = createRootRoute({
 component: => (
 <>
 <nav>…</nav>
 <Outlet />
 </>
 ),
})
```

Quando o router precisa de contexto tipado (um `QueryClient`, o estado de auth), a raiz muda de fábrica:

```tsx
import { createRootRouteWithContext } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'

interface RouterContext {
 queryClient: QueryClient
}

export const Route = createRootRouteWithContext<RouterContext>({
 component: RootComponent,
})
```

Repare na **dupla chamada**: `createRootRouteWithContext<T>(routeOptions)`. A fonte é explícita:

> "you must use the `createRootRouteWithContext<YourContextTypeHere>(routeOptions)` function to create a new router context instead of the `createRootRoute` function."

E a consequência prática, também citada:

> "If your context has any required properties, you will see a TypeScript error if you don't pass them in the initial router context."

O contexto em si — como flui, como `beforeLoad` o estende, como o `loader` o consome — é assunto de [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md).

| ID | Regra |
| --- | --- |
| `TSR-ROUTE-02` | O arquivo de rota raiz **MUST** se chamar `__root.tsx` e ficar na raiz de `routesDirectory`. |
| `TSR-ROUTE-03` | Contexto tipado no router **MUST** ser declarado por `createRootRouteWithContext<T>(...)`, nunca por `createRootRoute` com cast. |

---

## 3. Basic routes e index routes

Uma **basic route** casa um path exato:

```tsx
// src/routes/about.tsx → /about
export const Route = createFileRoute('/about')({
 component: AboutComponent,
})
```

Uma **index route** é o que preenche o pai quando a URL para exatamente nele:

> "Index routes specifically target their parent route when it is **matched exactly and no child route is matched**."

A sintaxe é a barra final no path e o token `index` no arquivo:

```tsx
// src/routes/posts.index.tsx → /posts (quando nenhum filho casa)
export const Route = createFileRoute('/posts/')({
 component: PostsIndexComponent,
})
```

Isto é a fonte de um bug recorrente: `posts.tsx` com filhos **não renderiza conteúdo próprio** quando a URL é `/posts`. Ele renderiza seu layout e um `<Outlet />` vazio. Quem preenche o `<Outlet />` em `/posts` é `posts.index.tsx`.

```
/posts → PostsLayout (posts.tsx) + PostsIndex (posts.index.tsx)
/posts/123 → PostsLayout (posts.tsx) + PostDetail (posts.$postId.tsx)
```

| ID | Regra |
| --- | --- |
| `TSR-ROUTE-04` | Toda rota que tem filhos e precisa exibir conteúdo na própria URL exata **MUST** ter uma index route irmã (`.index.tsx` / `index.tsx`). Sem ela, o `<Outlet />` fica vazio. |

---

## 4. Dynamic segments, prefixos e sufixos

O token `$` transforma um segmento em parâmetro:

> "Route segments with the `$` token are parameterized and will extract the value from the URL pathname as a route `param`."

E, citando a página de conceitos: *"Dynamic segments work at **each** segment of the path."* — `/users/$userId/posts/$postId` é válido e produz os dois params.

```tsx
// src/routes/posts.$postId.tsx
export const Route = createFileRoute('/posts/$postId')({
 loader: ({ params }) => fetchPost(params.postId),
 component: PostComponent,
})

function PostComponent {
 const { postId } = Route.useParams // postId: string
 return <h1>Post {postId}</h1>
}
```

Fora do arquivo da rota (componente code-split, componente compartilhado), leia com `from` explícito ou `getRouteApi`:

```tsx
import { useParams } from '@tanstack/react-router'

const { postId } = useParams({ from: '/posts/$postId' })
```

> "If your component is code-split, you can use the getRouteApi function to avoid having to import the Route configuration."

### Parâmetros opcionais

Sintaxe `{-$nome}`:

```tsx
// src/routes/posts.{-$category}.tsx → casa /posts E /posts/tech
export const Route = createFileRoute('/posts/{-$category}')({
 component: PostsComponent,
})

function PostsComponent {
 const { category } = Route.useParams // string | undefined
 return <h1>{category ? `Posts em ${category}` : 'Todos os posts'}</h1>
}
```

Podem ser encadeados — `/posts/{-$category}/{-$slug}` casa `/posts`, `/posts/tech` e `/posts/tech/hello-world` — e podem se misturar com obrigatórios: `/users/$id/{-$tab}` casa `/users/123` e `/users/123/settings`.

Quando ausente, o valor é `undefined`. E a prioridade:

> "Routes with optional parameters are ranked lower in priority than exact matches"

Ou seja, com `/posts/featured` estático e `/posts/{-$category}` opcional coexistindo, a URL `/posts/featured` vai para a rota estática. Detalhe em [TanStack Router - Route Matching](tanstack-router-route-matching.md).

### Prefixos e sufixos no segmento

Um parâmetro entre chaves pode ocupar só parte do segmento:

| Padrão | Casa | Param |
| --- | --- | --- |
| `post-{$postId}` | `post-123` | `postId = "123"` |
| `{$fileName}.txt` | `document.txt` | `fileName = "document"` |
| `user-{$userId}.json` | `user-42.json` | `userId = "42"` |

Isso torna `[...]` (escape de caractere literal) menos necessário do que parece, mas o escape continua existindo para segmentos totalmente estáticos: `script[.]js.tsx` gera `/script.js`.

| ID | Regra |
| --- | --- |
| `TSR-ROUTE-05` | Params lidos fora do arquivo da própria rota **MUST** informar `from` (ou usar `getRouteApi`) — `useParams` sem `from` nem `strict: false` não é tipado para aquela rota. |
| `TSR-ROUTE-06` | Consumidor de `{-$param}` **MUST** tratar `undefined`; o tipo é `string \| undefined`, não `string`. |
| `TSR-ROUTE-07` | Caractere especial que deve aparecer literalmente na URL **MUST** ser escapado com `[x]` no nome do arquivo (`script[.]js.tsx` → `/script.js`). |

---

## 5. Splat / catch-all

Um segmento `$` sozinho captura **todo o resto** da URL:

```tsx
// src/routes/files.$.tsx
export const Route = createFileRoute('/files/$')({
 loader: ({ params }) => fetchFile(params._splat),
})
// URL /files/documents/2024/report.pdf → params._splat === 'documents/2024/report.pdf'
```

O valor sai em `params._splat`. A fonte registra a forma legada:

> "In v1 of the router, splat routes are also denoted with a `*`"

> **Não verificado:** a afirmação, presente na versão anterior desta nota, de que a chave `*` "será removida na v2". A página de conceitos documenta `*` como alternativa em v1, mas não anuncia remoção. Trate `*` como legado, não como deprecado com data.

> **Não verificado:** a justificativa "escolhemos `$` em vez de `*` porque `*` não funciona bem em nomes de arquivo e ferramentas de CLI, seguindo o Remix". É plausível e coerente com a convenção, mas não apareceu na página oficial nesta verificação.

Splat é a última rota a ser testada — ver [TanStack Router - Route Matching](tanstack-router-route-matching.md).

| ID | Regra |
| --- | --- |
| `TSR-ROUTE-08` | O valor de uma splat route **MUST** ser lido em `params._splat`; a chave `*` **NEVER** entra em código novo. |

---

## 6. Layout routes: com path e sem path

Uma **layout route** é uma rota que tem filhos e envolve todos eles. Ela existe para:

- envolver os filhos com UI compartilhada;
- rodar `loader`/`beforeLoad` uma vez antes de qualquer filho;
- validar e prover search params para os filhos;
- oferecer `errorComponent` / `pendingComponent` comuns.

Duas grafias, mesmo resultado — flat ou diretório:

```
routes/ routes/
├── app.tsx └── app/
├── app.dashboard.tsx ├── route.tsx ← o layout
└── app.settings.tsx ├── dashboard.tsx
 └── settings.tsx
```

```tsx
// src/routes/app.tsx
export const Route = createFileRoute('/app')({
 loader: => fetchUserData,
 component: AppLayout,
})

function AppLayout {
 return (
 <div className="app-layout">
 <nav>App</nav>
 <main>
 <Outlet />
 </main>
 </div>
 )
}
```

**Sem o `<Outlet />` o filho não aparece.** Não há erro, não há aviso: a URL casa, o loader roda, e a tela mostra só o layout.

### Pathless layout route (`_prefixo`)

Quando você quer o wrapper mas **não** quer um segmento na URL:

> "Route segments with the `_` prefix are considered to be pathless layout routes and will not be used when matching its child routes against the URL pathname."

```
routes/
├── _pathlessLayout.tsx ← o wrapper
├── _pathlessLayout.a.tsx → /a
└── _pathlessLayout.b.tsx → /b
```

```
/ → <Index />
/a → <PathlessLayout><A /></PathlessLayout>
/b → <PathlessLayout><B /></PathlessLayout>
```

O caso de uso canônico é o guard de autenticação: `_authenticated.tsx` com `beforeLoad` que redireciona, e as rotas protegidas como filhas — sem que `/authenticated/` apareça na URL.

Restrição citada da fonte:

> "Pathless Layout Routes do not match based on URL path segments, this means that these routes do not support Dynamic Route Segments as part of their path"

```
❌ routes/_$postId/ ← não funciona: pathless não casa segmento
✅ routes/$postId/route.tsx ← layout com path, aí sim pode ser dinâmico
```

### Non-nested route (`_` sufixo)

O mesmo caractere, na outra ponta do nome, faz o oposto:

> "Route segments with the `_` suffix exclude the route from being nested under any parent routes."

```
routes/
├── posts.tsx ← layout
├── posts.$postId.tsx → /posts/123 (dentro do layout)
└── posts_.$postId.edit.tsx → /posts/123/edit (SEM o layout)
```

A URL continua idêntica; o que muda é a árvore de componentes. É como se faz a tela de edição em full screen sem o sidebar da listagem.

| Token | Efeito na URL | Efeito na árvore de componentes |
| --- | --- | --- |
| `_prefixo` (pathless layout) | remove o segmento | **adiciona** um nível de wrapper |
| `sufixo_` (non-nested) | não muda | **remove** os wrappers ancestrais |

| ID | Regra |
| --- | --- |
| `TSR-ROUTE-09` | Toda rota que tem filhos **MUST** renderizar `<Outlet />` no seu `component`. |
| `TSR-ROUTE-10` | Pathless layout (`_prefixo`) **NEVER** contém segmento dinâmico no próprio path — ele não casa por segmento de URL. |
| `TSR-ROUTE-11` | `_` como prefixo e `_` como sufixo **NEVER** são tratados como o mesmo recurso: prefixo adiciona layout sem mudar URL; sufixo remove layout sem mudar URL. |

---

## 7. Organização sem efeito de rota

Dois mecanismos que existem só para arrumar o diretório.

**Route group `(nome)/`** — agrupa arquivos sem entrar na URL:

> "A folder that matches this pattern is treated as a route group, preventing the folder from being included in the route's URL path."

```
routes/
├── (app)/
│ ├── dashboard.tsx → /dashboard
│ └── settings.tsx → /settings
└── (auth)/
 ├── login.tsx → /login
 └── register.tsx → /register
```

A página de conceitos é categórica: grupos são *"purely organizational and do not affect the route tree or component tree in any way"*. Se você quer layout compartilhado, precisa de um pathless layout (`_auth.tsx`), não de um grupo — o grupo não renderiza nada.

**Arquivos excluídos `-nome`** — colocation de código auxiliar:

> "Files and folders with the `-` prefix are excluded from the route tree."

```
routes/
├── posts.tsx
├── -posts-table.tsx ← ignorado
└── -components/ ← pasta inteira ignorada
 └── header.tsx
```

```tsx
// posts.tsx
import { PostsTable } from './-posts-table'
```

O prefixo é o default de `routeFileIgnorePrefix` — configurável, ver [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md).

| ID | Regra |
| --- | --- |
| `TSR-ROUTE-12` | Route group `(nome)` **NEVER** é usado para obter layout ou dados compartilhados — ele não cria nó na árvore. Para isso, pathless layout. |
| `TSR-ROUTE-13` | Arquivo auxiliar dentro de `routesDirectory` **MUST** usar o prefixo `-`; caso contrário vira rota. |

---

## 8. Matriz de decisão

| Você quer… | Use | Arquivo |
| --- | --- | --- |
| Rota simples | basic route | `about.tsx` |
| Conteúdo na URL exata do pai | index route | `posts.index.tsx` |
| Capturar um segmento | dynamic segment | `posts.$postId.tsx` |
| Segmento que pode faltar | optional param | `posts.{-$category}.tsx` |
| Parte de um segmento | prefixo/sufixo | `post-{$postId}.tsx` |
| Capturar o resto da URL | splat | `files.$.tsx` |
| UI + dados compartilhados **com** segmento | layout route | `app.tsx` + `app.*.tsx` |
| UI + dados compartilhados **sem** segmento | pathless layout | `_auth.tsx` + `_auth.*.tsx` |
| Escapar do layout do ancestral | non-nested | `posts_.$postId.edit.tsx` |
| Só arrumar pastas | route group | `(admin)/` |
| Código auxiliar junto da rota | arquivo excluído | `-table.tsx` |

---

## Antipadrões

**Layout sem `<Outlet />`**

```tsx
// ERRADO — a URL casa, o loader roda, e o filho nunca aparece
function AppLayout {
 return <div className="app"><nav>App</nav></div>
}

// CERTO
function AppLayout {
 return (
 <div className="app">
 <nav>App</nav>
 <Outlet />
 </div>
 )
}
```

**Route group para compartilhar layout**

```
// ERRADO — (auth) não renderiza nada; não há wrapper nem beforeLoad comum
routes/(auth)/login.tsx
routes/(auth)/register.tsx

// CERTO — pathless layout cria de fato um nó na árvore
routes/_auth.tsx (beforeLoad + <Outlet />)
routes/_auth.login.tsx
routes/_auth.register.tsx
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| Editar o literal em `createFileRoute('/…')` para mudar a URL | O gerador reescreve no próximo build; o path vem do nome do arquivo | Renomeie o arquivo (`TSR-ROUTE-01`) |
| `posts.tsx` com filhos e sem `posts.index.tsx` | `/posts` renderiza o layout com `<Outlet />` vazio | Crie a index route (`TSR-ROUTE-04`) |
| `_$postId/` como pathless layout dinâmico | Pathless não casa segmento de URL; o param nunca é capturado | Layout com path: `$postId/route.tsx` (`TSR-ROUTE-10`) |
| `params['*']` para ler splat | Chave legada de v1 | `params._splat` (`TSR-ROUTE-08`) |
| `const { id } = useParams` em componente compartilhado | Sem `from`, não há tipagem da rota | `useParams({ from: '/posts/$postId' })` (`TSR-ROUTE-05`) |
| `{-$category}` usado como se sempre existisse | O tipo inclui `undefined`; quebra em `/posts` | Tratar o ramo ausente (`TSR-ROUTE-06`) |
| `components/Header.tsx` dentro de `routes/` | Vira a rota `/components/Header` | Prefixo `-` (`TSR-ROUTE-13`) |

---

## Checklist de revisão

- [ ] O literal de `createFileRoute` bate com o nome do arquivo e não foi editado à mão? → `TSR-ROUTE-01`
- [ ] Existe exatamente um `__root.tsx`, na raiz de `routesDirectory`? → `TSR-ROUTE-02`
- [ ] Contexto tipado usa `createRootRouteWithContext<T>(...)`? → `TSR-ROUTE-03`
- [ ] Toda rota com filhos tem index route quando a URL exata do pai é navegável? → `TSR-ROUTE-04`
- [ ] `useParams` fora do arquivo da rota informa `from`? → `TSR-ROUTE-05`
- [ ] Param opcional tem o ramo `undefined` tratado? → `TSR-ROUTE-06`
- [ ] Splat lido por `params._splat`, não por `*`? → `TSR-ROUTE-08`
- [ ] Todo layout renderiza `<Outlet />`? → `TSR-ROUTE-09`
- [ ] Nenhum pathless layout tenta usar `$param` no próprio path? → `TSR-ROUTE-10`
- [ ] `(grupo)` está sendo usado só para organização, nunca para layout? → `TSR-ROUTE-12`
- [ ] Arquivos não-rota dentro de `routes/` usam prefixo `-`? → `TSR-ROUTE-13`

---

## Relacionados

- [TanStack Router](tanstack-router.md) — entrada
- [TanStack Router - Route Trees](tanstack-router-route-trees.md) · [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) · [TanStack Router - Route Matching](tanstack-router-route-matching.md) · [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)
- [TanStack Router - Navegação](tanstack-router-navegacao.md) · [TanStack Router - Search Params](tanstack-router-search-params.md) · [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) · [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md)
- [React.js](react-js.md) · [React - Patterns](react-patterns.md) · `TypeScript`

## Fontes consultadas

Verificadas em 2026-08-14:

- [Routing Concepts](https://tanstack.com/router/latest/docs/framework/react/routing/routing-concepts)
- [File Naming Conventions](https://tanstack.com/router/latest/docs/framework/react/routing/file-naming-conventions)
- [Path Params](https://tanstack.com/router/latest/docs/framework/react/guide/path-params)
- [Router Context](https://tanstack.com/router/latest/docs/framework/react/guide/router-context)
- [Code-Based Routing](https://tanstack.com/router/latest/docs/framework/react/routing/code-based-routing)

**Correções aplicadas nesta revisão** (a versão anterior desta nota afirmava o contrário):

- **Removidas todas as "implementações técnicas" em JavaScript** — `createFileRoute` interno, `inferParamsFromPath`, `matchRoute`, `parseSplatRoute`, `calculateRouteScore`, `generateTypes`, `executeLoaders`. Nenhuma delas existe na documentação; eram reconstruções inventadas do interno do router e induziam a raciocinar sobre um algoritmo que não é o real.
- **Removida a forma inventada do tipo gerado** (`interface FileRoutesByPath` com campos `params`/`search`/`loaderData`/`preLoaderRoute`). O formato do `routeTree.gen.ts` é artefato do gerador e não é API pública documentada.
- **Adicionado `__root.tsx`** como nome obrigatório do arquivo de raiz — a versão anterior descrevia a root route sem dizer onde ela mora.
- **Adicionada a dupla chamada** de `createRootRouteWithContext<T>(...)`; a versão anterior mostrava `createRootRouteWithContext<T>` sem o segundo par de parênteses, o que não compila com opções.
- **Adicionados prefixo/sufixo de segmento** (`post-{$postId}`, `{$fileName}.txt`) e o **escape `[x]`** — ausentes na versão anterior.
- **Corrigida a afirmação sobre `*`**: a fonte documenta `*` como grafia alternativa em v1, mas não anuncia remoção na v2.
- **Cortado por redundância:** a explicação de ordem de precedência entre rotas (agora só em [TanStack Router - Route Matching](tanstack-router-route-matching.md)), a configuração do plugin e a tabela de tokens (agora só em [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)), e o exemplo de `validateSearch` com Zod (agora em [TanStack Router - Search Params](tanstack-router-search-params.md)).
