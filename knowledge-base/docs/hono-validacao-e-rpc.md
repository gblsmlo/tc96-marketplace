---
titulo: Hono - Validação e RPC
Link: https://hono.dev/docs/guides/rpc
tags:
  - hono
  - validacao
  - rpc
  - agent-context
source: "Documentação oficial — https://hono.dev/docs"
verificado-em: 2026-08-15
---

# Hono - Validação e RPC

> `validator()` nativo e os seis targets · `zValidator` e o `sValidator` de Standard Schema · `c.req.valid()` · a resposta de erro default e como trocá-la · `export type AppType` e `hc<AppType>()` · chamada tipada, `param`/`query`/`header`/credenciais, `$url()` e `$path()` · `InferRequestType`/`InferResponseType`/`ApplyGlobalResponse` · o contrato da `queryFn` do TanStack Query · as limitações reais de inferência e o custo de compilação.
>
> **Não cobre:** declarar rota e formar resposta ([Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md)) · ordem e built-ins de middleware ([Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md)) · o panorama da ponte com o stack e o critério de adoção ([Hono](hono.md) § 8).

Entrada: [Hono](hono.md) · Base normativa: [Hono](hono.md) § 2 e § 6

---

## 1. Conceito: validar na fronteira e derivar o tipo do cliente são a mesma operação

Numa API tipada convencional há três descrições do mesmo contrato: o schema que valida em runtime, o tipo TypeScript do servidor, e o tipo que o frontend declara para consumir. As três divergem — não por descuido, mas porque nada as obriga a andar juntas.

Hono elimina a terceira, e a mecânica é simples: **o validator registrado numa rota vira parte do tipo daquela rota**. `zValidator('json', schema)` faz duas coisas indissociáveis — parseia o corpo em runtime e ensina ao tipo do app qual é o formato do input. `c.json(body, status)` faz o análogo na saída. E como o tipo do app se acumula pelo encadeamento ([Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 1), o `typeof` da variável final é o contrato inteiro.

```
schema Zod  ──┬──▶  validação em runtime (c.req.valid)
              └──▶  tipo do input na rota  ──┐
                                              ├──▶  typeof routes ──▶ hc<AppType>()
c.json(body, status) ──▶ tipo de saída  ──────┘
```

Não há geração de código, arquivo intermediário nem build step. Há um `typeof` cruzando um import.

Isso é o que descreve, com uma diferença importante: o contrato canônico aqui **é o código da rota**, não um documento. Ver. A contrapartida está na § 7: o acoplamento de tipo é forte, e nem todo projeto quer isso.

---

## 2. `validator()`: o mínimo, e o que ele estabelece

Hono traz *"only a very thin Validator"*. Ele não conhece schema nenhum: recebe um target e um callback que devolve o valor validado.

```ts
import { validator } from 'hono/validator'

app.post(
  '/pedidos',
  validator('json', (value, c) => {
    if (typeof value.clienteId !== 'string') {
      return c.json({ error: 'clienteId obrigatório' as const }, 400)
    }
    return { clienteId: value.clienteId }     // o retorno é o que c.req.valid devolve
  }),
  (c) => {
    const { clienteId } = c.req.valid('json')  // tipado pelo retorno do callback
    return c.json({ ok: true }, 201)
  }
)
```

Os seis targets: **`json`, `form`, `query`, `param`, `header`, `cookie`**. Vários validators podem coexistir na mesma rota, um por target.

Duas restrições que valem para o validator nativo e para todos os de terceiros:

**`json` e `form` exigem `Content-Type` casando.** Caso contrário *"the request body will not be parsed and you will receive an empty object (`{}`) as value in the callback"*. Em teste, é o erro que faz a suíte exercitar o caminho de falha sem que ninguém perceba — ver [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 8.

**O target `header` usa chaves minúsculas.** Validar `Idempotency-Key` significa ler `value['idempotency-key']`. A doc mostra as duas versões, ❌ e ✅, e a errada *"always return 400 as not expected"*. Relevante para onde a chave é justamente um header.

| ID | Regra |
| --- | --- |
| `HONO-RPC-01` | Todo input vindo do request **MUST** passar por um validator antes de alimentar lógica de domínio — `c.req.json()` cru **NEVER** é lido diretamente numa rota que aceita input externo. |
| `HONO-RPC-02` | O handler **MUST** ler o dado por `c.req.valid(target)`; reler `c.req.json()`/`c.req.query()` depois do validator **NEVER** acontece. |
| `HONO-RPC-03` | Validação de `header` **MUST** usar a chave em minúsculas. |

---

## 3. `zValidator`: schema no lugar do callback

`@hono/zod-validator` substitui o callback por um schema Zod. É a forma recomendada pela própria doc: *"We recommend using a third-party validator."*

```ts
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import * as z from 'zod'

const criarPedido = z.object({
  clienteId: z.string().uuid(),
  itens: z.array(z.object({ sku: z.string(), quantidade: z.number().int().positive() })).min(1),
})

const listarPedidos = z.object({
  pagina: z.coerce.number().int().positive().optional(),   // coerce: query chega string
  status: z.enum(['aberto', 'confirmado', 'cancelado']).optional(),
})

const routes = new Hono()
  .get('/pedidos', zValidator('query', listarPedidos), (c) => {
    const { pagina, status } = c.req.valid('query')   // number | undefined, enum | undefined
    return c.json({ pedidos: buscar({ pagina, status }) }, 200)
  })
  .post('/pedidos', zValidator('json', criarPedido), async (c) => {
    const input = c.req.valid('json')                 // z.infer<typeof criarPedido>
    return c.json({ pedido: await criar(input) }, 201)
  })
  .patch(
    '/pedidos/:id',
    zValidator('param', z.object({ id: z.string().uuid() })),
    zValidator('json', criarPedido.partial()),
    async (c) => {
      const { id } = c.req.valid('param')
      const patch = c.req.valid('json')
      return c.json({ pedido: await atualizar(id, patch) }, 200)
    }
  )
```

**`z.coerce` é o que reconcilia HTTP com tipos.** `query`, `param` e `header` chegam sempre como `string`. `z.coerce.number()` converte no servidor — e o cliente RPC continua obrigado a enviar `string` (§ 5). O schema é a fronteira entre os dois mundos.

**`sValidator` cobre o resto do ecossistema.** `@hono/standard-validator` aceita qualquer biblioteca [Standard Schema](https://standardschema.dev/) — Zod, Valibot, ArkType. Mesma assinatura, mesmos targets. Escolha-o se o vault um dia trocar de biblioteca de schema; a rota não muda.

**Versões verificadas:** `@hono/zod-validator` 0.9.0 tem peer deps `zod: ^3.25.0 || ^4.0.0` e `hono: >=4.11.2`.

---

## 4. A resposta de erro default é um vazamento — e é fácil trocar

Sem `hook`, quando a validação falha o middleware responde `c.json(result, 400)`, onde `result` é o **objeto `SafeParseError` inteiro do Zod**. Isto é: a estrutura interna do schema — caminhos, códigos de erro, mensagens — vai para o cliente por default. Pior: esse formato entra no **tipo da rota** como `TypedResponse<..., 400, 'json'>`, então o contrato do frontend passa a depender do formato de erro do Zod.

O terceiro argumento — o `hook` — troca isso. **Devolver é a forma default nesta estrutura**, porque o caso-alvo é um formulário React que exibe erro por campo: o que `return c.json(...)` produz entra no tipo da rota de forma controlada e chega ao `hc` discriminado por status (`HONO-CORE-13`). O que sai por `throw` vai para `app.onError` e **não entra na inferência** (`HONO-RPC-09`).

```ts
// validator-wrapper.ts — um lugar só, para o app inteiro
import type { ValidationTargets } from 'hono'
import { zValidator as zv } from '@hono/zod-validator'
import type * as z from 'zod'

export const zValidator = <T extends z.ZodType, Target extends keyof ValidationTargets>(
  target: Target,
  schema: T
) =>
  zv(target, schema, (result, c) => {
    if (!result.success) {
      return c.json(
        {
          error: 'validação falhou' as const,
          campos: result.error.issues.map((i) => ({
            campo: i.path.join('.'),
            mensagem: i.message,
          })),
        },
        400
      )
    }
  })
```

Agora o 400 tem formato próprio, o frontend deriva `InferResponseType<typeof $post, 400>` e mapeia `campos` para `setError` do formulário — ver [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) e [React - Formulários e Actions](react-formularios-e-actions.md).

**Lançar é a exceção, não o padrão.** Vale quando o 400 de validação não é dado de tela — endpoint de máquina, webhook, rota administrativa — e o cliente só precisa saber que falhou:

```ts
import { HTTPException } from 'hono/http-exception'

zv(target, schema, (result, c) => {
  if (!result.success) {
    throw new HTTPException(400, { cause: result.error })
  }
})
```

A doc registra esse segundo padrão como "Throw Error". Ele centraliza o tratamento em `app.onError` ([Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 7) e paga com o tipo: o corpo do 400 some do contrato da rota, e recuperá-lo exige declarar o status em `ApplyGlobalResponse` (`HONO-RPC-09`).

**`validationFunction`** é o quarto argumento, para casos como `.passthrough()`: por default o middleware usa `await schema.safeParseAsync(value)`.

| ID | Regra |
| --- | --- |
| `HONO-RPC-04` | Rota pública **MUST** customizar a resposta de erro do validator via `hook` — o default serializa o `SafeParseError` do Zod no corpo e no tipo da rota. |

---

## 5. `AppType` e `hc`: o contrato atravessando

Duas linhas no servidor, duas no cliente.

```ts
// server/routes.ts
export type AppType = typeof routes        // `routes` é a variável que recebeu a CADEIA
export default routes
```

```ts
// web/src/api.ts
import { hc } from 'hono/client'
import type { AppType } from '../../server/routes'

export const api = hc<AppType>('/api')
```

```ts
// chamada
const res = await api.pedidos.$post({ json: { clienteId, itens } })
if (res.ok) {
  const { pedido } = await res.json()      // tipado
}
```

Mapeamento do path para propriedade: segmento estático vira propriedade (`api.pedidos`), param vira índice com o nome literal (`api.pedidos[':id']`), método vira `$get`/`$post`/`$put`/`$patch`/`$delete`.

```ts
await api.pedidos[':id'].$get({ param: { id: '123' }, query: { incluirItens: 'true' } })
await api.pedidos[':pedidoId'][':itemId'].$delete({ param: { pedidoId: '1', itemId: '2' } })
```

**Regras de chamada, verificadas:**

- **`param` e `query` são sempre `string`**, ainda que o validator converta. *"Both path parameters and query values must be passed as `string`."*
- **`hc` não faz URL-encode de `param`.** Valor com `/` exige regex na rota (`:id{.+}`); a doc recomenda `encodeURIComponent` como caminho seguro.
- **Headers:** por chamada, no segundo argumento (`{ headers: { 'X-Custom': '...' } }`); para todas as chamadas, na criação (`hc<AppType>('/api', { headers: { Authorization: 'Bearer …' } })`).
- **Cookies:** `hc<AppType>(url, { init: { credentials: 'include' } })`.
- **`init`:** aceita um `RequestInit` completo — é por onde passa o `signal` de um `AbortController`. *"A `RequestInit` object defined by `init` takes the highest priority"* e pode sobrescrever `body`, `method` e `headers`.
- **`fetch` customizado:** opção `fetch` no construtor (a doc usa Service Bindings do Cloudflare como exemplo).
- **`buildSearchParams`:** serializador de query próprio, para notação de colchetes em arrays.
- **`$url()`** devolve `URL` e **exige base absoluta** — `hc<AppType>('/')` faz `$url()` lançar `TypeError: Failed to construct 'URL'`. **`$path()`** devolve string e funciona com qualquer base, inclusive relativa; aceita `param` e `query`.

**Status é o que discrimina a resposta.** `c.json(body, 200)` e `c.json(body, 404)` na mesma rota produzem uma união que o cliente estreita por `res.status`. Sem status literal, a união some.

**`c.notFound()` apaga o tipo.** A doc: *"If you want to use a client, you should not use `c.notFound()` ... The data that the client gets from the server cannot be inferred correctly"* — `data` vira `unknown`. Duas saídas: `c.json({ error: 'not found' }, 404)`, ou augmentar a interface:

```ts
declare module 'hono' {
  interface NotFoundResponse extends Response, TypedResponse<{ error: string }, 404, 'json'> {}
}
```

**Erro global não entra na inferência.** *"Hono RPC client doesn't automatically infer response types from global error handlers like `app.onError()` or global middleware."* Para o 500 ou o 401 padronizados chegarem tipados:

```ts
import type { ApplyGlobalResponse } from 'hono/client'

type AppComErros = ApplyGlobalResponse<AppType, {
  401: { json: { error: string } }
  500: { json: { error: string } }
}>

export const api = hc<AppComErros>('/api')
```

| ID | Regra |
| --- | --- |
| `HONO-RPC-05` | `export type AppType` **MUST** ser o `typeof` da variável que recebeu a cadeia completa de rotas e de `app.route()`. |
| `HONO-RPC-06` | Rota consumida por `hc` **NEVER** responde `c.notFound()` sem augmentar `interface NotFoundResponse`. |
| `HONO-RPC-07` | Toda resposta de rota consumida por `hc` **MUST** declarar status literal em `c.json(body, status)`. |
| `HONO-RPC-08` | `param` e `query` enviados por `hc` **MUST** ser `string`; valor com `/` **MUST** ter regex na rota ou `encodeURIComponent`. |
| `HONO-RPC-09` | Erro produzido por `app.onError` ou middleware global que o cliente precise tratar **MUST** ser declarado com `ApplyGlobalResponse`. |

---

## 6. `Infer*` e o consumo tipado

```ts
import type { InferRequestType, InferResponseType } from 'hono/client'

const $post = api.pedidos.$post

type EntradaCriarPedido = InferRequestType<typeof $post>['json']
type SaidaCriarPedido   = InferResponseType<typeof $post>          // união de todos os status
type SaidaCriada        = InferResponseType<typeof $post, 201>     // só o 201
```

`InferRequestType<T>` é indexado pelo **target** (`['json']`, `['query']`, `['param']`, `['form']`). `InferResponseType<T>` aceita um status como segundo parâmetro para estreitar.

É com esses dois tipos que a assinatura de um hook de mutation deixa de ser escrita à mão — o exemplo completo, com `useMutation` e invalidação, está em [Hono](hono.md) § 8.3 e em [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md).

**`parseResponse()` resolve o `res` que não lança.** `hc` devolve algo *"compatible with the fetch Response"*: um 404 chega como Promise resolvida, não como exceção. `parseResponse` parseia pelo `Content-Type`, **lança `DetailedError` se `!res.ok`**, e seu tipo de retorno já exclui 4xx/5xx — que é exatamente o contrato que uma `queryFn` do TanStack Query precisa.

```ts
import { parseResponse, DetailedError } from 'hono/client'

const pedido = await parseResponse(api.pedidos[':id'].$get({ param: { id } }))
// tipo: só o corpo do sucesso. Erro vira DetailedError lançado.
```

`DetailedError` estende `Error` com `detail`, `code`, `statusCode` e `log` (todos opcionais).

### 6.1 A ponte com TanStack Query: o contrato da `queryFn`

Esta subseção é a fronteira onde a estrutura de Hono encosta na de [TanStack Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md), e é onde o defeito mais caro do stack aparece.

**O defeito.** `hc` devolve algo *"compatible with the fetch Response"*. Um 404, um 409 e um 500 chegam como Promise **resolvida**. Uma `queryFn` que faz `return res.json()` nunca aciona o estado de erro: `isError` fica `false`, `retry` não roda, o Error Boundary não pega, e a tela mostra um estado vazio em vez da mensagem de falha. É um bug que não aparece em log nem em teste de happy path.

```ts
// ❌ a query fica em `success` com o corpo do erro dentro de `data`
queryFn: async () => {
  const res = await api.pedidos.$get({ query: {} })
  return res.json()
}
```

Duas formas corretas, e o critério entre elas:

```ts
// A. parseResponse — quando qualquer status de erro é "falhou".
//    Lança DetailedError se !res.ok, e o tipo de retorno já exclui 4xx/5xx.
import { parseResponse } from 'hono/client'
import { queryOptions } from '@tanstack/react-query'

export const pedidosOptions = (pagina: number) =>
  queryOptions({
    queryKey: ['pedidos', 'lista', { pagina }] as const,
    queryFn: ({ signal }) =>
      parseResponse(
        api.pedidos.$get({ query: { pagina: String(pagina) } }, { init: { signal } })
      ),
    staleTime: 60_000,
  })
```

```ts
// B. Discriminar por status — quando um status específico é estado de tela.
//    Exige que o handler tenha usado `return c.json(corpo, status)` (HONO-CORE-13).
export const pedidoOptions = (id: string) =>
  queryOptions({
    queryKey: ['pedidos', 'detalhe', id] as const,
    queryFn: async ({ signal }) => {
      const res = await api.pedidos[':id'].$get({ param: { id } }, { init: { signal } })
      if (res.status === 404) {
        const { error } = await res.json()      // { error: 'pedido não encontrado' }
        throw new PedidoNaoEncontrado(error)
      }
      if (!res.ok) throw new Error('falha ao carregar pedido')
      return res.json()                          // { pedido: Pedido }
    },
  })
```

**O `signal` só atravessa se você passar.** O segundo argumento de `$get`/`$post` aceita `{ init: RequestInit }`, e é por onde o `AbortSignal` que o TanStack Query entrega na `queryFn` chega ao `fetch`. Sem ele, cancelar a query desmonta o componente e deixa a requisição correndo — ver. Vale igual para `mutationFn`, quando a mutation precisa ser cancelável.

**Mutation com erro de domínio tipado chegando ao formulário.** É o caso em que `parseResponse` não serve: ele colapsa todo status de erro em `DetailedError`, e o formulário precisa saber **qual campo** falhou.

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query'
import type { InferRequestType, InferResponseType } from 'hono/client'

const $post = api.pedidos.$post

type Entrada = InferRequestType<typeof $post>['json']
type Criado = InferResponseType<typeof $post, 201>
type ErroValidacao = InferResponseType<typeof $post, 400>   // { error, campos: [...] }
type ErroConflito = InferResponseType<typeof $post, 409>    // { error, statusAtual }

class PedidoInvalido extends Error {
  constructor(readonly campos: ErroValidacao['campos']) { super('validação falhou') }
}
class PedidoEmConflito extends Error {
  constructor(readonly statusAtual: ErroConflito['statusAtual']) { super('conflito') }
}

export function useCriarPedido() {
  const queryClient = useQueryClient()
  return useMutation<Criado, PedidoInvalido | PedidoEmConflito | Error, Entrada>({
    mutationFn: async (novoPedido) => {
      const res = await $post({ json: novoPedido })
      if (res.status === 400) throw new PedidoInvalido((await res.json()).campos)
      if (res.status === 409) throw new PedidoEmConflito((await res.json()).statusAtual)
      if (!res.ok) throw new Error('falha ao criar pedido')
      return res.json()
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['pedidos', 'lista'] }),
  })
}
```

No componente, `error` do `useMutation` chega com o tipo da união e o `instanceof` estreita:

```tsx
const criar = useCriarPedido()

const onSubmit = (valores: Entrada) =>
  criar.mutate(valores, {
    onError: (erro) => {
      if (erro instanceof PedidoInvalido) {
        for (const { campo, mensagem } of erro.campos) {
          setError(campo as keyof Entrada, { message: mensagem })
        }
      }
    },
  })
```

Ver [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) e [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md).

| ID | Regra |
| --- | --- |
| `HONO-RPC-13` | `queryFn`/`mutationFn` que consome `hc` **MUST** usar `parseResponse()` ou lançar explicitamente quando `!res.ok` — `hc` **NEVER** lança sozinho, e a query fica em `success` com o corpo do erro dentro de `data`. |
| `HONO-RPC-14` | O `signal` fornecido pela `queryFn` do TanStack Query **MUST** ser repassado ao `hc` via `{ init: { signal } }` — é a única forma de o cancelamento chegar à rede. |

**`testClient` é o mesmo cliente, sem rede.** `testClient(app)` de `hono/testing` dá a mesma API tipada sobre a instância — e depende da mesma cadeia contínua. Ver [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 8.

---

## 7. As limitações reais

Esta seção é a que decide se a ponte compensa. Tudo aqui está na fonte.

**1. A cadeia precisa ser contínua, e isso condiciona a arquitetura.** Não é um detalhe de estilo que se resolve com lint: `const app = new Hono(); app.get(...)` produz um tipo vazio, sem erro de compilação. Vale também para `app.route()` — em app grande, o padrão documentado é encadear os `.route()` numa variável e exportar o `typeof` dela:

```ts
const app = new Hono()
const routes = app.route('/pedidos', pedidos).route('/clientes', clientes)
export default app
export type AppType = typeof routes      // `routes`, não `app`
```

E cada sub-app precisa ter sido escrito em cadeia também. Um sub-app escrito no estilo statement-por-statement contamina o tipo do app inteiro, silenciosamente.

**2. Handler extraído perde a inferência de param.** A doc desaconselha "controllers" no estilo Rails porque *"the path parameter cannot be inferred in the Controller without writing complex generics"*. A saída oficial é `factory.createHandlers()`.

**3. O custo de compilação é real e a doc admite.** *"When using RPC, the more routes you have, the slower your IDE will become. One of the main reasons for this is that massive amounts of type instantiations are executed to infer the type of your app."* Cada rota gera instanciações que o `tsserver` refaz a cada uso. Mitigações verificadas, em ordem de eficácia:

| Mitigação | Como | Nota da doc |
| --- | --- | --- |
| Pré-compilar o cliente | `export type Client = ReturnType<typeof hc<typeof app>>` + `hcWithType` que só faz o cast | **"recommended"** — `tsc` faz o trabalho pesado no build |
| Dividir app e cliente | um `hc` por sub-app (`hc<typeof authorsApp>('/authors')`) | *"tsserver doesn't need to instantiate types for all routes at once"* |
| Project references | quando back e front são projetos TS separados | necessário para o front enxergar `AppType` |
| Type argument manual | `app.get<'foo/:id'>('foo/:id', ...)` | *"a bit cumbersome"*, ganho por rota |

```ts
// server/client.ts — o padrão recomendado
import { hc } from 'hono/client'
import { routes } from './routes'      // a variável que recebeu a CADEIA — HONO-RPC-05

export type Client = ReturnType<typeof hc<typeof routes>>
export const hcWithType = (...args: Parameters<typeof hc>): Client =>
  hc<typeof routes>(...args)
```

> A doc escreve esse trecho com `typeof app` porque no exemplo dela `app` **é** a variável da cadeia (`export const app = new Hono().get(...)`). Onde a cadeia foi para `routes` — o padrão desta estrutura, e o do próprio exemplo de app grande acima — `typeof app` pré-compila o cliente do app **vazio**, e o erro só aparece como perda de autocomplete.

**4. Duas pré-condições de projeto.** Versão de `hono` **idêntica** no servidor e no cliente — divergência produz o erro *"Type instantiation is excessively deep and possibly infinite"*, que a doc cita nominalmente. E `"strict": true` no `compilerOptions` dos **dois** `tsconfig.json` (a doc aponta a issue #2270)..

**5. Só serve consumidor `hono/client`.** Não há OpenAPI, não há artefato publicável. Qualquer outro cliente — outra linguagem, mobile, webhook de terceiro — volta a precisar de contrato escrito à mão. Existe `@hono/zod-openapi` para emitir spec, mas é **outro pacote e outra forma de declarar rotas**, não verificado nesta doc.

**6. Hono não valida a saída — só o input.** O guia de Validation cobre exclusivamente o request: os targets são `json`, `form`, `query`, `param`, `header`, `cookie`, e não há equivalente a um schema de resposta checado em runtime. A consequência é assimétrica e fácil de ler errado: o tipo da resposta que chega ao `hc` é **inferido do que o handler escreve**, não verificado contra um schema. Se o handler devolve `c.json({ pedido }, 200)` e `pedido` vem de uma query que trouxe um campo a menos, o cliente é tipado como se o campo existisse e recebe `undefined` em runtime — sem erro em lugar nenhum.

Quem vem de [Elysia](elysia.md) supõe simetria e não há: `ELYSIA-TYPE-06` valida o retorno em runtime a partir de `response`, e **Hono não tem equivalente**. O que se pode fazer em Hono é parsear o resultado do domínio antes de responder — `return c.json(pedidoSchema.parse(pedido), 200)` — mas isso é código de aplicação, não um recurso do framework, e não há regra normativa aqui porque não há API a citar.

| ID | Regra |
| --- | --- |
| `HONO-RPC-10` | App com muitas rotas consumidas por RPC **MUST** pré-compilar o cliente (`hcWithType`) ou dividir em clientes por sub-app. |
| `HONO-RPC-11` | Servidor e cliente **MUST** usar a mesma versão de `hono` e `"strict": true` nos dois `tsconfig.json`. |
| `HONO-RPC-12` | `$url()` **MUST** receber base URL absoluta; com base relativa, use `$path()`. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| Ler `await c.req.json()` e checar campos à mão no handler | input não validado alimentando domínio; e o tipo do input não existe para o cliente | `zValidator(target, schema)` + `c.req.valid` — `HONO-RPC-01` / `HONO-RPC-02` |
| Validar com `zValidator` e depois reler `c.req.json()` | o body já foi consumido; e o valor relido não passou por coerção nem por defaults do schema | `c.req.valid('json')` — `HONO-RPC-02` |
| `zValidator` sem `hook` em rota pública | o `SafeParseError` do Zod inteiro vai no corpo do 400 **e no tipo da rota** | `hook` que lança `HTTPException` ou devolve formato próprio — `HONO-RPC-04` |
| Validar `header` com `value['Idempotency-Key']` | as chaves vêm minúsculas; o valor é sempre `undefined` e o validator rejeita tudo | `value['idempotency-key']` — `HONO-RPC-03` |
| `export type AppType = typeof app` quando a cadeia foi para `routes` | `app` é a instância vazia; o cliente não vê nenhuma rota | exportar `typeof routes` — `HONO-RPC-05` |
| `return c.notFound()` em rota consumida por `hc` | `data` do cliente vira `unknown` — a doc marca com ❌ | `c.json({ error }, 404)` ou augmentar `NotFoundResponse` — `HONO-RPC-06` |
| `c.json({ pedido })` sem status | a resposta existe no tipo mas não discrimina; `res.status === 404` não estreita nada | status literal sempre — `HONO-RPC-07` |
| `$get({ query: { pagina: 1 } })` com número | o cliente exige `string`, mesmo com `z.coerce.number()` no servidor | `{ pagina: String(pagina) }` — `HONO-RPC-08` |
| `const data = await res.json()` direto na `queryFn` | `hc` não lança em 4xx/5xx: a query fica em `success` com o corpo do erro dentro de `data`; `isError` é `false` e o `retry` não roda | `parseResponse(...)` ou checar `res.ok` e lançar — `HONO-RPC-13` |
| `queryFn: () => parseResponse(api.pedidos.$get({ query: {} }))` sem o `signal` | o cancelamento do TanStack Query não chega à rede; a requisição segue depois do unmount | `{ init: { signal } }` no segundo argumento — `HONO-RPC-14` |
| `parseResponse` numa mutation cujo formulário precisa do erro por campo | todo status de erro vira `DetailedError` genérico; o `campos` do 400 é perdido | discriminar por `res.status` e lançar erro de domínio — § 6.1 |
| Supor que o formato da resposta é validado em runtime | Hono valida **input**, não saída; o tipo do `hc` é inferido do que o handler escreve | parsear no handler antes de `c.json`, se o dado vem de fonte não confiável — § 7.6 |
| Contar com o 500 de `app.onError` chegando tipado no cliente | erro global não entra na inferência das rotas | `ApplyGlobalResponse` — `HONO-RPC-09` |
| Versões diferentes de `hono` no back e no front | *"Type instantiation is excessively deep and possibly infinite"* | alinhar versão; em monorepo, dependência única — `HONO-RPC-11` |
| Deixar o `hc<typeof app>` cru num app de 100 rotas | o `tsserver` reinstancia os tipos a cada uso; o editor trava | `hcWithType` pré-compilado — `HONO-RPC-10` |

---

## Checklist de revisão

- [ ] Todo input externo passa por validator? → `HONO-RPC-01`
- [ ] O handler lê só por `c.req.valid(target)`? → `HONO-RPC-02`
- [ ] Validação de `header` usa chave minúscula? → `HONO-RPC-03`
- [ ] O erro de validação tem formato próprio, não o dump do Zod? → `HONO-RPC-04`
- [ ] `AppType` vem da variável que recebeu a cadeia (inclusive de `.route()`)? → `HONO-RPC-05`
- [ ] Nenhum `c.notFound()` em rota consumida por `hc`? → `HONO-RPC-06`
- [ ] Todo `c.json` de rota RPC declara status literal? → `HONO-RPC-07`
- [ ] `param` e `query` são enviados como `string`? → `HONO-RPC-08`
- [ ] Erros globais que o cliente trata estão em `ApplyGlobalResponse`? → `HONO-RPC-09`
- [ ] O cliente está pré-compilado ou dividido por sub-app? → `HONO-RPC-10`
- [ ] Mesma versão de `hono` e `"strict": true` dos dois lados? → `HONO-RPC-11`
- [ ] `$url()` só com base absoluta? → `HONO-RPC-12`
- [ ] A `queryFn`/`mutationFn` usa `parseResponse()` ou lança quando `!res.ok`? → `HONO-RPC-13`
- [ ] O `signal` da `queryFn` chega ao `hc` via `{ init: { signal } }`? → `HONO-RPC-14`

---

## Relacionados

- [Hono](hono.md) — hub; § 8 tem a ponte completa com React e TanStack Query
- [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) · [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md)
- · ·
- [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) · [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) · [React.js](react-js.md)
- [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) · [React - Formulários e Actions](react-formularios-e-actions.md)
- · · ·
- · `TypeScript` · ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [RPC](https://hono.dev/docs/guides/rpc) · [Validation](https://hono.dev/docs/guides/validation) · [Best Practices](https://hono.dev/docs/guides/best-practices) · [Hono Stacks](https://hono.dev/docs/concepts/stacks)
- [HonoRequest](https://hono.dev/docs/api/request) · [Testing Helper](https://hono.dev/docs/helpers/testing) · [Factory Helper](https://hono.dev/docs/helpers/factory)
- [Zod Validator (README oficial do pacote)](https://github.com/honojs/middleware/tree/main/packages/zod-validator) e o código-fonte de `packages/zod-validator/src/index.ts`
- [Standard Schema Validator](https://github.com/honojs/middleware/tree/main/packages/standard-validator) · [Standard Schema](https://standardschema.dev/)
- Tipos publicados: `hono@4.13.2/dist/types/client/index.d.ts` e `client/utils.d.ts`
- Registry npm: `@hono/zod-validator` 0.9.0 (peer `zod ^3.25.0 || ^4.0.0`, `hono >=4.11.2`)

**O que a verificação contrariou:**

- **A resposta de erro default do `zValidator` é `c.json(result, 400)` com o `SafeParseError` inteiro.** Confirmado no código-fonte, e o tipo `ZodValidatorFailureBody` está declarado como parte do `TypedResponse` da rota. Não é um detalhe cosmético: o formato de erro do Zod vira contrato público por omissão.
- **`hc` não lança em resposta não-ok.** Consequência direta de ser *"compatible with the fetch Response"* — e a causa de queries que ficam em `success` com o erro dentro de `data`. `parseResponse()` existe exatamente para isso e seu tipo de retorno **exclui 4xx/5xx**.
- **`$path()` existe além de `$url()`**, e é o que funciona com base relativa. `$url()` com `hc('/')` lança `TypeError`.
- **`ApplyGlobalResponse` é necessário** porque `app.onError` e middleware global **não** entram na inferência das rotas. Assumir que o 500 padronizado chega tipado é errado.
- **A doc reconhece o custo de tipo do RPC em uma seção própria** ("Known issues → IDE performance") e recomenda pré-compilar o cliente. Não é queixa de comunidade.
- **`"strict": true` nos dois `tsconfig` é requisito documentado** para RPC em monorepo, com link para a issue #2270.
- **`c.notFound()` é explicitamente desaconselhado com cliente RPC**, e há uma saída por module augmentation de `interface NotFoundResponse` — mais nova e menos conhecida que a recomendação de usar `c.json`.
- **`@hono/zod-validator` 0.9.0 já suporta Zod v4** (peer `^3.25.0 || ^4.0.0`), e exige `hono >= 4.11.2`.
- **Hono não valida a saída.** O guia de Validation trata só de input; não existe na fonte nada equivalente ao `response` de Elysia, verificado em runtime. A ausência é do framework, e a simetria com Elysia que se supõe por hábito não existe — § 7.6.
- **O `signal` não atravessa sozinho.** A doc mostra `AbortController` explicitamente como caso de uso do `init`, no segundo argumento da chamada. Não há repasse implícito: uma `queryFn` que ignora o `signal` produz requisição órfã — `HONO-RPC-14`.
- **`parseResponse` recebe a Promise, não a `Response`.** A doc chama `parseResponse(client.hello.$get())` sem `await` interno, e o `.catch((e: DetailedError) => ...)` é o tratamento mostrado.
- **A doc escreve `hcWithType` com `typeof app` porque no exemplo dela `app` é a variável da cadeia.** Copiar literalmente num projeto onde a cadeia foi para `routes` pré-compila o cliente do app vazio — `HONO-RPC-05`.
- **`$path()` aceita `query` além de `param`** e serializa a query string (`/api/posts?page=1&limit=10`).
- **`hc` aceita a base URL como segundo parâmetro de tipo** (`hc<typeof route, 'http://localhost:8787'>(...)`), o que dá um `TypedURL` em `$url()`. A doc cita chave tipada para SWR como caso de uso.
