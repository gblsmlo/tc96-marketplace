---
titulo: Hono - Roteamento e Contexto
Link: https://hono.dev/docs/api/routing
tags:
  - hono
  - roteamento
  - agent-context
source: "Documentação oficial — https://hono.dev/docs"
verificado-em: 2026-08-15
---

# Hono - Roteamento e Contexto

> Encadeamento e o tipo acumulado do app · `Bindings`/`Variables` no generic · métodos, params, wildcards, regex e precedência de match · `app.route()`, `basePath` e agrupamento · leitura do request por `c.req` · as seis formas de resposta · `HTTPException`, `onError`, `notFound` e o critério `return` × `throw` · teste sem rede com `app.request()` e `testClient()` · cookies e cookie de sessão assinado.
>
> **Não cobre:** middleware, ordem de execução e built-ins ([Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md)) · validação de input e cliente tipado ([Hono - Validação e RPC](hono-validacao-e-rpc.md)) · adaptadores e matriz de runtimes ([Hono](hono.md) § 3).

Entrada: [Hono](hono.md) · Base normativa: [Hono](hono.md) § 2 e § 6

---

## 1. Conceito: o encadeamento não é estilo — é o que constrói o tipo

Em Express, `app.get(...)` é um comando: registra a rota e devolve `void`. Em Hono, `app.get(...)` **devolve uma instância nova, com um tipo maior**. A rota que você acabou de declarar — path, params, target de validação, formato e status da resposta — passa a fazer parte do tipo do valor retornado.

Isso muda o que "escrever a rota" significa:

```ts
// ❌ Registra as rotas. `typeof app` é o app VAZIO.
const app = new Hono()
app.get('/pedidos', handlerLista)
app.post('/pedidos', handlerCria)
export type AppType = typeof app        // sem nenhuma rota dentro

// ✅ Registra as rotas E preserva o tipo acumulado.
const app = new Hono()
  .get('/pedidos', handlerLista)
  .post('/pedidos', handlerCria)
export type AppType = typeof app        // as duas rotas, com seus tipos
```

O primeiro bloco **compila, roda e serve as duas rotas**. A quebra só aparece do outro lado: `hc<AppType>()` não tem autocomplete, `testClient(app)` não conhece `.pedidos`, e `res.json()` devolve `unknown`. É por isso que este é o erro nº 1 em Hono — o feedback chega longe do lugar onde foi introduzido.

A doc registra a exigência em dois lugares, para RPC e para o cliente de teste:

> "For the RPC to infer routes correctly, all included methods must be chained, and the endpoint or app type must be inferred from a declared variable."

Duas consequências que a doc não junta, mas que decorrem disso:

1. **`app.route()` também faz parte da cadeia.** Montar sub-apps sem encadear (`app.route('/a', a); app.route('/b', b)`) descarta o tipo pelo mesmo motivo.
2. **Middleware no encadeamento é seguro.** `app.post('/upload', bodyLimit({...}), handler)` fica dentro da cadeia. O que quebra é chamar `.get()` numa statement separada, não passar middleware como argumento.

| ID | Regra |
| --- | --- |
| `HONO-CORE-01` | Rotas **MUST** ser registradas em cadeia contínua a partir de `new Hono()` quando o tipo do app for consumido por `hc` ou `testClient`, e o tipo exportado **MUST** vir da variável que recebeu a cadeia. |

---

## 2. Instanciar: o generic é a tipagem do request inteiro

`new Hono<{ Bindings, Variables }>()` declara duas coisas diferentes:

- **`Bindings`** — o que o **runtime** injeta: env vars, KV, D1, R2, socket do Node. Lido em `c.env`.
- **`Variables`** — o que o **middleware** grava: usuário autenticado, conexão de banco, request id. Escrito com `c.set`, lido com `c.get`/`c.var`.

```ts
import { Hono } from 'hono'

type Bindings = {
  DATABASE_URL: string
  JWT_SECRET: string
}

type Variables = {
  usuario: { id: string; papel: 'admin' | 'operador' }
}

// A cadeia da § 1 vale também aqui: `.use()` e `.get()` na mesma expressão.
const app = new Hono<{ Bindings: Bindings; Variables: Variables }>()
  .use('/admin/*', async (c, next) => {
    const usuario = await autenticar(c.req.header('Authorization'), c.env.JWT_SECRET)
    c.set('usuario', usuario)   // tipado: só aceita o formato declarado
    await next()
  })
  .get('/admin/relatorio', (c) => {
    const { papel } = c.var.usuario   // `'admin' | 'operador'`, sem cast
    return c.json({ papel }, 200)
  })
```

Sem o generic, `c.env.DATABASE_URL` e `c.get('usuario')` continuam funcionando em runtime e param de existir para o compilador — o erro migra de `tsc` para produção.

**`c.set`/`c.get` valem um request.** A doc é literal: *"The value of `c.set` / `c.get` are retained only within the same request. They cannot be shared or persisted across different requests."* Não é um cache, não é um singleton.

**A alternativa global é uma armadilha.** Aumentar `interface ContextVariableMap` via `declare module 'hono'` tipa a variável em **todo** contexto — inclusive onde o middleware que a define nunca rodou. A própria doc marca o caso com ❌: *"val is undefined but typed as a string, which can lead to runtime errors"*. Use `ContextVariableMap` só para variável setada por middleware realmente aplicado ao app inteiro.

| ID | Regra |
| --- | --- |
| `HONO-CORE-02` | `Bindings` e `Variables` **MUST** ser declarados no generic do app ou do `createFactory`; `c.env` e `c.var` **NEVER** são acessados com `any` ou cast. |
| `HONO-CORE-05` | `ContextVariableMap` **NEVER** é aumentado para variável setada por middleware que não roda em todas as rotas — use o generic `Variables` do app ou do middleware. |

---

## 3. Declarar rota: padrões e precedência

```ts
const app = new Hono()
  .get('/pedidos', (c) => c.json({ pedidos: [] }, 200))
  .post('/pedidos', (c) => c.json({ ok: true }, 201))
  // param nomeado — NÃO casa `/`
  .get('/pedidos/:id', (c) => c.json({ id: c.req.param('id') }, 200))
  // param opcional: casa `/relatorios` e `/relatorios/:formato`
  .get('/relatorios/:formato?', (c) => c.text('ok'))
  // regex no param: filtra no roteamento, antes do handler
  .get('/faturas/:ano{[0-9]+}/:mes{[0-9]+}', (c) => {
    const { ano, mes } = c.req.param()
    return c.json({ ano, mes }, 200)
  })
  // regex que aceita barras — a única forma de casar path com `/`
  .get('/arquivos/:caminho{.+}', (c) => c.text(c.req.param('caminho')))
  // wildcard no meio
  .get('/static/*/thumb', (c) => c.text('thumb'))
  // método customizado, e vários métodos ou paths de uma vez
  .on('PURGE', '/cache', (c) => c.text('purged'))
  .on(['PUT', 'DELETE'], '/pedidos/:id', (c) => c.text('alterado'))
```

**Precedência é ordem de registro, não especificidade.** A doc: *"Handlers or middleware will be executed in registration order"* e *"When a handler is executed, the process will be stopped."* Não há resolução por "rota mais específica ganha":

```ts
app.get('/livros/a', (c) => c.text('a'))
app.get('/livros/:slug', (c) => c.text('comum'))
// GET /livros/a  → 'a'     (registrada antes)
// GET /livros/b  → 'comum'

app.get('*', (c) => c.text('comum'))
app.get('/foo', (c) => c.text('foo'))
// GET /foo → 'comum'  — o handler de /foo NUNCA roda
```

A regra prática: **rota específica antes, curinga depois; middleware antes de tudo.** Um `app.get('*', ...)` no topo do arquivo não é um fallback — é um sequestro.

**`strict` decide se `/hello` e `/hello/` são a mesma rota.** Default `true` (são rotas diferentes). `new Hono({ strict: false })` trata as duas igual.

**`getPath` reescreve o que o roteador casa.** A opção do construtor recebe o `Request` e devolve a string que vai ao roteador. É como se faz multi-tenant por hostname sem sub-app por domínio:

```ts
// rotear pelo header `host`: o path casado vira `/<host><path>`
const app = new Hono({
  getPath: (req) =>
    '/' + req.headers.get('host') + req.url.replace(/^https?:\/\/[^/]+(\/[^?]*).*/, '$1'),
})
  .get('/www1.exemplo.com/pedidos', (c) => c.json({ tenant: 'www1' }, 200))
  .get('/www2.exemplo.com/pedidos', (c) => c.json({ tenant: 'www2' }, 200))
```

A doc mostra a variante que lê o hostname da URL em vez do header, e observa que o mesmo mecanismo serve para rotear por `User-Agent`. O custo é que **todo** path registrado passa a incluir o prefixo sintético — não dá para misturar rotas com e sem ele na mesma instância.

**HEAD não tem handler.** Hono converte HEAD em GET *"before route matching occurs"*. `app.head(...)` e `app.on('HEAD', ...)` **nunca** são chamados — a doc marca as duas formas com ❌. Se HEAD precisa de comportamento próprio (não computar um corpo caro, por exemplo), a resposta é middleware que checa `c.req.method` depois do `await next()`.

| ID | Regra |
| --- | --- |
| `HONO-CORE-03` | Rota específica **MUST** ser registrada antes do curinga que a cobriria — o primeiro match responde e a execução para. |
| `HONO-CORE-04` | Param de path que precisa casar `/` **MUST** usar regex explícita (`:caminho{.+}`); param simples não casa barra. |
| `HONO-CORE-11` | Rota `HEAD` dedicada **NEVER** é registrada — HEAD vira GET antes do match; use middleware com `c.req.method`. |

---

## 4. Compor: `app.route()`, `basePath` e a ordem que quebra em silêncio

Aplicação grande se divide em sub-apps, não em controllers. A doc é explícita sobre isso em Best Practices: *"Don't make Controllers when possible"* — extrair o handler para `const lista = (c: Context) => ...` faz o path param perder a inferência, porque o tipo do path some junto com a linha de registro.

```ts
// server/pedidos.ts
const pedidos = new Hono()
  .get('/', (c) => c.json({ pedidos: [] }, 200))
  .get('/:id', (c) => c.json({ id: c.req.param('id') }, 200))

export default pedidos

// server/index.ts
const routes = new Hono()
  .route('/pedidos', pedidos)     // GET /pedidos, GET /pedidos/:id
  .route('/clientes', clientes)

export type AppType = typeof routes
export default routes
```

**Se o handler tem mesmo que morar noutro arquivo, use `factory.createHandlers()`** — é a saída oficial e preserva os tipos:

```ts
import { createFactory } from 'hono/factory'

const factory = createFactory<{ Variables: { usuario: Usuario } }>()

export const listarPedidos = factory.createHandlers(
  autenticacao,
  (c) => c.json({ pedidos: buscar(c.var.usuario.id) }, 200)
)

// no arquivo de rotas
app.get('/pedidos', ...listarPedidos)
```

**A ordem de `route()` quebra em silêncio.** `route()` copia as rotas do sub-app **no momento da chamada**. Montar antes de o sub-app ter rotas produz 404, sem erro nem aviso:

```ts
// ✅
tres.get('/hi', (c) => c.text('hi'))
dois.route('/tres', tres)
app.route('/dois', dois)          // GET /dois/tres/hi → 200

// ❌ mesma intenção, ordem invertida
tres.get('/hi', (c) => c.text('hi'))
app.route('/dois', dois)          // `dois` ainda está vazio aqui
dois.route('/tres', tres)         // GET /dois/tres/hi → 404
```

A doc chama isso de *"hard to notice"*. É o segundo erro mais caro depois da cadeia quebrada.

**`basePath()` é a alternativa quando o prefixo pertence ao sub-app**, não a quem monta: `const api = new Hono().basePath('/api')` faz `api.get('/pedidos', ...)` responder em `/api/pedidos`. Útil para agrupar mantendo `app.route('/', api)`.

| ID | Regra |
| --- | --- |
| `HONO-CORE-06` | Handler **NEVER** é extraído para uma função anotada como `(c: Context) => ...` — o path param perde a inferência; use `factory.createHandlers()`. |
| `HONO-CORE-07` | `app.route(base, sub)` **MUST** ser chamado depois de o sub-app já ter registrado suas rotas. |

---

## 5. Ler o request: `c.req`

`c.req` é um `HonoRequest` — um wrapper sobre o `Request` da Fetch API, acessível cru em `c.req.raw`.

| Leitura | Devolve | Cuidado |
| --- | --- | --- |
| `c.req.param('id')` / `c.req.param()` | `string` / objeto tipado pelo padrão da rota | os nomes vêm do path, não de um schema |
| `c.req.query('q')` / `c.req.query()` | `string \| undefined` / `Record<string, string>` | sempre `string` — conversão é do validator |
| `c.req.queries('tags')` | `string[] \| undefined` | para `?tags=A&tags=B` |
| `c.req.header('X-Foo')` | `string \| undefined` | **sem argumento, as chaves vêm minúsculas** |
| `c.req.json()` | `Promise<any>` | consome o body |
| `c.req.text()` / `arrayBuffer()` / `blob()` | conteúdo cru | consome o body |
| `c.req.formData()` | `Promise<FormData>` | a API padrão |
| `c.req.parseBody()` | objeto | `multipart/form-data` e `x-www-form-urlencoded`. Opções `{ all: true }` e `{ dot: true }` |
| `c.req.valid(target)` | dado **validado**, tipado | só existe se houver validator — ver [Hono - Validação e RPC](hono-validacao-e-rpc.md) |
| `c.req.path` / `url` / `method` / `raw` | metadados e o `Request` original | |

Duas armadilhas verificadas na fonte:

```ts
// ❌ chaves em minúsculas: `foo` é sempre undefined
const headers = c.req.header()
const foo = headers['X-Foo']

// ✅
const foo = c.req.header('X-Foo')
```

`parseBody()` com múltiplos arquivos exige o sufixo `[]` na chave (`body['anexos[]']` é sempre `(string | File)[]`) — sem ele, *"if multiple files are uploaded, the last one will be used"*, silenciosamente. A opção `{ all: true }` cobre o caso geral de campos repetidos.

**O body só pode ser lido uma vez.** Se um validator já consumiu o corpo e você precisa do `Request` original (proxy, encaminhamento, assinatura de webhook), use `cloneRawRequest` de `hono/request`, que *"works even after the request body has been consumed by validators or HonoRequest methods"*.

**Route helper para observabilidade.** `routePath(c)` devolve o padrão registrado (`/pedidos/:id`), não o path concreto — é o que se usa como label de métrica para não explodir cardinalidade. `matchedRoutes(c)`, `baseRoutePath(c)` e `basePath(c)` completam o conjunto. Vêm de `hono/route`; **`c.req.routePath` e `c.req.matchedRoutes` estão deprecados desde a v4.8.0.**.

| ID | Regra |
| --- | --- |
| `HONO-CORE-08` | `c.req.header()` sem argumento **NEVER** é indexado por nome com maiúsculas — as chaves vêm minúsculas; use `c.req.header('X-Foo')`. |

---

## 6. Formar a resposta: seis formas, um critério

| Forma | Content-Type | Quando |
| --- | --- | --- |
| `c.json(body, status?, headers?)` | `application/json` | **toda rota de API.** É a única forma que o cliente RPC infere |
| `c.text(str, status?, headers?)` | `text/plain` | health check, robots.txt, resposta de debug |
| `c.html(content)` | `text/html` | página renderizada no servidor |
| `c.body(data, status?, headers?)` | o que você setar | bytes, Content-Type incomum |
| `new Response(...)` | manual | resposta vinda de upstream, ou controle total |
| `stream` / `streamText` / `streamSSE` | conforme | resposta incremental — `hono/streaming` |

`c.body('x', 201, { 'X-Message': 'oi' })` é literalmente `new Response('x', { status: 201, headers: { ... } })`; a doc mostra os dois lado a lado e recomenda `c.text`/`c.html` quando o conteúdo é texto ou HTML.

**Status literal não é cosmético.** `c.json({ pedido }, 200)` e `c.json({ pedido })` produzem a mesma resposta e **tipos diferentes**: só o primeiro permite `InferResponseType<typeof $get, 200>` e a discriminação por `res.status` no cliente. Em rota consumida pelo frontend, o status é parte do contrato.

`c.header(...)` e `c.status(...)` são a forma imperativa; os argumentos de `c.json`/`c.text`/`c.body` são a declarativa. Prefira a declarativa: ela sobrevive ao refactor que move o `return` para dentro de um `if`.

**Streaming tem duas restrições.** Erro lançado dentro do callback **não** passa por `app.onError` — quando o callback roda, a resposta já começou e não pode ser sobrescrita. E `timeout()` não funciona com stream: a saída documentada é `setTimeout` + `stream.close()`, com `stream.onAbort()` para limpar.

| ID | Regra |
| --- | --- |
| `HONO-CORE-09` | Resposta destinada ao cliente RPC **MUST** declarar o status literal em `c.json(body, status)`. |

---

## 7. Erros: `HTTPException`, `onError` e `notFound`

Hono separa três coisas que costumam virar uma só:

- **Erro esperado** (validação falhou, recurso não existe, permissão negada) — é uma **resposta**, com status e corpo previsíveis.
- **Erro inesperado** (banco caiu, bug) — vira 500 e um log.
- **404 de rota** (nenhum handler casou) — é `app.notFound`.

**O critério não é "atravessa camadas" — é "o cliente RPC precisa ver isto tipado".** `app.onError` e middleware global **não entram na inferência** das rotas (`HONO-RPC-09`), então tudo que sai por `throw new HTTPException(...)` chega ao `hc` como resposta **não tipada**: `res.status === 409` não estreita nada, e o corpo é `unknown`. Um 409 que a tela precisa distinguir de um 500 é, portanto, `return c.json(corpo, 409)` — não uma exceção. `HTTPException` fica para o que o cliente só precisa ver como falha genérica (401 de middleware, erro de infraestrutura, validação já coberta por `ApplyGlobalResponse`).

```ts
import { HTTPException } from 'hono/http-exception'

const rotas = new Hono()
  .post('/pedidos/:id/confirmar', async (c) => {
    const pedido = await buscarPedido(c.req.param('id'))
    if (!pedido) {
      // Erro de domínio que o cliente RPC discrimina por status: resposta.
      return c.json({ error: 'pedido não encontrado' as const }, 404)
    }
    if (pedido.status !== 'aberto') {
      // Também é erro de domínio, e a tela distingue: resposta, não exceção.
      // `throw new HTTPException(409, ...)` aqui sairia por app.onError e
      // NÃO chegaria tipado ao hc — HONO-CORE-13 / HONO-RPC-09.
      return c.json(
        { error: 'pedido já confirmado' as const, statusAtual: pedido.status },
        409
      )
    }
    return c.json({ pedido: await confirmar(pedido) }, 200)
  })

// HTTPException continua certa quando o cliente só precisa ver "falhou":
// tipicamente em middleware, longe da rota que produz o contrato.
const exigeToken = createMiddleware(async (c, next) => {
  if (!c.req.header('Authorization')) {
    throw new HTTPException(401, { message: 'token ausente' })
  }
  await next()
})

// No app de topo — `notFound` e o `onError` de fallback só valem lá (HONO-APP-04).
const app = new Hono()
  .route('/', rotas)
  .onError((err, c) => {
    if (err instanceof HTTPException) {
      return err.getResponse()
    }
    console.error(err) // ver
    return c.text('Internal Server Error', 500)
  })
  .notFound((c) => c.json({ error: 'rota não encontrada' }, 404))
```

Pontos verificados que mudam decisão:

- **`HTTPException` aceita `res` e `cause`.** Com `res`, o status do construtor é o que vale — *"the status passed to the constructor is the one used to create responses"*, o status da `Response` passada é ignorado. `cause` carrega o erro original sem vazá-lo no corpo.
- **`getResponse()` ignora o `Context`.** Headers já setados em `c` não entram na resposta gerada; para incluí-los é preciso montar uma nova `Response`.
- **`onError` de rota tem prioridade sobre o do pai.** *"If both a parent app and its routes have onError handlers, the route-level handlers get priority."*
- **`app.notFound` só é chamado do app de topo.** Registrar em sub-app montado com `route()` não tem efeito.
- **`c.notFound()` apaga o tipo no cliente RPC.** Ver [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 5.
- **O que sai de `app.onError` não entra na inferência.** É a razão de `HONO-CORE-13` existir: a escolha entre `return` e `throw` decide se o erro é parte do contrato tipado ou não. Ver [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 5 e `HONO-RPC-09`.

A divisão entre "esperado" e "inesperado" é a mesma de: erro esperado é parte do contrato da API e deve chegar tipado no cliente; erro inesperado é 500 genérico, log estruturado, e nada de detalhe interno no corpo.

| ID | Regra |
| --- | --- |
| `HONO-CORE-10` | `app.onError` **MUST** distinguir `HTTPException` (devolver `err.getResponse()`) de erro inesperado (logar e devolver 500 genérico sem detalhe interno). |
| `HONO-CORE-13` | Erro de domínio que o cliente RPC precisa discriminar por status **MUST** ser `return c.json(corpo, status)` no handler — `throw new HTTPException` sai por `app.onError` e **NEVER** chega tipado ao `hc`. |

---

## 8. Testar: `app.request()` e `testClient()`

Não é preciso subir servidor. `app.request()` dispara o `fetch` da instância e devolve uma `Response`:

```ts
import { describe, expect, it } from 'bun:test'   // ou vitest — ver [Bun - Testes](bun-testes.md)
import app from './index'

describe('POST /pedidos', () => {
  it('cria e devolve 201', async () => {
    const res = await app.request('/pedidos', {
      method: 'POST',
      body: JSON.stringify({ clienteId: 'c-1', itens: [] }),
      headers: new Headers({ 'Content-Type': 'application/json' }),  // obrigatório
    })
    expect(res.status).toBe(201)
  })
})
```

**O `Content-Type` não é detalhe.** A doc avisa que um validator de `json` ou `form` só parseia o body se o header casar — sem ele, *"the request body will not be parsed and you will receive an empty object (`{}`) as value"*. O teste passa a exercitar o caminho de erro do validator sem que ninguém perceba.

`app.request()` aceita um terceiro argumento com o `env`, que é como se mocka `Bindings`:

```ts
const res = await app.request('/pedidos', {}, { DATABASE_URL: 'postgres://test' })
```

`testClient(app)` de `hono/testing` dá a mesma coisa **tipada**, com autocomplete de path e de body — e depende da mesma pré-condição da § 1: *"you must define your routes using chained methods directly on the Hono instance"*. Se o teste tipado não enxerga a rota, o problema é a cadeia, não o teste.

```ts
import { testClient } from 'hono/testing'

const client = testClient(app)
const res = await client.pedidos.$get({ query: { pagina: '1' } })
expect(res.status).toBe(200)
```

**Nem `app.request()` nem `testClient()` abrem porta.** Os dois chamam o `fetch` da instância em processo: não há socket, não há `listen`, não há URL a configurar. Subir o servidor num `beforeAll` e usar `fetch('http://localhost:3000/...')` troca um teste determinístico por um teste com porta, corrida de inicialização e dependência de rede — sem cobrir uma linha a mais.

| ID | Regra |
| --- | --- |
| `HONO-CORE-12` | Teste de rota com validator de `json` ou `form` **MUST** enviar o `Content-Type` correspondente — sem ele o body chega vazio ao validator. |
| `HONO-CORE-15` | Teste de rota **MUST** usar `app.request()` ou `testClient(app)`; subir servidor e chamar por `fetch` na rede **NEVER** acontece em teste de rota. |

---

## 9. Cookies

Cookies não são um middleware: são cinco funções de `hono/cookie` que operam sobre o `Context`. Não há estado, não há sessão embutida — o que o helper dá é leitura, escrita, remoção e assinatura HMAC.

| Função | Assinatura verificada | Nota |
| --- | --- | --- |
| `getCookie(c, nome?, prefix?)` | síncrona | sem `nome`, devolve todos |
| `setCookie(c, nome, valor, options?)` | síncrona | |
| `deleteCookie(c, nome, options?)` | síncrona | devolve o valor removido; opções aceitas: `path`, `secure`, `domain` |
| `getSignedCookie(c, secret, nome?, prefix?)` | **`async`** | HMAC SHA-256 via WebCrypto |
| `setSignedCookie(c, nome, valor, secret, options?)` | **`async`** | |

`generateCookie` e `generateSignedCookie` (esta última `async`) montam a **string** do cookie sem escrevê-la na resposta — para quem precisa setar o header à mão.

**Opções de `setCookie`/`setSignedCookie`, verificadas na fonte:** `domain`, `expires` (`Date`), `httpOnly`, `maxAge`, `path`, `secure`, `sameSite` (`'Strict' | 'Lax' | 'None'`), `priority` (`'Low' | 'Medium' | 'High'`), `prefix` (`'secure' | 'host'`), `partitioned`.

```ts
import { setSignedCookie, getSignedCookie, deleteCookie } from 'hono/cookie'

const SESSAO = 'sessao'

const rotas = new Hono<{ Bindings: { COOKIE_SECRET: string } }>()
  .post('/sessoes', zValidator('json', credenciais), async (c) => {
    const usuario = await autenticar(c.req.valid('json'))
    if (!usuario) return c.json({ error: 'credenciais inválidas' as const }, 401)

    await setSignedCookie(c, SESSAO, usuario.id, c.env.COOKIE_SECRET, {
      httpOnly: true,      // fora do alcance de document.cookie
      secure: true,        // só por HTTPS
      sameSite: 'Lax',     // sobrevive à navegação de topo, barra POST cross-site
      path: '/',
      maxAge: 60 * 60 * 8,
    })
    return c.json({ usuario: { id: usuario.id, nome: usuario.nome } }, 201)
  })
  .delete('/sessoes', (c) => {
    deleteCookie(c, SESSAO, { path: '/', secure: true })
    return c.json({ ok: true as const }, 200)
  })
```

Ler no middleware, não no handler — o handler consome `c.var`:

```ts
const sessao = createMiddleware<{
  Bindings: { COOKIE_SECRET: string }
  Variables: { usuarioId: string }
}>(async (c, next) => {
  const id = await getSignedCookie(c, c.env.COOKIE_SECRET, SESSAO)
  // assinatura inválida devolve `false`; cookie ausente ou sem formato
  // assinado devolve `undefined`. Os dois são falsy — um teste cobre os dois.
  if (!id) return c.json({ error: 'sessão inválida' as const }, 401)
  c.set('usuarioId', id)
  await next()
})
```

**Três comportamentos que a fonte contraria o hábito:**

- **`getSignedCookie` distingue `false` de `undefined`.** `false` = tem assinatura e ela **não** confere (adulteração). `undefined` = não é um cookie assinado, ou não existe. `if (!value)` cobre os dois; distinguir só importa se você quer logar tentativa de adulteração.
- **Prefixos `__Secure-`/`__Host-` são validados, e o helper *lança*.** Nome com `__Secure-` sem `secure`, ou `__Host-` sem `secure`, com `path` diferente de `/`, ou com `domain` setado, produzem `Error` no parse — não um cookie silenciosamente inválido.
- **`maxAge` acima de 400 dias lança.** Idem `expires` mais de 400 dias no futuro. É a implementação do RFC6265bis-13; não há flag para desligar.

O `secret` é segredo de inicialização, vem de `c.env`/`env(c)` e nunca do código — `HONO-APP-03`. Para o resto da política de sessão (rotação, expiração, invalidação no servidor) ver [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) e [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md).

| ID | Regra |
| --- | --- |
| `HONO-CORE-14` | Cookie de sessão ou de autenticação **MUST** ser escrito com `setSignedCookie` e as opções `httpOnly: true` e `secure: true`; `setCookie` cru **NEVER** carrega identidade. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `const app = new Hono()` e depois `app.get(...)` em statements separadas | `typeof app` fica sendo o app vazio; `hc` e `testClient` perdem todas as rotas, **sem erro de compilação** | encadear a partir de `new Hono()` e exportar `typeof` da variável da cadeia — `HONO-CORE-01` |
| Extrair o handler para `const lista = (c: Context) => ...` | o path param perde a inferência; `c.req.param('id')` vira `string` sem relação com a rota | escrever o handler na linha de registro, ou `factory.createHandlers()` — `HONO-CORE-06` |
| `app.route('/dois', dois)` antes de `dois` ter rotas | `route()` copia o que existe no momento da chamada; resultado é 404 silencioso | montar de dentro para fora — `HONO-CORE-07` |
| `app.get('*', fallback)` no topo do arquivo | o primeiro match responde e a execução para: nenhuma rota abaixo é alcançada | curinga por último — `HONO-CORE-03` |
| `app.head('/recurso', ...)` para responder HEAD sem corpo | Hono converte HEAD em GET antes do match; o handler nunca roda | middleware que checa `c.req.method` após `await next()` — `HONO-CORE-11` |
| `c.json({ pedido })` sem status em rota consumida pelo frontend | o tipo existe mas não discrimina por status; `res.status === 404` não estreita nada no cliente | `c.json({ pedido }, 200)` e `c.json({ error }, 404)` — `HONO-CORE-09` |
| `const h = c.req.header()` e depois `h['Authorization']` | as chaves vêm minúsculas; o valor é sempre `undefined` | `c.req.header('Authorization')` — `HONO-CORE-08` |
| `app.request('/x', { method: 'POST', body: JSON.stringify(...) })` sem `Content-Type` | o validator recebe `{}` e o teste passa a exercitar o caminho de erro | incluir `headers: { 'Content-Type': 'application/json' }` — `HONO-CORE-12` |
| `throw new Error('não encontrado')` no handler | vira 500 genérico; o cliente não distingue bug de regra de negócio | `c.json({ error }, 404)` — `HONO-CORE-10` / `HONO-CORE-13` |
| `throw new HTTPException(409, ...)` para conflito que a tela precisa distinguir | sai por `app.onError`, que **não** entra na inferência: `res.status === 409` não estreita nada no `hc` | `return c.json({ error, ... }, 409)` — `HONO-CORE-13` |
| `app.notFound()` registrado no sub-app | só o app de topo o chama; o handler nunca roda | registrar no app de topo — [Hono](hono.md) `HONO-APP-04` |
| Subir o servidor e testar por `fetch('http://localhost:3000/...')` | porta, corrida de inicialização e rede num teste que a instância resolve em processo | `app.request()` ou `testClient(app)` — `HONO-CORE-15` |
| `setCookie(c, 'sessao', id)` sem `httpOnly`/`secure`, ou sem assinar | qualquer script lê, e o valor é forjável — o servidor não distingue cookie legítimo de inventado | `setSignedCookie` com `httpOnly: true, secure: true` — `HONO-CORE-14` |

---

## Checklist de revisão

- [ ] As rotas estão em cadeia contínua, e o `typeof` exportado é o da variável da cadeia? → `HONO-CORE-01`
- [ ] `Bindings` e `Variables` estão no generic, sem cast em `c.env`/`c.var`? → `HONO-CORE-02`
- [ ] Algum curinga registrado antes de rota específica? → `HONO-CORE-03`
- [ ] Algum param precisa casar `/` sem regex? → `HONO-CORE-04`
- [ ] Algum `ContextVariableMap` cobrindo middleware não global? → `HONO-CORE-05`
- [ ] Algum handler extraído com `(c: Context)` em vez de `createHandlers`? → `HONO-CORE-06`
- [ ] Todo `app.route()` vem depois de o sub-app ter rotas? → `HONO-CORE-07`
- [ ] Nenhum `c.req.header()` indexado com maiúsculas? → `HONO-CORE-08`
- [ ] Todo `c.json` de rota pública declara status literal? → `HONO-CORE-09`
- [ ] `onError` separa `HTTPException` de erro inesperado, sem vazar detalhe? → `HONO-CORE-10`
- [ ] Nenhuma rota `HEAD` dedicada? → `HONO-CORE-11`
- [ ] Testes de `json`/`form` enviam `Content-Type`? → `HONO-CORE-12`
- [ ] Todo erro de domínio que a tela discrimina sai por `return c.json(corpo, status)`? → `HONO-CORE-13`
- [ ] Cookie de sessão é assinado, `httpOnly` e `secure`? → `HONO-CORE-14`
- [ ] Nenhum teste de rota sobe servidor ou usa a rede? → `HONO-CORE-15`

---

## Relacionados

- [Hono](hono.md) — hub, mapa da API, árvores de decisão
- [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) · [Hono - Validação e RPC](hono-validacao-e-rpc.md)
- · ·
- [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) · [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) ·
- ·
- [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Bun - Testes](bun-testes.md) ·
- ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Routing](https://hono.dev/docs/api/routing) · [App - Hono](https://hono.dev/docs/api/hono) · [Context](https://hono.dev/docs/api/context) · [HonoRequest](https://hono.dev/docs/api/request) · [HTTPException](https://hono.dev/docs/api/exception)
- [Best Practices](https://hono.dev/docs/guides/best-practices) · [Testing](https://hono.dev/docs/guides/testing) · [Validation](https://hono.dev/docs/guides/validation)
- [Factory Helper](https://hono.dev/docs/helpers/factory) · [Route Helper](https://hono.dev/docs/helpers/route) · [Streaming Helper](https://hono.dev/docs/helpers/streaming) · [Testing Helper](https://hono.dev/docs/helpers/testing) · [Cookie Helper](https://hono.dev/docs/helpers/cookie)

**O que a verificação contrariou:**

- **O cookie helper valida prefixo e prazo, e lança.** `__Secure-` sem `secure`, `__Host-` sem `secure` / com `path` ≠ `/` / com `domain`, `maxAge` acima de 400 dias e `expires` mais de 400 dias à frente produzem `Error` no parse. É implementação de RFC6265bis-13 e CHIPS-01, não validação opcional.
- **`getSignedCookie` tem três resultados, não dois.** Valor, `false` (assinatura presente e inválida) e `undefined` (não é cookie assinado, ou não existe). Tratar só "existe / não existe" perde o caso de adulteração.
- **`generateCookie` e `generateSignedCookie` existem** e só montam a string — não escrevem no header. Não constavam do inventário anterior desta estrutura.
- **`routePath(c)` aceita um índice** (`routePath(c, 0)`, `routePath(c, -1)`), como `Array.prototype.at()`, para escolher entre as rotas casadas quando há middleware curinga.
- **Hono não valida a resposta.** O guia de Validation cobre exclusivamente input: os targets são `json`, `form`, `query`, `param`, `header`, `cookie`. Não há equivalente a um schema de saída checado em runtime — ver [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 7.

- **`app.head()` não é ignorado por engano — é impossível por design.** A conversão HEAD→GET acontece *"before route matching occurs"*, e a doc lista as duas tentativas (`app.head` e `app.on('HEAD', ...)`) como ❌.
- **`app.query()` existe.** O método HTTP QUERY aparece no exemplo básico de Routing e no default de `allowMethods` do CORS.
- **`app.notFound` não vale para sub-app.** É restrição documentada, com link para a issue #3465 do repositório.
- **`HTTPException` com a opção `res`: o status do construtor vence**, o da `Response` passada é ignorado. E `getResponse()` não enxerga headers setados no `Context`.
- **`c.req.routePath` e `c.req.matchedRoutes` estão deprecados desde a v4.8.0** em favor do helper `hono/route` — a nota anterior do vault teria usado a forma antiga.
- **`cloneRawRequest` (`hono/request`) resolve o body já consumido**, caso que normalmente exige guardar o corpo à mão antes de validar.
- **Erro no callback de streaming não passa por `app.onError`**, porque a resposta já começou. É a única classe de erro que escapa do handler global.
