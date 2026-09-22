---
titulo: Elysia - Roteamento e Handler
Link: https://elysiajs.com/essential/handler.html
tags:
 - elysia
 - http
 - agent-context
source: "Documentação oficial — https://elysiajs.com/"
verificado-em: 2026-08-15
---

# Elysia - Roteamento e Handler

> Instância e `listen` · verbos, path params, wildcard e precedência · `group` · o objeto de contexto · formas de resposta e coerção · `status` e `set` · cookie reativo · redirect, arquivo, stream e SSE · `onError` e a taxonomia de códigos · testar sem subir servidor.
>
> **Não cobre:** escopo, hooks e plugins ([Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md)) · schema, validação e Eden ([Elysia - Schema e Eden](elysia-schema-e-eden.md)) · o servidor HTTP por baixo ([Bun - HTTP e Servidor](bun-http-e-servidor.md)).

Entrada: [Elysia](elysia.md) · Base normativa: [Elysia](elysia.md) § 6

---

## 1. Conceito: o contexto é um acúmulo de decisões anteriores, não um objeto fixo

O handler recebe um objeto só. A tentação é tratá-lo como um `req`/`res` de Express com outros nomes — e é aí que o modelo mental erra.

O contexto de Elysia tem uma parte fixa (`body`, `query`, `params`, `headers`, `cookie`, `set`, `store`, `request`, `path`, `route`, `status`, `redirect`, `server`) e uma parte **que foi colocada ali** por `decorate`, `derive`, `resolve` e macros registrados antes desta rota. O tipo de `params.id` é `string` ou `number` dependendo de haver schema. O tipo de `body` é `unknown` sem schema e exato com schema. Se um plugin com `resolve` está no encadeamento, `ctx.usuario` existe; se o escopo dele for `local` e a rota estiver na instância pai, não existe — e o TypeScript avisa.

Isso tem uma consequência prática direta: **desestruturar no parâmetro é a forma canônica**, não açúcar sintático. `({ params: { id }, status }) =>...` documenta exatamente o que a rota consome e é o que a doc usa em todos os exemplos. E é também o que a doc recomenda ao delegar para uma camada de serviço: *"it's recommended to destructure properties from inline function to prevent unnecessary type inference"* — passar o `Context` inteiro para uma classe controller é explicitamente desaconselhado, porque o tipo é dinâmico demais para ser anotado à mão.

```ts
import { Elysia, t } from 'elysia'

new Elysia
.get('/pedidos/:id', ({ params: { id }, status }) => {
 const pedido = pedidos.buscar(id) // id é number: o schema coagiu
 if (!pedido) return status(404, { erro: 'Pedido não encontrado' })
 return pedido
 }, {
 params: t.Object({ id: t.Numeric })
 })
.listen(3000)
```

| ID | Regra |
| --- | --- |
| `ELYSIA-CORE-02` | O handler **MUST** desestruturar as propriedades do contexto que usa — **NEVER** receber e repassar o objeto `Context` inteiro para outra camada. |

---

## 2. Instância, rotas e precedência de caminho

`new Elysia` cria a instância; `.listen(port)` sobe o servidor. Toda rota aceita três argumentos: caminho, handler, e um objeto opcional de metadados (schema + hooks locais).

```ts
new Elysia({ prefix: '/v1' })
.get('/status', 'ok') // valor literal, sem função
.post('/pedidos', ({ body }) => criar(body))
.all('/webhook', ({ request }) => aceitar(request))
.route('M-SEARCH', '/discover', 'ok') // verbo customizado, MAIÚSCULO
.listen(3000)
```

Um valor literal no lugar da função é uma otimização real: a doc explica que permite compilar a resposta antecipadamente, e com `nativeStaticResponse` em Bun ela vira `Bun.serve.static`. **Não funciona no Cloudflare Worker** (não se pode construir `Response` antes do start).

### Tipos de caminho

| Forma | Sintaxe | `params` |
| --- | --- | --- |
| estático | `/pedidos` | — |
| dinâmico | `/pedidos/:id` | `params.id` |
| múltiplos | `/lojas/:loja/pedidos/:id` | `params.loja`, `params.id` |
| opcional | `/pedidos/:id?` | `params.id` pode faltar |
| wildcard | `/arquivos/*` | `params['*']` |

**Precedência, verificada:** estático → dinâmico → wildcard. `/id/1` ganha de `/id/:id`, que ganha de `/id/*`.

Duas armadilhas de comportamento que a tabela oficial deixa explícitas:

- `/pedidos/:id` **não** casa com `/pedidos` (é Not Found) nem com `/pedidos/1/itens`.
- Barra final é tolerada por padrão. `strictPath: false` (default) faz `/nome` e `/nome/` resolverem igual; `strictPath: true` segue a RFC 3986 e separa os dois.

Sem schema de `params`, todo path param é `string`. Com `t.Number` no schema de rota, Elysia converte para `t.Numeric` e coage — detalhe em [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 3.

### `group` e `guard`

`group` aplica prefixo. Aceita um guard opcional no segundo argumento, o que evita aninhar `group` dentro de `guard`:

```ts
new Elysia
.group('/usuarios', (app) => app
.post('/entrar', ({ body }) => entrar(body))
.post('/registrar', ({ body }) => registrar(body))
 )
 // com guard no 2º argumento: schema aplicado às duas rotas de uma vez
.group('/admin', { headers: t.Object({ authorization: t.String }) }, (app) => app
.get('/metricas', => metricas)
.delete('/cache', => limparCache)
 )
```

A alternativa sem aninhamento é `new Elysia({ prefix: '/usuarios' })` como instância separada, aplicada com `.use`. É o que a organização por feature da doc recomenda: uma instância por módulo, cada uma com seu prefixo. Cuidado: instância separada traz junto a semântica de **escopo** — ver [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 5.

| ID | Regra |
| --- | --- |
| `ELYSIA-CORE-01` | Hook, plugin e `onError` **MUST** ser registrados antes das rotas que devem afetar — evento só se aplica a rota registrada depois dele. |

---

## 3. O objeto de contexto

Lista verificada em `context.d.ts` de 1.4.29.

| Propriedade | O que é | Observação |
| --- | --- | --- |
| `body` | corpo parseado | `unknown` sem schema. Ignorado em GET/HEAD por padrão (RFC 2616) |
| `query` | query string | `Record<string, string>` sem schema |
| `params` | path params | `string` sem schema |
| `headers` | headers do request | **sempre em minúsculas** |
| `cookie` | cookie jar reativo | é um Proxy: nunca `undefined`, só `.value` pode ser |
| `set` | `{ headers, status }` da resposta | `set.redirect` está deprecado |
| `store` | estado global da instância | criado por `.state` |
| `status` | função de resposta com status tipado | substitui o antigo `error` |
| `redirect` | função de redirect | também exportada por `elysia` |
| `request` | `Request` Web Standard | escape hatch para o que não está no contexto |
| `server` | instância do servidor | **Bun only**, `null` fora dele e antes do `listen` |
| `path` | caminho da URL | ex.: `/pedidos/9` |
| `route` | caminho **registrado** no router | ex.: `/pedidos/:id` — útil para métrica e log |
| — | `decorate`, `derive`, `resolve` | tudo que plugins e hooks anteriores acrescentaram |

`route` é a propriedade que quase ninguém conhece e resolve um problema real: agrupar métricas e logs por rota em vez de por URL concreta, sem cardinalidade explodindo. Ver.

`onRequest` recebe um `PreContext` reduzido — só `request`, `set`, `store`, `status`, `redirect`, `server` e decorators. Não tem `body`, `query`, `params`, `headers`, `cookie`, `path`, `route` nem nada de `derive`/`resolve`, porque roda antes de tudo isso existir. `status` está lá, e é o que permite curto-circuitar tipado: `return status(429, { erro: 'Limite excedido' })`. Enumeração canônica e a lista do que fica de fora em [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 2.

---

## 4. Formas de resposta

O valor retornado pelo handler é convertido automaticamente. Não é preciso serializar nem definir `Content-Type` na maioria dos casos.

```ts
import { Elysia, file, form, sse } from 'elysia'

new Elysia
.get('/texto', => 'ok') // text/plain
.get('/json', => ({ id: 1, nome: 'Ana' })) // application/json
.get('/arquivo', file('public/manual.pdf')) // arquivo
.get('/pacote', => form({ // FormData
 titulo: 'Relatório',
 anexos: [file('a.pdf'), file('b.pdf')]
 }))
.get('/bruto', => new Response('...', { status: 202 })) // Response passa direto
```

### Status e headers

Duas APIs, e a escolha entre elas importa:

```ts
new Elysia
.get('/a', ({ status }) => status(418, 'Sou um bule')) // tipado, checado contra o response schema
.get('/b', ({ set }) => {
 set.status = 418 // NÃO é checado contra o schema
 set.headers['x-powered-by'] = 'Elysia'
 return 'Sou um bule'
 })
```

A doc é explícita sobre a diferença: *"Unlike the `status` function, `set.status` cannot infer the return value type, therefore it can't check if the return value is correctly typed to the response schema"*. `set.status` serve para o caso em que um plugin quer definir um status padrão e deixar o usuário retornar o valor. Para tudo mais, `status`.

`status` aceita número ou o nome do status (`status("I'm a teapot")`), com autocomplete. Headers de resposta vão em `set.headers`, sempre em minúsculas (`set-cookie`, não `Set-Cookie`) — `headers` sem `set.` é o **request**.

### Cookie reativo

O cookie jar é um Proxy. Não há `getCookie`/`setCookie`: você lê e escreve `.value` e o header é sincronizado.

`ELYSIA-CORE-05` é conjuntivo: **assinado e `httpOnly`**. `httpOnly` sozinho impede o JavaScript do cliente de *ler* o cookie, mas não impede ninguém de *forjar* um. Por isso o bloco canônico de sessão declara as duas coisas, e a assinatura vive no construtor:

```ts
import { Elysia, env } from 'elysia' // `env`, não `process.env` — ELYSIA-APP-09

new Elysia({
 cookie: {
 secrets: [env.COOKIE_SECRET_ATUAL!, env.COOKIE_SECRET_ANTIGO!],
 sign: ['sessao'] // assina na primeira chave, verifica em todas
 }
})
.get('/entrar', ({ cookie: { sessao } }) => {
 sessao.value = { usuarioId: 42 } // objeto: encode/decode automático
 sessao.httpOnly = true // as duas metades de ELYSIA-CORE-05:
 sessao.secure = true // `sign` acima + `httpOnly` aqui
 sessao.sameSite = 'lax'
 sessao.maxAge = 7 * 86400
 return 'ok'
 })
.get('/sair', ({ cookie: { sessao } }) => {
 sessao.remove // ou: delete cookie.sessao
 return 'ok'
 })
```

O mesmo par pode ser declarado de uma vez no schema da rota, com `t.Cookie(props, { secrets, sign, httpOnly, secure })` — é a forma que também documenta o cookie no OpenAPI. Ver [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 3.

`set({...})` reseta todas as propriedades do cookie e aplica as novas; `add({...})` sobrescreve só as informadas.

Colocar `null` no array de `secrets` deixa cookies não assinados passarem — a doc apresenta como transição gradual, e diz para usar só durante a migração. Segredos vêm da inicialização, não do código:.

> **Aviso de tipo:** o TypeScript pode marcar `cookie.nome` como possivelmente `undefined`. A doc esclarece: *"Elysia cookie can never be `undefined` because it's a Proxy object"* — só `.value` pode ser. Resolve-se declarando um schema `t.Cookie`.

### Redirect

```ts
new Elysia
.get('/antigo', ({ redirect }) => redirect('/novo'))
.get('/externo', ({ redirect }) => redirect('https://exemplo.com', 302))
```

O valor retornado depois de `redirect` é ignorado. `set.redirect` ainda existe, mas está marcado `@deprecated` nos tipos.

### Stream e SSE

Um handler `function*` vira streaming. Envolver o valor em `sse` liga `text/event-stream` e o formato de evento.

```ts
import { Elysia, sse } from 'elysia'

new Elysia
.get('/progresso', function* ({ set }) {
 set.headers['x-job'] = 'importacao' // headers só valem ANTES do primeiro yield
 for (const etapa of etapas) {
 yield sse({ event: 'progresso', data: { etapa: etapa.nome, pct: etapa.pct } })
 }
 yield sse({ event: 'fim' })
 })
.get('/talvez', function* {
 if (cacheQuente) return respostaCompleta // sem yield: vira resposta normal
 yield* pedacos
 })
```

Três comportamentos verificados que mudam código:

1. **Headers depois do primeiro `yield` não fazem nada.** Uma vez enviado o primeiro chunk, os headers já foram.
2. **Retornar sem `yield` converte para resposta normal**, o que permite decidir entre stream e resposta única em runtime.
3. **Cancelamento é automático**: se o cliente aborta, Elysia para o generator. Ver.

No cliente, o Eden interpreta o stream como `AsyncGenerator` — `for await (const chunk of data)`.

| ID | Regra |
| --- | --- |
| `ELYSIA-CORE-04` | `status(code, valor)` **MUST** ser usado no lugar de `set.status` sempre que a rota declarar schema de `response` — só ele é checado contra o schema. |
| `ELYSIA-CORE-05` | Cookie de sessão **MUST** ser assinado (`secrets` + `sign`) e marcado `httpOnly`. |
| `ELYSIA-CORE-06` | `set.headers` **NEVER** é alterado depois do primeiro `yield` de um handler generator — a alteração é silenciosamente ignorada. |

---

## 5. Erros: taxonomia, retorno × exceção, e customização

Elysia captura o que estoura em qualquer fase, classifica e entrega ao `onError` com um `code` que estreita o tipo de `error`.

**Códigos embutidos, verificados:** `NOT_FOUND`, `PARSE`, `VALIDATION`, `INTERNAL_SERVER_ERROR`, `INVALID_COOKIE_SIGNATURE`, `INVALID_FILE_TYPE`, `UNKNOWN`, **ou um número de status HTTP**. Erro desconhecido cai em `UNKNOWN` com status 500.

Cada classe embutida traz um status default, e é ele que sai **sem `onError` nenhum**. Extraídos de `error.js` de `elysia@1.4.29`:

| Código | Classe | Status default |
| --- | --- | --- |
| `VALIDATION` | `ValidationError` | **422** |
| `INVALID_FILE_TYPE` | `InvalidFileType` | 422 |
| `NOT_FOUND` | `NotFoundError` | 404 |
| `PARSE` | `ParseError` | 400 |
| `INVALID_COOKIE_SIGNATURE` | `InvalidCookieSignature` | 400 |
| `INTERNAL_SERVER_ERROR` / `UNKNOWN` | `InternalServerError` | 500 |

O **422** de validação é o número que mais surpreende, porque o reflexo de quem vem de outros frameworks é 400. Ele é o status de `ValidationError` no pacote, não uma escolha do `onError` do exemplo abaixo — um app sem `onError` já responde 422 a payload inválido, e é por isso que o teste da § 6 pode assertá-lo. Um `onError` que devolve 400 para `code === 'VALIDATION'` está **mudando** o default, não formalizando-o; se o contrato da API promete 400, isso precisa estar declarado no `response` schema e no OpenAPI, senão a documentação mente.

```ts
import { Elysia } from 'elysia'

new Elysia
.onError(({ code, error, status, route, path }) => {
 switch (code) {
 case 'NOT_FOUND':
 return status(404, { erro: 'Recurso não encontrado' })
 case 'VALIDATION':
 // error é ValidationError; error.all lista todas as causas
 return status(422, { erro: 'Payload inválido', causas: error.all })
 default:
 // inesperado: logue com contexto e devolva mensagem genérica
 logger.error({ code, route, path, err: error })
 return status(500, { erro: 'Erro interno' })
 }
 })
.get('/pedidos/:id', /*... */)
```

O `switch` acima segue: esperado vira resposta com significado, inesperado vira 500 opaco **com log**. Não devolva `error.message` de um erro desconhecido ao cliente.

### A distinção que confunde: `return status` × `throw status`

Citação literal da fonte, porque a paráfrase perde:

> "If a `status` is **throw**, it will be caught by `onError` middleware. If a `status` is **return**, it will be **NOT** caught by `onError` middleware."

Isso não é detalhe de implementação — é uma escolha de arquitetura:

| | `return status(...)` | `throw status(...)` |
| --- | --- | --- |
| Passa por `onError` | não | sim |
| Checado contra `response` schema | sim | não |
| Tipo chega ao Eden com narrowing por status | sim | não |
| Usar quando | o erro faz parte do contrato da API | erro atravessa camadas e um handler central formata |

A doc recomenda a abordagem **never-throw** para o caso normal, e lista as três razões: checagem contra o schema, autocomplete por status, e narrowing do erro no Eden. Ver.

Há um caso legítimo de `throw`: uma camada de serviço, longe do handler, que precisa abortar. A própria doc faz isso no exemplo de Best Practice — `throw status(400, '...')` dentro de um `Auth.signIn` que não conhece o contexto Elysia.

### Erros customizados

```ts
class EstoqueInsuficiente extends Error {
 status = 409
 constructor(public sku: string) { super(`Sem estoque para ${sku}`) }
 toResponse { return Response.json({ erro: 'estoque', sku: this.sku }, { status: 409 }) }
}

new Elysia
.error({ ESTOQUE: EstoqueInsuficiente }) // registra o código
.onError(({ code, error, status }) => {
 if (code === 'ESTOQUE') return status(409, { sku: error.sku }) // error é tipado
 })
.post('/carrinho', ({ body }) => adicionar(body))
```

`status` na classe define o status padrão; `toResponse` define a resposta inteira. Registrar em `.error` é o que dá narrowing por `code` no `onError`.

### Mensagem de validação

Por campo, com `error` no schema; ou centralizado, narroweando `code === 'VALIDATION'`. Detalhe em [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 5. Um comportamento a saber agora: **em `NODE_ENV=production` os detalhes da validação são omitidos por padrão** — a resposta diz que falhou, sem revelar nomes de campo e tipos esperados. `allowUnsafeValidationDetails: true` no construtor reverte, e a doc adverte que isso vaza a forma do schema.

| ID | Regra |
| --- | --- |
| `ELYSIA-CORE-03` | Erro esperado **MUST** ser `return status(...)`, não `throw`, quando o tipo precisa chegar tipado ao Eden. |
| `ELYSIA-CORE-07` | `onError` **NEVER** devolve `error.message` de um erro `UNKNOWN` ao cliente — logue o detalhe e responda genérico. |
| `ELYSIA-CORE-08` | Erro de domínio recorrente **MUST** ser registrado em `.error({...})` para ter `code` próprio e narrowing no `onError`. |

---

## 6. Testar sem subir servidor

`app.fetch(request)` e `app.handle(request)` processam um `Request` Web Standard e devolvem uma `Response` — sem porta, sem rede. A doc insiste que **não é mock**: *"you can expect it to behave like an actual request sent to the server"*, com lifecycle completo.

```ts
import { describe, it, expect } from 'bun:test'
import { Elysia, t } from 'elysia'

const app = new Elysia
.post('/pedidos', ({ body, status }) => status(201, { id: 1,...body }), {
 body: t.Object({ sku: t.String, quantidade: t.Number })
 })

describe('POST /pedidos', => {
 it('cria e devolve 201', async => {
 const res = await app.fetch(new Request('http://localhost/pedidos', {
 method: 'POST',
 headers: { 'content-type': 'application/json' },
 body: JSON.stringify({ sku: 'ABC', quantidade: 2 })
 }))

 expect(res.status).toBe(201)
 expect(await res.json).toEqual({ id: 1, sku: 'ABC', quantidade: 2 })
 })

 it('rejeita payload inválido', async => {
 const res = await app.fetch(new Request('http://localhost/pedidos', {
 method: 'POST',
 headers: { 'content-type': 'application/json' },
 body: JSON.stringify({ sku: 'ABC' }) // falta quantidade
 }))

 // 422 é o status default de ValidationError — esta app não tem onError. Ver § 5.
 expect(res.status).toBe(422)
 })
})
```

Se a app usa plugin assíncrono ou `import` lazy, espere `await app.modules` antes de assertar — módulos deferidos registram-se depois do start.

A mesma função é o que torna Elysia embutível: `app.fetch(request)` é literalmente o que os guias de Next.js, Astro, Expo, Vercel e TanStack Start usam para montar Elysia numa API route.

Para teste com tipos ponta a ponta, `treaty(app)` recebe a instância direta e não faz requisição de rede — ver [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 7. Contexto mais amplo em e.

| ID | Regra |
| --- | --- |
| `ELYSIA-CORE-09` | Teste de rota **MUST** usar `app.fetch`/`app.handle` — **NEVER** subir servidor e requisitar por rede. |
| `ELYSIA-CORE-10` | App com plugin assíncrono ou `import` lazy **MUST** aguardar `app.modules` antes das asserções. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `onError` no fim do encadeamento | evento só vale para rota registrada depois; as rotas acima ficam sem tratamento e ninguém percebe até a produção | registrar `onError` antes de qualquer rota — `ELYSIA-CORE-01` |
| `return status(404)` esperando cair no `onError` | retorno não passa pelo `onError`; o handler central de formatação nunca roda | `throw status(404)` se o `onError` deve formatar; `return` se o contrato é da rota — `ELYSIA-CORE-03` |
| `set.status = 422` com `response` schema declarado | não é checado contra o schema, e o Eden não estreita o tipo do erro | `status(422, valor)` — `ELYSIA-CORE-04` |
| Controller class recebendo `Context` inteiro | `Context` é dinâmico e depende de plugins; anotá-lo à mão perde integridade de tipo, e é desaconselhado na própria doc | desestruturar no handler inline e passar valores primitivos ao serviço — `ELYSIA-CORE-02` |
| `set.headers[...]` dentro do loop de um generator | depois do primeiro `yield` os headers já foram enviados; a atribuição é silenciosamente ignorada | definir todos os headers antes do primeiro `yield` — `ELYSIA-CORE-06` |
| Devolver `error.message` no `default` do `onError` | mensagem de erro desconhecido vaza stack, query SQL, caminho de arquivo | logar o detalhe, responder mensagem genérica — `ELYSIA-CORE-07` |
| Subir o servidor com `listen` dentro do teste | porta ocupada, teste lento, flakiness em paralelo — e é desnecessário | `app.fetch(new Request(...))` — `ELYSIA-CORE-09` |
| `Cookie`/`Set-Cookie` com maiúscula em `set.headers` | Elysia normaliza headers em minúsculas; a chave com maiúscula pode duplicar | usar `set-cookie`, ou melhor, a API de cookie do contexto |
| Cookie de sessão sem `httpOnly` nem assinatura | legível e forjável por JavaScript no cliente | `t.Cookie` com `secrets` + `sign` + `httpOnly` — `ELYSIA-CORE-05` |

---

## Checklist de revisão

- [ ] Todo `onError`, `guard` e `.use` aparece antes das rotas que deve afetar? → `ELYSIA-CORE-01`
- [ ] Nenhum handler recebe `Context` inteiro para repassar? → `ELYSIA-CORE-02`
- [ ] `return` × `throw` de `status` está coerente com quem deve formatar o erro? → `ELYSIA-CORE-03`
- [ ] Onde há `response` schema, o status sai por `status` e não por `set.status`? → `ELYSIA-CORE-04`
- [ ] Cookies de sessão têm `sign` + `httpOnly`, com segredo vindo do ambiente? → `ELYSIA-CORE-05`
- [ ] Handlers generator definem headers antes do primeiro `yield`? → `ELYSIA-CORE-06`
- [ ] O ramo `default` do `onError` loga o detalhe e devolve mensagem genérica? → `ELYSIA-CORE-07`
- [ ] Erros de domínio recorrentes estão registrados em `.error({...})`? → `ELYSIA-CORE-08`
- [ ] Testes usam `app.fetch` sem subir servidor? → `ELYSIA-CORE-09`
- [ ] Há `await app.modules` onde existe plugin assíncrono? → `ELYSIA-CORE-10`

---

## Relacionados

- [Elysia](elysia.md) — hub
- [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) · [Elysia - Schema e Eden](elysia-schema-e-eden.md)
- [Bun - HTTP e Servidor](bun-http-e-servidor.md) — `serve`, TLS, sockets por baixo do `listen`
- · ·
- · ·
- ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Route](https://elysiajs.com/essential/route.html) · [Handler](https://elysiajs.com/essential/handler.html)
- [Lifecycle — On Error](https://elysiajs.com/essential/life-cycle.html) · [Error Handling](https://elysiajs.com/patterns/error-handling.html)
- [Reactive Cookie](https://elysiajs.com/patterns/cookie.html) · [Config](https://elysiajs.com/patterns/configuration.html)
- [Unit Test](https://elysiajs.com/patterns/unit-test.html) · [Best Practice](https://elysiajs.com/essential/best-practice.html)
- `elysia@1.4.29` — `context.d.ts` (forma exata do `Context` e do `PreContext`) e `error.d.ts` (classes e `status`)

**O que a verificação contrariou:**

- **`error` do contexto não existe mais**; foi renomeado para `status`. Exemplos remanescentes na doc oficial (Lifecycle § Local Error) ainda usam o nome antigo.
- **`context.route` existe** e traz o caminho **registrado** (`/pedidos/:id`), separado de `context.path` (a URL concreta). É o valor certo para rótulo de métrica e log.
- **`set.redirect` está deprecado** nos tipos, com o próprio JSDoc indicando a migração para o `redirect` inline.
- **`return status` não passa pelo `onError`** — só `throw` passa. É a fonte da confusão mais comum sobre tratamento de erro em Elysia.
- **Detalhes de erro de validação são omitidos em produção por padrão**, deliberadamente, para não vazar a forma do schema.
- **`strictPath` tem default `false`**: `/nome` e `/nome/` resolvem para a mesma rota a menos que se peça o contrário.
- **Body é ignorado em GET e HEAD por padrão**, seguindo a RFC 2616 — um GET com corpo não chega em `body`.
- **Valor inline em rota não funciona no Cloudflare Worker**, porque exige construir a `Response` antes do start do servidor.
- **O status default de erro de validação é 422, não 400.** `ValidationError.status = 422` em `error.js` de 1.4.29 — nenhuma página da doc declara o número, e ele sai mesmo sem `onError`. `InvalidFileType` também é 422; `ParseError` e `InvalidCookieSignature` são 400; `NotFoundError`, 404.
- **O `PreContext` de `onRequest` inclui `status`**, apesar de a página de Lifecycle enumerar só `request`, `set`, `store` e decorators. Verificado em `context.d.ts`; enumeração canônica em [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 2.
