---
Link: https://tanstack.com/query/latest/docs/framework/react/guides/suspense
tags:
 - tanstack-query
 - suspense
 - ssr
 - agent-context
source: "Documentação oficial — https://tanstack.com/query/latest/docs/framework/react"
verificado-em: 2026-08-14
---

# TanStack Query - Suspense e SSR

> `useSuspenseQuery` · `useSuspenseQueries` · `useSuspenseInfiniteQuery` · `QueryErrorResetBoundary` · `dehydrate` / `HydrationBoundary` · streaming e hidratação de queries `pending` · cancelamento com `AbortSignal` · network mode.
>
> **Não cobre:** `status` × `fetchStatus` e setup do `QueryClient` no cliente ([TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)) · `staleTime` e `gcTime` ([TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md)) · prefetch em event handler e roteador ([TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md)) · o que é um Error Boundary ([React - Suspense e Assincronia](react-suspense-e-assincronia.md)).

Entrada: [TanStack Query](tanstack-query.md) · Base normativa: [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)

---

## 1. Conceito: quem responde por loading e erro

`useQuery` devolve estados e deixa o componente decidir o que fazer com eles. `useSuspenseQuery` faz o oposto: ele **sai do componente** e delega loading ao `<Suspense>` mais próximo e erro ao Error Boundary mais próximo.

O ganho é de tipo, e é real:

> "This works nicely in TypeScript, because `data` is guaranteed to be defined (as errors and loading states are handled by Suspense- and ErrorBoundaries)."

Sem `data?.`, sem early return de loading, sem `if (isError)`. O componente escreve o caminho feliz porque os outros dois foram movidos para cima.

O custo é que o boundary passa a ser infraestrutura obrigatória, não decoração. E é aqui que a estrutura de React já tem regra: **`REACT-ASYNC-08` — todo boundary de Suspense em fronteira de dados MUST ter Error Boundary** ([React - Suspense e Assincronia](react-suspense-e-assincronia.md)). Não existe ID `TSQ-*` equivalente: cite `REACT-ASYNC-08`. Sem Error Boundary, uma falha de rede desmonta a árvore inteira até o root.

E `REACT-ASYNC-09` continua valendo dentro do modelo: erro esperado (404, 409, validação) é estado, não exceção para boundary. O boundary é para o que você não previu —.

---

## 2. Os hooks de Suspense

Três, verificados: `useSuspenseQuery`, `useSuspenseQueries`, `useSuspenseInfiniteQuery`.

```tsx
function Perfil({ id }: { id: string }) {
 const { data } = useSuspenseQuery(userOptions(id))
 return <h1>{data.name}</h1> // data é T, não T | undefined
}

<ErrorBoundary fallback={<Erro />}>
 <Suspense fallback={<Skeleton />}>
 <Perfil id={id} />
 </Suspense>
</ErrorBoundary>
```

### Duas restrições que decidem a arquitetura

**Não dá para desabilitar condicionalmente:**

> "On the flip side, you therefore can't conditionally enable / disable the Query."

Não há `enabled` aqui — porque a promessa de que `data` está definido não sobrevive a uma query que não roda. Query condicional continua sendo `useQuery` com `enabled` ou `skipToken` ([TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) § 5).

**Queries no mesmo componente rodam em série:**

> "all your Queries inside one component are fetched in serial."

A primeira suspende o componente antes de a segunda ser alcançada. Duas queries de 300ms viram 600ms — um waterfall criado pela forma do código, não pela dependência dos dados.

```tsx
// ERRADO — 2x a latência, sem nenhuma dependência entre as duas
const { data: user } = useSuspenseQuery(userOptions(id))
const { data: posts } = useSuspenseQuery(postsOptions(id))

// CERTO — paralelo
const [{ data: user }, { data: posts }] = useSuspenseQueries({
 queries: [userOptions(id), postsOptions(id)],
})
```

A outra saída é separar em dois componentes irmãos, cada um com seu boundary — o que também dá granularidade de fallback.

### `throwOnError` não é o que se assume

O default verificado:

```
throwOnError: (error, query) => typeof query.state.data === 'undefined'
```

O erro só sobe para o boundary **quando não há dado em cache**. Se um refetch em segundo plano falha e a query já tinha dado, o componente segue renderizando o dado antigo e o boundary não é acionado. Bom para UX, silencioso para observabilidade: falhas de revalidação não aparecem em lugar nenhum a menos que você as trate.

### Reset para "tentar de novo"

Um Error Boundary que se recupera precisa que a query também esqueça o erro. É o papel de `QueryErrorResetBoundary` (componente) e `useQueryErrorResetBoundary` (hook).

```tsx
<QueryErrorResetBoundary>
 {({ reset }) => (
 <ErrorBoundary
 onReset={reset}
 fallbackRender={({ resetErrorBoundary }) => (
 <button onClick={ => resetErrorBoundary}>Tentar de novo</button>
 )}
 >
 <Perfil id={id} />
 </ErrorBoundary>
 )}
</QueryErrorResetBoundary>
```

Sem o `reset`, o botão remonta o componente, a query ainda está em erro, e o boundary dispara de novo na hora.

| ID | Regra |
| --- | --- |
| `TSQ-SSR-01` | `useSuspenseQuery` **NEVER** é usado para query condicional — não aceita `enabled`. Use `useQuery`. |
| `TSQ-SSR-02` | Duas ou mais suspense queries independentes no mesmo componente **MUST** virar `useSuspenseQueries` ou componentes irmãos — elas rodam em série. |
| `TSQ-SSR-03` | Error Boundary com retry sobre queries **MUST** ser envolvido por `QueryErrorResetBoundary` ou usar `useQueryErrorResetBoundary`. |

---

## 3. SSR: as duas abordagens

### `initialData` — o caminho simples e limitado

Passar o dado do servidor como `initialData` funciona, e a fonte lista as desvantagens: é preciso atravessar a árvore com o dado, o `dataUpdatedAt` fica impreciso, e — o ponto grave —

> "initialData will never overwrite this data, **even if the new data is fresher than the old one**."

### Prefetch + `dehydrate` / `HydrationBoundary` — o recomendado

Três passos: buscar no servidor com um `QueryClient` dedicado, serializar o cache com `dehydrate`, restaurar no cliente dentro de `<HydrationBoundary>`.

```tsx
// Servidor (loader de rota / RSC / getServerSideProps)
export async function loader {
 const queryClient = new QueryClient // um por requisição
 await queryClient.prefetchQuery(todosOptions)
 return { dehydratedState: dehydrate(queryClient) }
}

// Cliente
export default function Page({ dehydratedState }: Props) {
 return (
 <HydrationBoundary state={dehydratedState}>
 <Todos />
 </HydrationBoundary>
 )
}
```

O `<HydrationBoundary>` pode ficar por rota ou na raiz da app.

### As regras do servidor

**Um `QueryClient` por requisição.** A fonte, em negrito:

> "**This ensures that data is not shared between different users and requests**."

Um `QueryClient` no escopo de módulo em código de servidor é um cache compartilhado entre usuários — o dado do usuário A servido ao usuário B. É bug de segurança, não de performance. No cliente a regra irmã é `TSQ-BASE-01`: criar em `useState( => new QueryClient)`, nunca no corpo do render.

**`staleTime` acima de zero:**

> "With SSR, we usually want to set some default `staleTime` above 0 to avoid refetching immediately on the client."

Com o default `0`, tudo que o servidor buscou é considerado velho no instante da hidratação, e o cliente refaz todas as requisições. O HTML pré-renderizado deixa de valer alguma coisa.

**`gcTime: 0` não:**

> "**Avoid setting `gcTime` to `0`** as it may result in a hydration error"

**Serialização segura.** A fonte alerta que bibliotecas de serialização precisam prevenir XSS, e desaconselha `JSON.stringify` cru para injetar o estado desidratado no HTML.

| ID | Regra |
| --- | --- |
| `TSQ-SSR-04` | No servidor, o `QueryClient` **MUST** ser criado por requisição — **NEVER** em escopo de módulo. Cache compartilhado entre requisições vaza dado entre usuários. |
| `TSQ-SSR-05` | App com SSR **MUST** definir `staleTime` > 0 no cliente, ou o HTML pré-renderizado é descartado na hidratação. |
| `TSQ-SSR-06` | `gcTime: 0` **NEVER** em app com hidratação — a fonte associa o valor a erro de hidratação. |
| `TSQ-SSR-07` | Estado desidratado **MUST** ser consumido por `<HydrationBoundary state={...}>`, não distribuído como `initialData` pela árvore. |

---

## 4. Streaming e hidratação de queries pendentes

O comportamento que mudou o padrão de prefetch em SSR:

> "as of React Query v5.40.0, you don't have to `await` all prefetches for this to work, as `pending` Queries can also be dehydrated and sent to the client."

Antes, prefetch tinha que terminar antes do render — a resposta esperava a query mais lenta. Agora dá para iniciar o fetch, desidratar a query **pendente**, mandar o shell, e streamar o resultado quando ele resolve. É `<Suspense>` de streaming funcionando de ponta a ponta.

A configuração do comportamento default de desidratação:

```tsx
shouldDehydrateQuery: (query) =>
 defaultShouldDehydrateQuery(query) || query.state.status === 'pending'
```

### Server Components e Server Actions

Sobre RSC, a orientação da fonte é enxuta e vale como fronteira:

> "From the React Query perspective, treat Server Components as a place to prefetch data, nothing more."

E um aviso que contradiz um padrão comum em Next.js: **Server Actions não servem como `queryFn`**, porque *"run serially, not in parallel"*. Toda a arquitetura da biblioteca assume paralelismo; serializar as requisições reintroduz o waterfall que o prefetch existe para eliminar. Server Action é fronteira de escrita — e `REACT-RSC-06` em [React - Server Components e Diretivas](react-server-components-e-diretivas.md).

### O pacote experimental

`@tanstack/react-query-next-experimental`, com `ReactQueryStreamedHydration`, permite *"fetch data on the server (in a Client Component) by just calling `useSuspenseQuery`"*, sem prefetch manual — *"Results will then be streamed from the server to the client as SuspenseBoundaries resolve"*.

Ele continua rotulado como **experimental** pela própria documentação. Vale como opção consciente, com decisão registrada; não como default de um projeto novo.

| ID | Regra |
| --- | --- |
| `TSQ-SSR-08` | Server Function / Server Action **NEVER** é usada como `queryFn` — elas rodam em série. |
| `TSQ-SSR-09` | `@tanstack/react-query-next-experimental` **NEVER** entra em produção sem decisão registrada — a fonte o mantém marcado como experimental. |

---

## 5. Cancelamento

> "TanStack Query provides each query function with an `AbortSignal` instance."

```tsx
useQuery({
 queryKey: ['todos'],
 queryFn: async ({ signal }) => {
 const res = await fetch('/todos', { signal })
 if (!res.ok) throw new Error(`status ${res.status}`)
 return todosSchema.parse(await res.json)
 },
})

// axios (v0.22.0+)
useQuery({
 queryKey: ['todos'],
 queryFn: ({ signal }) => axios.get('/todos', { signal }),
})
```

O contrato:

> "If you consume the `AbortSignal`, the Promise will be cancelled (e.g. aborting the fetch) and therefore, also the Query must be cancelled."

E o efeito no estado:

> "Cancelling the query will result in its state being *reverted* to its previous state."

Cancelamento não é erro. A query volta ao que era antes, sem `status: 'error'` e sem entrada de erro no cache. É por isso que o padrão de `AbortController` em `useEffect` — onde é preciso filtrar `AbortError` no `catch` à mão ([React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) § 3) — deixa de ser necessário: a biblioteca trata a reversão.

`queryClient.cancelQueries({ queryKey: ['todos'] })` cancela manualmente, *"and revert it back to its previous state"*. É exatamente o primeiro passo do update otimista (`TSQ-MUT-10`).

Não repassar o `signal` não quebra nada visível — só faz a requisição obsoleta seguir viajando, consumindo conexão e, em listas com busca por digitação, mantendo N requisições em voo por um resultado que ninguém vai ver. Ver.

| ID | Regra |
| --- | --- |
| `TSQ-SSR-10` | Toda `queryFn` que faz I/O cancelável **MUST** repassar o `signal` do `QueryFunctionContext`. |

---

## 6. Network Mode

Três modos, verificados:

| Modo | Comportamento |
| --- | --- |
| `online` (default) | *"Queries and Mutations will not fire unless you have network connection."* |
| `always` | *"TanStack Query will always fetch and ignore the online / offline state."* Para `queryFn` que não usa rede — AsyncStorage, IndexedDB, mock. |
| `offlineFirst` | *"TanStack Query will run the `queryFn` once, but then pause retries."* Para PWA com service worker ou cache HTTP na frente. |

Em `online`, ficar offline durante um fetch pausa também o retry: *"Paused queries will then continue to run once you re-gain network connection."* A retomada é automática.

O caveat de UI é o que mais aparece em bug report, e já é regra em `TSQ-BASE-08`:

> "it might not be enough to check for `pending` state to show a loading spinner. Queries can be in `state: 'pending'`, but `fetchStatus: 'paused'` if they are mounting for the first time, and you have no network connection."

Um app que só olha `isPending` mostra spinner infinito no modo avião, sem nunca dizer ao usuário que o problema é a rede.

O default `online` também explica um caso confuso: `queryFn` que lê de storage local nunca roda offline, porque a biblioteca nem tenta. É o caso de `networkMode: 'always'`.

| ID | Regra |
| --- | --- |
| `TSQ-SSR-11` | `queryFn` que não depende de rede (storage local, memória, mock) **MUST** declarar `networkMode: 'always'`. |

---

## Antipadrões

```tsx
// ERRADO — QueryClient de módulo em código de servidor:
// o cache é compartilhado entre requisições e entre usuários
const queryClient = new QueryClient
export async function loader {
 await queryClient.prefetchQuery(meOptions)
 return { dehydratedState: dehydrate(queryClient) }
}

// CERTO — um por requisição
export async function loader {
 const queryClient = new QueryClient
 await queryClient.prefetchQuery(meOptions)
 return { dehydratedState: dehydrate(queryClient) }
}
```

```tsx
// ERRADO — suspense query com condição: enabled não existe aqui
const { data } = useSuspenseQuery({...userOptions(id), enabled: !!id })

// CERTO — condicional volta a ser useQuery
const { data } = useQuery({...userOptions(id), enabled: !!id })
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| `<Suspense>` de dados sem Error Boundary | uma falha de rede desmonta a árvore até o root | Error Boundary — `REACT-ASYNC-08` |
| Botão "tentar de novo" sem `reset` | a query segue em erro; o boundary redispara na hora | `QueryErrorResetBoundary` — `TSQ-SSR-03` |
| Duas `useSuspenseQuery` independentes no mesmo componente | serializa duas latências sem dependência entre elas | `useSuspenseQueries` — `TSQ-SSR-02` |
| SSR com `staleTime: 0` | o cliente refaz tudo que o servidor buscou, na hidratação | `staleTime` > 0 — `TSQ-SSR-05` |
| Server Action como `queryFn` | roda em série; recria o waterfall | rota HTTP para leitura — `TSQ-SSR-08` |
| `queryFn` que ignora o `signal` | requisições obsoletas seguem em voo; N em paralelo numa busca por digitação | repassar `signal` — `TSQ-SSR-10` |
| Spinner só por `isPending` | modo avião vira loading infinito sem mensagem | tratar `fetchStatus: 'paused'` — `TSQ-BASE-08` |

---

## Checklist de revisão

- [ ] Nenhuma suspense query tenta ser condicional? → `TSQ-SSR-01`
- [ ] Suspense queries independentes no mesmo componente foram agrupadas? → `TSQ-SSR-02`
- [ ] Retry de Error Boundary passa por `QueryErrorResetBoundary`? → `TSQ-SSR-03`
- [ ] Todo `<Suspense>` de dados tem Error Boundary acima? → `REACT-ASYNC-08`
- [ ] O `QueryClient` do servidor é criado por requisição? → `TSQ-SSR-04`
- [ ] `staleTime` > 0 no cliente em app com SSR? → `TSQ-SSR-05`
- [ ] Nenhum `gcTime: 0` com hidratação? → `TSQ-SSR-06`
- [ ] O estado desidratado passa por `<HydrationBoundary>`? → `TSQ-SSR-07`
- [ ] Nenhuma Server Action é usada como `queryFn`? → `TSQ-SSR-08`
- [ ] O pacote experimental tem decisão registrada? → `TSQ-SSR-09`
- [ ] Toda `queryFn` de rede repassa o `signal`? → `TSQ-SSR-10`
- [ ] `queryFn` sem rede declara `networkMode: 'always'`? → `TSQ-SSR-11`

---

## Relacionados

- [TanStack Query](tanstack-query.md) — hub
- [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) · [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md)
- [React - Suspense e Assincronia](react-suspense-e-assincronia.md) (`REACT-ASYNC-08`, `REACT-ASYNC-09`) · [React - Server Components e Diretivas](react-server-components-e-diretivas.md) · [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) · [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md)
- · · ·
- · · · ·

## Fontes consultadas

Verificadas em **2026-08-14**:

- [Suspense](https://tanstack.com/query/latest/docs/framework/react/guides/suspense)
- [Server Rendering & Hydration](https://tanstack.com/query/latest/docs/framework/react/guides/ssr)
- [Advanced Server Rendering](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr)
- [Query Cancellation](https://tanstack.com/query/latest/docs/framework/react/guides/query-cancellation)
- [Network Mode](https://tanstack.com/query/latest/docs/framework/react/guides/network-mode)

**O que a verificação contrariou:**

- **Queries `pending` podem ser desidratadas desde a v5.40.0** — não é preciso `await` de todos os prefetches para o streaming funcionar. A nota anterior descrevia streaming apenas via o pacote experimental do Next.
- **A fonte desaconselha Server Actions como `queryFn`**, porque *"run serially, not in parallel"*. É um padrão comum em código gerado e a documentação o contraindica explicitamente.
- **`gcTime: 0` é associado a erro de hidratação** — a nota anterior não trazia essa restrição.
- **A regra do `QueryClient` por requisição está no texto como prevenção de vazamento entre usuários**, não como detalhe de performance: *"This ensures that data is not shared between different users and requests"*.
- **`initialData` nunca sobrescreve dado existente, mesmo sendo mais fresco** — o que desqualifica a abordagem para SSR em telas revisitadas.
- **O default de `throwOnError` em suspense é uma função**, `(error, query) => typeof query.state.data === 'undefined'`: falha de refetch com dado em cache não chega ao boundary e não aparece em lugar nenhum.
- **A fonte alerta para XSS na serialização do estado desidratado** e desaconselha `JSON.stringify` cru — ponto de segurança que não estava registrado.
