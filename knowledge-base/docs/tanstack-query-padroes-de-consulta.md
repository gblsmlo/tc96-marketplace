---
Link: https://tanstack.com/query/latest/docs/framework/react/guides/dependent-queries
tags:
 - tanstack-query
 - patterns
 - agent-context
source: "Documentação oficial — https://tanstack.com/query/latest/docs/framework/react"
verificado-em: 2026-08-14
---

# TanStack Query - Padrões de Consulta

> Queries dependentes · paralelas e `useQueries` · paginadas com `keepPreviousData` · `useInfiniteQuery` · lazy, `enabled` e `skipToken` · prefetching e achatamento de waterfalls · `select`.
>
> **Não cobre:** key, `queryFn` e `status` ([TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)) · `staleTime`, `placeholderData` × `initialData` ([TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md)) · escrita e invalidação ([TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md)) · `useSuspenseQueries` e prefetch em SSR ([TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md)).

Entrada: [TanStack Query](tanstack-query.md) · Base normativa: [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)

---

## 1. Conceito: a forma da consulta é decisão de latência

Todos os padrões desta nota respondem à mesma pergunta: **quantas viagens até a tela ficar pronta, e em que ordem.**

Duas requisições paralelas custam uma latência. Duas em série custam duas. Com 200ms de RTT a diferença é 200ms; num celular em 4G ruim, é um segundo e meio. A fonte é direta sobre isso ao discutir queries dependentes: elas criam um *"request waterfall"* que *"hurts performance"*, e executá-las em série *"takes twice as long"*.

A ordem de preferência, do melhor ao pior:

1. **Uma requisição** que traz tudo que a tela precisa — mudança de API, não de frontend;
2. **N requisições em paralelo** — `useQuery` lado a lado ou `useQueries`;
3. **N em série, com prefetch** para achatar o que dá;
4. **N em série** (`enabled` encadeado) — o caso que exige justificativa.

Escolher a forma é decidir a latência antes de escrever o componente.

---

## 2. Dependentes e paralelas

### Dependentes — `enabled`

A query só roda quando o insumo existe:

```tsx
const { data: user } = useQuery({
 queryKey: ['user', email],
 queryFn: => getUserByEmail(email),
})

const userId = user?.id

const { data: projects } = useQuery({
 queryKey: ['projects', userId],
 queryFn: => getProjectsByUser(userId!),
 enabled: !!userId, // não executa até userId existir
})
```

Enquanto desabilitada, a segunda query fica em `status: 'pending'`, `fetchStatus: 'idle'` — a combinação que quebra `if (isPending)` e exige `isLoading` (`TSQ-BASE-07`).

E o aviso da fonte, que precisa aparecer na revisão e não só na leitura: a solução preferida é *"restructure the backend APIs so that both queries can be fetched in parallel"* — um endpoint que devolva usuário e projetos de uma vez. Quando isso não é possível (API de terceiro, backend fora do seu controle, ID que só existe depois de uma escrita), o encadeamento é legítimo e a justificativa deve estar no código.

### Paralelas — lado a lado

Com número fixo de queries, basta empilhar os hooks:

```tsx
const usersQuery = useQuery({ queryKey: ['users'], queryFn: fetchUsers })
const teamsQuery = useQuery({ queryKey: ['teams'], queryFn: fetchTeams })
const projectsQuery = useQuery({ queryKey: ['projects'], queryFn: fetchProjects })
```

As três disparam juntas. **Menos em Suspense**, onde a fonte é explícita:

> "When using React Query in suspense mode, this pattern of parallelism does not work, since the first query would throw a promise internally and would suspend the component before the other queries run."

Sob Suspense, use `useSuspenseQueries` — ver [TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md) § 2.

### `useQueries` — número variável

Quando a quantidade muda entre renders, empilhar hooks viola `REACT-HOOK-01` (Hooks nunca em loop ou condicional — [React.js](react-js.md) § 6). `useQueries` resolve:

> "accepts an **options object** with a **queries key** whose value is an **array of query objects**. It returns an **array of query results**."

```tsx
const userQueries = useQueries({
 queries: users.map((user) => ({
 queryKey: ['user', user.id],
 queryFn: => fetchUserById(user.id),
 })),
})
```

Também aceita `combine`, para reduzir o array de resultados a um único valor. E funciona para dependentes dinâmicas: monte o array a partir do resultado anterior, devolvendo `[]` enquanto o insumo não chegou.

> **Caveat de tipagem verificado:** um `select` inline dentro de um objeto de query em `useQueries` não infere `data` a partir da `queryFn` do mesmo objeto. Extraia a função com tipo explícito.

| ID | Regra |
| --- | --- |
| `TSQ-PATTERN-01` | Query dependente via `enabled` **MUST** trazer, em comentário ou ADR, por que a API não pode devolver os dois dados em uma chamada. |
| `TSQ-PATTERN-02` | Número variável de queries **MUST** usar `useQueries` — Hooks **NEVER** em loop (`REACT-HOOK-01`). |
| `TSQ-PATTERN-03` | Queries paralelas sob `<Suspense>` **MUST** usar `useSuspenseQueries` — hooks lado a lado suspendem em série. |

---

## 3. Paginadas

> "Rendering paginated data is a very common UI pattern and in TanStack Query, it 'just works' by including the page information in the query key."

Só que "just works" traz um efeito colateral que a própria fonte nomeia:

> "The UI jumps in and out of the `success` and `pending` states because each new page is treated like a brand new query."

Cada página é uma entrada de cache diferente. Ao avançar, a nova key não tem dado, a query volta a `pending`, e a tabela desaparece antes de reaparecer. `placeholderData: keepPreviousData` corta isso:

> "The data from the last successful fetch is available while new data is being requested, even though the query key has changed"

E quando os novos dados chegam, *"the previous `data` is seamlessly swapped to show the new data"*.

```tsx
import { keepPreviousData, useQuery } from '@tanstack/react-query'

const [page, setPage] = useState(0)

const { data, isPlaceholderData, isFetching } = useQuery({
 queryKey: ['projects', { page }],
 queryFn: => fetchProjects(page),
 placeholderData: keepPreviousData,
})

<button
 onClick={ => setPage((p) => p + 1)}
 // sem isso, o clique avança sobre dados da página anterior
 disabled={isPlaceholderData || !data?.hasMore}
>
 Próxima
</button>
```

O `isPlaceholderData` não é opcional aqui: *"`isPlaceholderData` is made available to know what data the query is currently providing you."* Enquanto ele é `true`, `data.hasMore` descreve a página **anterior**. Clicar duas vezes rápido pula uma página ou avança além do fim.

A fonte confirma que o padrão *"works flawlessly with the `useInfiniteQuery` hook"* também.

O estado de página, note, é candidato natural a viver na URL em vez de em `useState` — ver [TanStack Router - Search Params](tanstack-router-search-params.md) (`REACT-PAT-10`) e.

| ID | Regra |
| --- | --- |
| `TSQ-PATTERN-04` | Query paginada **MUST** incluir a página na `queryKey` e usar `placeholderData: keepPreviousData`. |
| `TSQ-PATTERN-05` | Controle de navegação de página **MUST** ficar desabilitado enquanto `isPlaceholderData` for `true`. |

---

## 4. Infinitas

```tsx
const {
 data,
 fetchNextPage,
 hasNextPage,
 isFetchingNextPage,
} = useInfiniteQuery({
 queryKey: ['projects'],
 queryFn: ({ pageParam, signal }) => fetchProjects(pageParam, signal),
 initialPageParam: 0, // obrigatório
 getNextPageParam: (lastPage) => lastPage.nextCursor, // undefined = acabou
})

// data.pages — array com as páginas buscadas
// data.pageParams — array com os params usados
```

`initialPageParam` é descrito como *"available (and required)"*. `getNextPageParam` e `getPreviousPageParam` servem *"for both determining if there is more data to load and the information to fetch it"* — devolver `undefined` é o que zera `hasNextPage`.

### Dois caveats que produzem bug em produção

**Refetch refaz todas as páginas, em ordem:**

> "each group is fetched sequentially, starting from the first one. This ensures that even if the underlying data is mutated, we're not using stale cursors..."

Comportamento correto e caro: uma lista com 30 páginas carregadas faz 30 requisições em série ao ser invalidada. Daí `maxPages`, que a fonte oferece para *"limit the number of pages stored in the query data to improve the performance and UX"*.

**Só existe um fetch em voo por infinite query:**

> "calling `fetchNextPage` while an ongoing fetch is in progress runs the risk of overwriting data refreshes happening in the background"

> "there can only be a single ongoing fetch for an InfiniteQuery"

Um `IntersectionObserver` que dispara `fetchNextPage` a cada evento de scroll, sem guarda, atropela o próprio carregamento.

```tsx
useEffect( => {
 if (inView && hasNextPage && !isFetchingNextPage) {
 fetchNextPage
 }
}, [inView, hasNextPage, isFetchingNextPage, fetchNextPage])
```

| ID | Regra |
| --- | --- |
| `TSQ-PATTERN-06` | `useInfiniteQuery` **MUST** declarar `initialPageParam` e `getNextPageParam`. |
| `TSQ-PATTERN-07` | `fetchNextPage` **NEVER** é chamado com `isFetchingNextPage` verdadeiro. |
| `TSQ-PATTERN-08` | Infinite query sem teto natural de páginas **MUST** declarar `maxPages` — o refetch refaz todas as páginas em série. |

---

## 5. Lazy, `enabled` e `skipToken`

`enabled` não é só liga/desliga permanente:

> "The `enabled` option can not only be used to permanently disable a query, but also to enable / disable it at a later time. A good example would be a filter form where you only want to fire off the first request once the user has entered a filter value."

Comportamento de uma query desabilitada, verificado:

- com dado em cache, inicia em `status === 'success'`;
- sem dado em cache, inicia em `status === 'pending'` e `fetchStatus === 'idle'`;
- não busca ao montar e não faz refetch em segundo plano;
- *"The query will ignore query client `invalidateQueries` and `refetchQueries` calls"*;
- `refetch` manual continua funcionando.

O terceiro item é o que surpreende: uma mutation que invalida um prefixo **não** faz nada com as queries desabilitadas dele. O dado volta stale quando ela for reabilitada, o que geralmente é o comportamento desejado — mas não é o comportamento que se assume.

### `skipToken` e a armadilha do `refetch`

`skipToken` é a alternativa com tipagem melhor: em vez de `enabled: !!id` com `id!` dentro da `queryFn`, o TypeScript entende que a query não roda e `data` fica `undefined`.

```tsx
import { skipToken, useQuery } from '@tanstack/react-query'

const { data } = useQuery({
 queryKey: ['todos', filtro],
 queryFn: filtro ? => fetchTodos(filtro) : skipToken,
})
```

E o caveat literal:

> "`refetch` from `useQuery` will not work with `skipToken`. Calling `refetch` on a query that uses `skipToken` will result in a `Missing queryFn` error"

O critério é direto: precisa de disparo manual → `enabled: false`. Não precisa → `skipToken`, pela tipagem.

| ID | Regra |
| --- | --- |
| `TSQ-PATTERN-09` | Query que precisa de disparo manual **MUST** usar `enabled: false` — `refetch` com `skipToken` lança `Missing queryFn`. |
| `TSQ-PATTERN-10` | Query desabilitada **NEVER** é usada para dado que uma mutation precisa manter fresco — ela ignora `invalidateQueries`. |

---

## 6. Prefetching e waterfalls

Prefetch popula o cache antes de alguém pedir. O objetivo declarado é achatar waterfalls: transformar `A → B → C` em `A + B + C`.

Comportamento verificado de `prefetchQuery` / `prefetchInfiniteQuery`:

- respeitam o `staleTime` do `queryClient`, e aceitam um próprio — mas *"This `staleTime` is only used for the prefetch, you still need to set it for any `useQuery` call as well"*;
- *"These functions return `Promise<void>` and thus never return query data. If that's something you need, use `fetchQuery`/`fetchInfiniteQuery` instead."*;
- *"The prefetch functions never throw errors because they usually try to fetch again in a `useQuery` which is a nice graceful fallback. If you need to catch errors, use `fetchQuery`/`fetchInfiniteQuery` instead."*;
- *"If no instances of `useQuery` appear for a prefetched query, it will be deleted and garbage collected after the time specified in `gcTime`."*

Os dois últimos pontos decidem a escolha entre `prefetch*` e `fetch*`: **prefetch é uma aposta, fetch é um requisito.** Se a renderização depende do dado, prefetch não serve — ele não devolve nada e engole o erro.

Padrões de aplicação listados na fonte: em event handlers, em componentes, via integração com roteador, e durante server rendering.

```tsx
// Event handler: a rede começa no hover, não no clique
<Link
 to="/todos/$id"
 params={{ id }}
 onMouseEnter={ => queryClient.prefetchQuery(todoOptions(id))}
 onFocus={ => queryClient.prefetchQuery(todoOptions(id))}
/>
```

```tsx
// Componente: dispara a query do filho junto com a do pai.
// Sem `await` e sem uso do retorno — só aquece o cache.
function Article({ id }: { id: string }) {
 const queryClient = useQueryClient
 queryClient.prefetchQuery(commentsOptions(id)) // paralelo ao artigo
 const { data } = useQuery(articleOptions(id))
 //...
}
```

O caminho mais robusto, quando há roteador, é o `loader` da rota: o prefetch começa na navegação, antes de qualquer componente montar — [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md). O `queryOptions` exportado (`TSQ-BASE-09`) é o que permite o `loader` e o componente compartilharem exatamente a mesma definição.

| ID | Regra |
| --- | --- |
| `TSQ-PATTERN-11` | `prefetchQuery` **NEVER** é usado para dado obrigatório à renderização — ele devolve `Promise<void>` e não lança. Fora de um loader de rota, use `fetchQuery`; **dentro** de um loader, use `ensureQueryData` (`TSR-LOAD-16`). |
| `TSQ-PATTERN-12` | Prefetch e o `useQuery` correspondente **MUST** compartilhar o mesmo `queryOptions`. Apelido de `TSQ-BASE-09`. |

**Qual usar, e por quê os três existem:**

| Função | Devolve | Rebusca se já está fresco? | Onde |
| --- | --- | --- | --- |
| `prefetchQuery` | `Promise<void>` — **não lança** | não | aquecimento oportunista, onde falhar é aceitável |
| `fetchQuery` | `Promise<TData>` — lança | **sim, sempre** | fora de loader, quando você precisa do dado ou do erro |
| `ensureQueryData` | `Promise<TData>` — lança | não, respeita o cache | **dentro de loader** — é `fetchQuery` com respeito ao `staleTime` |

`ensureQueryData` é a escolha no loader justamente porque lança (o erro chega ao `errorComponent`) **e** não refaz o que já está fresco. `fetchQuery` num loader ignora o cache e refaz a cada navegação.

---

## 7. `select`

`select` transforma o que o componente enxerga, sem mexer no cache. Duas consequências: menos re-render (a fonte: *"A component using the `useTodoCount` custom hook will only re-render if the length of the todos changes"*) e um lugar para adaptar o formato do servidor ao da UI sem quebrar structural sharing (`TSQ-CACHE-04`).

```tsx
// O cache guarda Todo[]; este componente só re-renderiza quando a contagem muda.
const contagem = useQuery({
...todosOptions,
 select: (todos) => todos.length,
})
```

E o caveat que mais dói, literal:

> "A `select` function that returns an error results in `data` being `undefined` and `isSuccess` being `true`."

Ou seja: `select` que lança produz uma query aparentemente bem-sucedida sem dado. Não é lugar para validação. A fonte manda tratar erro *"in the `queryFn` instead"* — que é onde o `parse` do Zod já mora (`TSQ-BASE-06`).

Sobre estabilidade: a fonte recomenda envolver `select` em `useCallback` para evitar reexecução a cada render. Definir a função fora do componente resolve igual e sem hook.

| ID | Regra |
| --- | --- |
| `TSQ-PATTERN-13` | `select` **NEVER** valida nem lança — erro em `select` produz `data: undefined` com `isSuccess: true`. Valide na `queryFn`. |
| `TSQ-PATTERN-14` | `select` inline com cálculo caro **MUST** ser estabilizado (`useCallback` ou função fora do componente). |

---

## Antipadrões

```tsx
// ERRADO — Hook em loop
{users.map((u) => useQuery({ queryKey: ['user', u.id], queryFn:... }))}

// CERTO
const results = useQueries({
 queries: users.map((u) => ({ queryKey: ['user', u.id], queryFn: => fetchUser(u.id) })),
})
```

```tsx
// ERRADO — waterfall por hábito: o backend já poderia devolver os dois
const { data: user } = useQuery(userOptions(email))
const { data: settings } = useQuery({
...settingsOptions(user?.id),
 enabled: !!user?.id,
})

// CERTO — uma viagem
const { data } = useQuery(userWithSettingsOptions(email))
```

```tsx
// ERRADO — select validando: erro vira sucesso sem dado
select: (raw) => todoSchema.parse(raw)

// CERTO — validação na queryFn
queryFn: async => todoSchema.parse(await res.json),
select: (todos) => todos.filter((t) => !t.done),
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| Paginação sem `keepPreviousData` | a tabela some a cada troca de página | `placeholderData: keepPreviousData` — `TSQ-PATTERN-04` |
| Botão "próxima" ativo com `isPlaceholderData` | decide sobre dados da página anterior; pula ou ultrapassa | `disabled={isPlaceholderData}` — `TSQ-PATTERN-05` |
| `fetchNextPage` no observer sem guarda | só há um fetch em voo por infinite query; a chamada atropela o refresh | checar `isFetchingNextPage` — `TSQ-PATTERN-07` |
| Infinite query sem `maxPages` | invalidar refaz todas as páginas em série | `maxPages` — `TSQ-PATTERN-08` |
| `skipToken` + botão "buscar" com `refetch` | `Missing queryFn` | `enabled: false` — `TSQ-PATTERN-09` |
| `prefetchQuery` antes de renderizar dado obrigatório | não devolve dado e não lança; a tela quebra sem erro | `fetchQuery` — `TSQ-PATTERN-11` |
| `select` inline recriado a cada render | reexecuta o cálculo em todo render | função estável — `TSQ-PATTERN-14` |
| Queries paralelas lado a lado sob `<Suspense>` | a primeira suspende antes de as outras rodarem | `useSuspenseQueries` — `TSQ-PATTERN-03` |

---

## Checklist de revisão

- [ ] Todo `enabled` encadeado tem justificativa registrada? → `TSQ-PATTERN-01`
- [ ] Número variável de queries usa `useQueries`? → `TSQ-PATTERN-02`
- [ ] Paralelas sob Suspense usam `useSuspenseQueries`? → `TSQ-PATTERN-03`
- [ ] Paginação inclui a página na key e usa `keepPreviousData`? → `TSQ-PATTERN-04`
- [ ] Navegação de página desabilita com `isPlaceholderData`? → `TSQ-PATTERN-05`
- [ ] `useInfiniteQuery` declara `initialPageParam` e `getNextPageParam`? → `TSQ-PATTERN-06`
- [ ] `fetchNextPage` é guardado por `isFetchingNextPage`? → `TSQ-PATTERN-07`
- [ ] Lista infinita longa declara `maxPages`? → `TSQ-PATTERN-08`
- [ ] Disparo manual usa `enabled: false`, não `skipToken`? → `TSQ-PATTERN-09`
- [ ] Nenhum dado invalidável está em query permanentemente desabilitada? → `TSQ-PATTERN-10`
- [ ] Dado obrigatório usa `fetchQuery`, não `prefetchQuery`? → `TSQ-PATTERN-11`
- [ ] Prefetch e `useQuery` compartilham o `queryOptions`? → `TSQ-PATTERN-12`
- [ ] Nenhum `select` valida ou lança? → `TSQ-PATTERN-13`
- [ ] `select` com cálculo caro é estável? → `TSQ-PATTERN-14`

---

## Relacionados

- [TanStack Query](tanstack-query.md) — hub
- [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) · [TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md)
- ·
- · · ·
- [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) · [React - Patterns](react-patterns.md) · [React - Performance e Concorrência](react-performance-e-concorrencia.md) · [React.js](react-js.md) (`REACT-HOOK-01`)

## Fontes consultadas

Verificadas em **2026-08-14**:

- [Dependent Queries](https://tanstack.com/query/latest/docs/framework/react/guides/dependent-queries)
- [Parallel Queries](https://tanstack.com/query/latest/docs/framework/react/guides/parallel-queries)
- [Paginated Queries](https://tanstack.com/query/latest/docs/framework/react/guides/paginated-queries)
- [Infinite Queries](https://tanstack.com/query/latest/docs/framework/react/guides/infinite-queries)
- [Disabling / Pausing Queries](https://tanstack.com/query/latest/docs/framework/react/guides/disabling-queries)
- [Prefetching & Router Integration](https://tanstack.com/query/latest/docs/framework/react/guides/prefetching)
- [Render Optimizations](https://tanstack.com/query/latest/docs/framework/react/guides/render-optimizations) — `select`

**O que a verificação contrariou:**

- **`select` que lança não vira erro de query.** A fonte: *"A `select` function that returns an error results in `data` being `undefined` and `isSuccess` being `true`."* A nota anterior citava `select` só como ferramenta de inferência de tipo, sem o caveat — que é o mais perigoso da página.
- **Infinite query só admite um fetch em voo por vez**, e `fetchNextPage` durante outro fetch *"runs the risk of overwriting data refreshes happening in the background"*. Não estava registrado.
- **`prefetchQuery` respeita `staleTime`, mas o `staleTime` do prefetch não vale para o `useQuery`** — precisa ser configurado nos dois lugares.
- **Query desabilitada ignora `invalidateQueries` e `refetchQueries`.** A nota anterior descrevia `enabled: false` apenas como "não busca ao montar".
- **`useQueries` tem limitação de inferência com `select` inline** — o `data` do select não é inferido a partir da `queryFn` do mesmo objeto.
- **`useQueries` aceita `combine`** para reduzir o array de resultados, o que a nota anterior não mencionava.
