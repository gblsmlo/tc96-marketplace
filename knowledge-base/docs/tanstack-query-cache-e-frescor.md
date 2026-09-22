---
Link: https://tanstack.com/query/latest/docs/framework/react/guides/caching
tags:
 - tanstack-query
 - cache
 - agent-context
source: "Documentação oficial — https://tanstack.com/query/latest/docs/framework/react"
verificado-em: 2026-08-14
---

# TanStack Query - Cache e Frescor

> Ciclo de vida de uma query · `staleTime` × `gcTime` · gatilhos de refetch e como calibrá-los · structural sharing e tracked properties · `placeholderData` × `initialData`.
>
> **Não cobre:** identidade de key e `queryFn` ([TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)) · invalidação disparada por escrita ([TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md)) · `keepPreviousData` em paginação ([TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md)) · hidratação e `gcTime` em SSR ([TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md)).

Entrada: [TanStack Query](tanstack-query.md) · Base normativa: [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)

---

## 1. Conceito: frescor é decisão de domínio, não default

Cache não é "guardar a resposta". É responder três perguntas que a biblioteca não pode responder por você:

1. **Por quanto tempo esta resposta pode ser exibida sem consultar de novo?** → `staleTime`
2. **Por quanto tempo ela vale a pena manter em memória depois que ninguém a usa?** → `gcTime`
3. **Quais leituras uma escrita torna suspeitas?** → invalidação

Os defaults respondem as três de um jeito específico e agressivo: *nada é fresco* (`staleTime: 0`), *guarde 5 minutos* (`gcTime`), *nada invalida nada sozinho*. Isso é ótimo para começar e péssimo para deixar quieto — o raciocínio está em:

> "Uma lista alterada frequentemente e uma tabela estática de referência não compartilham necessariamente a mesma política. Defaults precisam ser conhecidos antes de serem aceitos."

O erro estrutural não é escolher mal o `staleTime`. É nunca escolher, e depois combater os sintomas desligando `refetchOnWindowFocus`.

---

## 2. O ciclo de vida de uma query

A fonte narra o ciclo com um exemplo de `gcTime: 3 * 60 * 1000`. Reproduzido com os pontos verificados:

**1. Primeira instância de `useQuery({ queryKey: ['todos'], queryFn: fetchTodos })` monta.**

> "Since no other queries have been made with the `['todos']` query key, this query will show a hard loading state and make a network request to fetch the data."

Os dados voltam, são cacheados sob a key, e ficam *"marked as stale after the configured `staleTime` (defaults to `0`, or immediately)"*.

**2. Uma segunda instância da mesma key monta em outro lugar da árvore.**

> "Since the cache already has data for the `['todos']` key from the first query, that data is immediately returned from the cache."

Não há loading state — há dado de cache imediato **mais** uma requisição em segundo plano. Quando ela volta, *"the cache's data under the `['todos']` key is updated with the new data, and both instances are updated with the new data"*. É a dedupe e a sincronização entre instâncias acontecendo sem que nenhum componente saiba do outro.

**3. Todas as instâncias desmontam.** A query fica **inativa**.

> "Since there are no more active instances of this query, a garbage collection timeout is set using `gcTime` to delete and garbage collect the query (defaults to **5 minutes**)."

**4a. Uma nova instância monta antes do timeout.** A query *"immediately returns the available cached data while the `fetchTodos` function is being run in the background"*. Este é o efeito que o usuário percebe como "o app é rápido": voltar para uma tela mostra o conteúdo na hora.

**4b. Ninguém monta dentro dos 5 minutos.** *"The cached data under the `['todos']` key is deleted and garbage collected."*

O que esse ciclo estabelece: **`staleTime` e `gcTime` governam fases diferentes e não competem.** `staleTime` age enquanto a query está **ativa** (decide se refaz). `gcTime` age depois que ela ficou **inativa** (decide quando descarta). Um `staleTime` alto com `gcTime` baixo dá um app que não revalida mas perde o cache ao trocar de tela — a pior combinação possível.

| | `staleTime` | `gcTime` |
| --- | --- | --- |
| Governa | quando o dado é considerado velho | quanto tempo o dado inativo fica na memória |
| Vale enquanto | há instância ativa | **não** há instância ativa |
| Default | `0` | 5 minutos |
| Efeito de aumentar | menos requisições | mais memória, navegação mais rápida |
| Nome antigo | — | `cacheTime` (v4) |

---

## 3. `staleTime`: escolher uma política

Uma query stale refaz sozinha nos três gatilhos verificados na fonte:

> "New instances of the query mount" · "The window is refocused" · "The network is reconnected"

Com `staleTime: 0`, isso significa: cada montagem de componente, cada volta de aba, cada reconexão de wifi dispara rede. Em uma tela com seis queries e um usuário que alterna abas, é tráfego considerável para dado que não mudou.

**A calibração se faz pela volatilidade do dado, não pela tela.**

| Natureza do dado | `staleTime` | Racional |
| --- | --- | --- |
| Feature flags, permissões, enums, tabelas de referência | `'static'` | imutável durante a sessão |
| Perfil do usuário, configurações de conta | 30–60 min | muda raramente, e por ação do próprio usuário |
| Listagem de recursos do usuário | 1–5 min | muda pela app, e a mutation invalida |
| Detalhe consultado logo após listagem | igual ao da listagem | evita refetch imediato ao navegar |
| Contadores, status ao vivo, saldo | `0` + `refetchInterval` | frescor é o requisito |

Os dois valores especiais, literais da fonte:

- **`Infinity`** — impede refetch por staleness. `invalidateQueries` continua funcionando.
- **`'static'`** — *"never trigger a refetch, even if the Query is invalidated manually"*. Bloqueia também `refetchOnMount`, `refetchOnWindowFocus` e `refetchOnReconnect` mesmo configurados como `"always"`.

A diferença é decisiva: `'static'` remove a query do alcance da invalidação. Usá-lo em dado que uma mutation pode mudar produz um bug que não aparece em teste — a invalidação roda, retorna sem erro, e não faz nada.

```tsx
// Base sã para uma app CRUD: default conservador, exceções explícitas.
new QueryClient({
 defaultOptions: {
 queries: {
 staleTime: 60_000,
 gcTime: 10 * 60_000,
 },
 },
})

export const featureFlagsOptions = queryOptions({
 queryKey: ['feature-flags'],
 queryFn: fetchFlags,
 staleTime: 'static', // não muda em runtime, e nada invalida
})
```

| ID | Regra |
| --- | --- |
| `TSQ-CACHE-01` | `staleTime` **MUST** aparecer explicitamente na query ou nos `defaultOptions` do `QueryClient` — aceitar `0` é decisão, não omissão. |
| `TSQ-CACHE-02` | `staleTime: 'static'` **NEVER** é usado em dado que alguma mutation pode alterar — ele bloqueia `invalidateQueries`. |

---

## 4. Os gatilhos de refetch e a tentação de desligá-los

Cada gatilho tem um flag: `refetchOnMount`, `refetchOnWindowFocus`, `refetchOnReconnect`. Todos aceitam `true` (default), `false` e `'always'` — `'always'` ignora o `staleTime` e refaz de qualquer jeito.

A rota errada quando o app requisita demais é `refetchOnWindowFocus: false`. Ela funciona, e é por isso que engana: some o sintoma e mantém o problema. O que `staleTime: 0` está dizendo é "este dado nunca pode ser confiado", e essa afirmação continua verdadeira depois de você desligar o gatilho — ela só deixou de ser visível. O resultado é uma app que exibe dado velho ao montar componente, porque `refetchOnMount` continua ligado, e não exibe ao voltar para a aba, porque o focus foi desligado. Duas políticas contraditórias no mesmo cache.

A ordem correta é: calibrar `staleTime` primeiro. Se depois disso um gatilho específico ainda incomoda (janela de dashboard que fica aberta o dia inteiro, por exemplo), desligue esse gatilho — como ajuste fino, não como remédio.

Para casos fora do browser, a fonte documenta o `focusManager`: `focusManager.setEventListener` substitui o listener padrão (`visibilitychange` + `document.visibilityState === 'visible'`), e `focusManager.setFocused(true | false | undefined)` força o estado. Em React Native o gancho é o módulo `AppState`.

| ID | Regra |
| --- | --- |
| `TSQ-CACHE-03` | Excesso de refetch **MUST** ser corrigido por `staleTime` antes de qualquer `refetchOnMount`/`refetchOnWindowFocus`/`refetchOnReconnect: false`. |

---

## 5. Structural sharing e tracked properties

Duas otimizações que rodam sozinhas — e duas maneiras de desligá-las sem perceber.

### Structural sharing

> "React Query will keep the original reference if *nothing* changed in the data. If a subset changed, React Query will keep the unchanged parts and only replace the changed parts."

Consequência: um refetch que devolve exatamente o mesmo JSON não re-renderiza nada, e um refetch que muda um item de uma lista de 200 preserva a identidade dos outros 199 — `memo`, `useMemo` e arrays de dependência continuam valendo.

A limitação é literal:

> "This optimization only works if the `queryFn` returns JSON compatible data."

`Date`, `Map`, `Set`, `BigInt`, instâncias de classe: sempre parecem novas. Uma `queryFn` que converte strings ISO em `Date` antes de devolver desliga a otimização para o objeto inteiro. A conversão pertence ao consumidor (ou a um `select`), não ao cache. Dá para desligar com `structuralSharing: false` ou substituir por implementação própria.

### Tracked properties

O resultado de `useQuery` é um Proxy. O componente só re-renderiza pelas propriedades que ele **acessa**. Um componente que lê só `data` não re-renderiza quando `isFetching` alterna.

E o jeito de perder isso:

> "The get trap of a proxy is invoked by accessing a property, either via destructuring or by accessing it directly. If you use object rest destructuring, you will disable this optimization."

```tsx
// ERRADO — rest destructuring toca todas as propriedades:
// o componente passa a re-renderizar por isFetching, isStale, dataUpdatedAt...
const { data,...rest } = useQuery(todosOptions)

// CERTO — só as propriedades realmente lidas entram no tracking
const { data, isLoading } = useQuery(todosOptions)
```

Ajuste explícito, quando necessário: `notifyOnChangeProps`.

| ID | Regra |
| --- | --- |
| `TSQ-CACHE-04` | `queryFn` **MUST** devolver dado compatível com JSON — `Date`, `Map`, `Set` e instâncias de classe quebram structural sharing. Converta no consumidor ou em `select`. |
| `TSQ-CACHE-05` | O resultado de `useQuery` **NEVER** é desestruturado com rest (`const { data,...rest }`) — isso desliga tracked properties. |

---

## 6. `placeholderData` × `initialData`

As duas opções fazem a query começar em `success` em vez de `pending`. A diferença é uma só, e ela decide tudo:

> "Placeholder data allows a query to behave as if it already has data, similar to the `initialData` option, but **the data is not persisted to the cache**."

| | `initialData` | `placeholderData` |
| --- | --- | --- |
| Vai para o cache | **sim** | não |
| Sujeito a `staleTime` | sim — conta como se tivesse acabado de ser buscado | não se aplica |
| Sinalizado no resultado | não há flag | `isPlaceholderData: true` |
| Outras instâncias da mesma key veem | sim | não |
| Para que serve | dado **real**, só que obtido por outro caminho | dado **provisório**, para não mostrar tela vazia |

### `initialData` — dado real por outro caminho

> "`initialData` is persisted to the cache, so it is not recommended to provide placeholder, partial or incomplete data."

O uso legítimo é aproveitar o que já está em outro ponto do cache: o item que a listagem já trouxe, servindo de ponto de partida para a tela de detalhe.

```tsx
const todo = useQuery({
...todoOptions(todoId),
 initialData: =>
 queryClient
.getQueryData<Todo[]>(['todos', 'list'])
 ?.find((t) => t.id === todoId),
 initialDataUpdatedAt: =>
 queryClient.getQueryState(['todos', 'list'])?.dataUpdatedAt,
})
```

O `initialDataUpdatedAt` é o que impede o pior caso. Sem ele, um item cacheado há vinte minutos entra como se tivesse acabado de chegar, e o `staleTime` protege dado velho de ser revalidado. A fonte descreve a opção como *"a numeric JS timestamp in milliseconds of when the initialData itself was last updated"*.

Sobre a interação com `staleTime`: sem `staleTime` configurado, *"the query will immediately refetch when it mounts"*; com `staleTime`, *"the data will be considered fresh for that same amount of time, as if it was just fetched from your query function"*.

### `placeholderData` — provisório, e marcado como tal

Não entra no cache, não contamina outras instâncias, e vem com bandeira: *"the result includes an `isPlaceholderData` flag set to `true`"*.

Aceita função com dois parâmetros, `previousData` e `previousQuery`, que é a base da paginação sem piscar (`keepPreviousData` — [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) § 3).

```tsx
const { data, isPlaceholderData } = useQuery({
...todoOptions(todoId),
 placeholderData: { id: todoId, title: '', done: false }, // esqueleto
})

// O dado provisório não pode alimentar decisão nem escrita.
<button disabled={isPlaceholderData} onClick={ => concluir(data)}>
 Concluir
</button>
```

Ignorar `isPlaceholderData` é o que transforma a otimização em bug: o usuário clica em "próxima página" sobre uma contagem provisória, ou submete um formulário pré-preenchido com esqueleto.

| ID | Regra |
| --- | --- |
| `TSQ-CACHE-06` | `initialData` **NEVER** recebe dado parcial, incompleto ou de esqueleto — ele é persistido no cache e outras instâncias o leem. |
| `TSQ-CACHE-07` | `initialData` derivado de outro cache **MUST** vir acompanhado de `initialDataUpdatedAt`. |
| `TSQ-CACHE-08` | Consumidor de `placeholderData` **MUST** checar `isPlaceholderData` antes de habilitar ação ou decisão baseada nele. |

---

## Antipadrões

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| Nunca declarar `staleTime` | todo dado nasce stale; a app requisita a cada montagem, foco e reconexão | `staleTime` explícito por volatilidade — `TSQ-CACHE-01` |
| `refetchOnWindowFocus: false` como remédio geral | apaga o sintoma e deixa `refetchOnMount` com política oposta no mesmo cache | calibrar `staleTime` — `TSQ-CACHE-03` |
| `staleTime: 'static'` em dado que uma mutation altera | `invalidateQueries` roda, não falha, e não surte efeito | `Infinity` (invalidação continua funcionando) — `TSQ-CACHE-02` |
| `staleTime: Infinity` + `gcTime` default | não revalida enquanto ativa, mas perde tudo 5 min depois de sair da tela | subir `gcTime` junto |
| `queryFn` convertendo ISO em `Date` | objeto inteiro parece novo a cada refetch; structural sharing desligado | converter em `select` ou no componente — `TSQ-CACHE-04` |
| `const { data,...rest } = useQuery(...)` | rest toca todas as props do Proxy; re-render por `isFetching`, `isStale`, `dataUpdatedAt` | desestruturar só o que usa — `TSQ-CACHE-05` |
| `initialData` com objeto de esqueleto | esqueleto é gravado no cache e servido a todas as instâncias da key | `placeholderData` — `TSQ-CACHE-06` |
| `initialData` de outro cache sem timestamp | dado antigo entra como recém-buscado e o `staleTime` protege o obsoleto | `initialDataUpdatedAt` — `TSQ-CACHE-07` |

---

## Checklist de revisão

- [ ] Existe `staleTime` explícito na query ou no `defaultOptions`? → `TSQ-CACHE-01`
- [ ] Algum `staleTime: 'static'` cobre dado que uma mutation altera? → `TSQ-CACHE-02`
- [ ] Há gatilho de refetch desligado sem `staleTime` calibrado antes? → `TSQ-CACHE-03`
- [ ] A `queryFn` devolve só valores compatíveis com JSON? → `TSQ-CACHE-04`
- [ ] Nenhum `const { data,...rest }` no resultado de `useQuery`? → `TSQ-CACHE-05`
- [ ] `initialData` só recebe dado real e completo? → `TSQ-CACHE-06`
- [ ] `initialData` vindo do cache traz `initialDataUpdatedAt`? → `TSQ-CACHE-07`
- [ ] `isPlaceholderData` bloqueia ações sobre dado provisório? → `TSQ-CACHE-08`
- [ ] `gcTime` acompanha o `staleTime` quando a navegação retorna à mesma tela?

---

## Relacionados

- [TanStack Query](tanstack-query.md) — hub
- [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) · [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) · [TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md)
- ·
- · ·
- [React - Performance e Concorrência](react-performance-e-concorrencia.md) · [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md)

## Fontes consultadas

Verificadas em **2026-08-14**:

- [Caching](https://tanstack.com/query/latest/docs/framework/react/guides/caching)
- [Important Defaults](https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults)
- [Render Optimizations](https://tanstack.com/query/latest/docs/framework/react/guides/render-optimizations)
- [Initial Query Data](https://tanstack.com/query/latest/docs/framework/react/guides/initial-query-data)
- [Placeholder Query Data](https://tanstack.com/query/latest/docs/framework/react/guides/placeholder-query-data)
- [Window Focus Refetching](https://tanstack.com/query/latest/docs/framework/react/guides/window-focus-refetching)
- [Query Retries](https://tanstack.com/query/latest/docs/framework/react/guides/query-retries)

**O que a verificação contrariou:**

- **Tracked properties não estavam na nota anterior**, e o caveat é o mais fácil de violar de toda a biblioteca: `const { data,...rest }` desliga a otimização inteira em silêncio.
- **A página de Placeholder Query Data não menciona `keepPreviousData`.** Ele aparece no guia de Paginated Queries. A associação "placeholderData = keepPreviousData" é derivada, não literal da página do conceito.
- **`initialDataUpdatedAt` existe e é o que impede dado velho de entrar como fresco.** A nota anterior tratava `initialData` apenas como "pré-popular o cache", sem o problema de timestamp.
- **A página de Window Focus Refetching não documenta `'always'`** para `refetchOnWindowFocus`; o valor aparece indiretamente no guia de defaults, ao explicar o que `staleTime: 'static'` bloqueia.
- **`staleTime: 'static'` bloqueia `refetchOnMount`/`refetchOnWindowFocus`/`refetchOnReconnect` mesmo em `"always"`** — mais forte do que "não refetch por invalidação".
