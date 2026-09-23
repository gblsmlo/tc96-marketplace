---
titulo: TanStack Router - Navegação
Link: https://tanstack.com/router/latest/docs/framework/react/guide/navigation
tags:
  - tanstack-router
  - navegacao
  - agent-context
source: "Documentação oficial — https://tanstack.com/router/latest/docs/framework/react/"
verificado-em: 2026-08-14
---

# TanStack Router - Navegação

> `<Link>` · `useNavigate` · `<Navigate>` · `router.navigate` · `redirect` · `useRouter` · `useMatch` / `useMatches` · `useMatchRoute` / `<MatchRoute>` · `useBlocker` / `<Block>` · `linkOptions` · route masking.
>
> Não cobre: sintaxe de path e definição de rota (`$param`, `{-$opt}`, layouts) — [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md); validação e leitura de search params — [TanStack Router - Search Params](tanstack-router-search-params.md); o que `loader` e `beforeLoad` carregam — [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md).

Entrada: [TanStack Router](tanstack-router.md) · Conceitos de rota: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Conceito: toda navegação é relativa e tipada

Duas ideias sustentam a API inteira.

**A primeira:** navegação sempre tem origem e destino.

> "every navigation within an app is **relative**, even if you aren't using explicit relative path syntax."

Origem é `from`, destino é `to`. E o default de `from` é o que quebra a intuição:

> "If a `from` route path isn't provided, the router will assume you are navigating from the root `/` route."

Ou seja: não existe "navegação relativa implícita a partir de onde estou". Sem `from`, `..` sobe a partir de `/`, não da rota atual.

**A segunda:** `to` não é uma string. É uma união literal gerada a partir da árvore de rotas. Digitar `/psots/$postId` não vira 404 em runtime — vira erro de compilação. E o tipo de `to` determina, por inferência, quais chaves `params` e `search` exigem. Uma rota `/posts/$postId` torna `params.postId` obrigatório; uma rota com `validateSearch` torna as chaves do schema obrigatórias no `search`:

> "TypeScript will notify you of the required search params."

Isso muda o custo do refactor: renomear um arquivo de rota quebra a compilação em todos os links que apontavam para ela, em vez de produzir links mortos silenciosos.

### As três camadas de opções

Todas as APIs de navegação compartilham o mesmo objeto, em três níveis de especialização.

```ts
type ToOptions = {
  from?: string
  to: string
  params?: Record<string, unknown> | ((prevParams: Record<string, unknown>) => Record<string, unknown>)
  search?: Record<string, unknown> | ((prevSearch: Record<string, unknown>) => Record<string, unknown>)
  hash?: string | ((prevHash: string) => string)
  state?: Record<string, any> | ((prevState: Record<string, unknown>) => Record<string, unknown>)
  mask?: ToMaskOptions<TRouteTree>
}
```

```ts
export type NavigateOptions = ToOptions & {
  replace?: boolean
  resetScroll?: boolean
  hashScrollIntoView?: boolean | ScrollIntoViewOptions
  viewTransition?: boolean | ViewTransitionOptions
  ignoreBlocker?: boolean
  reloadDocument?: boolean
  href?: string
}
```

```tsx
export type LinkOptions = NavigateOptions & {
  target?: HTMLAnchorElement['target']
  activeOptions?: {
    exact?: boolean
    includeHash?: boolean
    includeSearch?: boolean
    explicitUndefined?: boolean
  }
  preload?: false | 'intent' | 'viewport' | 'render'
  preloadDelay?: number
  disabled?: boolean
}
```

`<Link>` aceita tudo. `navigate()` e `redirect()` aceitam `NavigateOptions`. Aprender um objeto cobre as quatro APIs.

Sobre `to`, o aviso literal da fonte:

> "Do not interpolate path params, hash or search params into the `to` options. Use the `params`, `search`, and `hash` options instead."

E sobre `params`:

> "This is the only way to interpolate dynamic parameters into the final URL."

| ID | Regra |
| --- | --- |
| `TSR-NAV-01` | `to` **NEVER** recebe string interpolada (`` `/posts/${id}` ``) — path params vão em `params`, query em `search`, fragmento em `hash`. |

Interpolar destrói justamente o que o router oferece: a string deixa de casar com a união literal, o TypeScript degrada para `string`, e nenhum erro de destino é mais detectado em build.

---

## 2. `<Link>` é o default, e não por estilo

```tsx
import { Link } from '@tanstack/react-router'

const link = <Link to="/about">About</Link>
```

`<Link>` renderiza uma âncora real com `href` preenchido. Isso não é detalhe cosmético — é o que entrega, de graça:

- Ctrl/Cmd + clique e clique do meio abrindo em nova aba;
- "copiar endereço do link" no menu de contexto;
- destino visível na barra de status do browser;
- papel de `link` para leitores de tela, em vez de `div` com `onClick`;
- preload por intenção (§ 4);
- estado ativo (§ 3).

Um `onClick={() => navigate(...)}` em `<button>` ou `<div>` perde todos os itens acima de uma vez. A fonte é explícita:

> "Because of the `Link` component's built-in affordances around `href`, cmd/ctrl + click-ability, and active/inactive capabilities, it's recommended to use the `Link` component instead of `useNavigate` for anything the user can interact with. However, there are some cases where `useNavigate` is necessary to handle side-effect navigations."

| ID | Regra |
| --- | --- |
| `TSR-NAV-02` | Elemento que o usuário clica para trocar de rota **MUST** ser `<Link>`. `useNavigate` em `onClick` **NEVER** é usado quando o destino já é conhecido no momento do render. |

**O critério de "side-effect navigation"** — sem ele a regra vira negociável. Aceite `navigate()` quando o destino só existe depois de um efeito: id retornado por uma mutation, resultado de autenticação, expiração de sessão, término de um wizard, `setTimeout`. Se você consegue escrever o `to` e o `params` durante o render, é `<Link>`.

### Absoluto, relativo, `.` e `..`

Por padrão links são absolutos. Relativo exige `from`:

```tsx
const postIdRoute = createRoute({ path: '/blog/post/$postId' })

const link = (
  <Link from={postIdRoute.fullPath} to="../categories">
    Categories
  </Link>
)
```

A fonte recomenda `route.fullPath` em vez de string literal, porque "the `route.fullPath` is a reference that will update if you refactor your application".

Os dois caminhos especiais: `.` recarrega a location atual (ou a de `from`), `..` sobe uma rota.

```tsx
export const Route = createFileRoute('/posts/$postId')({
  component: PostComponent,
})

function PostComponent() {
  return (
    <div>
      <Link to=".">Reload the current route of /posts/$postId</Link>
      <Link to="..">Navigate back to /posts</Link>
      <Link to="/posts">Navigate back to /posts</Link>
      <Link from="/posts" to=".">Navigate back to /posts</Link>
      <Link to="/">Navigate to root</Link>
      <Link from="/posts" to="..">Navigate to root</Link>
    </div>
  )
}
```

Note a última linha: `from="/posts"` com `to=".."` vai para a raiz, não para `/posts`. Relatividade é sempre em relação a `from`, e `from` ausente significa `/`.

Caveat de layout sem path:

> "When using this in a pathless layout route, since the pathless layout route does not have an actual path, the `from` location is regarded as the parent of the pathless layout route."

| ID | Regra |
| --- | --- |
| `TSR-NAV-03` | Link com `to` relativo (`.`, `..`, `../algo`) **MUST** declarar `from` — sem ele a origem é `/`, não a rota atual. |
| `TSR-NAV-04` | `from` **MUST** vir de `Route.fullPath` / `route.fullPath`, **NEVER** de string literal repetida no JSX. |

### `params`: objeto substitui, função herda

```tsx
<Link to="/blog/post/$postId" params={{ postId: 'my-first-blog-post' }}>
  Blog Post
</Link>
```

Com params opcionais (`{-$param}`), a distinção entre "não mencionar" e "passar `undefined`" é semântica, não acidental:

```tsx
// herda o parâmetro da rota atual
<Link to="/posts/{-$category}" params={{}}>All Posts</Link>

// remove o parâmetro
<Link to="/posts/{-$category}" params={{ category: undefined }}>All Posts</Link>

// preserva os demais e mexe em um só
<Link to="/articles/{-$category}/{-$slug}" params={(prev) => ({ ...prev, category: 'news' })}>
  News Articles
</Link>
```

### `hash`: o caveat que causa bug de hidratação

```tsx
<Link to="/blog/post/$postId" params={{ postId: 'my-first-blog-post' }} hash="section-1">
  Section 1
</Link>
```

> "When directly navigating to a URL with a hash fragment, the fragment is only available on the client; the browser does not send the fragment to the server as part of the request URL. This means that if you are using a server-side rendering approach, the hash fragment will not be available on the server-side, and hydration mismatches can occur when using the hash for rendering markup."

Os padrões problemáticos citados: devolver o valor do hash no markup, renderização condicional baseada no hash, e definir estado ativo de link a partir do hash.

| ID | Regra |
| --- | --- |
| `TSR-NAV-05` | Em aplicação com SSR, o `hash` **NEVER** decide markup renderizado, renderização condicional ou estado ativo — apenas alvo de scroll. |

### `state`: history API, não URL

> "State is stored in the history API and can be useful for passing data between routes."

Consequência prática: `state` não sobrevive a compartilhamento do link, não aparece na URL e some se o usuário recarregar por digitação. Serve para dado efêmero de transição (posição de scroll de origem, "veio de onde"). Estado que o usuário espera recuperar ao colar o link pertence a `search` — é o apelido de `REACT-PAT-10` em [React - Patterns](react-patterns.md), detalhado em [TanStack Router - Search Params](tanstack-router-search-params.md).

---

## 3. Estado ativo

```tsx
<Link
  to="/blog/post/$postId"
  params={{ postId: 'my-first-blog-post' }}
  activeProps={{ style: { fontWeight: 'bold' } }}
>
  Section 1
</Link>
```

Regra de merge, citada:

> "All props other than styles and classes passed here will override the original props passed to `Link`. Any styles or classes passed are merged together."

Além de `activeProps`/`inactiveProps`, há duas saídas mais baratas:

```tsx
// atributo no DOM: `active` ou undefined
// permite estilizar via CSS: a[data-status='active'] { ... }
<Link to="/posts">Posts</Link>

// função como children recebe isActive
<Link to="/blog/post">
  {({ isActive }) => (
    <>
      <span>My Blog Post</span>
      <icon className={isActive ? 'active' : 'inactive'} />
    </>
  )}
</Link>
```

> "adds a `data-status` attribute to the rendered element when it is in an active state. This attribute will be `active` or `undefined`."

### `activeOptions` e o bug clássico do link "Home"

Defaults citados da fonte:

> "By default, it will check if the resulting **pathname** is a prefix of the current route."

> "If any search params are provided, it will check that they _inclusively_ match those in the current location."

> "Hashes are not checked by default."

| Opção | Efeito |
| --- | --- |
| `exact: true` | o link deixa de ficar ativo quando você está numa rota filha |
| `includeHash: true` | inclui o hash na comparação |
| `includeSearch: false` | ignora search params na comparação |
| `explicitUndefined: true` | chaves explicitamente `undefined` em `search` **não** podem existir na URL atual para o link contar como ativo |

Como o default é prefixo de pathname, `/` é prefixo de tudo — o link para a home fica permanentemente ativo:

```tsx
<Link to="/" activeOptions={{ exact: true }}>Home</Link>
```

| ID | Regra |
| --- | --- |
| `TSR-NAV-06` | Link cujo `to` é prefixo de outras rotas (`/`, e qualquer rota pai com filhas) **MUST** declarar `activeOptions={{ exact: true }}` se o destaque visual deve valer só para ela. |

---

## 4. Preload: performance percebida tem preço

Quatro valores para `preload`:

| Valor | Comportamento |
| --- | --- |
| `false` | desliga o preload automático |
| `'intent'` | preload em foco, hover ou touch |
| `'viewport'` | preload quando o link entra no viewport (Intersection Observer) |
| `'render'` | preload assim que o link é renderizado no DOM |

```tsx
<Link to="/blog/post/$postId" preload="intent" preloadDelay={100}>
  Blog Post
</Link>
```

> "For `'intent'` and `'viewport'` preloading, a configurable delay determines how long to wait before preloading begins. If focus or hover ends, or the link leaves the viewport before the delay, the queued preload is cancelled. Touch intent preloads immediately. The default delay is 50 milliseconds."

**O que preload custa.** Preload não busca só o chunk de código: executa as dependências da rota destino, incluindo `loader`. Cada link com preload ativo é uma requisição real potencial. Com `'intent'` e delay, o usuário demonstrou intenção e o custo é proporcional; com `'render'`, uma lista de 200 itens dispara 200 execuções de loader na montagem, antes de qualquer intenção. `'viewport'` fica no meio: proporcional ao que rolou na tela.

Duas políticas independentes governam o que fica em cache:

> "Freshness defaults to 30 seconds. Configure it with `defaultPreloadStaleTime` or a route's `preloadStaleTime`."

> "The unused retention window defaults to 5 minutes. Configure it with `defaultPreloadGcTime` or a route's `preloadGcTime`."

Se o loader delega para [TanStack Query](tanstack-query.md), há dois caches sobrepostos, e o do router precisa sair do caminho:

> "Settled preload data then becomes immediately stale in the Router, while retention still follows `preloadGcTime`."

```tsx
const router = createRouter({
  routeTree,
  defaultPreload: 'intent',
  defaultPreloadStaleTime: 0, // deixa a política de frescor com o TanStack Query
})
```

| ID | Regra |
| --- | --- |
| `TSR-NAV-07` | `preload="render"` **NEVER** é aplicado a link dentro de lista de tamanho não limitado — cada link monta e dispara o loader do destino. |
| `TSR-NAV-08` | Se o `loader` usa TanStack Query, `defaultPreloadStaleTime` **MUST** ser `0`, para que o frescor seja decidido em um cache só. **Apelido de `TSR-LOAD-14`** — em revisão, cite o canônico. |

---

## 5. Navegação imperativa

```tsx
function Component() {
  const navigate = useNavigate({ from: '/posts/$postId' })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const response = await fetch('/posts', {
      method: 'POST',
      body: JSON.stringify({ title: 'My First Post' }),
    })
    const { id: postId } = await response.json()
    if (response.ok) {
      navigate({ to: '/posts/$postId', params: { postId } })
    }
  }
}
```

> "While this is also possible to pass in the resulting `navigate` function each time you call it, it's recommended to pass it here to reduce on potential error."

Três variantes, com propósitos distintos:

| API | Quando |
| --- | --- |
| `useNavigate({ from })` | dentro de componente, navegação como efeito colateral |
| `<Navigate to="..." />` | redirect client-only no mount de um componente |
| `router.navigate({ ... })` | fora do React — interceptor de HTTP, listener de websocket, código de terceiros |

Sobre `<Navigate>`:

> "Think of the `Navigate` component as a way to navigate to a route immediately when a component mounts. It's a great way to handle client-only redirects. It is _definitely not_ a substitute for handling server-aware redirects responsibly on the server."

Sobre `router.navigate`:

> "Unlike the `useNavigate` hook, it is available anywhere your `router` instance is available and is thus a great way to navigate imperatively from anywhere in your application, including outside of your framework."

### Opções que mudam o histórico

| Opção | Uso |
| --- | --- |
| `replace` | "Determines whether the navigation should replace the current history entry or push a new one." |
| `resetScroll` | "Determines whether scroll position will be reset to 0,0." |
| `hashScrollIntoView` | "Determines whether an id matching the hash will be scrolled into view." |
| `viewTransition` | "Determines if and how the browser will call document.startViewTransition()." |
| `ignoreBlocker` | "Determines if navigation should ignore any blockers." |
| `reloadDocument` | "Determines if navigation will trigger a full page load." |
| `href` | "Can be used in place of `to` to navigate to a full built href." |

| ID | Regra |
| --- | --- |
| `TSR-NAV-09` | Navegação que consome a rota atual (pós-login, pós-submit de wizard, redirect de rota intermediária) **MUST** usar `replace: true` — senão o botão voltar devolve o usuário a um estado já consumido. |

---

## 6. `redirect()` em `beforeLoad` e `loader`

A parte que mais gera bug silencioso: **`redirect()` por padrão não redireciona sozinho.**

> "If `throw` is `true`, the `Redirect` object will be thrown from within the function call."

> "If `throw` is `false | undefined`, the `Redirect` object will be returned."

Como o default é retornar, escrever `redirect({ to: '/login' })` como statement solto em `beforeLoad` não faz nada — cria um objeto e o descarta. As duas formas corretas são `throw redirect({ ... })` ou `redirect({ ..., throw: true })`.

```tsx
export const Route = createFileRoute('/_authed')({
  beforeLoad: ({ context, location }) => {
    if (!context.auth.isAuthenticated) {
      throw redirect({
        to: '/login',
        search: {
          redirect: location.href,
        },
      })
    }
  },
})
```

O `search.redirect` guardando `location.href` é o padrão da própria documentação para retomar o destino depois do login — e é search param cumprindo a função de estado ([TanStack Router - Search Params](tanstack-router-search-params.md)).

Dentro de `try/catch`, o redirect vira exceção capturada pelo seu próprio tratamento de erro. Reencaminhe:

```tsx
try {
  const user = await verifySession()
  if (!user) {
    throw redirect({
      to: '/login',
      search: { redirect: location.href },
    })
  }
  return { user }
} catch (error) {
  if (isRedirect(error)) throw error
  // trata falhas de autenticação de verdade
}
```

Existem ainda `Route.redirect` e `getRouteApi().redirect`, que a fonte apresenta como preferíveis ao `redirect` avulso por type safety e resolução automática de path.

E o limite de tudo isso:

> "None of these APIs are a replacement for server-side redirects. If you need to redirect a user immediately from one route to another before mounting your application, use a server-side redirect instead of a client-side navigation."

| ID | Regra |
| --- | --- |
| `TSR-NAV-10` | `redirect()` **MUST** ser lançado (`throw redirect(...)`) ou receber `throw: true` — chamada sem isso é no-op. |
| `TSR-NAV-11` | `try/catch` em volta de código que chama `redirect` **MUST** re-lançar quando `isRedirect(error)` for verdadeiro. |
| `TSR-NAV-12` | Controle de acesso **NEVER** existe apenas como redirect client-side — o dado protegido continua sendo servido se o servidor não negar. |

---

## 7. Ler o estado do roteador

### `useRouter` e a armadilha de `router.state`

```tsx
const router = useRouter()
```

> "`router.state` is always up to date, but NOT REACTIVE. If you use `router.state` in a component, the component will not re-render when the router state changes."

Para estado reativo a fonte manda usar `useRouterState`. `useRouter` serve para a instância: `router.navigate`, `router.matchRoute`, `router.invalidate`.

| ID | Regra |
| --- | --- |
| `TSR-NAV-13` | `router.state` **NEVER** é lido durante o render para derivar UI — use `useRouterState`, `useMatch` ou `useMatches`. |

### `useMatch` e `useMatches`

```tsx
const matches = useMatches()
//     ^? [RouteMatch, RouteMatch, ...]
```

`useMatches` devolve "the router's complete presented array of `RouteMatch` objects **regardless of its caller's position in the component tree**" — é o que faz breadcrumb funcionar de qualquer lugar. Com o caveat: o array "can include still-loading descendants or matches below a pending/error/not-found render boundary". Para recortes hierárquicos existem `useParentMatches` e `useChildMatches`.

Ambos os hooks aceitam o mesmo par de opções de leitura seletiva:

| Opção | Em `useMatch` | Em `useMatches` |
| --- | --- | --- |
| `from` | route id do match; "Optional, but recommended for full type safety" | — |
| `strict` | `default: true`; `false` afrouxa os tipos | — |
| `shouldThrow` | `default: true`; "If `false`, `useMatch` will not throw an invariant exception in case a match was not found" | — |
| `select` | `(match: RouteMatch) => TSelected` | `(matches: RouteMatch[]) => TSelected` |
| `structuralSharing` | "Configures whether structural sharing is enabled for the value returned by `select`" | idem |

### `useMatchRoute` vs `router.matchRoute`

```tsx
<Link to="/users">
  Users
  <MatchRoute to="/users" pending>
    <Spinner />
  </MatchRoute>
</Link>
```

> "The `matchRoute` function returned by `useMatchRoute` changes identity when the relevant router state changes. If you only need to check the route at the time an event occurs, use the stable router instance returned by `useRouter` and call `router.matchRoute` directly."

```tsx
function Component() {
  const router = useRouter()

  return (
    <button
      onClick={() => {
        if (router.matchRoute({ to: '/users' }, { fuzzy: true })) {
          console.info('The users route is active')
        }
      }}
    >
      Check current route
    </button>
  )
}
```

| ID | Regra |
| --- | --- |
| `TSR-NAV-14` | Checagem de rota dentro de event handler ou dependência de efeito **MUST** usar `router.matchRoute` — `useMatchRoute` troca de identidade a cada mudança de estado relevante. |

---

## 8. Bloqueio de navegação

```tsx
import { useBlocker } from '@tanstack/react-router'

function MyComponent() {
  const [formIsDirty, setFormIsDirty] = useState(false)

  useBlocker({
    shouldBlockFn: () => {
      if (!formIsDirty) return false

      const shouldLeave = confirm('Are you sure you want to leave?')
      return !shouldLeave
    },
  })

  // ...
}
```

Com `withResolver: true` o hook devolve `{ proceed, reset, status }`, para UI própria em vez de `confirm()` nativo:

```tsx
function MyComponent() {
  const { proceed, reset, status } = useBlocker({
    shouldBlockFn: ({ current, next }) => {
      return (
        current.routeId === '/foo' &&
        next.fullPath === '/bar/$id' &&
        next.params.id === 123 &&
        next.search.hello === 'world'
      )
    },
    withResolver: true,
  })

  // ...
}
```

`status === 'blocked'` é o gatilho para renderizar o diálogo; `proceed()` libera, `reset()` cancela. O componente `<Block>` oferece o mesmo com render props.

### Ambiguidade na fonte — leia com cuidado

A página descreve o retorno assim:

> "If any blocker function resolves or returns `true`, the navigation will be allowed and all other blockers will continue to do the same until all blockers have been allowed to proceed."

> "If any single blocker resolves or returns `false`, the navigation will be canceled and the rest of the `blocker` functions will be ignored."

Isso contradiz o nome da opção e o exemplo oficial da mesma página, onde `return false` quando o formulário está limpo **permite** sair, e `return !shouldLeave` **bloqueia** quando o usuário cancela o `confirm`. Os dois exemplos de código só fazem sentido com a leitura "`true` bloqueia" — a prosa citada acima parece descrever a semântica do `blockerFn` antigo. Trate `shouldBlockFn` como o nome diz e confirme no comportamento observado antes de inverter qualquer condição.

Sobre saída do documento (fechar aba, recarregar):

> "even if `shouldBlockFn` returns `false`, the browser's `beforeunload` event may still be triggered on page reloads or tab closing."

`enableBeforeUnload` aceita boolean ou função para condicionar esse registro.

> **Não verificado:** o valor default de `enableBeforeUnload` e o comportamento exato de `disabled` não estão detalhados na página consultada.

E o escape: `navigate({ ..., ignoreBlocker: true })` passa por cima dos blockers — necessário justamente na navegação que o próprio fluxo dispara depois de salvar.

| ID | Regra |
| --- | --- |
| `TSR-NAV-15` | Formulário com alteração não salva **MUST** bloquear tanto navegação interna (`shouldBlockFn`) quanto saída do documento (`enableBeforeUnload`) — são dois canais distintos. |
| `TSR-NAV-16` | A navegação disparada pelo próprio fluxo depois de salvar **MUST** usar `ignoreBlocker: true`, ou o usuário verá o diálogo de descarte no caminho feliz. |

---

## 9. Route masking

Mostrar uma URL na barra de endereço e navegar para outra. O caso canônico é modal: a rota real é `/photos/$photoId/modal`, a URL exibida é `/photos/$photoId`.

```tsx
<Link
  to="/photos/$photoId/modal"
  params={{ photoId: 5 }}
  mask={{
    to: '/photos/$photoId',
    params: { photoId: 5 },
  }}
>
  Open Photo
</Link>
```

```tsx
navigate({
  to: '/photos/$photoId/modal',
  params: { photoId: 5 },
  mask: {
    to: '/photos/$photoId',
    params: { photoId: 5 },
  },
})
```

Declarativo, no nível do router:

```tsx
const photoModalToPhotoMask = createRouteMask({
  routeTree,
  from: '/photos/$photoId/modal',
  to: '/photos/$photoId',
  params: (prev) => ({
    photoId: prev.photoId,
  }),
})

const router = createRouter({
  routeTree,
  routeMasks: [photoModalToPhotoMask],
})
```

**Como funciona e o que isso implica.** A location real fica no `location.state` do history, sob `__tempLocation`; a URL original permanece em `location.maskedLocation`. Duas consequências diretas: compartilhar o link desmascara (o state não viaja junto), e recarregar a página **não** desmascara por padrão, porque o state sobrevive no history. Para desmascarar no reload existe `unmaskOnReload`, disponível em três níveis de prioridade: opção default do router, retorno de `createRouteMask()`, e prop direta em `<Link>`/`navigate()`.

| ID | Regra |
| --- | --- |
| `TSR-NAV-17` | Máscara **NEVER** é usada para ocultar informação sensível da URL — o link compartilhado abre a rota real, sem máscara. |

---

## 10. `linkOptions`

Objeto literal de navegação só é verificado quando espalhado dentro de `Link`. Fora disso, passa batido:

> `linkOptions` "type checks an object literal and returns the inferred input as is. This provides type safety on options exactly like `Link` before it is used allowing for easier maintenance and re-usability."

```tsx
const dashboardLinkOptions = linkOptions({
  to: '/dashboard',
  search: { search: '' },
})

function DashboardComponent() {
  return <Link {...dashboardLinkOptions} />
}
```

Aceita array, preservando propriedades extras que não existem em `Link` — o formato natural para menus:

```tsx
const options = linkOptions([
  { to: '/dashboard', label: 'Summary', activeOptions: { exact: true } },
  { to: '/dashboard/invoices', label: 'Invoices' },
  { to: '/dashboard/users', label: 'Users' },
])
```

| ID | Regra |
| --- | --- |
| `TSR-NAV-18` | Objeto de navegação declarado fora do JSX (menus, constantes, config) **MUST** passar por `linkOptions` — sem ele o destino não é verificado até o spread. |

---

## Antipadrões

```tsx
// ERRADO — string interpolada: o tipo degrada para string,
// destino inválido deixa de ser erro de compilação
<Link to={`/posts/${post.id}`}>{post.title}</Link>

// CERTO
<Link to="/posts/$postId" params={{ postId: post.id }}>{post.title}</Link>
```

```tsx
// ERRADO — perde href, ctrl+clique, nova aba, papel de link e preload
<button onClick={() => navigate({ to: '/posts/$postId', params: { postId } })}>
  Ver post
</button>

// CERTO
<Link to="/posts/$postId" params={{ postId }}>Ver post</Link>
```

```tsx
// ERRADO — sem from, ".." sobe a partir de "/", não da rota atual
<Link to="..">Voltar</Link>

// CERTO
<Link from={Route.fullPath} to="..">Voltar</Link>
```

```tsx
// ERRADO — redirect() sem throw retorna um objeto e é descartado
beforeLoad: ({ context }) => {
  if (!context.auth.isAuthenticated) {
    redirect({ to: '/login' })
  }
}

// CERTO
beforeLoad: ({ context, location }) => {
  if (!context.auth.isAuthenticated) {
    throw redirect({ to: '/login', search: { redirect: location.href } })
  }
}
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| `<Link to="/">Home</Link>` com estilo de ativo | `/` é prefixo de toda rota — fica sempre ativo | `activeOptions={{ exact: true }}` (`TSR-NAV-06`) |
| `defaultPreload: 'render'` global | dispara o loader de todo link montado, incluindo listas longas | `'intent'` como default, `'render'` pontual (`TSR-NAV-07`) |
| Ler `router.state.location` no render | `router.state` não é reativo — o componente não re-renderiza | `useRouterState` / `useMatch` (`TSR-NAV-13`) |
| `try/catch` engolindo `redirect` em `beforeLoad` | o redirect vira "erro tratado" e a navegação nunca acontece | `if (isRedirect(error)) throw error` (`TSR-NAV-11`) |
| `mask` para esconder id ou token da URL | o link compartilhado abre a rota real | não colocar o dado na rota (`TSR-NAV-17`) |
| Menu de navegação com objetos literais soltos | destinos inválidos só falham no spread, ou nem isso | `linkOptions` (`TSR-NAV-18`) |

---

## Checklist de revisão

- [ ] Nenhum `to` com template string ou concatenação? → `TSR-NAV-01`
- [ ] Todo alvo clicável de navegação é `<Link>`, não `button` + `navigate`? → `TSR-NAV-02`
- [ ] Todo `to` relativo tem `from`, e o `from` vem de `Route.fullPath`? → `TSR-NAV-03` / `TSR-NAV-04`
- [ ] Nada de markup ou estado ativo derivado de `hash` em app com SSR? → `TSR-NAV-05`
- [ ] Links para rotas-prefixo declaram `activeOptions={{ exact: true }}`? → `TSR-NAV-06`
- [ ] Nenhuma lista longa com `preload="render"`? → `TSR-NAV-07`
- [ ] Loader com TanStack Query acompanhado de `defaultPreloadStaleTime: 0`? → `TSR-NAV-08`
- [ ] Navegação que consome a rota atual usa `replace: true`? → `TSR-NAV-09`
- [ ] Todo `redirect()` é lançado, e todo `catch` re-lança `isRedirect`? → `TSR-NAV-10` / `TSR-NAV-11`
- [ ] O gate de acesso existe também no servidor? → `TSR-NAV-12`
- [ ] Nenhum `router.state` lido no render? → `TSR-NAV-13`
- [ ] Checagem de rota em handler usa `router.matchRoute`? → `TSR-NAV-14`
- [ ] Formulário sujo bloqueia navegação interna **e** `beforeunload`? → `TSR-NAV-15`
- [ ] A navegação pós-salvamento usa `ignoreBlocker: true`? → `TSR-NAV-16`
- [ ] Nenhuma máscara escondendo dado sensível? → `TSR-NAV-17`
- [ ] Objetos de navegação reutilizados passam por `linkOptions`? → `TSR-NAV-18`

---

## Relacionados

- [TanStack Router](tanstack-router.md) · [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · [TanStack Router - Search Params](tanstack-router-search-params.md)
- [TanStack Router - Route Matching](tanstack-router-route-matching.md) · [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) · [TanStack Router - Route Trees](tanstack-router-route-trees.md)
- [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) · [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md)
- [React - Patterns](react-patterns.md) (`REACT-PAT-10`: estado que sobrevive a refresh pertence à URL) · [React.js](react-js.md)

## Fontes consultadas

Verificadas em 2026-08-14:

- [Navigation](https://tanstack.com/router/latest/docs/framework/react/guide/navigation) — `ToOptions`, `NavigateOptions`, `LinkOptions`, `<Link>`, `useNavigate`, `<Navigate>`, `router.navigate`, `useMatchRoute`
- [Path Params](https://tanstack.com/router/latest/docs/framework/react/guide/path-params) · [Preloading](https://tanstack.com/router/latest/docs/framework/react/guide/preloading)
- [Navigation Blocking](https://tanstack.com/router/latest/docs/framework/react/guide/navigation-blocking) — prosa e exemplos divergem sobre o retorno de `shouldBlockFn` (§ 8)
- [Route Masking](https://tanstack.com/router/latest/docs/framework/react/guide/route-masking) · [Link Options](https://tanstack.com/router/latest/docs/framework/react/guide/link-options)
- [Authenticated Routes](https://tanstack.com/router/latest/docs/framework/react/guide/authenticated-routes) · [redirect](https://tanstack.com/router/latest/docs/framework/react/api/router/redirectFunction)
- [useRouter](https://tanstack.com/router/latest/docs/framework/react/api/router/useRouterHook) · [useMatch](https://tanstack.com/router/latest/docs/framework/react/api/router/useMatchHook) · [useMatches](https://tanstack.com/router/latest/docs/framework/react/api/router/useMatchesHook)
