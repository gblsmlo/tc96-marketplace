---
titulo: TanStack Router - Route Trees
Link: https://tanstack.com/router/latest/docs/framework/react/routing/route-trees
tags:
  - tanstack-router
  - routing
  - agent-context
source: "Documentação oficial — https://tanstack.com/router/latest/docs/framework/react/"
verificado-em: 2026-08-14
---

# TanStack Router - Route Trees

> A **topologia**: o que é uma route tree, por que nested routing casa URL com árvore de componentes, e as cinco formas de montá-la — flat, diretório, misto, virtual e code-based. Inclui a API completa de code-based routing (`createRootRoute`, `createRoute`, `addChildren`, `createRouter`).
>
> **Não cobre:** o significado de cada tipo de rota ([TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) · a tabela de tokens de nome de arquivo e a configuração do gerador ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · qual nó ganha quando dois casam ([TanStack Router - Route Matching](tanstack-router-route-matching.md)) · a API `rootRoute`/`route`/`index`/`layout`/`physical` ([TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)).

Entrada: [TanStack Router](tanstack-router.md) · Base normativa: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Conceito: a URL é uma árvore, não uma string

Roteadores tradicionais tratam a URL como uma chave de um mapa plano: `/blog/posts/123` procura uma entrada e renderiza um componente. O TanStack Router trata a URL como **um caminho descendo uma árvore**, e renderiza *todos* os nós do caminho, aninhados.

> "Nested routing is a powerful concept that allows you to use a URL to render a nested component tree."

```
URL: /blog/posts/123

├── blog
│   ├── posts
│   │   ├── $postId
```

```tsx
<Blog>
  <Posts>
    <Post postId="123" />
  </Posts>
</Blog>
```

Isso é o que torna layouts, loaders em cascata e error boundaries por nível possíveis sem nenhuma API extra: cada ancestral do match é um lugar onde você pode pendurar UI, dados, validação e fallback. A consequência de projeto é direta e vale mais que qualquer convenção de nome:

**Você não desenha a árvore a partir da URL. Você desenha a partir de que UI e que dados precisam ser compartilhados, e a URL é o que sobra.** Duas telas com o mesmo prefixo de URL mas nenhum layout comum não deveriam ser irmãs na árvore — é para isso que existe o sufixo `_` (non-nested, ver [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) § 6).

| ID | Regra |
| --- | --- |
| `TSR-TREE-01` | A hierarquia da árvore **MUST** ser decidida pelo compartilhamento de layout, dados e contexto — não pela semelhança dos paths. Prefixo de URL igual não obriga aninhamento. |

---

## 2. As cinco formas de montar a árvore

| Forma | Onde a estrutura vive | Quando usar |
| --- | --- | --- |
| **Flat routes** | nomes de arquivo com `.` | árvores rasas; ver tudo de uma vez |
| **Directory routes** | pastas | subárvores profundas ou com muitos arquivos auxiliares |
| **Mixed** | ambos | o caso real da maioria dos projetos |
| **Virtual file routes** | código TS que aponta para arquivos | estrutura de arquivos pré-existente que não se quer mover — [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) |
| **Code-based** | código TS, sem geração | § 4 — desaconselhado pela fonte |

A fonte é explícita sobre a preferência:

> "file-based routing requires less code for the same or better results" — e é "the preferred and recommended way" de configurar o router.

### Flat

```
routes/
├── __root.tsx
├── index.tsx
├── about.tsx
├── posts.index.tsx          → /posts
├── posts.$postId.tsx        → /posts/$postId
└── posts.$postId.edit.tsx   → /posts/$postId/edit
```

O `.` é literalmente o separador de nível:

> "Routes can use the `.` character to denote a nested route. For example, `blog.post` will be generated as a child of `blog`."

### Diretório

```
routes/
├── __root.tsx
├── index.tsx
└── settings/
    ├── route.tsx           ← o layout de /settings
    ├── profile.tsx         → /settings/profile
    └── notifications.tsx   → /settings/notifications
```

O ponto que mais confunde: **uma pasta sozinha não é um layout.** Ela contribui o segmento de path e nada mais. Só existe componente de layout para `/settings` se houver `settings/route.tsx` (ou o irmão flat `settings.tsx`).

> "The `route` suffix can be used to create a route file at the directory's path" — `blog/post/route.tsx` para `/blog/post`.

### Misto

Combinar é suportado e normal. O exemplo da própria documentação mistura os dois estilos na mesma árvore:

```
/routes
├── __root.tsx
├── index.tsx
├── about.tsx
├── posts/
│   ├── index.tsx
│   ├── $postId.tsx
├── posts.$postId.edit.tsx
├── settings/
│   ├── profile.tsx
│   ├── notifications.tsx
├── _pathlessLayout/
│   ├── route-a.tsx
│   ├── route-b.tsx
├── files/
│   ├── $.tsx
```

O risco do misto é definir a mesma rota duas vezes — `posts.index.tsx` e `posts/index.tsx` coexistindo. O gerador não tem como escolher entre eles.

| ID | Regra |
| --- | --- |
| `TSR-TREE-02` | A mesma rota **NEVER** é definida por dois arquivos (flat e diretório simultaneamente). Escolha um estilo por subárvore. |
| `TSR-TREE-03` | Layout compartilhado em um diretório **MUST** vir de um `route.tsx` (ou do irmão flat de mesmo nome); a pasta sozinha só contribui segmento de path. |

O artefato gerado (`routeTree.gen.ts`) e a configuração do gerador são assunto de [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) — inclusive `TSR-FILE-05`, que proíbe editá-lo à mão. Não há regra nova aqui.

---

## 3. Lendo a árvore em runtime

```tsx
import { useRouter, useMatches } from '@tanstack/react-router'

function Breadcrumbs() {
  const matches = useMatches() // do root até a folha, em ordem
  return <nav>{matches.map((m) => m.pathname).join(' / ')}</nav>
}
```

`useMatches()` devolve exatamente o caminho da árvore que casou — é a leitura direta do modelo mental da § 1, e a base natural de breadcrumbs e de UI que depende de "estou dentro de qual seção".

> **Não verificado:** a versão anterior desta nota descrevia uma API `router.routeTree` com `getRoute(id)`, `getRoutes()` e `findRouteByPath(path)`. Essas funções não foram encontradas na documentação nesta verificação; foram removidas do corpo da nota. Se precisar navegar a árvore programaticamente, confirme na fonte antes de usar.

---

## 4. Code-based routing

Existe, é totalmente tipado, e a documentação desaconselha:

> "Code-based routing is not recommended for most applications. It is recommended to use File-Based Routing instead."

Ainda assim é o que sustenta o modelo mental: file-based é açúcar que gera exatamente isto.

```tsx
import {
  createRootRoute,
  createRoute,
  createRouter,
  Outlet,
} from '@tanstack/react-router'

const rootRoute = createRootRoute({
  component: () => <Outlet />,
})

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: HomeComponent,
})

const postsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/posts',
  component: PostsLayout,
})

const postsIndexRoute = createRoute({
  getParentRoute: () => postsRoute,
  path: '/', // índice de /posts
  component: PostsIndex,
})

const postDetailRoute = createRoute({
  getParentRoute: () => postsRoute,
  path: '$postId',
  component: PostDetail,
})

const routeTree = rootRoute.addChildren([
  indexRoute,
  postsRoute.addChildren([postsIndexRoute, postDetailRoute]),
])

export const router = createRouter({ routeTree })
```

Quatro pontos que não são negociáveis:

- **`getParentRoute` é obrigatório** e é uma *função* que devolve o pai. É por ela que o TypeScript liga a rota ao ancestral e infere `params`, `search` e `context` acumulados.
- **A raiz vem de `createRootRoute()` ou `createRootRouteWithContext<T>()()`**, nunca de `createRoute` com um `id` inventado.
- **Index route é `path: '/'`**, não um `id` chamado `index`.
- **Pathless layout usa `id` no lugar de `path`** — é o equivalente code-based do prefixo `_`.

```tsx
const authLayoutRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: '_auth', // sem path: não contribui segmento à URL
  component: AuthLayout,
})
```

| ID | Regra |
| --- | --- |
| `TSR-TREE-04` | Code-based routing **NEVER** entra em projeto novo sem decisão registrada — a fonte o desaconselha explicitamente para a maioria das aplicações. |
| `TSR-TREE-05` | Toda `createRoute` **MUST** declarar `getParentRoute: () => pai`; sem isso não há inferência de tipo do ancestral. |
| `TSR-TREE-06` | A raiz **MUST** vir de `createRootRoute` / `createRootRouteWithContext`, **NEVER** de `createRoute`. |
| `TSR-TREE-07` | Index route em code-based **MUST** ser `path: '/'`. |
| `TSR-TREE-08` | Pathless layout em code-based **MUST** usar `id` e omitir `path`. |

---

## 5. Comparativo

| Aspecto | File-based | Code-based |
| --- | --- | --- |
| Onde a estrutura vive | sistema de arquivos | módulo TS |
| Boilerplate | mínimo | um bloco por rota + montagem manual |
| Type safety | gerada pelo plugin | manual, via `getParentRoute` |
| Code splitting automático | sim (`autoCodeSplitting`) | manual |
| Recomendação oficial | **preferida** | "not recommended for most applications" |
| Caso legítimo | padrão | árvore montada em runtime a partir de configuração |

---

## Antipadrões

**Raiz criada como rota comum**

```tsx
// ERRADO — createRoute não cria raiz; não há pai para apontar
const rootRoute = createRoute({ id: '__root__', component: RootComponent })

// CERTO
const rootRoute = createRootRoute({ component: RootComponent })
```

**Pasta tratada como layout**

```
// ERRADO — não existe layout em /settings; profile e notifications
// renderizam sozinhas e o header não aparece
routes/settings/profile.tsx
routes/settings/notifications.tsx

// CERTO
routes/settings/route.tsx        ← layout com <Outlet />
routes/settings/profile.tsx
routes/settings/notifications.tsx
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| Aninhar por semelhança de URL sem layout comum | Todo filho passa a herdar loader e UI que não usa | Sufixo `_` para desaninhar (`TSR-TREE-01`) |
| `posts.index.tsx` **e** `posts/index.tsx` | Duas definições da mesma rota; o gerador não escolhe | Um estilo por subárvore (`TSR-TREE-02`) |
| `createRoute` sem `getParentRoute` | A rota não se liga à árvore e perde a inferência de tipos | Declarar `getParentRoute` (`TSR-TREE-05`) |
| `id: 'index'` para rota índice em code-based | Vira pathless layout, não índice | `path: '/'` (`TSR-TREE-07`) |
| Migrar para code-based "para ter mais controle" | Perde geração de tipos e code splitting automático | Virtual file routes resolve o caso real (`TSR-TREE-04`) |

---

## Checklist de revisão

- [ ] O aninhamento reflete compartilhamento de layout/dados, não coincidência de path? → `TSR-TREE-01`
- [ ] Nenhuma rota está definida em flat e em diretório ao mesmo tempo? → `TSR-TREE-02`
- [ ] Todo diretório que precisa de layout tem `route.tsx`? → `TSR-TREE-03`
- [ ] Se há code-based, existe decisão registrada para isso? → `TSR-TREE-04`
- [ ] Toda `createRoute` declara `getParentRoute`? → `TSR-TREE-05`
- [ ] A raiz usa `createRootRoute`/`createRootRouteWithContext`? → `TSR-TREE-06`
- [ ] Rotas índice em code-based usam `path: '/'`? → `TSR-TREE-07`
- [ ] Pathless layouts em code-based usam `id` sem `path`? → `TSR-TREE-08`
- [ ] `routeTree.gen.ts` está intacto (sem edição manual)? → `TSR-FILE-05`

---

## Relacionados

- [TanStack Router](tanstack-router.md) — entrada
- [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) · [TanStack Router - Route Matching](tanstack-router-route-matching.md) · [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)
- [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) · [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md) · [TanStack Router - Navegação](tanstack-router-navegacao.md)
- [React.js](react-js.md) · `TypeScript`

## Fontes consultadas

Verificadas em 2026-08-14:

- [Route Trees](https://tanstack.com/router/latest/docs/framework/react/routing/route-trees)
- [Code-Based Routing](https://tanstack.com/router/latest/docs/framework/react/routing/code-based-routing)
- [File Naming Conventions](https://tanstack.com/router/latest/docs/framework/react/routing/file-naming-conventions)
- [File-Based Routing](https://tanstack.com/router/latest/docs/framework/react/routing/file-based-routing)

**Correções aplicadas nesta revisão:**

- **`createVirtualFileRoute` não existe.** A versão anterior ensinava `createVirtualFileRoute('/admin')({...})` importado de `@tanstack/react-router` e passado ao router numa opção `virtualRoutes`. Nada disso existe. A API real é `rootRoute`/`route`/`index`/`layout`/`physical` do pacote `@tanstack/virtual-file-routes`, consumida pela opção `virtualRouteConfig` do plugin — ver [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md).
- **Raiz em code-based estava errada.** A versão anterior mostrava `createRoute({ id: '__root__' })`. O correto é `createRootRoute()`.
- **Exemplo de pathless layout estava com URLs erradas.** A versão anterior mostrava `_dashboard/analytics.tsx → /dashboard/analytics`. Um diretório com prefixo `_` **não** contribui segmento: a URL resultante é `/analytics`.
- **Removidas as implementações internas em JavaScript** — `class RouteTree`, `class RouteNode`, `generateRouteTree`, `buildTreeFromDirectory`, `parseFlatRoute`, `matchRoutes`, `generateTypes`, `calculatePriority` e a tabela `PRIORITIES`. Eram invenções; a ordem de precedência real está documentada e vive em [TanStack Router - Route Matching](tanstack-router-route-matching.md).
- **Removida a API `RouteTreeAPI`** (`getRoute`, `getRoutes`, `findRouteByPath`) — não encontrada na documentação. Ver a nota de "Não verificado" na § 3.
- **Removido o campo `preLoaderRoute`** do exemplo de tipo gerado, junto com o resto do formato inventado do `routeTree.gen.ts`.
- **Cortado por redundância:** a tabela de convenções de nomenclatura por token (agora só em [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)), a explicação de cada tipo de rota (agora só em [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)), o algoritmo de matching passo a passo (agora só em [TanStack Router - Route Matching](tanstack-router-route-matching.md)) e a seção de virtual file routes (agora só em [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)).
