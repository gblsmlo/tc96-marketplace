---
titulo: TanStack Query - Mutations e Invalidação
Link: https://tanstack.com/query/latest/docs/framework/react/guides/mutations
tags:
  - tanstack-query
  - mutations
  - agent-context
source: "Documentação oficial — https://tanstack.com/query/latest/docs/framework/react"
verificado-em: 2026-08-14
---

# TanStack Query - Mutations e Invalidação

> `useMutation` · callbacks de ciclo de vida e suas assinaturas atuais · `mutate` × `mutateAsync` · `invalidateQueries` e `refetchType` · `setQueryData` · update otimista com snapshot e rollback · `useMutationState` · escopos e serialização.
>
> **Não cobre:** identidade de key e `queryFn` ([TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)) · `staleTime` e política de frescor ([TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md)) · `useOptimistic` do React ([React - Formulários e Actions](react-formularios-e-actions.md)).

Entrada: [TanStack Query](tanstack-query.md) · Base normativa: [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md)

---

## 1. Conceito: leitura e escrita não são simétricas

Uma query é idempotente, cacheável e pode rodar sozinha a qualquer momento. Uma mutation não é nada disso: ela tem efeito no servidor, roda uma vez por vontade explícita, e — este é o ponto — **invalida conhecimento que o cache tinha e não sabe que perdeu**.

Por isso a mutation não termina quando o servidor responde `200`. Ela termina quando o cache voltou a refletir o servidor. Esse segundo passo é o que separa código que funciona no happy path de código que funciona.

Três formas de fechar o ciclo, da mais barata em código à mais barata em rede:

| Estratégia | Custo | Quando |
| --- | --- | --- |
| `invalidateQueries` | uma requisição extra | padrão; o servidor pode ter derivado coisas que você não vê |
| `setQueryData` com a resposta | zero requisições | a resposta da mutation **é** o recurso completo e atualizado |
| Update otimista | zero requisições percebidas, mais código e mais testes | latência é percebida na interação (toggle, like, drag) |

O raciocínio conceitual está em — a nota vale a leitura antes de escrever a terceira.

---

## 2. `useMutation`

Estados verificados: `idle`, `pending`, `error`, `success` (com os espelhos `isIdle`, `isPending`, `isError`, `isSuccess`). As variáveis chegam *"by calling the mutate function with a single variable or object"* — um argumento só.

```tsx
const queryClient = useQueryClient()

const criarTodo = useMutation({
  mutationFn: (novo: NovoTodo) => api.post('/todos', novo),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})

criarTodo.mutate({ title: 'Lavar roupa' })
```

Escrita passa por `useMutation`. Usar `useQuery` para disparar um POST quebra tudo que a query assume: a `queryFn` roda em montagem, em foco de janela, em reconexão e em retry automático — quatro caminhos para executar a escrita sem ninguém ter pedido.

| ID | Regra |
| --- | --- |
| `TSQ-MUT-01` | Escrita no servidor **MUST** usar `useMutation` — `useQuery` **NEVER** dispara POST/PUT/PATCH/DELETE. |

### As assinaturas dos callbacks

**Este é o ponto mais desatualizado do material que circula sobre a biblioteca.** As assinaturas verificadas hoje na documentação:

```tsx
useMutation({
  mutationFn: updateTodo,
  onMutate: (variables, context) => {
    return { id: 1 }                       // vira `onMutateResult`
  },
  onError: (error, variables, onMutateResult, context) => {},
  onSuccess: (data, variables, onMutateResult, context) => {},
  onSettled: (data, error, variables, onMutateResult, context) => {},
})
```

Duas mudanças em relação ao que a maioria dos exemplos antigos mostra:

1. **O retorno de `onMutate` chega como terceiro argumento nomeado `onMutateResult`**, não como `context`.
2. **`context` agora é o último argumento e é outra coisa**: um objeto com `client` (o `QueryClient`), o que permite tocar o cache sem `useQueryClient`.

**A direção da quebra é a oposta da que se imagina — leia com atenção, porque é contraintuitivo.**

A mudança é **aditiva**, não uma troca de posição: o retorno de `onMutate` continua sendo o **terceiro argumento posicional**; ele só foi renomeado de `context` para `onMutateResult`, e um quarto argumento novo (`context`, com `client`) foi acrescentado. Nome de parâmetro não é vinculante em JavaScript.

Consequência prática:

| Código | Roda bem? |
| --- | --- |
| Forma antiga: `onError: (err, vars, context) => context.previousTodos` | **Sim.** O terceiro argumento continua sendo o retorno de `onMutate`. O nome `context` é apenas enganoso hoje. |
| Forma nova em versão que ainda não tem o quarto argumento: `context.client` | **Não.** `context` chega `undefined` e estoura em runtime. |

Ou seja: quem quebra não é quem escreveu a forma antiga — é quem adota `context.client` num projeto travado numa versão anterior da própria v5. Como `TSQ-BASE-10` manda travar patch exato, esse cenário é o comum, não o excepcional.

> **Não verificado:** a partir de qual release da v5 `onMutateResult` e `context.client` passaram a existir. Antes de usar `context.client`, confira a assinatura nos tipos da versão instalada (`node_modules/@tanstack/react-query`). Se não estiver lá, use `useQueryClient()` no escopo do componente — funciona em qualquer versão.

### Promise devolvida por callback

> "When returning a promise in any of the callback functions it will first be awaited before the next callback is called"

É o que mantém `isPending` verdadeiro até o refetch terminar. Sem `return`, o botão volta a "Salvar" enquanto a lista ainda mostra o estado antigo — e o usuário clica de novo.

```tsx
// ERRADO — a mutation "termina" antes de a lista atualizar
onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['todos'] }) }

// CERTO
onSuccess: () => queryClient.invalidateQueries({ queryKey: ['todos'] })
```

A fonte reforça no guia de optimistic updates: *"make sure to return the Promise from the query invalidation so that the mutation stays in `pending` state until the refetch is finished."*

### Callbacks por chamada

Também dá para passar `onSuccess`/`onError`/`onSettled` ao próprio `mutate`. E existe uma diferença que decide o que pode morar ali:

> "those additional callbacks won't run if your component unmounts before the mutation finishes"

> "When passed to the mutate function, they will be fired up only once and only if the component is still mounted"

Os callbacks do `useMutation` rodam sempre. Os do `mutate` rodam se o componente sobreviver. Logo: sincronização de cache, invalidação e rollback pertencem ao `useMutation`. Navegar, fechar modal e mostrar toast — coisas que só fazem sentido se a tela existe — pertencem ao `mutate`.

```tsx
const salvar = useMutation({
  mutationFn: updateTodo,
  // obrigatório: precisa acontecer mesmo se o usuário sair da tela
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})

salvar.mutate(valores, {
  // opcional: só faz sentido se a tela ainda estiver montada
  onSuccess: () => { fecharModal(); toast('Salvo') },
})
```

### `mutate` × `mutateAsync`

> "Use `mutateAsync` instead of `mutate` to get a promise which will resolve on success or throw on an error"

`mutate` não devolve nada e não lança — o erro vive em `mutation.error`. `mutateAsync` lança. Um `await mutateAsync(...)` sem `try/catch` produz unhandled rejection, mesmo com `onError` definido: o callback trata o efeito, não a Promise.

Use `mutateAsync` só quando precisar encadear (`await` de duas escritas em sequência, ou compor com outra Promise). Fora disso, `mutate` é a forma correta.

### Retry e escopo

> "By default, TanStack Query will not retry a mutation on error"

O default oposto ao das queries, e por bom motivo: repetir uma escrita não idempotente duplica o efeito. Ligar `retry` em mutation exige que a operação seja idempotente do lado do servidor —.

Sobre concorrência: mutations rodam em paralelo por padrão.

> "All mutations with the same `scope.id` will run in serial"

Duas escritas paralelas sobre o mesmo recurso produzem ordem de chegada indefinida no servidor, e — se houver update otimista — snapshots aninhados que restauram estado errado no rollback.

| ID | Regra |
| --- | --- |
| `TSQ-MUT-02` | Callback que dispara invalidação ou refetch **MUST** retornar a Promise, para a mutation seguir `pending` até o refetch terminar. |
| `TSQ-MUT-03` | Callback passado a `mutate(vars, {...})` **NEVER** carrega sincronização de cache, invalidação ou rollback — ele não roda se o componente desmontar. |
| `TSQ-MUT-04` | `mutateAsync` **MUST** ter `catch` ou `try/catch` — ele lança, diferente de `mutate`. |
| `TSQ-MUT-05` | `retry` em mutation **NEVER** é ligado sem idempotência garantida no servidor. |
| `TSQ-MUT-06` | Mutations que escrevem a mesma entrada de cache **MUST** declarar `scope: { id }` para rodar em série. |

---

## 3. `invalidateQueries`

O que a invalidação faz, literal da fonte:

> "It is marked as stale. This stale state overrides any `staleTime` configurations being used in `useQuery` or related hooks"

> "If the query is currently being rendered via `useQuery` or related hooks, it will also be refetched in the background."

Duas coisas, não uma. A marcação atinge **todas** as queries que casam com o filtro; o refetch atinge, por padrão, só as ativas.

### Casamento por prefixo

`{ queryKey: ['todos'] }` casa `['todos']`, `['todos', 'list', { page: 1 }]`, `['todos', 'detail', 42]` — tudo que começa com o prefixo. É o que torna a hierarquia de key (`TSQ-BASE-02`) uma decisão de arquitetura: a key define o que uma escrita consegue invalidar de uma vez.

```tsx
// invalida listagens e detalhes de todos
queryClient.invalidateQueries({ queryKey: ['todos'] })

// só as listagens
queryClient.invalidateQueries({ queryKey: ['todos', 'list'] })

// só a entrada exata
queryClient.invalidateQueries({ queryKey: ['todos', 'list'], exact: true })

// controle total
queryClient.invalidateQueries({
  predicate: (query) => query.queryKey[0] === 'todos' && algumCriterio(query),
})
```

Filtros verificados: `queryKey`, `exact`, `type: 'active' | 'inactive' | 'all'`, `stale`, `fetchStatus`, `predicate`. Sobre o `predicate`, a fonte: *"will receive each `Query` instance from the query cache and allow you to return `true` or `false` for whether you want to invalidate that query"*.

### `refetchType` — o que a maioria não configura

Da referência do `QueryClient`, `invalidateQueries` aceita `refetchType`, **default `'active'`**:

| Valor | Comportamento |
| --- | --- |
| `'active'` (default) | *"only queries that match the refetch predicate and are actively being rendered via `useQuery` and friends will be refetched in the background"* |
| `'inactive'` | só as que **não** estão sendo renderizadas |
| `'all'` | todas as que casam |
| `'none'` | *"no queries will be refetched, and those that match the refetch predicate will be marked as invalid only"* |

O default é o certo quase sempre: refazer agora o que está na tela, e deixar o resto marcado para refazer quando alguém montar. `'all'` em um prefixo largo, num app com muitas telas visitadas, dispara uma rajada de requisições por dado que ninguém está olhando.

Também aceita `cancelRefetch` (default `true`) e `throwOnError`.

### Invalidar sem filtro

`queryClient.invalidateQueries()` sem argumento marca **o cache inteiro** como stale. Funciona, e é por isso que aparece: resolve o bug de "esqueci de invalidar alguma coisa" ao custo de refazer toda query ativa da aplicação a cada escrita. Se você não sabe o que uma mutation afeta, o problema é a hierarquia de keys.

| ID | Regra |
| --- | --- |
| `TSQ-MUT-07` | `invalidateQueries()` sem filtro **NEVER** entra em código novo — invalide pelo prefixo mais específico que cobre o efeito da escrita. |

---

## 4. `setQueryData`

Quando a mutation devolve o recurso completo e atualizado, gravar direto evita a viagem de volta. A restrição é absoluta:

> "Updates via `setQueryData` must be performed in an *immutable* way."

> "DO NOT attempt to write directly to the cache by mutating data (that you retrieved from the cache) in place."

Mutar no lugar quebra structural sharing e o `Object.is` de que o React depende para saber que houve mudança: o dado no cache está certo, e a tela não atualiza.

```tsx
const editar = useMutation({
  mutationFn: editTodo,
  onSuccess: (todoAtualizado, variables, onMutateResult, context) => {
    // grava o detalhe
    context.client.setQueryData(
      todoOptions(todoAtualizado.id).queryKey,   // key tipada, vinda do queryOptions
      todoAtualizado,
    )
    // e reconcilia a listagem, imutavelmente
    context.client.setQueryData<Todo[]>(['todos', 'list'], (old) =>
      old?.map((t) => (t.id === todoAtualizado.id ? todoAtualizado : t)),
    )
  },
})
```

Da referência do `QueryClient`, um detalhe que evita cache lixo:

> "If the updater function returns `undefined`, the query data will not be updated. If the updater function receives `undefined` as input, you can return `undefined` to bail out of the update and thus *not* create a new cache entry."

Ou seja: `(old) => old?.map(...)` já se comporta bem quando a entrada não existe — devolve `undefined`, e nenhuma entrada é criada. Isso importa porque criar uma entrada de cache a partir de uma escrita, sem nunca ter buscado, produz dado parcial servido como se fosse completo.

| ID | Regra |
| --- | --- |
| `TSQ-MUT-08` | `setQueryData` **MUST** ser imutável — **NEVER** mutar no lugar o objeto lido do cache. |
| `TSQ-MUT-09` | Updater de `setQueryData` **MUST** devolver `undefined` quando recebe `undefined` — não crie entrada de cache a partir de uma escrita. |

---

## 5. Update otimista com snapshot e rollback

O ciclo completo, na forma que a documentação apresenta hoje:

```tsx
const alternar = useMutation({
  mutationFn: updateTodo,

  onMutate: async (novoTodo, context) => {
    // 1. cancelar refetches em voo: uma resposta antiga a caminho
    //    sobrescreveria o update otimista
    await context.client.cancelQueries({ queryKey: ['todos'] })

    // 2. snapshot ANTES de mexer
    const previousTodos = context.client.getQueryData<Todo[]>(['todos'])

    // 3. aplicar o otimismo, imutavelmente
    context.client.setQueryData<Todo[]>(['todos'], (old) =>
      old?.map((t) => (t.id === novoTodo.id ? novoTodo : t)),
    )

    // 4. o snapshot viaja pelo retorno — vira `onMutateResult`
    return { previousTodos }
  },

  onError: (err, novoTodo, onMutateResult, context) => {
    context.client.setQueryData(['todos'], onMutateResult.previousTodos)
  },

  onSettled: (data, error, variables, onMutateResult, context) =>
    context.client.invalidateQueries({ queryKey: ['todos'] }),
})
```

Cada passo cobre uma falha específica:

- **`cancelQueries`** — sem ele, um refetch em voo disparado antes da mutation chega depois do `setQueryData` e reverte o otimismo. O bug pisca na tela e some, o que o torna quase impossível de reproduzir sob demanda.
- **snapshot antes** — o valor precisa ser capturado antes da escrita otimista, não durante o `onError`, quando já foi sobrescrito.
- **snapshot pelo retorno de `onMutate`** — guardar em `useRef` ou variável de módulo quebra com mutations concorrentes: a segunda sobrescreve o snapshot da primeira, e o rollback restaura o estado errado. O canal existe justamente para isolar por chamada.
- **`invalidateQueries` em `onSettled`, não em `onSuccess`** — em sucesso, o servidor pode ter derivado coisas que a resposta não traz (`updatedAt`, contadores, ordenação). Em erro, o rollback restaurou um valor local que também precisa ser confirmado contra a fonte.
- **`return` no `onSettled`** — mantém `isPending` até o refetch terminar (`TSQ-MUT-02`).

Falha esperada e falha inesperada não se tratam igual aqui: `409 Conflict` é resultado de negócio e vira mensagem no formulário; timeout é defeito e vai para o boundary. `REACT-ASYNC-09` em [React - Suspense e Assincronia](react-suspense-e-assincronia.md).

### A alternativa mais barata: otimismo pela UI

Para um único ponto na interface, a fonte oferece um caminho sem tocar o cache — renderizar as `variables` da mutation enquanto ela está `pending`:

```tsx
const adicionar = useMutation({
  mutationFn: (texto: string) => api.post('/todos', { texto }),
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
})

const { isPending, variables, isError } = adicionar

return (
  <ul>
    {todos.map((t) => <Item key={t.id} todo={t} />)}
    {isPending && <li className="opacity-50">{variables}</li>}
    {isError && <li>Falhou. <button onClick={() => adicionar.mutate(variables!)}>Tentar de novo</button></li>}
  </ul>
)
```

Sem snapshot, sem rollback, sem risco de deixar ID temporário no cache — porque o cache nunca foi tocado. Quando a mutation resolve, o item provisório some e o invalidate traz o real.

Para ler mutations disparadas por **outro** componente, existe `useMutationState` com filtro por `mutationKey`.

**Critério de escolha:** se o dado otimista precisa aparecer em mais de um lugar, ou sobreviver à navegação, o otimismo pertence ao cache. Se aparece em um lugar só, use `variables` — é a versão que não tem como dar rollback errado.

| ID | Regra |
| --- | --- |
| `TSQ-MUT-10` | Update otimista sobre o cache **MUST** ter o ciclo completo: `cancelQueries` → snapshot → `setQueryData` → rollback em `onError` → invalidação em `onSettled`. |
| `TSQ-MUT-11` | O snapshot **MUST** trafegar pelo retorno de `onMutate` (`onMutateResult`) — **NEVER** por `useRef`, variável de módulo ou estado de componente. |
| `TSQ-MUT-12` | A invalidação pós-otimismo **MUST** ficar em `onSettled`, nunca só em `onSuccess`. |

---

## Antipadrões

```tsx
// FRÁGIL — funciona, mas o nome mente: o terceiro argumento é o retorno
// de onMutate, não o `context` novo. Quem for editar depois vai confundir.
onError: (err, novo, context) => {
  queryClient.setQueryData(['todos'], context.previous)
},

// CERTO — nomeie o terceiro pelo que ele é, e guarde contra onMutate que falhou
onError: (err, novo, onMutateResult) => {
  if (!onMutateResult?.previousTodos) return   // onMutate lançou antes do return
  queryClient.setQueryData(['todos'], onMutateResult.previousTodos)
},
```

A guarda não é preciosismo: se `onMutate` lançar antes do `return` — `cancelQueries` rejeitando, por exemplo — `onMutateResult` chega `undefined`, e **a linha do rollback vira a linha que derruba a aplicação**. O callback encarregado de consertar o estado é o que quebra.

```tsx
// ERRADO — mutação no lugar: o cache muda, a tela não
onSuccess: (todo) => {
  const lista = queryClient.getQueryData<Todo[]>(['todos'])
  lista!.push(todo)
}

// CERTO
onSuccess: (todo) => {
  queryClient.setQueryData<Todo[]>(['todos'], (old) => (old ? [...old, todo] : old))
}
```

```tsx
// ERRADO — mutateAsync sem catch: unhandled rejection mesmo com onError definido
const salvar = async () => {
  await mutation.mutateAsync(valores)
  navegar('/todos')
}

// CERTO — ou mutate com callback, ou try/catch
const salvar = () => mutation.mutate(valores, { onSuccess: () => navegar('/todos') })
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| `invalidateQueries()` sem filtro após toda escrita | refaz toda query ativa da app por qualquer mutation | invalidar pelo prefixo — `TSQ-MUT-07` |
| Update otimista sem `cancelQueries` | refetch em voo chega depois e reverte o otimismo; bug intermitente | `await cancelQueries` em `onMutate` — `TSQ-MUT-10` |
| Snapshot em `useRef` | mutations concorrentes sobrescrevem o snapshot; rollback restaura estado errado | retorno de `onMutate` — `TSQ-MUT-11` |
| Invalidar só em `onSuccess` | rollback deixa valor local não confirmado contra o servidor | `onSettled` — `TSQ-MUT-12` |
| `retry: 3` em `POST /pedidos` | três pedidos duplicados | manter default, ou garantir idempotência — `TSQ-MUT-05` |
| Fechar modal em `onSuccess` do `useMutation` | roda mesmo depois de a tela ter sumido | `mutate(vars, { onSuccess })` — `TSQ-MUT-03` |

---

## Checklist de revisão

- [ ] Toda escrita passa por `useMutation`? → `TSQ-MUT-01`
- [ ] Callbacks de invalidação usam `return`? → `TSQ-MUT-02`
- [ ] Rollback e invalidação estão no `useMutation`, não no `mutate`? → `TSQ-MUT-03`
- [ ] Todo `mutateAsync` tem tratamento de erro? → `TSQ-MUT-04`
- [ ] Nenhum `retry` em mutation não idempotente? → `TSQ-MUT-05`
- [ ] Mutations concorrentes sobre o mesmo recurso têm `scope`? → `TSQ-MUT-06`
- [ ] Nenhum `invalidateQueries()` sem filtro? → `TSQ-MUT-07`
- [ ] Todo `setQueryData` é imutável? → `TSQ-MUT-08`
- [ ] Updater devolve `undefined` quando não há entrada? → `TSQ-MUT-09`
- [ ] Update otimista tem os cinco passos? → `TSQ-MUT-10`
- [ ] O snapshot vem do retorno de `onMutate`? → `TSQ-MUT-11`
- [ ] A invalidação final está em `onSettled`? → `TSQ-MUT-12`
- [ ] As assinaturas dos callbacks têm `onMutateResult` como terceiro argumento?

---

## Relacionados

- [TanStack Query](tanstack-query.md) — hub
- [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) · [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) · [TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md)
- · ·
- · · ·
- [React - Formulários e Actions](react-formularios-e-actions.md) (`useOptimistic`) · [React - Suspense e Assincronia](react-suspense-e-assincronia.md) (`REACT-ASYNC-09`) · [React - Patterns](react-patterns.md)

## Fontes consultadas

Verificadas em **2026-08-14**:

- [Mutations](https://tanstack.com/query/latest/docs/framework/react/guides/mutations)
- [Query Invalidation](https://tanstack.com/query/latest/docs/framework/react/guides/query-invalidation)
- [Updates from Mutation Responses](https://tanstack.com/query/latest/docs/framework/react/guides/updates-from-mutation-responses)
- [Optimistic Updates](https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates)
- [Filters](https://tanstack.com/query/latest/docs/framework/react/guides/filters)
- [QueryClient reference](https://tanstack.com/query/latest/docs/reference/QueryClient) — `refetchType`, `setQueryData`

**O que a verificação contrariou:**

- **As assinaturas dos callbacks mudaram e a nota anterior estava implicitamente desatualizada.** Hoje: `onError: (error, variables, onMutateResult, context)`. O retorno de `onMutate` é o **terceiro** argumento (`onMutateResult`); o quarto (`context`) é um objeto com `client`. A mudança é **aditiva**: código antigo que lê o terceiro parâmetro chamando-o de `context` continua correto em runtime — o risco está em adotar `context.client` numa versão que ainda não tem o quarto argumento. Ver § 2.
- **Os exemplos oficiais de optimistic update agora usam `context.client`** em vez de `useQueryClient()` — o `QueryClient` chega pelo callback.
- **`invalidateQueries` tem `refetchType`, default `'active'`.** A nota anterior tratava invalidação como se refizesse tudo que casa com o filtro; por padrão, inativas são só marcadas.
- **`setQueryData` tem semântica documentada para `undefined`**: updater que devolve `undefined` não atualiza e não cria entrada — não é um no-op acidental.
- **A `predicate` de filtro recebe a instância de `Query`**, não a key — dá acesso a `query.state`.
- A nota anterior grafava "Konkurênz" no lugar de concorrência, e afirmava que Mutation Scopes exigem `setMutationDefaults`. O que a fonte liga a `setMutationDefaults` é a **persistência de mutations offline**; `scope: { id }` é opção direta do `useMutation`.
