---
Link: https://elysiajs.com/essential/validation.html
tags:
 - elysia
 - schema
 - agent-context
source: "Documentação oficial — https://elysiajs.com/"
verificado-em: 2026-08-15
---
# Elysia - Schema e Eden

> `t` (TypeBox) e Standard Schema · schema por rota e coerção automática · `guard`, precedência e `standalone` · reference models · `response` por status · erro de validação · OpenAPI e `fromTypes` · `export type App` · Eden Treaty e Eden Fetch · integração com TanStack Query.
>
> **Não cobre:** rotas, contexto e respostas ([Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md)) · escopo, hooks e plugins ([Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md)).

Entrada: [Elysia](elysia.md) · Base normativa: [Elysia](elysia.md) § 6

---

## 1. Conceito: uma declaração produz quatro artefatos — duplicar qualquer um é regressão

A frase é literal da fonte:

> "A single Elysia/TypeBox schema can be used for: Runtime validation · Data coercion · TypeScript type · OpenAPI schema"

E há um quinto, que a doc trata em outra página: o mesmo schema é o **contrato que o Eden consome no frontend**. Uma declaração, cinco efeitos.

```ts
import { Elysia, t } from 'elysia'

const app = new Elysia
.post('/pedidos', ({ body, status }) => {
 // body é { sku: string, quantidade: number } — sem anotação, sem cast
 const pedido = criar(body)
 if (!pedido) return status(409, { erro: 'Sem estoque' })
 return status(201, pedido) // 201 está no `response`: o sucesso sai por `status`
 }, {
 body: t.Object({
 sku: t.String({ minLength: 3 }),
 quantidade: t.Number({ minimum: 1 })
 }),
 response: {
 201: t.Object({ id: t.Number, sku: t.String }),
 409: t.Object({ erro: t.String })
 }
 })

export type App = typeof app
```

Desse bloco saem, sem nenhuma linha adicional: a rejeição de payload malformado em runtime; o tipo de `body` no handler; o tipo de retorno checado contra `response`; a entrada no `/openapi`; e o tipo que o `treaty<App>` do frontend enxerga, incluindo o 409 como variante de erro tipada.

> **Repare no `status(201, pedido)`.** Declarar `201` no `response` não muda o status de nada — `return pedido` cru sai como **200**, e o 200 nem está no mapa. O status declarado e o status emitido são duas coisas, e é o `status(code, valor)` que os une; `ELYSIA-CORE-04` existe exatamente por isso. Um mapa `response` que lista códigos que o handler nunca emite é documentação falsa: passa no build, gera OpenAPI errado, e o `switch (error.status)` do frontend cobre um caso morto.

O corolário é a regra mais importante desta nota: **qualquer `interface` TypeScript escrita à mão para descrever um payload que já tem schema é duplicação e vai divergir.** Quando você precisa do tipo fora do handler, extraia:

```ts
export const PedidoBody = t.Object({ sku: t.String, quantidade: t.Number })
export type PedidoBody = typeof PedidoBody.static // ← não reescreva
```

É a tese de e com a diferença de que aqui a ferramenta torna a duplicação desnecessária em vez de apenas indesejável.

| ID | Regra |
| --- | --- |
| `ELYSIA-TYPE-01` | Tipo TypeScript de um payload validado **MUST** derivar do schema (`typeof S.static`) — **NEVER** ser reescrito à mão. |

---

## 2. `t` × Standard Schema: onde Zod ainda faz sentido

Elysia 1.4 suporta **Standard Schema**. A lista verificada é Zod, Valibot, ArkType, Effect Schema, Yup e Joi — e a fonte é explícita sobre a mistura: *"You can use any validator together in the same handler without any issue."*

```ts
import { Elysia } from 'elysia'
import { z } from 'zod'
import * as v from 'valibot'

new Elysia
.get('/id/:id', ({ params: { id }, query: { nome } }) => id, {
 params: z.object({ id: z.coerce.number }), // Zod
 query: v.object({ nome: v.literal('Lilith') }) // Valibot, na mesma rota
 })
```

Então a pergunta deixa de ser "posso usar Zod" e vira "onde". Os trade-offs verificados:

| | `t` (TypeBox) | Zod via Standard Schema |
| --- | --- | --- |
| Coerção de query/params | **automática** — `t.Number` vira `t.Numeric` em schema de rota | manual: `z.coerce.number` |
| OpenAPI | direto, sem configuração | exige `mapJsonSchema: { zod: z.toJSONSchema }` no plugin |
| Validação de arquivo | `t.File({ type: 'image/*' })` valida de fato | precisa de `fileType` — ver abaixo |
| Opções de cookie no schema | `t.Cookie(props, { secrets, sign, httpOnly })` | não há equivalente |
| Compartilhar schema com o frontend | tipo viaja pelo Eden; o schema em si é do servidor | o schema inteiro é importável nos dois lados |
| Ecossistema do vault | novo | já estabelecido |

**Calibração.** Use `t` na fronteira HTTP: query, params, headers, cookie, upload. É onde os tipos de Elysia fazem trabalho que o Zod não faz de graça, e onde o OpenAPI sai sem configuração. Use Zod onde o schema é **compartilhado com o frontend** — validação de formulário que precisa das mesmas regras do servidor, tipos de domínio que já vivem num pacote comum. Os dois convivem, inclusive na mesma rota, e um `guard` `standalone` com Zod pode somar-se a um schema local em `t` (§ 4).

O que **não** fazer é declarar em Zod e redeclarar em `t` a mesma forma. Isso é a duplicação da § 1 com passos extras.

> **Validação de arquivo com Standard Schema exige cuidado.** A doc é incisiva: *"most validators don't actually validate the file"* — checam o `content-type` declarado, que o cliente controla. Elysia exporta `fileType`, que verifica por magic number:
>
> ```ts
> import { Elysia, fileType } from 'elysia'
> import { z } from 'zod'
>
> new Elysia.post('/upload', ({ body }) => body, {
> body: z.object({
> foto: z.file.refine((f) => fileType(f, 'image/jpeg'))
> })
> })
> ```

| ID | Regra |
| --- | --- |
| `ELYSIA-TYPE-02` | Upload validado por Standard Schema **MUST** usar `fileType` — validadores genéricos conferem o `content-type` declarado pelo cliente, não o conteúdo. |

---

## 3. Schema por rota e coerção automática

Seis chaves no terceiro argumento da rota: `body`, `query`, `params`, `headers`, `cookie`, `response`.

```ts
new Elysia
.get('/pedidos', ({ query }) => listar(query), {
 query: t.Object({
 pagina: t.Number({ minimum: 1, default: 1 }), // "2" → 2
 ativos: t.Boolean, // "true" → true
 tags: t.Array(t.String), // ?tags=a,b ou ?tags=a&tags=b
 filtro: t.Optional(t.ObjectString({ uf: t.String })) // JSON em string
 })
 })
```

### As três regras de coerção

1. **`t.Number` vira `t.Numeric` em schema de rota.** Porque header, query e path param chegam sempre como string. Vale para `params`, `query`, `headers`, `cookie` — **não vale para `body`**, nem para `t.Object` aninhado. `t.Number` fora de um schema de rota também não é convertido.
2. **`t.Boolean` vira `t.BooleanString`**, pela mesma razão e com as mesmas exceções.
3. **Array em query aceita dois formatos:** vírgula (`?tags=a,b,c`, o formato do `nuqs`) e chave repetida (`?tags=a&tags=b`, formato de formulário HTML). Precisa declarar `t.Array(...)` — sem isso, uma chave repetida vira string única.

Essa assimetria entre `body` e o resto é deliberada e é a fonte de um bug recorrente: `t.Number` num `body` **rejeita** `"2"`, porque JSON tem números de verdade e não há razão para coagir.

### Comportamentos específicos por chave

- **`headers`**: `additionalProperties: true` por padrão (headers extras passam), e **nomes sempre em minúsculas** — declarar `Authorization` não casa.
- **`cookie`**: também `additionalProperties: true`. `t.Cookie(props, opts)` aceita opções de cookie no segundo argumento (`secrets`, `sign`, `httpOnly`, `secure`, `maxAge`, …), o que torna assinatura e rotação de chave declarativas.
- **`params`**: raramente necessário — Elysia já infere `string` do path. Declare quando precisar de número, formato ou template literal.
- **`body`**: ignorado em GET e HEAD por padrão (RFC 2616). O parser é escolhido a partir do schema (objeto → JSON; objeto com `t.File` um nível → multipart; `t.URLEncoded` → urlencoded; primitivo → texto), e pode ser forçado com `parse: 'json' | 'formdata' | 'urlencoded' | 'text' | 'none'`.
- **`t.Optional`** no nível da rota torna a *chave inteira* opcional (`query: t.Optional(t.Object({...}))`), o que difere do TypeBox puro, onde `Optional` marca um campo de objeto.

### `normalize`: campos fora do schema somem

O construtor tem `normalize` com default **`true`**: propriedades não declaradas são removidas silenciosamente da entrada **e da saída**. Com `normalize: false`, viram erro de validação.

O default é conveniente e tem uma consequência de segurança boa (mass assignment não passa) e uma armadilha: um campo que você acha que está devolvendo, mas esqueceu de declarar no `response`, some da resposta sem aviso.

| ID | Regra |
| --- | --- |
| `ELYSIA-TYPE-03` | Schema de `headers` **MUST** declarar os nomes em minúsculas — Elysia normaliza e um nome capitalizado nunca casa. |
| `ELYSIA-TYPE-04` | Campo numérico de `body` **NEVER** conta com coerção — só `params`, `query`, `headers` e `cookie` convertem `t.Number` em `t.Numeric`. |

---

## 4. `guard`, precedência e `standalone`; reference models

`guard` aplica schema a várias rotas. A precedência, verificada: entre schemas globais vence o **último**; entre global e local vence o **local**.

E o comportamento que surpreende: o schema da rota **substitui** o do guard em vez de somar-se a ele.

```ts
new Elysia
.guard({ body: t.Object({ idade: t.Number }) })
.post('/usuario', ({ body }) => body, {
 body: t.Object({ nome: t.String }) // substitui: `idade` não é mais exigido
 })
```

Para somar, `schema: 'standalone'`:

```ts
new Elysia
.guard({
 schema: 'standalone', // [!code ++]
 body: t.Object({ idade: t.Number })
 })
.post('/usuario', ({ body }) => body, { // body exige idade E nome
 body: t.Object({ nome: t.String })
 })
```

`standalone` roda os dois schemas de forma independente, e — detalhe verificado — **eles podem ser de bibliotecas diferentes**: um guard em Zod somando-se a um schema local em `t` funciona.

### Reference models

`.model` registra schemas por nome, referenciáveis por string, com autocomplete:

```ts
// auth.model.ts
export const authModel = new Elysia
.model({
 'auth.entrar': t.Object({ usuario: t.String, senha: t.String }),
 'auth.perfil': t.Object({ id: t.Number, usuario: t.String })
 })

// auth/index.ts
new Elysia
.use(authModel)
.post('/entrar', ({ body }) => entrar(body), {
 body: 'auth.entrar',
 response: { 200: 'auth.perfil' }
 })
```

Dois efeitos: o schema aparece na seção `components` do OpenAPI e é referenciado por `$ref`, em vez de repetido inline; e nomes duplicados fazem Elysia **lançar erro**, o que a doc contorna com a convenção de prefixo por namespace (`admin.auth`, `user.auth`).

| ID | Regra |
| --- | --- |
| `ELYSIA-TYPE-05` | Schema de `guard` que precisa **somar-se** ao da rota **MUST** declarar `schema: 'standalone'` — o default `override` faz o schema local substituir o do guard. |

---

## 5. `response` por status, e o erro de validação

Declarar `response` faz quatro coisas ao mesmo tempo, e é a declaração de maior alavancagem em Elysia:

1. **valida a saída** — o handler não consegue devolver forma errada;
2. **restringe o tipo de retorno do handler** em tempo de compilação;
3. **tipa `status(code, valor)`**, que passa a só aceitar os códigos e formatos declarados;
4. **entrega ao Eden a união de resultados por status**, que é o que dá narrowing de erro no frontend.

```ts
.get('/pedidos/:id', ({ params: { id }, status }) => {
 const pedido = buscar(id)
 if (!pedido) return status(404, { erro: 'Não encontrado' })
 if (!podeVer(pedido)) return status(403, { erro: 'Sem permissão' })
 return pedido
}, {
 params: t.Object({ id: t.Numeric }),
 response: {
 200: t.Object({ id: t.Number, total: t.Number }),
 403: t.Object({ erro: t.String }),
 404: t.Object({ erro: t.String })
 }
})
```

Sem o mapa por status, o Eden não sabe que 404 existe e o erro chega como `unknown`. Com ele, o frontend faz `switch (error.status)` com autocomplete — § 7.

`withHeader` (de `@elysia/openapi`) documenta headers de resposta, mas a doc adverte: *"`withHeader` is an annotation only, and does not enforce or validate the actual response headers."*

### Erro de validação

Duas camadas. Por campo, com a propriedade `error` do schema (string ou função):

```ts
body: t.Object({
 quantidade: t.Number({ error: 'quantidade deve ser um número' }),
 email: t.String({ format: 'email', error: 'e-mail inválido' })
})
```

E central, narroweando `code === 'VALIDATION'` no `onError`:

```ts
.onError(({ code, error, status }) => {
 if (code === 'VALIDATION') {
 // error é ValidationError; `all` lista todas as causas, com `path` no formato OpenAPI
 return status(422, {
 erro: 'Payload inválido',
 campos: error.all.map((e) => ({ campo: e.path, mensagem: e.summary }))
 })
 }
})
```

`ValidationError` expõe `all` (todas as causas) e `validator` (o `TypeCheck` do TypeBox). A função `error` de um campo **só é chamada se aquele campo falhar** — se o valor inteiro não é objeto, a função do campo não roda, só a do objeto.

**O status default é 422.** `ValidationError.status = 422` no pacote, e é isso que sai de um app **sem `onError` nenhum** — o `onError` acima está reafirmando o default, não criando-o. Se o contrato da sua API promete 400 para payload inválido, o `onError` precisa mudar o número **e** o `response` schema precisa declará-lo, senão o OpenAPI publica 422 e o cliente trata 400. Tabela completa de status default por classe de erro em [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) § 5.

Quatro comportamentos de produção verificados:

- **Em `NODE_ENV=production`, os detalhes são omitidos por padrão.** A resposta traz `type`, `on`, `found` vazio e, opcionalmente, a `message` customizada.
- **`allowUnsafeValidationDetails: true` (default `false`) reverte a omissão**, e a doc adverte que isso vaza a forma do schema — nomes de campo, tipos esperados, restrições. É reconhecimento gratuito para quem estiver sondando a API, e a opção é global: não há como ligá-la só para uma rota. Se o detalhe é necessário em desenvolvimento, condicione ao ambiente em vez de deixar ligado.
- **`validationDetail('mensagem')`** (exportado por `elysia`) inclui o detalhe mesmo assim, campo a campo — é o caminho cirúrgico quando um campo específico precisa de mensagem acionável em produção.
- **`error.detail(error.message)`** no `onError` aplica isso a todos de uma vez.

| ID | Regra |
| --- | --- |
| `ELYSIA-TYPE-06` | Rota que devolve mais de um status **MUST** declarar `response` como mapa por status — sem ele o erro chega ao Eden como `unknown`. |
| `ELYSIA-TYPE-12` | `allowUnsafeValidationDetails: true` **NEVER** fica ligado em produção — a opção é global e faz a resposta de erro publicar a forma do schema. |

---

## 6. OpenAPI

```ts
import { Elysia } from 'elysia'
import { openapi } from '@elysia/openapi'

new Elysia
.use(openapi({
 documentation: {
 info: { title: 'API de Pedidos', version: '1.0.0' },
 tags: [{ name: 'Pedidos', description: 'Ciclo de vida do pedido' }]
 }
 }))
```

UI em `/openapi` (Scalar por padrão; `provider: 'swagger-ui'` ou `null`), spec JSON em `/openapi/json`. Descrição por rota vai em `detail` (`summary`, `description`, `tags`, `deprecated`, `hide`, `security`), que segue o Operation Object do OpenAPI 3. `detail` e `tags` também são aceitos no construtor, valendo para toda a instância. Ver.

### `fromTypes`: doc a partir dos tipos

O modo normal lê o schema em runtime. `fromTypes` lê os **tipos** do arquivo raiz e documenta até rotas sem schema declarado:

```ts
import { openapi, fromTypes } from '@elysia/openapi'

export const app = new Elysia // precisa ser exportada
.use(openapi({ references: fromTypes }))
```

Quatro caveats verificados: o schema de runtime tem precedência sobre o tipo; em produção convém apontar para o `.d.ts` gerado (`fromTypes('dist/index.d.ts')`); tipos explícitos podem não resolver — o contorno documentado é envolver em `Prettify<T>`; e em monorepo é preciso informar `projectRoot` e, havendo vários, `tsconfigPath`. **Não funciona no Cloudflare Worker** (depende de `fs`).

### Com Zod ou Valibot

Standard Schema não implica conversão automática para OpenAPI. Elysia tenta o método nativo do schema; não havendo, é preciso mapear — `z.toJSONSchema` (Zod 4), `zodToJsonSchema` (Zod 3), `@valibot/to-json-schema`, `JSONSchema.make` (Effect):

```ts
openapi({ mapJsonSchema: { zod: z.toJSONSchema } })
```

**Sem isso, rotas declaradas em Zod aparecem sem schema na documentação** — é o custo escondido de usar Zod na fronteira HTTP.

| ID | Regra |
| --- | --- |
| `ELYSIA-TYPE-07` | Rota declarada com Zod/Valibot/Effect **MUST** ter `mapJsonSchema` configurado no plugin de OpenAPI, ou some da documentação. |

---

## 7. Eden: o contrato atravessa para o frontend

### `export type App`

```ts
// server/index.ts
const app = new Elysia.use(pedidos).use(usuarios).listen(3000)
export type App = typeof app // o encadeamento inteiro, num tipo
```

Duas condições para isso funcionar, ambas verificadas: **method chaining contínuo** (quebrar perde os tipos acumulados — `ELYSIA-APP-01`) e **`strict: true`** no `tsconfig` dos dois lados, com TypeScript >= 5.0.

### Eden Treaty

```ts
// client/api.ts
import { treaty } from '@elysia/eden'
import type { App } from '../server' // import de TIPO: nada vai para o bundle

// `parseDate: false` não é opcional se este cliente alimenta o cache do
// TanStack Query — ELYSIA-TYPE-10. Ver a nota no fim desta seção.
export const api = treaty<App>('localhost:3000', { parseDate: false })
```

O caminho HTTP vira acesso a propriedade; o parâmetro dinâmico vira chamada de função com o nome do parâmetro:

| Rota | Eden |
| --- | --- |
| `GET /pedidos` | `api.pedidos.get` |
| `GET /pedidos/:id` | `api.pedidos({ id: 9 }).get` |
| `POST /pedidos` | `api.pedidos.post({ sku: 'A', quantidade: 2 })` |
| `GET /pedidos/:id/itens` | `api.pedidos({ id: 9 }).itens.get` |

Métodos com corpo recebem `(body, opções?)`; `GET`/`HEAD` recebem só `(opções?)`. As opções são `{ query, headers, fetch }`, e `fetch` aceita qualquer `RequestInit` — inclusive `signal`, o que dá cancelamento. Se o corpo é opcional mas você precisa de query, passe `null` como primeiro argumento.

`treaty` também aceita a **instância** em vez da URL: `treaty(app)` chama `app.handle` diretamente, sem rede. É a base do teste com tipos ponta a ponta e do padrão isomórfico (mesmo código chamando local no servidor e HTTP no cliente).

### A forma exata do retorno

Verificada em `@elysia/eden@1.4.10`, `treaty2/types.d.ts` — é uma **união discriminada**:

```ts
| { data: T, error: null, response: Response, status: number, headers }
| { data: null, error: { status: C, value: V }, response: Response, status: number, headers }
```

```ts
const { data, error } = await api.pedidos({ id: 9 }).get

// data: Pedido | null — enquanto `error` não for checado
if (error) {
 switch (error.status) {
 case 404: return mostrarNaoEncontrado(error.value) // value tipado pelo response[404]
 case 403: return mostrarSemPermissao(error.value)
 default: throw error.value
 }
}
// data: Pedido — estreitado
```

Três pontos que decidem código:

1. **`error` não é um `Error`.** É `{ status, value }`, com `status` literal e `value` tipado pelo `response` daquele status. É por isso que a § 5 insiste no mapa por status.
2. **`data` é `null` em qualquer status >= 300.** A doc: *"If the server responds with an HTTP status >= 300, then the value will always be `null`."*
3. **Eden não lança por padrão.** `throwHttpError` tem default `false`.

`Treaty.Data<T>` e `Treaty.Error<T>` extraem os dois tipos quando você precisa deles fora da chamada.

### A integração com TanStack Query

O ponto 3 acima é o que quebra, e quebra em silêncio. A [Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) decide sucesso ou falha pelo fato de a `queryFn` **lançar**. Uma `queryFn` que devolve o envelope do Eden nunca lança: a query fica `success`, `isError` é `false`, `retry` não roda, o error boundary não vê nada, e o componente recebe `{ data: null, error: {...} }` como se fosse dado bom.

```ts
// api/pedidos.ts — desembrulhar e lançar acontece uma vez, num lugar só
import { queryOptions } from '@tanstack/react-query'
import { api } from './client'

export const pedidoOptions = (id: number) =>
 queryOptions({
 queryKey: ['pedidos', 'detalhe', id] as const,
 queryFn: async ({ signal }) => {
 const { data, error } = await api.pedidos({ id }).get({ fetch: { signal } })
 if (error) throw error // sem isto, a query "tem sucesso" com data: null
 return data
 },
 staleTime: 60_000 // TSQ-CACHE-01
 })
```

```ts
// mutation: mesma regra, mais a invalidação
const criar = useMutation({
 mutationFn: async (novo: NovoPedido) => {
 const { data, error } = await api.pedidos.post(novo)
 if (error) throw error
 return data
 },
 onSuccess: => queryClient.invalidateQueries({ queryKey: ['pedidos'] })
})
```

Ver [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) para a política de invalidação.

### Erro de domínio tipado chegando ao formulário

A discriminação por `error.status` costuma ser mostrada em query, mas o caso que decide UI é a **mutation**: um 409 de estoque ou um 422 de validação precisa virar mensagem no campo certo, não um toast genérico. O que atravessa é o mesmo `{ status, value }` — a única diferença é que na mutation ele chega pelo `error` do `useMutation`, e o `value` é o corpo declarado naquele status do `response`.

Duas condições, as duas já cobertas por regras: o `throw error` da `mutationFn` (`ELYSIA-TYPE-09`), que é o que faz a Query tratar como falha; e o mapa `response` por status no servidor (`ELYSIA-TYPE-06`), que é o que dá tipo ao `value`.

```tsx
// servidor: response: { 201: PedidoCriado, 409: t.Object({ erro: t.String, sku: t.String }) }

function FormularioPedido {
 const criar = useMutation({
 mutationFn: async (novo: NovoPedido) => {
 const { data, error } = await api.pedidos.post(novo)
 if (error) throw error // ELYSIA-TYPE-09
 return data
 },
 onSuccess: => queryClient.invalidateQueries({ queryKey: ['pedidos', 'lista'] })
 })

 // `criar.error` é o { status, value } do Eden — mesmo narrowing da query
 const erroDeEstoque = criar.error?.status === 409 ? criar.error.value : undefined

 return (
 <form onSubmit={(e) => { e.preventDefault; criar.mutate(lerFormulario(e)) }}>
 <input name="sku" aria-invalid={erroDeEstoque !== undefined} />
 {erroDeEstoque && <span role="alert">Sem estoque para {erroDeEstoque.sku}</span>}
 {criar.error && criar.error.status >= 500 && <span role="alert">Erro interno. Tente de novo.</span>}
 <button disabled={criar.isPending}>Criar</button>
 </form>
 )
}
```

O `status >= 500` no segundo ramo é deliberado: erro esperado do domínio tem tratamento próprio e mensagem específica; o resto é opaco por design —. Para o mesmo padrão com `useActionState` e `<form action>`, ver [React - Formulários e Actions](react-formularios-e-actions.md).

### O envelope de resposta paginada

Esta é a lacuna que o servidor precisa fechar para o frontend funcionar, e ela não é uma API de Elysia — é contrato do vault. [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) exige, em `TSQ-PATTERN-05`, que o botão "próxima" seja desabilitado por `isPlaceholderData || !data?.hasMore`. **`hasMore` tem que vir do servidor.** Uma rota que devolve `{ pedidos }` e nada mais torna a regra do frontend insatisfazível, e o resultado prático é um botão que avança para uma página vazia.

O envelope mínimo, declarado uma vez como reference model e reusado:

```ts
// pedidos.model.ts
import { Elysia, t } from 'elysia'

export const Pedido = t.Object({
 id: t.Number,
 sku: t.String,
 total: t.Number
})

export const pedidosModel = new Elysia.model({
 'pedidos.lista': t.Object({
 itens: t.Array(Pedido),
 total: t.Number, // total de registros, não da página — alimenta o "de N"
 hasMore: t.Boolean // o nome é o que TSQ-PATTERN-05 lê; não renomeie
 })
})

// pedidos/index.ts
new Elysia
.use(pedidosModel)
.get('/pedidos', ({ query: { pagina, porPagina } }) => {
 const { itens, total } = repositorio.listar({ pagina, porPagina })
 return { itens, total, hasMore: pagina * porPagina < total }
 }, {
 query: t.Object({
 pagina: t.Number({ minimum: 1, default: 1 }), // "2" → 2, coerção de query
 porPagina: t.Number({ minimum: 1, maximum: 100, default: 20 })
 }),
 response: { 200: 'pedidos.lista' }
 })
```

```ts
// cliente: a queryKey tem o nível de escopo, e a página entra nela — TSQ-PATTERN-04
export const pedidosOptions = (pagina: number) =>
 queryOptions({
 queryKey: ['pedidos', 'lista', { pagina }] as const,
 queryFn: async ({ signal }) => {
 const { data, error } = await api.pedidos.get({ query: { pagina }, fetch: { signal } })
 if (error) throw error
 return data // { itens, total, hasMore }
 },
 placeholderData: keepPreviousData // TSQ-PATTERN-04
 })
```

`hasMore` como booleano do servidor, e não como `itens.length === porPagina` inferido no cliente, é o que faz a última página parar certo: a inferência erra exatamente quando o total é múltiplo do tamanho da página. Para o trade-off entre offset e cursor — e quando `total` deixa de ser barato de calcular — ver.

Alternativa: `treaty<App>(url, { throwHttpError: true })` faz o Eden lançar sozinho, ao custo de perder o `{ error }` tipado em todos os pontos de chamada. Escolha uma política e aplique no cliente inteiro — misturar as duas produz tratamento de erro inconsistente.

> **`parseDate` tem default `true`.** O Eden converte strings de data em objetos `Date`. Isso colide com `TSQ-CACHE-04` de [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md): structural sharing só preserva referência com dado compatível com JSON, e um `Date` parece novo a cada refetch — re-render de tudo que consome a query, mesmo sem mudança. Se o dado entra no cache, use `parseDate: false` e converta no `select`.

**`queryKey` não vem do Eden.** O Eden dá tipo e chamada; a chave de cache continua sendo decisão de domínio, e precisa casar com o que as mutations invalidam.

### Eden Fetch

```ts
import { edenFetch } from '@elysia/eden'
const fetch = edenFetch<App>('http://localhost:3000')

const { data, error } = await fetch('/pedidos/:id', { params: { id: '9' } })
```

Mesma forma de retorno, sintaxe de string. Quando preferir: a doc dá um critério numérico — *"If your single process contains **more than 500 routes**, and you need to consume all of the routes **in a single frontend codebase**"*. E desfaz a razão histórica: *"Unlike Elysia < 1.0, Eden Fetch is not faster than Eden Treaty anymore."* A escolha hoje é performance do **compilador TypeScript**, não do runtime. Abaixo desse porte, Treaty.

`edenTreaty` (minúsculo, "Treaty 1") é **legado** — a doc recomenda `treaty` para projeto novo. Os dois convivem no mesmo pacote, então exemplo antigo compila sem aviso.

### WebSocket

```ts
// servidor
new Elysia.ws('/chat', {
 body: t.String,
 response: t.String,
 message(ws, mensagem) { ws.send(mensagem) }
})

// cliente
const chat = api.chat.subscribe
chat.subscribe((m) => console.log('recebido', m.data))
chat.on('open', => chat.send('olá'))
```

`subscribe` devolve um `EdenWS` que estende `WebSocket` (mesma API, mais `.raw` para o socket nativo). O schema de `ws` aceita `body`, `query`, `params`, `header`, `cookie` e `response`, e mensagem JSON stringificada é parseada antes de validar.

### Quando o Eden devolve `any`

Checklist da doc para quando a inferência falha: `strict: true` ausente; versões de `elysia` diferentes entre cliente e servidor (`npm why elysia` deve mostrar uma só no topo); TypeScript < 5.0; encadeamento quebrado; e — em monorepo — path alias que não resolve para o **mesmo arquivo** nos dois lados. O alias é a causa mais difícil de diagnosticar, porque resolve para *algo* e o tipo degrada para `any` sem erro.

| ID | Regra |
| --- | --- |
| `ELYSIA-TYPE-08` | Retorno do Eden **MUST** ter `error` verificado antes de usar `data` — `data` é `null` em qualquer status >= 300. |
| `ELYSIA-TYPE-09` | `queryFn`/`mutationFn` que chama Eden **MUST** lançar em caso de erro (ou o cliente **MUST** usar `throwHttpError: true`) — sem isso a query fica `success` com dado nulo. |
| `ELYSIA-TYPE-10` | Cliente Eden que alimenta cache do TanStack Query **MUST** usar `parseDate: false` — `Date` quebra structural sharing. |
| `ELYSIA-TYPE-11` | Cliente e servidor **MUST** resolver a mesma versão de `elysia`, com `strict: true` e TypeScript >= 5.0 nos dois. |
| `ELYSIA-TYPE-13` | Rota de listagem paginada **MUST** declarar no `response` um envelope com `itens`, `total` e `hasMore` — devolver o array cru torna `TSQ-PATTERN-05` insatisfazível no frontend. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `interface Pedido {...}` no frontend duplicando o `t.Object` do servidor | duas fontes de verdade para a mesma forma; a divergência aparece em produção, não no build | `typeof S.static` no servidor, `treaty<App>` no cliente — `ELYSIA-TYPE-01` |
| `queryFn: => api.pedidos.get` | devolve o envelope `{data, error}` e nunca lança: query fica `success` com `data.data === null`, sem retry, sem error boundary | desembrulhar e `throw error` na `queryFn` — `ELYSIA-TYPE-09` |
| Rota com 404/403 sem mapa `response` por status | o Eden tipa o erro como `unknown`; o `switch (error.status)` perde o narrowing e vira `any` | declarar `response: { 200: …, 403: …, 404: … }` — `ELYSIA-TYPE-06` |
| Eden com `parseDate` default alimentando o cache da Query | strings ISO viram `Date`, structural sharing desliga, tudo re-renderiza a cada refetch | `parseDate: false` e converter no `select` — `ELYSIA-TYPE-10` |
| `guard` com schema, esperando que some ao da rota | o default é `override`: o schema local **substitui** o do guard, e a validação que você achava garantida some | `schema: 'standalone'` no guard — `ELYSIA-TYPE-05` |
| `t.Number` num campo de `body` esperando aceitar `"2"` | coerção só acontece em `params`/`query`/`headers`/`cookie`; em `body` o número precisa ser número | `t.Numeric` explícito se o cliente manda string — `ELYSIA-TYPE-04` |
| `headers: t.Object({ Authorization: t.String })` | Elysia normaliza headers em minúsculas; a chave capitalizada nunca casa e a validação sempre falha | `authorization` — `ELYSIA-TYPE-03` |
| Rotas em Zod sem `mapJsonSchema` | validação funciona, mas as rotas aparecem sem schema no `/openapi` — a documentação mente por omissão | `openapi({ mapJsonSchema: { zod: z.toJSONSchema } })` — `ELYSIA-TYPE-07` |
| `z.file` sem `fileType` num upload | valida o `content-type` declarado pelo cliente, que é forjável — arquivo executável passa como imagem | `.refine((f) => fileType(f, 'image/jpeg'))` — `ELYSIA-TYPE-02` |
| Versões diferentes de `elysia` no monorepo | o Eden degrada silenciosamente para `any`; o build passa e nada avisa | fixar a versão e conferir com `npm why elysia` — `ELYSIA-TYPE-11` |
| `response: { 201:... }` com o handler fazendo `return pedido` | o retorno cru sai como **200**, que nem está no mapa; o OpenAPI publica um 201 que nunca acontece | `return status(201, pedido)` — `ELYSIA-CORE-04` |
| `allowUnsafeValidationDetails: true` deixado ligado em produção | a resposta de erro passa a listar campos, tipos e restrições do schema para qualquer requisição malformada | condicionar ao ambiente, ou `validationDetail` campo a campo — `ELYSIA-TYPE-12` |
| `GET /pedidos` devolvendo `{ pedidos }` sem `total` nem `hasMore` | o controle de paginação do frontend não tem como saber se há próxima página; `TSQ-PATTERN-05` fica insatisfazível e o botão avança para o vazio | envelope `{ itens, total, hasMore }` no `response` — `ELYSIA-TYPE-13` |

---

## Checklist de revisão

- [ ] Nenhum tipo de payload é reescrito à mão? → `ELYSIA-TYPE-01`
- [ ] Uploads validados por Standard Schema usam `fileType`? → `ELYSIA-TYPE-02`
- [ ] Nomes de header no schema estão em minúsculas? → `ELYSIA-TYPE-03`
- [ ] Nenhum campo de `body` depende de coerção? → `ELYSIA-TYPE-04`
- [ ] Guards que precisam somar declaram `schema: 'standalone'`? → `ELYSIA-TYPE-05`
- [ ] Toda rota com múltiplos status tem mapa `response`? → `ELYSIA-TYPE-06`
- [ ] Rotas em Zod/Valibot têm `mapJsonSchema`? → `ELYSIA-TYPE-07`
- [ ] Todo consumo do Eden checa `error` antes de usar `data`? → `ELYSIA-TYPE-08`
- [ ] Toda `queryFn`/`mutationFn` lança em erro? → `ELYSIA-TYPE-09`
- [ ] O cliente que alimenta o cache usa `parseDate: false`? → `ELYSIA-TYPE-10`
- [ ] `npm why elysia` mostra uma única versão? → `ELYSIA-TYPE-11`
- [ ] Nenhum ambiente de produção liga `allowUnsafeValidationDetails`? → `ELYSIA-TYPE-12`
- [ ] Toda listagem paginada devolve `{ itens, total, hasMore }`? → `ELYSIA-TYPE-13`
- [ ] Todo status declarado no `response` é de fato emitido por um `status(code, valor)`? → `ELYSIA-CORE-04`
- [ ] Headers anotados com `withHeader` são de fato setados em `set.headers`? (é anotação, não validação — § 5)
- [ ] Nenhum `edenTreaty` (API legada) em código novo? (§ 7)

---

## Relacionados

- [Elysia](elysia.md) — hub
- [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) · [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md)
- · ·
- · ·
- [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) · [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md)
- [React - Formulários e Actions](react-formularios-e-actions.md) — o mesmo erro tipado chegando por `useActionState`
- `TypeScript` · [React.js](react-js.md) · ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Validation](https://elysiajs.com/essential/validation.html) — schema por rota, guard, reference model, erro
- [TypeBox (Elysia.t)](https://elysiajs.com/patterns/typebox.html) — tipos e comportamento de coerção
- [Standalone Schema](https://elysiajs.com/tutorial/patterns/standalone-schema.html) · [Validation Error](https://elysiajs.com/tutorial/patterns/validation-error.html)
- [OpenAPI (patterns)](https://elysiajs.com/patterns/openapi.html) · [OpenAPI (plugin)](https://elysiajs.com/plugins/openapi.html)
- [Eden Overview](https://elysiajs.com/eden/overview.html) · [Installation](https://elysiajs.com/eden/installation.html) · [Treaty Overview](https://elysiajs.com/eden/treaty/overview.html) · [Parameters](https://elysiajs.com/eden/treaty/parameters.html) · [Response](https://elysiajs.com/eden/treaty/response.html) · [Config](https://elysiajs.com/eden/treaty/config.html) · [WebSocket](https://elysiajs.com/eden/treaty/websocket.html) · [Unit Test](https://elysiajs.com/eden/treaty/unit-test.html) · [Legacy](https://elysiajs.com/eden/treaty/legacy.html) · [Eden Fetch](https://elysiajs.com/eden/fetch.html)
- [At a glance](https://elysiajs.com/at-glance.html) · [WebSocket](https://elysiajs.com/patterns/websocket.html) · [TanStack Start](https://elysiajs.com/integrations/tanstack-start.html)
- `elysia@1.4.29` — `type-system/index.d.ts` (lista exata dos tipos de Elysia); `@elysia/eden@1.4.10` — `treaty2/types.d.ts` (forma do retorno e opções)

**O que a verificação contrariou:**

- **Elysia não obriga TypeBox.** Standard Schema aceita Zod, Valibot, ArkType, Effect Schema, Yup e Joi, e schemas de bibliotecas diferentes coexistem no mesmo handler e no mesmo `guard` standalone.
- **Standard Schema não implica OpenAPI automático.** Sem `mapJsonSchema`, rotas em Zod validam mas não documentam. É o custo escondido de trocar `t` por Zod na fronteira HTTP.
- **`t.Uint8Array` é a grafia real** (`type-system/index.d.ts`), enquanto a documentação escreve `t.UInt8Array`. Existe também `t.NumericEnum`, `t.ArrayString`, `t.ArrayQuery`, `t.NoValidate` e `t.String({ trusted })`, ausentes da página de TypeBox.
- **`t.ObjectString` exige as propriedades como argumento** (`t.ObjectString({ uf: t.String })`), embora a doc mostre `t.ObjectString` sem argumento.
- **Coerção não vale para `body`** — só para `params`, `query`, `headers` e `cookie`, e nunca dentro de `t.Object` aninhado.
- **`t.Optional` no nível da rota difere do TypeBox puro**: torna a chave inteira opcional, em vez de marcar um campo do objeto.
- **`normalize` tem default `true`**: propriedades fora do schema somem silenciosamente da entrada **e da saída**.
- **Eden Treaty não lança em erro HTTP** (`throwHttpError: false`) e **converte data em `Date`** (`parseDate: true`) por padrão. As duas defaults têm efeito direto e silencioso sobre TanStack Query.
- **`error` do Eden não é um `Error`** — é `{ status, value }`, uma união discriminada por código de status.
- **Eden Fetch não é mais mais rápido que Treaty**; a única razão documentada para preferi-lo é performance de tipos acima de ~500 rotas.
- **O exemplo oficial de integração com React Query** (página de TanStack Start) usa `queryFn: => getTreaty.get`, que devolve o envelope e não trata erro — correto como demonstração mínima, insuficiente como código de produção.
- **O status default de erro de validação é 422**, e nenhuma página da doc o declara. Está em `ValidationError.status = 422` no `error.js` do pacote publicado. Sai mesmo sem `onError`, o que contraria o reflexo de esperar 400.
- **`allowUnsafeValidationDetails` tem default `false`** (página de Config) e é **global**: não há granularidade por rota. Ligar em produção para depurar um endpoint expõe a forma do schema de todos.
- **`parseDate` (default `true`) e `throwHttpError` (default `false`)** estão confirmados na página de Config do Eden Treaty, com esses números explícitos. `throwHttpError` também aceita uma função `(response) => boolean`, o que permite lançar só para certos status — detalhe ausente da narrativa "ou lança tudo, ou nada".
- **O envelope paginado não é uma convenção de Elysia.** Elysia não prescreve formato de resposta de lista; `{ itens, total, hasMore }` é decisão deste vault, derivada de `TSQ-PATTERN-05`. Está registrado como `ELYSIA-TYPE-13` porque o custo de divergir é do backend, mas a origem da exigência é o frontend, não a fonte oficial.
