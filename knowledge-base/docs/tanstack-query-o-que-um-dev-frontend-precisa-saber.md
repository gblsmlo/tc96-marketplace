---
titulo: TanStack Query - O que um Dev Frontend Precisa Saber
Link: https://tanstack.com/query/latest/docs/framework/react/overview
tags:
 - tanstack-query
 - fundamentos
 - data-fetching
 - agent-context
source: "Documentação oficial — https://tanstack.com/query/latest/docs/framework/react"
verificado-em: 2026-08-14
---

# TanStack Query - O que um Dev Frontend Precisa Saber

> Estado do servidor vs. estado de cliente · setup e `QueryClient` · `queryKey` · `queryFn` e `QueryFunctionContext` · `status` × `fetchStatus` · defaults agressivos · `queryOptions` e tipagem · Devtools.
>
> **Não cobre:** política de frescor e ciclo de vida do cache ([TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md)) · escrita e invalidação ([TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md)) · dependentes, paginadas, infinitas, prefetch e `select` ([TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md)) · Suspense, hidratação, cancelamento e network mode ([TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md)).

Entrada: [TanStack Query](tanstack-query.md)

---

## Versão coberta

Verificado em **2026-08-14** no registry npm: `@tanstack/react-query` tem `dist-tags.latest = 5.101.4`. **A v5 continua sendo a versão corrente e estável.** A v6 existe apenas como pré-release (`6.0.0-beta.8`, agosto/2026) e não está publicada sob a tag `latest`. As páginas em `tanstack.com/query/latest` correspondem à v5 — `/latest/...` e `/v5/...` devolvem o mesmo conteúdo.

> Consequência prática: não escreva código contra a v6. Mas "é v5" não basta como garantia — algumas assinaturas que circulam como v5 já estão desatualizadas **dentro** da v5. O caso concreto são os callbacks de mutation: ver [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) § 2.

---

## 1. Conceito: o dado remoto não é seu

A documentação abre com a definição funcional:

> "TanStack Query (formerly known as React Query) is often described as the missing data-fetching library for web applications, but in more technical terms, it makes **fetching, caching, synchronizing and updating server state** in your web applications a breeze."

O termo que carrega o peso é **server state**. A fonte lista quatro características dele:

> - "Is persisted remotely in a location you may not control or own"
> - "Requires asynchronous APIs for fetching and updating"
> - "Implies shared ownership and can be changed by other people without your knowledge"
> - "Can potentially become 'out of date' in your applications if you're not careful"

Nenhuma dessas quatro é verdade para estado de cliente. Um menu aberto não tem propriedade compartilhada; uma preferência de tema não fica desatualizada porque outra pessoa mexeu nela. É por isso que guardar resposta de API em `useState` ou em store de cliente não é "uma escolha diferente" — é aplicar a ferramenta errada ao problema. O raciocínio completo está em e.

**Este princípio já tem ID canônico no vault: `REACT-PAT-03`** ("Dado remoto **NEVER** é `useState` como fonte de verdade" — [React - Patterns](react-patterns.md)). Não crie um `TSQ-*` equivalente; cite `REACT-PAT-03`.

### O que a biblioteca assume ao tomar esse estado

A lista de desafios que a fonte diz resolver de fábrica:

> Caching · "Deduping multiple requests for the same data into a single request" · "Updating 'out of date' data in the background" · "Knowing when data is 'out of date'" · "Reflecting updates to data as quickly as possible" · "Performance optimizations like pagination and lazy loading data" · "Managing memory and garbage collection of server state" · "Memoizing query results with structural sharing"

Cada item dessa lista é uma coisa que um `useEffect` + `fetch` **não** faz — é o argumento inteiro de `REACT-EFFECT-06` em [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md).

### O que a biblioteca **não** faz

Ela coordena ciclo de vida e cache. Ela não valida a resposta. Uma API que mudou o contrato entrega dado errado com `status: 'success'` e tipagem otimista. A validação é sua, na `queryFn` — e.

---

## 2. Setup

```bash
npm i @tanstack/react-query
```

Compatibilidade declarada na fonte: *"React Query is compatible with React v18+ and works with ReactDOM and React Native."*

```tsx
import {
 QueryClient,
 QueryClientProvider,
 useQuery,
} from '@tanstack/react-query'

// Fora do render: uma instância por app no cliente.
const queryClient = new QueryClient({
 defaultOptions: {
 queries: {
 staleTime: 60_000, // decisão explícita — ver TSQ-CACHE-01
 },
 },
})

export function App {
 return (
 <QueryClientProvider client={queryClient}>
 <Repo />
 </QueryClientProvider>
 )
}
```

O `QueryClient` **é** o cache. Criá-lo dentro do corpo de um componente o recria a cada render e joga o cache fora junto. As duas formas corretas: módulo (SPA pura) ou `useState( => new QueryClient)` (quando o app pode remontar, ou quando há SSR). No servidor a regra é outra e mais forte — uma instância **por requisição** — ver [TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md) § 3.

> **Com TanStack Router**, criar em escopo de módulo continua correto; o que **NEVER** se faz é *ler* esse singleton dentro de `beforeLoad`/`loader`. Ali o `queryClient` precisa chegar pelo `context` do router (`TSR-CTX-05`), senão quebra em SSR. Crie no módulo **e** injete no `createRouter` — as duas docs não se contradizem: uma fala de criação, a outra de acesso. Ver [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md).

| ID | Regra |
| --- | --- |
| `TSQ-BASE-01` | O `QueryClient` **NEVER** é construído no corpo do render — use escopo de módulo ou `useState( => new QueryClient)`. |

---

## 3. Query Keys — a identidade do dado no cache

A key é o índice do cache e a unidade de invalidação. Duas afirmações literais da fonte:

> "Query keys have to be an Array at the top level, and can be as simple as an Array with a single string, or as complex as an array of many strings and nested objects."

> "As long as the query key is serializable using `JSON.stringify`, and **unique to the query's data**, you can use it!"

### Hashing determinístico, com uma assimetria

> "Query Keys are hashed deterministically! This means that no matter the order of keys in objects, all of the following queries are considered equal:"

```tsx
// EQUIVALENTES — ordem de chaves dentro de um objeto não importa,
// e `undefined` é descartado
useQuery({ queryKey: ['todos', { status, page }],... })
useQuery({ queryKey: ['todos', { page, status }],... })
useQuery({ queryKey: ['todos', { page, status, other: undefined }],... })
```

Mas:

> "Array item order matters!"

```tsx
// DIFERENTES — três entradas de cache distintas
useQuery({ queryKey: ['todos', status, page],... })
useQuery({ queryKey: ['todos', page, status],... })
useQuery({ queryKey: ['todos', undefined, page, status],... })
```

A assimetria é a fonte de bug mais comum: posições soltas no array são posicionais, objeto no array é comutativo. Por isso a hierarquia estável é `[entidade, escopo, parâmetros-como-objeto]` — `['todos', 'list', { page, status }]`. Ela é o que torna a invalidação por prefixo previsível ([TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) § 3).

### A regra que a fonte chama de fundamental

> "If your query function depends on a variable, include it in your query key" — "Adding dependent variables to your query key will ensure that queries are cached independently, and that any time a variable changes, *queries will be refetched automatically*."

```tsx
function Todo({ todoId }: { todoId: string }) {
 return useQuery({
 queryKey: ['todos', 'detail', todoId],
 queryFn: => fetchTodoById(todoId),
 })
}
```

Omitir `todoId` da key não causa erro visível de imediato: causa o pior tipo de bug, que é o item B exibindo os dados do item A porque ambos escrevem na mesma entrada de cache.

| ID | Regra |
| --- | --- |
| `TSQ-BASE-02` | Query key **MUST** ser array no nível superior, serializável por `JSON.stringify` e única para os dados daquela query. |
| `TSQ-BASE-03` | Toda variável lida pela `queryFn` **MUST** aparecer na `queryKey`. |

---

## 4. Query Functions

Qualquer função que devolve uma Promise. Três regras da fonte, todas com consequência silenciosa quando violadas.

### Erro precisa ser lançado

> "For TanStack Query to determine a query has errored, the query function **must throw** or return a **rejected Promise**."

`fetch` não rejeita em `404` ou `500` — ele resolve com `response.ok === false`. Sem a checagem explícita, o corpo de erro da API entra no cache como sucesso.

### `undefined` é falha

> "On success, the resolved value may be anything **except `undefined`**. Queries that resolve to `undefined` will be treated as failed."

Para representar ausência com sucesso, a fonte manda resolver `null`.

```tsx
const todoQuery = useQuery({
 queryKey: ['todos', 'detail', todoId],
 queryFn: async ({ signal }): Promise<Todo | null> => {
 const response = await fetch(`/api/todos/${todoId}`, { signal })

 if (response.status === 404) return null // ausência é sucesso
 if (!response.ok) {
 throw new Error(`GET /todos/${todoId} falhou: ${response.status}`)
 }

 return todoSchema.parse(await response.json) // contrato validado
 },
})
```

Três coisas nesse exemplo não são opcionais: o `signal` repassado (cancelamento — [TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md) § 5), o `throw` em `!response.ok`, e o `parse` do Zod. O `return` sem anotação também funcionaria: a inferência flui da `queryFn` para `data`.

### `QueryFunctionContext`

Propriedades verificadas na fonte:

| Propriedade | Tipo | Uso |
| --- | --- | --- |
| `queryKey` | `QueryKey` | ler os parâmetros da própria key, em vez de fechar sobre variáveis |
| `client` | `QueryClient` | acesso ao cache de dentro da `queryFn` |
| `signal` | `AbortSignal \| undefined` | cancelamento — repasse a `fetch`/`axios` |
| `meta` | `Record<string, unknown> \| undefined` | *"an optional field you can fill with additional information about your query"* |
| `pageParam` | `TPageParam` | apenas em infinite queries |
| `direction` | `'forward' \| 'backward'` | **marcado como deprecated** — a direção deve ir dentro do `pageParam` |

| ID | Regra |
| --- | --- |
| `TSQ-BASE-04` | `queryFn` **NEVER** resolve `undefined` — para "sem dado", resolva `null`. |
| `TSQ-BASE-05` | `queryFn` baseada em `fetch` **MUST** checar `response.ok` e lançar; `fetch` não rejeita em erro HTTP. |
| `TSQ-BASE-06` | `queryFn` **MUST** devolver o resultado de um `parse`/`safeParse` do schema, nunca o JSON cru. |

---

## 5. `status` × `fetchStatus` — dois eixos, não um

O erro de leitura mais comum da API. A fonte separa explicitamente:

> "The `status` gives information about the `data`: Do we have any or not? The `fetchStatus` gives information about the `queryFn`: Is it running or not?"

| Eixo | Valores | Pergunta que responde |
| --- | --- | --- |
| `status` | `pending` · `error` · `success` | tenho dado? |
| `fetchStatus` | `fetching` · `paused` · `idle` | a `queryFn` está rodando? |

E o motivo de serem independentes:

> "Background refetches and stale-while-revalidate logic make all combinations for `status` and `fetchStatus`" possíveis.

As combinações que importam:

| `status` | `fetchStatus` | Situação |
| --- | --- | --- |
| `success` | `idle` | caso normal: dado fresco, nada rodando |
| `success` | `fetching` | refetch em segundo plano — a UI **tem** dado, não mostre spinner de página |
| `pending` | `fetching` | primeira carga de verdade |
| `pending` | `idle` | query desabilitada (`enabled: false`) — nunca vai resolver sozinha |
| `pending` | `paused` | sem rede, em `networkMode: 'online'` — parece loading eterno |

Duas dessas combinações quebram um `if (isPending) return <Spinner />` ingênuo. As correções:

**Query que pode estar desabilitada** → use `isLoading`, que a fonte define como derivado:

> "`isLoading` [is] a derived flag that is computed from: `isPending && isFetching`"

**Rede ausente** → a fonte avisa diretamente no guia de network mode:

> "it might not be enough to check for `pending` state to show a loading spinner. Queries can be in `state: 'pending'`, but `fetchStatus: 'paused'` if they are mounting for the first time, and you have no network connection."

```tsx
const { data, isLoading, isError, error, fetchStatus } = useQuery(todosOptions)

if (fetchStatus === 'paused') return <Offline />
if (isLoading) return <Spinner />
if (isError) return <Erro erro={error} />
return <Lista todos={data} />
```

Para indicador discreto de refetch em segundo plano existe `isFetching` por query e `useIsFetching` global.

| ID | Regra |
| --- | --- |
| `TSQ-BASE-07` | Loader de primeira carga em query que pode estar desabilitada **MUST** usar `isLoading`, nunca `isPending`. |
| `TSQ-BASE-08` | Em `networkMode: 'online'`, o spinner **NEVER** depende só de `status === 'pending'` — trate `fetchStatus: 'paused'` separadamente. |

---

## 6. Defaults agressivos

A fonte chama de "important defaults" porque nenhum deles é neutro. Todos verificados:

| Default | Valor | Efeito |
| --- | --- | --- |
| `staleTime` | `0` | todo dado nasce stale |
| refetch automático | ao montar nova instância, ao refocar a janela, ao reconectar a rede | dispara sempre que o dado está stale |
| `gcTime` | `1000 * 60 * 5` (5 min) | queries **inativas** somem da memória depois disso |
| `retry` | `3` | falhas são retentadas em silêncio |
| `retry` no servidor | `0` | *"to make server rendering as fast as possible"* |
| `retryDelay` | `Math.min(1000 * 2 ** attemptIndex, 30000)` | backoff exponencial, teto de 30s |
| `structuralSharing` | ativo | referência preservada quando o dado não mudou de fato |

Dois valores especiais de `staleTime` verificados na fonte:

- `Infinity` — impede refetch por staleness, mas `invalidateQueries` continua funcionando;
- `'static'` — *"never trigger a refetch, even if the Query is invalidated manually"*. Bloqueia também `refetchOnMount`, `refetchOnWindowFocus` e `refetchOnReconnect` mesmo com `"always"`.

O default de `retry: 3` merece atenção específica: um `404` legítimo vira quatro requisições e ~7 segundos de espera antes de a UI mostrar "não encontrado". Erros de cliente não devem ser retentados.

```tsx
new QueryClient({
 defaultOptions: {
 queries: {
 retry: (failureCount, error) => {
 if (error instanceof HttpError && error.status < 500) return false
 return failureCount < 3
 },
 },
 },
})
```

A política de frescor derivada desses defaults é o assunto de [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) e de.

---

## 7. `queryOptions` e tipagem

A fonte descreve `queryOptions` como

> "one of the best ways to share `queryKey` and `queryFn` between multiple places, yet keep them co-located to one another"

Em runtime ele apenas devolve o que recebeu. O valor está na inferência e no fato de a key viajar junto da função que a preenche.

```tsx
import { queryOptions } from '@tanstack/react-query'

export function todoOptions(todoId: string) {
 return queryOptions({
 queryKey: ['todos', 'detail', todoId] as const,
 queryFn: async ({ signal }) => {
 const res = await fetch(`/api/todos/${todoId}`, { signal })
 if (!res.ok) throw new Error(`status ${res.status}`)
 return todoSchema.parse(await res.json)
 },
 staleTime: 5 * 60_000,
 })
}
```

Consumidores verificados na fonte: `useQuery`, `useSuspenseQuery`, `useQueries`, `queryClient.prefetchQuery`, `queryClient.setQueryData`. E a key permanece tipada ao ser reusada:

```tsx
queryClient.setQueryData(todoOptions(id).queryKey, updated) // updated é tipado
```

Para infinite queries existe `infiniteQueryOptions`.

> **Não verificado:** o helper `mutationOptions`. A página de Query Options menciona `queryOptions` e `infiniteQueryOptions`; `mutationOptions` não aparece nela. A nota anterior o afirmava — não replique sem checar a referência de mutations.

Pontos de TypeScript confirmados na página oficial:

- versão mínima: *"TypeScript versions released within the last 2 years. At the moment, that means TypeScript **5.4** and newer."*
- **mudanças de tipo saem como patch**: *"Changes to types in this repository are considered **non-breaking** and are usually released as **patch** semver changes."* — trave a versão exata do pacote.
- o resultado é uma **discriminated union** por `status`: checar `isSuccess` estreita `data` de `T | undefined` para `T`.
- `error` é `Error` por padrão. Para erros customizados, a fonte recomenda *narrowing* (ex.: `axios.isAxiosError`) em vez de generics, que quebram a inferência do resto.
- a interface `Register` registra tipos globais: `defaultError`, `queryMeta`, `mutationMeta`, `queryKey`, `mutationKey`.

| ID | Regra |
| --- | --- |
| `TSQ-BASE-09` | `queryKey` e `queryFn` **MUST** ser co-locadas em um `queryOptions` exportado quando a query tem mais de um consumidor. |
| `TSQ-BASE-10` | A versão de `@tanstack/react-query` **MUST** ser travada em patch exato — mudanças de tipo são publicadas como patch. |

---

## 8. Devtools

`@tanstack/react-query-devtools`, componente `ReactQueryDevtools`. Excluídos automaticamente de builds de produção. Modo *floating* (botão flutuante) ou *embedded* (`ReactQueryDevtoolsPanel`). Desde a v5 observam também as mutations, e trazem toggle para simular offline — útil para exercitar `fetchStatus: 'paused'` e `TSQ-BASE-08` sem desligar a rede de verdade.

Recomendado também: `@tanstack/eslint-plugin-query`, que pega estaticamente a maior parte das violações de `TSQ-BASE-03`.

---

## Antipadrões

```tsx
// ERRADO — resposta da API espelhada em estado de cliente
const { data } = useQuery(todosOptions)
const [todos, setTodos] = useState<Todo[]>([])
useEffect( => { if (data) setTodos(data) }, [data])

// CERTO — o cache já é o estado. Não há segunda fonte de verdade.
const { data: todos } = useQuery(todosOptions)
```
Violação de `REACT-PAT-03` e de `REACT-EFFECT-04`. O sintoma aparece na primeira mutation: o cache atualiza, o `useState` fica para trás.

```tsx
// ERRADO — variável usada na queryFn e ausente da key
useQuery({
 queryKey: ['todos'],
 queryFn: => fetchTodos(filtro),
})

// CERTO
useQuery({
 queryKey: ['todos', 'list', filtro],
 queryFn: => fetchTodos(filtro),
})
```
Violação de `TSQ-BASE-03`. Trocar o filtro não refaz a busca, e as duas variações disputam a mesma entrada de cache.

```tsx
// ERRADO — fetch não lança em 500; o corpo de erro entra no cache como sucesso
queryFn: => fetch('/api/todos').then((r) => r.json)

// CERTO
queryFn: async => {
 const r = await fetch('/api/todos')
 if (!r.ok) throw new Error(`status ${r.status}`)
 return todosSchema.parse(await r.json)
}
```
Violação de `TSQ-BASE-05` e `TSQ-BASE-06`.

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| `new QueryClient` no corpo do componente | cache descartado a cada render; toda query refaz do zero | escopo de módulo ou `useState( =>...)` — `TSQ-BASE-01` |
| `if (isPending) return <Spinner />` em query com `enabled` | `pending + idle` é estado permanente; spinner nunca sai | `isLoading` — `TSQ-BASE-07` |
| `queryFn` devolvendo `undefined` quando não acha nada | a query é marcada como **falha**, não como vazia | devolver `null` — `TSQ-BASE-04` |
| `['todos', page, status]` com posições soltas | ordem posicional; refatorar a ordem invalida o cache inteiro em silêncio | `['todos', 'list', { page, status }]` |
| Aceitar `retry: 3` para toda a app | `404` custa 4 requisições e ~7s antes de virar UI | `retry` como função, sem retry em 4xx |

---

## Checklist de revisão

- [ ] O `QueryClient` está fora do render? → `TSQ-BASE-01`
- [ ] A key é array, serializável e única para aquele dado? → `TSQ-BASE-02`
- [ ] Toda variável lida pela `queryFn` está na key? → `TSQ-BASE-03`
- [ ] Ausência de dado resolve `null`, não `undefined`? → `TSQ-BASE-04`
- [ ] `response.ok` é checado e o erro é lançado? → `TSQ-BASE-05`
- [ ] A resposta passa por `parse` antes de virar `data`? → `TSQ-BASE-06`
- [ ] Query com `enabled` usa `isLoading` e não `isPending`? → `TSQ-BASE-07`
- [ ] `fetchStatus: 'paused'` tem tratamento próprio? → `TSQ-BASE-08`
- [ ] Query com múltiplos consumidores está em `queryOptions`? → `TSQ-BASE-09`
- [ ] A versão do pacote está travada em patch exato? → `TSQ-BASE-10`
- [ ] Nenhuma resposta de API foi copiada para `useState`/store? → `REACT-PAT-03`

---

## Relacionados

- [TanStack Query](tanstack-query.md) — hub
- [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) · [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) · [TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md)
- · ·
- · ·
- [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) § 3 (`REACT-EFFECT-06`) · [React - Patterns](react-patterns.md) (`REACT-PAT-03`) · [React.js](react-js.md)
- · ·

## Fontes consultadas

Verificadas em **2026-08-14**:

- [Overview](https://tanstack.com/query/latest/docs/framework/react/overview) · [Installation](https://tanstack.com/query/latest/docs/framework/react/installation)
- [Queries](https://tanstack.com/query/latest/docs/framework/react/guides/queries) · [Query Keys](https://tanstack.com/query/latest/docs/framework/react/guides/query-keys) · [Query Functions](https://tanstack.com/query/latest/docs/framework/react/guides/query-functions) · [Query Options](https://tanstack.com/query/latest/docs/framework/react/guides/query-options)
- [Important Defaults](https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults) · [Query Retries](https://tanstack.com/query/latest/docs/framework/react/guides/query-retries)
- [Disabling Queries](https://tanstack.com/query/latest/docs/framework/react/guides/disabling-queries) (definição de `isLoading`) · [Network Mode](https://tanstack.com/query/latest/docs/framework/react/guides/network-mode) (`pending` + `paused`)
- [TypeScript](https://tanstack.com/query/latest/docs/framework/react/typescript)
- `registry.npmjs.org/@tanstack/react-query` — `dist-tags.latest = 5.101.4`

**O que a verificação contrariou:**

- **A nota anterior afirmava `require TypeScript ≥ 5.4` como fato estático.** A fonte declara a regra, não o número fixo: *"TypeScript versions released within the last 2 years. At the moment, that means TypeScript 5.4 and newer."* O piso sobe sozinho.
- **`QueryFunctionContext.direction` está marcado como deprecated** — a direção deve ser codificada dentro do `pageParam`. A nota anterior não registrava a propriedade.
- **`QueryFunctionContext` inclui `client: QueryClient`.** Dá para tocar o cache de dentro da `queryFn` sem `useQueryClient`.
- **`mutationOptions` não foi confirmado** na página de Query Options, ao contrário do que a nota anterior afirmava.
- **A página de Overview não exibe indicador de versão.** A checagem de versão precisa ir ao npm, não ao site.
- **v5 continua corrente** (`5.101.4`); a v6 está em beta e não é `latest`.
