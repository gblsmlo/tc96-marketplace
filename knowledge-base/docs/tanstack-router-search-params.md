---
Link: https://tanstack.com/router/latest/docs/framework/react/guide/search-params
tags:
 - tanstack-router
 - search-params
 - agent-context
source: "Documentação oficial — https://tanstack.com/router/latest/docs/framework/react/"
verificado-em: 2026-08-14
---

# TanStack Router - Search Params

> `validateSearch` · adapters (Zod, Valibot, ArkType, Effect/Schema) · `useSearch` · `getRouteApi.useSearch` · atualização por `<Link search>` e `navigate({ search })` · herança entre rotas · `search.middlewares` (`retainSearchParams`, `stripSearchParams`) · `parseSearchWith` / `stringifySearchWith`.
>
> Não cobre: `<Link>` e navegação imperativa em geral — [TanStack Router - Navegação](tanstack-router-navegacao.md); path params (`$id`, `{-$opt}`) e `params.parse` — [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md); uso de search no `loader` — [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md).

Entrada: [TanStack Router](tanstack-router.md) · Conceitos de rota: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Conceito: search param é estado de aplicação, não string na URL

É aqui que o TanStack Router se separa dos demais roteadores. Em quase todo router, search param é `string | null` vindo de `URLSearchParams`, e a aplicação faz `Number(params.get('page') ?? '1')` espalhado em cada componente que precisa. O TanStack Router trata a query string como **uma fatia tipada e validada do estado da aplicação**, com schema declarado na rota.

A troca vale a pena porque estado na URL ganha três propriedades que `useState` não tem:

- sobrevive a refresh e ao botão voltar;
- é compartilhável — o link reproduz a tela exata;
- é observável — o estado da UI está visível, não escondido em memória.

É exatamente o que `REACT-PAT-10` de [React - Patterns](react-patterns.md) normatiza ("estado que precisa sobreviver a refresh, ser compartilhável por link ou responder ao botão voltar **MUST** viver na URL"). Este satélite não cria um ID novo para o mesmo princípio: **`REACT-PAT-10` é a regra; o que segue é como cumpri-la com type safety.**

E a razão de existir validação, citada da fonte:

> "Despite TanStack Router being able to parse search params into reliable JSON, they ultimately still came from **a user-facing raw-text input**."

Qualquer pessoa pode digitar `?page=banana` na barra de endereço. Sem schema, isso vira `NaN` três componentes abaixo. Search param é entrada não confiável na fronteira do sistema — a mesma categoria de body de request e variável de ambiente. É a ponte direta com: o tipo TypeScript some em runtime, então quem garante a forma do valor é o schema, não a anotação.

### Serialização JSON-first

Diferente de `URLSearchParams`, o router serializa estruturas aninhadas automaticamente:

```tsx
search={{
 pageIndex: 3,
 includeCategories: ['electronics', 'gifts'],
 sortBy: 'price',
 desc: true,
}}
```

vira `/shop?pageIndex=3&includeCategories=%5B%22electronics%22%2C%22gifts%22%5D&sortBy=price&desc=true`.

O primeiro nível continua plano e compatível com `URLSearchParams`; valores aninhados viram strings JSON. Por isso `page` volta como `number` e `desc` como `boolean`, sem conversão manual.

| ID | Regra |
| --- | --- |
| `TSR-SEARCH-01` | Rota que lê search param **MUST** declarar `validateSearch` — sem schema não há tipo, não há default e não há garantia de forma. |
| `TSR-SEARCH-02` | `window.location.search`, `URLSearchParams` e `useSearchParams` de outra biblioteca **NEVER** são usados para ler search dentro de uma rota do router — a fonte é `useSearch`. |

---

## 2. `validateSearch`

Na forma mais crua, é só uma função de `Record<string, unknown>` para o tipo validado:

```tsx
type ProductSearchSortOptions = 'newest' | 'oldest' | 'price'

type ProductSearch = {
 page: number
 filter: string
 sort: ProductSearchSortOptions
}

export const Route = createFileRoute('/shop/products')({
 validateSearch: (search: Record<string, unknown>): ProductSearch => {
 return {
 page: Number(search?.page ?? 1),
 filter: (search.filter as string) || '',
 sort: (search.sort as ProductSearchSortOptions) || 'newest',
 }
 },
})
```

Repare no que o corpo dessa função faz: **todas as chaves têm comportamento definido para ausente e para inválido.** Não existe caminho em que `page` saia `undefined`. É isso que faz o tipo de saída ser confiável no resto da rota — e é a razão de a assinatura receber `Record<string, unknown>`, e não um objeto já tipado.

| ID | Regra |
| --- | --- |
| `TSR-SEARCH-03` | Toda chave do schema de search **MUST** definir comportamento para valor ausente e para valor inválido — `.catch`, `.default` ou fallback explícito. Schema que só descreve o caso feliz não valida nada. |

---

## 3. Adapters e Standard Schema

A escrita manual acima é didática; na prática o schema vem de uma biblioteca de validação.

```tsx
const productSearchSchema = z.object({
 page: z.number.catch(1),
 filter: z.string.catch(''),
 sort: z.enum(['newest', 'oldest', 'price']).catch('newest'),
})
```

**Zod v4, Valibot, ArkType e Effect/Schema** implementam Standard Schema e são aceitos diretamente:

```tsx
export const Route = createFileRoute('/shop/products/')({
 validateSearch: productSearchSchema,
})
```

**Zod v3** precisa do adapter:

```tsx
import { zodValidator } from '@tanstack/zod-adapter'

export const Route = createFileRoute('/shop/products/')({
 validateSearch: zodValidator(productSearchSchema),
})
```

### `.catch` ou `.default` — é uma decisão de produto

A fonte é explícita sobre o critério:

> "we used Zod's `.catch` modifier instead of `.default` to avoid showing an error to the user because we firmly believe that if a search parameter is malformed, you probably don't want to halt the user's experience through the app to show a big fat error message. That said, there may be times that you **do want to show an error message**. In that case, you can use `.default` instead of `.catch`."

Ou seja: `.catch` degrada silenciosamente para um valor sensato; `.default` só cobre a ausência, e um valor malformado sobe para o tratamento de erro da rota. Filtro de listagem quer `.catch`. Parâmetro que muda o significado da página — o id de um recurso, o modo de um formulário — provavelmente quer o erro visível.

### A pegadinha do Zod v3

> "In Zod v3, the use of `catch` here overrides the types and makes `page`, `filter` and `sort` `unknown` causing type loss. We have handled this case by providing a `fallback` generic function which retains the types but provides a `fallback` value when validation fails"

```tsx
import { fallback, zodValidator } from '@tanstack/zod-adapter'

const productSearchSchema = z.object({
 page: fallback(z.number, 1).default(1),
 filter: fallback(z.string, '').default(''),
 sort: fallback(z.enum(['newest', 'oldest', 'price']), 'newest').default('newest'),
})
```

O sintoma de esquecer isso é sutil: nada quebra, o schema funciona, e o `useSearch` passa a devolver `unknown` — o que faz o TypeScript parar de reclamar de uso errado, exatamente o oposto do que se queria.

> **Não verificado:** a configuração de `input`/`output` divergentes no adapter. A fonte menciona que "it is also possible to configure `input` and `output` type in case the `output` type is more accurate than the `input` type", sem que a assinatura completa apareça na página consultada.

| ID | Regra |
| --- | --- |
| `TSR-SEARCH-04` | A escolha entre `.catch` e `.default` **MUST** ser deliberada: `.catch` quando um valor malformado deve degradar em silêncio; `.default` quando ele deve virar erro visível. |
| `TSR-SEARCH-05` | Com Zod v3, `.catch` no schema de search **NEVER** aparece sem `fallback` do `@tanstack/zod-adapter` — o tipo colapsa para `unknown`. |
| `TSR-SEARCH-06` | Zod v3 **MUST** passar por `zodValidator`; bibliotecas que implementam Standard Schema (Zod v4, Valibot, ArkType, Effect/Schema) **MUST** ser passadas direto, sem wrapper. |

---

## 4. Ler: `useSearch`

Dentro da rota que declarou o schema:

```tsx
const ProductList = => {
 const { page, filter, sort } = Route.useSearch
 // ^? number, string, 'newest' | 'oldest' | 'price'
 return <div>...</div>
}
```

Em componente que não pode importar a `Route` (arquivo separado, componente de biblioteca interna), `getRouteApi` dá o mesmo tipo sem o import circular:

```tsx
import { getRouteApi } from '@tanstack/react-router'

const routeApi = getRouteApi('/shop/products')

const ProductList = => {
 const routeSearch = routeApi.useSearch
}
```

Opções do hook:

| Opção | Tipo | Comportamento |
| --- | --- | --- |
| `from` | `string` | "The RouteID to match the search query parameters from" — obrigatório na forma estrita |
| `strict` | `boolean` (`default: true`) | "If `false`, the `opts.from` option will be ignored and types will be loosened to `Partial<FullSearchSchema>`" |
| `shouldThrow` | `boolean` (`default: true`) | "If `false`, `useSearch` will not throw an invariant exception in case a match was not found" |
| `select` | `(search) => TSelected` | "If supplied, this function will be called with the search object and the return value will be returned" |
| `structuralSharing` | `boolean` | "Configures whether structural sharing is enabled for the value returned by `select`" |

`select` não é só conveniência de sintaxe: reduz o que o componente observa, e com `structuralSharing` evita re-render quando outra chave do search muda.

```tsx
// só re-renderiza quando `page` muda
const page = Route.useSearch({ select: (search) => search.page })
```

`strict: false` é a válvula de escape para componentes genuinamente genéricos — um `<Pagination>` usado em várias rotas. O preço é `Partial<...>`: tudo vira opcional, e o componente precisa lidar com ausência.

---

## 5. Herança entre rotas

Rotas filhas enxergam o search validado pelos ancestrais, com os tipos mesclados:

```tsx
export const Route = createFileRoute('/shop/products/$productId')({
 beforeLoad: ({ search }) => {
 search // ProductSearch — herdado da rota pai
 },
})
```

Isso tem uma consequência de design: **onde você declara o `validateSearch` define o escopo do estado.** Um filtro declarado em `/shop/products` existe para toda a subárvore; declarado na raiz, existe no app inteiro. Não é acidente que os middlewares de retenção (§ 7) vivam no mesmo lugar do schema — escopo e política de propagação são a mesma decisão.

---

## 6. Atualizar: objeto substitui, função mescla

A distinção mais fácil de errar da API inteira.

```tsx
// forma objeto — define o search resultante
<Link from={Route.fullPath} search={{ page: 2, filter: 'new' }}>
 Next Page
</Link>

// forma funcional — parte do search atual
<Link from={Route.fullPath} search={(prev) => ({...prev, page: prev.page + 1 })}>
 Next Page
</Link>
```

Em componente genérico, `to="."` mantém a rota atual e mexe só no estado:

```tsx
<Link to="." search={(prev) => ({...prev, page: prev.page + 1 })}>
 Next Page
</Link>
```

Imperativo, mesmo objeto:

```tsx
const navigate = useNavigate({ from: Route.fullPath })

navigate({
 search: (prev) => ({ page: prev.page + 1 }),
})
```

```tsx
router.navigate({ search: (prev) => ({...prev, page: 2 }) })
```

Repare que o penúltimo exemplo, tirado da própria documentação, **não** espalha `prev`: `search: (prev) => ({ page: prev.page + 1 })` descarta `filter` e `sort`. Isso é intencional quando você quer resetar os demais filtros ao paginar — e é bug quando não quer. A forma funcional não mescla sozinha; ela apenas te dá acesso ao valor anterior.

O aviso da fonte sobre tipos:

> "Search params are a highly dynamic state management mechanism, so it's important to ensure that you are passing the correct types."

| ID | Regra |
| --- | --- |
| `TSR-SEARCH-07` | Atualização de uma única chave do search **MUST** usar a forma funcional com spread (`(prev) => ({...prev, page })`) — objeto literal e função sem spread substituem o search inteiro. |
| `TSR-SEARCH-08` | Componente reutilizado por várias rotas **MUST** navegar com `to="."` e forma funcional, **NEVER** com o path da rota escrito à mão. |
| `TSR-SEARCH-09` | Valor que já vive no search **NEVER** é copiado para `useState` — apelido de `REACT-PAT-01` e `REACT-PAT-03` em [React - Patterns](react-patterns.md). Duas fontes de verdade divergem no botão voltar. |
| `TSR-SEARCH-10` | Token, credencial, id de sessão e dado pessoal **NEVER** entram em search param — a URL vai para histórico, log de servidor, `Referer` e link compartilhado. |

---

## 7. Search middlewares

Middlewares transformam o search **na geração de links**, antes de a URL ser construída. Resolvem o problema de "esse parâmetro precisa acompanhar o usuário por toda a navegação" sem espalhar `search={(prev) =>...}` em cada `<Link>`.

```tsx
export const Route = createRootRoute({
 validateSearch: zodValidator(searchSchema),
 search: {
 middlewares: [
 ({ search, next }) => {
 const result = next(search)
 return { rootValue: search.rootValue,...result }
 },
 ],
 },
})
```

Dois middlewares prontos cobrem a maioria dos casos.

### `retainSearchParams`

> "The `retainSearchParams` either accepts `true` or a list of keys of those search params that shall be retained. If `true` is passed in, all search params will be retained."

```tsx
search: {
 middlewares: [retainSearchParams(['rootValue'])],
}
```

```tsx
search: {
 middlewares: [retainSearchParams(true)],
}
```

Caso típico: `?tenant=` ou `?locale=` que não pode sumir ao clicar em qualquer link.

### `stripSearchParams`

Três formas de entrada:

1. `true` — "if the search schema has no required params, `true` can be used to strip all search params";
2. array de chaves — "a list of keys of those search params that shall be removed; only keys of optional search params are allowed";
3. objeto — "an object that conforms to the partial input search schema. The search params are compared against the values of this object; if the value is deeply equal, it will be removed".

```tsx
// remove os params que estão no valor default — URL limpa quando nada foi filtrado
search: { middlewares: [stripSearchParams({ one: 'abc', two: 'xyz' })] }

// remove sempre uma chave opcional
search: { middlewares: [stripSearchParams(['hello'])] }

// remove tudo (só quando o schema não tem chave obrigatória)
search: { middlewares: [stripSearchParams(true)] }
```

A terceira forma é o que produz URLs limpas sem perder defaults: `/shop/products` em vez de `/shop/products?page=1&filter=&sort=newest`. Mas ela acopla o middleware ao schema — se o default do schema virar `sort: 'price'` e o `stripSearchParams` continuar com `'newest'`, a URL passa a carregar `?sort=newest` como se fosse escolha do usuário.

| ID | Regra |
| --- | --- |
| `TSR-SEARCH-11` | Middleware que retém ou remove uma chave **MUST** ser declarado na mesma rota que valida essa chave — o escopo do schema é o escopo da política. |
| `TSR-SEARCH-12` | Os valores passados a `stripSearchParams({... })` **MUST** ser exatamente os defaults do schema. Divergência transforma o default antigo em parâmetro explícito na URL. |
| `TSR-SEARCH-13` | `stripSearchParams` com array **MUST** listar apenas chaves opcionais, e a forma `true` **MUST** ser usada só quando o schema não tem chave obrigatória. |

---

## 8. Serialização customizada

O router expõe `parseSearch` e `stringifySearch` nas opções, com os helpers `parseSearchWith` e `stringifySearchWith`. O default é `JSON.parse` / `JSON.stringify`:

```tsx
const search = {
 page: 1,
 sort: 'asc',
 filters: { author: 'tanner', min_words: 800 },
}
```

produz `?page=1&sort=asc&filters=%7B%22author%22%3A%22tanner%22%2C%22min_words%22%3A800%7D`.

Alternativas documentadas, com o mesmo objeto acima:

| Estratégia | Resultado |
| --- | --- |
| Base64 | `?page=1&sort=asc&filters=eyJhdXRob3IiOiJ0YW5uZXIiLCJtaW5fd29yZHMiOjgwMH0%3D` |
| `query-string` | `?page=1&sort=asc&filters=author%3Dtanner%26min_words%3D800` |
| JSURL2 | `?page=1&sort=asc&filters=(author~tanner~min*_words~800)~` |
| Zipson | `?page=1&sort=asc&filters=JTdCJUMyJUE4YXV0aG9y...` (comprimido) |

```tsx
const router = createRouter({
 routeTree,
 parseSearch: parseSearchWith(JSON.parse),
 stringifySearch: stringifySearchWith(JSON.stringify),
})
```

Os dois avisos da fonte:

> "If you are serializing user input into Base64, you run the risk of causing a collision with the URL deserialization."

E sobre `atob`/`btoa`: as funções nativas do browser "aren't guaranteed to work properly with non-UTF8 characters"; a documentação fornece utilitários de codificação seguros no lugar delas.

O custo estrutural raramente aparece na discussão: **a serialização faz parte do contrato público das suas URLs.** Links compartilhados, bookmarks, itens de histórico e URLs em e-mails ficam gravados no formato antigo. Trocar `JSON` por JSURL2 depois do lançamento quebra todos eles de uma vez, e o sintoma é `validateSearch` caindo no fallback.

| ID | Regra |
| --- | --- |
| `TSR-SEARCH-14` | `parseSearch`/`stringifySearch` **MUST** ser decididos uma única vez, no `createRouter`, antes de a aplicação ir a público — a serialização é contrato de URLs já compartilhadas. |
| `TSR-SEARCH-15` | Base64 **NEVER** é aplicado sobre input de usuário na URL (risco de colisão na desserialização), e `atob`/`btoa` nativos **NEVER** são usados como codificador — use os utilitários seguros documentados. |

---

## 9. Caso completo: `redirect` de retorno pós-login

O padrão mais comum de search param carregando estado de navegação — e o único em que um search param vira **superfície de ataque**.

A guarda escreve o destino ao barrar o acesso:

```tsx
// routes/_authenticated.tsx
beforeLoad: ({ context, location }) => {
 if (!context.auth.isAuthenticated) {
 throw redirect({ to: '/login', search: { redirect: location.href } })
 }
}
```

A rota `/login` precisa **validar essa chave como qualquer outra** — inclusive definindo o comportamento para ausente e para inválido (`TSR-SEARCH-03`):

```tsx
// routes/login.tsx
const rotaInternaSegura = z
.string
.refine((v) => v.startsWith('/') && !v.startsWith('//'), 'destino externo')
.catch('/')

export const Route = createFileRoute('/login')({
 validateSearch: zodValidator(z.object({ redirect: fallback(rotaInternaSegura, '/') })),
})

function Login {
 const { redirect: destino } = Route.useSearch
 const navigate = useNavigate

 async function aoEntrar(credenciais: Credenciais) {
 await autenticar(credenciais)
 navigate({ to: destino, replace: true }) // replace: TSR-NAV-09
 }
}
```

**Por que o `refine` não é opcional.** `redirect` é entrada controlada pelo usuário: qualquer pessoa monta `/login?redirect=https://evil.example/phish` e manda o link. Sem validação, sua tela de login legítima despeja o usuário autenticado num domínio de terceiros — é **open redirect**, e o fato de o valor vir "do seu próprio router" não o torna confiável.

Os dois testes que o `refine` faz: começa com `/` (caminho interno) e **não** começa com `//` (que o browser interpreta como protocol-relative URL, ou seja, host externo). Rejeitar só pelo primeiro teste deixa o buraco aberto.

| ID | Regra |
| --- | --- |
| `TSR-SEARCH-16` | Search param que vira destino de navegação **MUST** ser validado como caminho interno — começa com `/` e não com `//` — antes de ser usado. Sem isso, é open redirect. |
| `TSR-SEARCH-17` | Navegação que consome um destino guardado **MUST** ter fallback definido para valor ausente ou rejeitado, nunca navegar para `undefined`. |

> **Não verificado:** se `location.href` dentro de `beforeLoad` é o href relativo do router ou o absoluto do browser. A validação de `TSR-SEARCH-16` cobre os dois casos — um href absoluto do próprio origin seria rejeitado pelo `refine` e cairia no fallback, o que é seguro, ainda que perca o destino. Confirme o formato antes de relaxar a regra.

---

## Antipadrões

```tsx
// ERRADO — o search vira "unknown" na leitura e nenhum uso errado é detectado (Zod v3)
const schema = z.object({ page: z.number.catch(1) })
export const Route = createFileRoute('/shop')({ validateSearch: zodValidator(schema) })

// CERTO — fallback preserva o tipo
const schema = z.object({ page: fallback(z.number, 1).default(1) })
```

```tsx
// ERRADO — objeto literal descarta filter e sort ao paginar
<Link to="." search={{ page: page + 1 }}>Próxima</Link>

// CERTO
<Link to="." search={(prev) => ({...prev, page: prev.page + 1 })}>Próxima</Link>
```

```tsx
// ERRADO — duas fontes de verdade: o botão voltar muda a URL e o estado local fica velho
const [page, setPage] = useState(1)
const search = Route.useSearch
useEffect( => setPage(search.page), [search.page])

// CERTO — a URL é o estado
const { page } = Route.useSearch
const navigate = useNavigate({ from: Route.fullPath })
const setPage = (page: number) => navigate({ search: (prev) => ({...prev, page }) })
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| Ler `new URLSearchParams(location.search)` na rota | ignora schema, tipos e reatividade do router | `useSearch` (`TSR-SEARCH-02`) |
| Schema sem `.catch`/`.default` nas chaves | `?page=banana` chega como `NaN` no componente | comportamento explícito por chave (`TSR-SEARCH-03`) |
| `validateSearch` tipando o argumento como já validado | a função existe justamente para converter `unknown` | assinatura `(search: Record<string, unknown>)` |
| `stripSearchParams` com defaults dessincronizados do schema | o default antigo vaza para a URL como escolha explícita | espelhar os defaults (`TSR-SEARCH-12`) |
| Guardar `?token=` ou `?email=` para "passar entre telas" | URL vai para histórico, logs e `Referer` | contexto de rota ou `state` (`TSR-SEARCH-10`) |
| Trocar a serialização depois do lançamento | URLs compartilhadas param de desserializar | decidir uma vez (`TSR-SEARCH-14`) |

---

## Checklist de revisão

- [ ] Toda rota que lê search declara `validateSearch`? → `TSR-SEARCH-01`
- [ ] Nenhuma leitura por `URLSearchParams` ou `window.location.search`? → `TSR-SEARCH-02`
- [ ] Toda chave do schema trata ausência **e** valor inválido? → `TSR-SEARCH-03`
- [ ] A escolha `.catch` vs `.default` é deliberada por chave? → `TSR-SEARCH-04`
- [ ] Zod v3 usa `fallback` junto de `.catch`? → `TSR-SEARCH-05`
- [ ] Zod v3 passa por `zodValidator`; Standard Schema entra direto? → `TSR-SEARCH-06`
- [ ] Toda atualização parcial usa `(prev) => ({...prev,... })`? → `TSR-SEARCH-07`
- [ ] Componentes genéricos navegam com `to="."`? → `TSR-SEARCH-08`
- [ ] Nenhum `useState` espelhando valor do search? → `TSR-SEARCH-09`
- [ ] Nenhum dado sensível na query string? → `TSR-SEARCH-10`
- [ ] Middlewares declarados na rota dona do schema? → `TSR-SEARCH-11`
- [ ] `stripSearchParams` espelha os defaults e usa só chaves opcionais? → `TSR-SEARCH-12` / `TSR-SEARCH-13`
- [ ] Serialização definida uma vez, sem Base64 sobre input de usuário? → `TSR-SEARCH-14` / `TSR-SEARCH-15`

---

## Relacionados

- [TanStack Router](tanstack-router.md) · [TanStack Router - Navegação](tanstack-router-navegacao.md) · [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)
- [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) · [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md)
- — search param é entrada de fronteira: o tipo TypeScript não existe em runtime
- [React - Patterns](react-patterns.md) (`REACT-PAT-10`, `REACT-PAT-01`, `REACT-PAT-03`) · [React.js](react-js.md)
- — search descreve *o que* pedir; a Query cuida do *dado* que volta

## Fontes consultadas

Verificadas em 2026-08-14:

- [Search Params](https://tanstack.com/router/latest/docs/framework/react/guide/search-params) — `validateSearch`, adapters, `useSearch`, herança, middlewares, `.catch` vs `.default`, `fallback`
- [Custom Search Param Serialization](https://tanstack.com/router/latest/docs/framework/react/guide/custom-search-param-serialization) — `parseSearchWith`/`stringifySearchWith` e avisos sobre Base64
- [retainSearchParams](https://tanstack.com/router/latest/docs/framework/react/api/router/retainSearchParamsFunction) · [stripSearchParams](https://tanstack.com/router/latest/docs/framework/react/api/router/stripSearchParamsFunction)
- [useSearch](https://tanstack.com/router/latest/docs/framework/react/api/router/useSearchHook)
- [Navigation](https://tanstack.com/router/latest/docs/framework/react/guide/navigation) — forma objeto vs funcional em `<Link search>`
