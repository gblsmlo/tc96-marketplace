---
titulo: Hono - Middleware e Ciclo de Vida
Link: https://hono.dev/docs/guides/middleware
tags:
  - hono
  - middleware
  - agent-context
source: "Documentação oficial — https://hono.dev/docs"
verificado-em: 2026-08-15
---

# Hono - Middleware e Ciclo de Vida

> Onion model e a fronteira do `await next()` · assinatura e as saídas legítimas · escopo global × por path × por rota · `createMiddleware` e middleware tipado que popula `c.var` · os built-ins que importam em produção, com import exato e default · o custo de ordenar errado · configuração dependente de `c.env` · composição com `some`/`every`/`except`.
>
> **Não cobre:** declarar rota e formar resposta ([Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md)) · validator como middleware ([Hono - Validação e RPC](hono-validacao-e-rpc.md)) · disponibilidade de cada middleware por runtime ([Hono](hono.md) § 3).

Entrada: [Hono](hono.md) · Base normativa: [Hono](hono.md) § 2 e § 6

---

## 1. Conceito: o `await next()` é a fronteira entre entrada e saída

A doc descreve o modelo em uma frase: *"'Middleware' is executed before and after the Handler and handles the `Request` and `Response`. It's like an onion structure."* A consequência operacional é mais específica do que "roda antes e depois": **um único `await next()` divide o corpo do middleware em duas fases**.

```ts
app.use(async (c, next) => {
  // FASE DE ENTRADA — roda na ordem de registro.
  // Aqui existe o Request. Não existe Response ainda: c.res é indefinido.
  const inicio = performance.now()

  await next()

  // FASE DE SAÍDA — roda na ordem INVERSA de registro.
  // Aqui existe c.res, e c.error se o handler lançou.
  c.res.headers.set('X-Response-Time', `${performance.now() - inicio}`)
})
```

Com três middlewares registrados, a ordem verificada é:

```
middleware 1 start
  middleware 2 start
    middleware 3 start
      handler
    middleware 3 end
  middleware 2 end
middleware 1 end
```

**Esquecer o `await` é a falha silenciosa mais comum.** `next()` devolve uma Promise. Sem `await`, o código depois dele roda **imediatamente**, antes de o handler ter produzido resposta:

```ts
// ❌ compila, não lança, e o header nunca chega ao cliente
app.use(async (c, next) => {
  const inicio = Date.now()
  next()                                   // sem await
  c.res.headers.set('X-Duration', `${Date.now() - inicio}`)
  // c.res ainda é a resposta anterior (ou indefinida): a duração medida é ~0
})
```

Não há erro de tipo — o retorno de `next()` é descartável. Não há exceção — a Promise resolve depois, sozinha. O sintoma é um header que às vezes aparece com valor errado e às vezes não aparece. Em middleware de log, é log de resposta que registra o status errado; em middleware de cache, é escrita de cache antes de o conteúdo existir.

**Corolário: nem toda lógica de middleware é "antes".** A pergunta a fazer ao escrever um middleware é *em qual fase isso pertence* — e a resposta define o lado do `await next()`. Auth, rate limit, `bodyLimit`, CORS preflight: entrada. Header de resposta, compressão, ETag, log de status, métrica de duração: saída.

**Uma exceção, e só uma.** Delegar a um middleware interno com `return mw(c, next)` (o wrapper de configuração dependente de `c.env` da § 7) não chama `next()` — passa `next` adiante, e quem o chama é o middleware interno. É a forma documentada, e é a única linha legítima em que `next` aparece sem `await`.

| ID | Regra |
| --- | --- |
| `HONO-MW-01` | Toda chamada a `next()` no corpo do middleware **MUST** ser `await`ed — a única forma legítima sem `await` é delegar com `return mw(c, next)`, que não chama `next()` e sim o repassa. |
| `HONO-MW-02` | Lógica que depende da resposta (header, log de status, métrica, ETag) **MUST** ficar **depois** do `await next()`. |

---

## 2. Assinatura: as saídas legítimas

A doc define handler e middleware pelo que devolvem:

> "Handler - should return `Response` object. Only one handler will be called.
> Middleware - should `await next()` and return nothing to call the next Middleware, **or** return a `Response` to early-exit."

São exatamente duas saídas válidas, e não há uma terceira:

```ts
// A. Deixa passar. Não retorna nada.
const requestLog = createMiddleware(async (c, next) => {
  await next()
  console.log(c.req.method, c.req.path, c.res.status)
})

// B. Curto-circuita. Retorna Response e o handler NÃO roda.
const somenteInterno = createMiddleware(async (c, next) => {
  if (!c.req.header('x-internal-token')) {
    return c.json({ error: 'forbidden' }, 403)
  }
  await next()
})
```

Middleware que não chama `next()` **nem** devolve `Response` pendura o request. Middleware que chama `next()` **e** devolve uma `Response` própria sobrescreve o trabalho do handler — às vezes é a intenção (ver `c.res = new Response(...)` na fase de saída), mas nunca por acidente.

**Há uma terceira saída, e ela é legítima: `throw`.** Um `throw new HTTPException(401, ...)` não pendura nada — Hono captura, `app.onError` decide, e a resposta sai. É o que o middleware de autenticação da § 4 faz. A ressalva de contrato é outra: o que sai por `app.onError` **não entra na inferência do cliente RPC** ([Hono - Validação e RPC](hono-validacao-e-rpc.md) `HONO-RPC-09`), então erro que a tela precisa discriminar por status volta a ser `return c.json(corpo, status)` — `HONO-CORE-13`. E a quarta forma — delegar com `return mw(c, next)` — é a da § 7: quem chama `next()` é o middleware interno.

**`next()` nunca lança.** Este é o ponto que a doc explicita e que contraria o hábito de Express:

> "if the handler or any middleware throws, hono will catch it and either pass it to your `app.onError()` callback or automatically convert it to a 500 response before returning it up the chain of middleware. This means that `next()` will never throw, so there is no need to wrap it in a try/catch/finally."

Portanto: `try { await next() } catch (e) { ... }` não pega nada, e o `finally` é redundante — a fase de saída já é o `finally`. Para reagir ao erro do handler, leia `c.error` depois do `await next()`:

```ts
const relatorDeErro = createMiddleware(async (c, next) => {
  await next()
  if (c.error) {
    reportar(c.error, { rota: routePath(c), requestId: c.get('requestId') })
  }
})
```

| ID | Regra |
| --- | --- |
| `HONO-MW-03` | Middleware **MUST** terminar por `await next()`, por `return` de uma `Response`, por `throw` de `HTTPException` ou por `return mw(c, next)` — sair sem nenhuma das quatro **NEVER** acontece, porque pendura o request. |
| `HONO-MW-04` | `next()` **NEVER** é envolvido em `try/catch` para tratar erro do handler — Hono já captura; leia `c.error` após o `await next()` ou use `app.onError`. |

---

## 3. Escopo: global, por path, por rota

Três formas de registro, com semânticas diferentes:

```ts
app.use(logger())                              // todo método, toda rota
app.use('/api/*', cors())                      // por prefixo de path
app.post('/api/upload', bodyLimit({ maxSize: 5 * 1024 * 1024 }), handler)  // por rota
```

A terceira forma é a única que fica **dentro do encadeamento** e portanto não ameaça a inferência do tipo (ver [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 1) — mas também é a única que não pode ser esquecida numa rota nova. O critério:

| Escopo | Use para | Risco |
| --- | --- | --- |
| Global (`app.use(mw)`) | log, request id, secure headers, CSRF, timing | custo pago por rotas que não precisam (health check, static) |
| Por path (`app.use('/admin/*', mw)`) | auth de área, CORS de API, cache de leitura | rota nova fora do prefixo nasce desprotegida |
| Por rota (no encadeamento) | `bodyLimit` de upload, `timeout` de rota lenta, auth de exceção | esquecer numa rota nova é invisível |

**Ordem de registro é ordem de execução, e middleware registrado depois do handler não intercepta.** A doc: *"If you have the middleware that you want to execute, write the code above the handler."* Não é preferência de organização de arquivo — é a diferença entre o middleware rodar e não rodar.

| ID | Regra |
| --- | --- |
| `HONO-MW-05` | Middleware **MUST** ser registrado antes do handler que ele afeta — registro posterior não intercepta. |

---

## 4. `createMiddleware`: o middleware tipado que popula `c.var`

Middleware escrito inline dentro de `app.use()` funciona, mas *"can limit its reusability"*. Ao extrair para outro arquivo, uma função solta perde os tipos de `c` e `next`. `createMiddleware` de `hono/factory` existe exatamente para isso — e vai além: é como se declara **o que o middleware acrescenta ao contexto**.

```ts
import { createMiddleware } from 'hono/factory'
import { HTTPException } from 'hono/http-exception'

type Usuario = { id: string; papel: 'admin' | 'operador' }

export const autenticacao = createMiddleware<{
  Bindings: { JWT_SECRET: string }
  Variables: { usuario: Usuario }
}>(async (c, next) => {
  const header = c.req.header('Authorization')
  if (!header?.startsWith('Bearer ')) {
    throw new HTTPException(401, { message: 'token ausente' })
  }
  c.set('usuario', await verificar(header.slice(7), c.env.JWT_SECRET))
  await next()
})
```

O generic `Variables` é o que faz `c.var.usuario` chegar tipado no handler. Sem ele, `c.set('usuario', ...)` é aceito e `c.get('usuario')` volta sem tipo útil.

**Middleware parametrizado é uma função que devolve um middleware:**

```ts
const exigePapel = (papel: Usuario['papel']) =>
  createMiddleware<{ Variables: { usuario: Usuario } }>(async (c, next) => {
    if (c.var.usuario.papel !== papel) {
      return c.json({ error: 'permissão insuficiente' as const }, 403)
    }
    await next()
  })

app.get('/admin/relatorio', autenticacao, exigePapel('admin'), (c) => c.json({ ok: true }, 200))
```

**Tipos se acumulam ao encadear `.use()`.** A doc: *"each `.use()` call returns a new Hono instance with the merged type, so the type grows as middleware is chained. This eliminates the need to manually declare a combined `Env` type upfront."*

```ts
const app = new Hono()
  .use(autenticacao)
  .use(conexaoDeBanco)
  .get('/pedidos', (c) => {
    c.var.usuario   // tipado pelo primeiro middleware
    c.var.db        // tipado pelo segundo
    return c.json({ pedidos: [] }, 200)
  })
```

**`createFactory` evita declarar o `Env` duas vezes.** Sem ele, o mesmo tipo aparece em `new Hono<Env>()` e em `createMiddleware<Env>()`. Com `createFactory<Env>()`, `factory.createApp()` e `factory.createMiddleware()` já vêm tipados — e a opção `initApp` permite registrar middleware de base (conexão de banco, por exemplo) uma vez, para todo app criado pela factory.

| ID | Regra |
| --- | --- |
| `HONO-MW-06` | Middleware reutilizável **MUST** ser criado com `createMiddleware()` ou `factory.createMiddleware()` — função solta perde os tipos de `c` e `next`. |
| `HONO-MW-07` | Middleware que grava em `c.set` **MUST** declarar a chave no generic `Variables` do próprio middleware. |

---

## 5. Os built-ins que importam em produção

Built-in significa **sem dependência externa**: vêm no pacote `hono`, em subcaminhos. Nomes e defaults verificados na doc oficial.

| Middleware | Import | Configuração que decide |
| --- | --- | --- |
| CORS | `import { cors } from 'hono/cors'` | `origin` default é **`*`**. `allowMethods` default `['GET','HEAD','PUT','POST','DELETE','PATCH','QUERY']`, `allowHeaders` e `exposeHeaders` default `[]`. `credentials`, `maxAge` |
| Logger | `import { logger } from 'hono/logger'` | aceita `PrintFunc` própria; `NO_COLOR` desliga cor (Workers não tem `process.env` e já sai em texto puro) |
| JWT | `import { jwt } from 'hono/jwt'`, tipo `JwtVariables` | `secret` e `alg` **obrigatórios**. `alg` ∈ HS/RS/PS/ES 256‑512 e `EdDSA`. `cookie`, `headerName`, `realm`, `verification: { iss, aud, nbf, iat, exp }`. Payload em `c.get('jwtPayload')` |
| Bearer | `import { bearerAuth } from 'hono/bearer-auth'` | `token: string \| string[]` obrigatório, ou `verifyToken`. `prefix` default `"Bearer"`, `headerName` default `Authorization` |
| Basic | `import { basicAuth } from 'hono/basic-auth'` | usuário/senha; só para área administrativa interna |
| Secure Headers | `import { secureHeaders } from 'hono/secure-headers'` | remove `X-Powered-By`; liga HSTS, `X-Content-Type-Options`, `X-Frame-Options: SAMEORIGIN`, COOP/CORP, `Referrer-Policy: no-referrer`. **CSP não vem por default** — `contentSecurityPolicy` é "No Setting". `crossOriginEmbedderPolicy` vem **desligado** |
| CSRF | `import { csrf } from 'hono/csrf'` | valida `Origin` **ou** `Sec-Fetch-Site`; default aceita só mesma origem / `same-origin`. Só age em método inseguro com content-type de formulário HTML |
| Body Limit | `import { bodyLimit } from 'hono/body-limit'` | `maxSize` default `100 * 1024`. Usa `Content-Length` se houver; senão lê o stream. Em Bun, valor acima de 128 MiB exige subir `maxRequestBodySize` no `Bun.serve` |
| Compress | `import { compress } from 'hono/compress'` | `threshold` default 1024 bytes; `encoding` `'gzip' \| 'deflate'`. **Desnecessário em Cloudflare Workers e Deno Deploy** (compressão automática) |
| Cache | `import { cache } from 'hono/cache'` | `cacheName` obrigatório. `wait` default `false` — **`true` obrigatório em Deno**. `cacheableStatusCodes` default `[200]`. Só Workers com domínio custom e Deno 1.26+ |
| ETag | `import { etag } from 'hono/etag'` | `weak` default `false`; `retainedHeaders` com `RETAINED_304_HEADERS` |
| Request ID | `import { requestId } from 'hono/request-id'`, tipo `RequestIdVariables` | `headerName` default `X-Request-Id` (aceita valor de entrada), `limitLength` 255, `generator` default `crypto.randomUUID()` |
| Timing | `import { timing, startTime, endTime, setMetric, wrapTime } from 'hono/timing'`, tipo `TimingVariables` | header `Server-Timing`. `enabled` aceita função de `c`. Impreciso em Workers |
| Timeout | `import { timeout } from 'hono/timeout'` | duração em ms + exceção customizada opcional. **Não funciona com stream** |
| Combine | `import { some, every, except } from 'hono/combine'` | compõe middlewares — ver § 7 |
| Context Storage | `import { contextStorage, getContext } from 'hono/context-storage'` | exige `AsyncLocalStorage`; em Workers, flag `nodejs_compat`/`nodejs_als` |
| Method Not Allowed | `import { methodNotAllowed } from 'hono/method-not-allowed'` | sem ele, método não suportado em rota existente devolve **404**, não 405 |

**Combinação mínima para uma API pública** (a ordem importa — ver § 6):

```ts
import { Hono } from 'hono'
import { requestId } from 'hono/request-id'
import { logger } from 'hono/logger'
import { secureHeaders } from 'hono/secure-headers'
import { cors } from 'hono/cors'
import { bodyLimit } from 'hono/body-limit'

const app = new Hono()
  .use(requestId())          // primeiro: todo log abaixo carrega o id
  .use(logger())
  .use(secureHeaders())
  .use('/api/*', cors({ origin: ['https://app.exemplo.com'], credentials: true }))
  .use('/api/*', bodyLimit({ maxSize: 1024 * 1024 }))
```

`requestId` antes de `logger` é o que permite correlacionar entrada e saída da mesma requisição E `logger()` da caixa imprime uma linha por request: útil em desenvolvimento, insuficiente para produção estruturada e fácil de virar ruído —.

**CORS não é configuração de conveniência, e não é só de produção.** SPA React + API Hono é **origem cruzada em desenvolvimento** — o Vite serve o frontend em `localhost:5173` e o app Hono responde em `localhost:3000`. Sem `cors()`, a primeira chamada do `hc` falha no preflight, e o sintoma no console (*"blocked by CORS policy"*) não menciona Hono. O default `origin: '*'` é permissivo e, combinado com `credentials: true` — que é o que se usa quando a sessão é cookie (`HONO-CORE-14`) —, é a configuração que os navegadores **recusam**: a especificação proíbe curinga com credenciais.

```ts
const origens = {
  development: ['http://localhost:5173'],
  production: ['https://app.exemplo.com'],
}[env(c).NODE_ENV ?? 'development']

app.use('/api/*', cors({ origin: origens, credentials: true }))
```

`origin` aceita `string`, `string[]` ou `(origin, c) => string`; `allowMethods` também aceita função de `(origin, c)`. E ao rodar Hono sob Vite, a doc pede `server.cors: false` no `vite.config.ts` para o CORS embutido do Vite não conflitar com o middleware..

**JWT: `secret` é segredo de inicialização.** `jwt({ secret: c.env.JWT_SECRET })` exige o wrapper da § 6, e o segredo vem do ambiente, não do código Para chave assimétrica e rotação, o caminho é JWKS; Hono tem um middleware JWK dedicado, **não verificado nesta doc**. Autorização — quem pode o quê — não é o middleware de JWT: ele só prova identidade..

| ID | Regra |
| --- | --- |
| `HONO-MW-08` | `cors()` **MUST** declarar `origin` explicitamente em API exposta a browser — o default é `*`. |
| `HONO-MW-09` | Middleware built-in **MUST** ser importado do seu subcaminho exato (`hono/cors`, `hono/jwt`, …); nenhum deles é exportado por `hono`. |

---

## 6. O custo de ordenar errado

Ordem errada raramente quebra: encarece, ou abre buraco. Quatro casos concretos:

**Auth depois de trabalho caro.** Um request sem token válido deveria custar quase nada. Se o parse de body, a hidratação de sessão ou uma consulta de cache rodam antes da autenticação, o servidor paga o custo integral de cada request não autorizado — e isso é exatamente a superfície que um atacante escolhe. `bodyLimit` tem a mesma lógica: limitar o tamanho depois de já ter lido o corpo não limita nada.

**Log antes do request id.** Inverter os dois produz linhas de log sem correlação, e a falta só aparece durante um incidente — quando já não dá para reproduzir. `requestId()` grava em `c.var.requestId` (tipo `RequestIdVariables`) e aceita o valor que já vier no header `X-Request-Id`, o que é o que permite seguir o mesmo id através de serviços; `logger()` registrado antes dele emite a linha de entrada sem id nenhum..

**Label de métrica com o path concreto.** `c.req.path` é `/pedidos/7f3a…` — um valor por pedido. Usado como label de métrica ou nome de span, cria uma série temporal por id. `routePath(c)` de `hono/route` devolve o **padrão registrado** (`/pedidos/:id`), que é uma série só:

```ts
import { routePath } from 'hono/route'

const metricas = createMiddleware(async (c, next) => {
  const inicio = performance.now()
  await next()
  // ✅ label estável: '/pedidos/:id'    ❌ c.req.path: '/pedidos/7f3a…'
  observar(routePath(c), c.req.method, c.res.status, performance.now() - inicio)
})
```

`routePath(c)` aceita um índice opcional (`routePath(c, 0)` = primeira rota casada, `routePath(c, -1)` = última), útil quando há middleware curinga no caminho..

**Middlewares que escrevem o mesmo header.** A doc avisa em `secureHeaders`: *"Please be cautious about the order of specification when dealing with middleware that manipulates the same header."* O último a escrever na fase de saída vence — e a fase de saída é a **inversa** do registro. Se dois middlewares disputam `Cache-Control` ou `X-Powered-By`, o vencedor é o registrado **primeiro**.

**Curinga registrado antes.** Um `app.use('*', ...)` não é problema, mas um `app.get('*', handler)` antes das rotas reais captura tudo — ver [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 3.

Ordem de referência para uma API:

```
requestId → logger → secureHeaders → cors → csrf → bodyLimit → auth → timeout → rotas
```

| ID | Regra |
| --- | --- |
| `HONO-MW-10` | Autenticação e `bodyLimit` **MUST** ser registrados antes de qualquer middleware ou handler que faça trabalho caro. |
| `HONO-MW-11` | Middlewares que escrevem o mesmo header de resposta **MUST** ter ordem decidida explicitamente — na fase de saída, quem registrou primeiro escreve por último. |
| `HONO-MW-12` | `requestId()` **MUST** ser registrado antes de `logger()` e de qualquer middleware que emita log — registrado depois, a linha de entrada sai sem id e as linhas do mesmo request não correlacionam. |
| `HONO-MW-13` | Label de rota em métrica, span ou log estruturado **MUST** vir de `routePath(c)` (`hono/route`); `c.req.path` **NEVER** é usado como label — é o path concreto, e cria uma série por valor de param. |

---

## 7. Configuração que depende de `c.env`, e composição

Middlewares built-in são **funções que devolvem middleware**, e a chamada acontece no momento do registro — antes de existir qualquer `Context`. Configuração que depende de `c.env` (o caso normal em Cloudflare Workers, onde não há `process.env`) exige um wrapper:

```ts
app.use('*', async (c, next) => {
  const middleware = cors({ origin: c.env.CORS_ORIGIN })
  return middleware(c, next)      // note: `return`, não `await next()`
})
```

O mesmo padrão vale para `jwt({ secret: c.env.JWT_SECRET })`. É a forma documentada, e o `return` é obrigatório — o middleware interno é quem chama `next()`.

**Composição condicional com `hono/combine`:**

| Função | Semântica |
| --- | --- |
| `some(a, b)` | roda `a`; se passar, **não** roda `b`. "Token válido dispensa rate limit" |
| `every(a, b)` | roda todos; para no primeiro que falhar. "Precisa de IP permitido **e** token" |
| `except(alvo, mw)` | roda `mw` exceto quando o path casa `alvo` (string, função ou array). "Auth em tudo, menos em `/api/public/*`" |

```ts
import { some, every, except } from 'hono/combine'

app.use('/api/*', except('/api/public/*', autenticacao))
app.use('/api/*', some(bearerAuth({ token }), rateLimit({ limit: 100 })))
```

`except` é preferível a repetir `app.use` em cada prefixo: a exceção fica declarada num lugar só, em vez de espalhada por vários registros que alguém vai esquecer de atualizar.

**Terceiros vivem em `@hono/*`.** Ao contrário dos built-ins, dependem de bibliotecas externas. Os que tocam este stack: `@hono/zod-validator` e `@hono/standard-validator` (ver [Hono - Validação e RPC](hono-validacao-e-rpc.md)), `@hono/otel` para OpenTelemetry, `@hono/sentry`, `@hono/prometheus`, `@hono/oauth-providers`, `@hono/clerk-auth`, `@hono/zod-openapi`. A lista completa está em [Third-party Middleware](https://hono.dev/docs/middleware/third-party); **as opções de cada um não foram verificadas nesta doc** — consulte o pacote antes de escrever configuração.

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `next()` sem `await` | a fase de saída roda antes de a resposta existir; header, log e métrica ficam errados ou somem. Não há erro de tipo nem exceção | `await next()` sempre — `HONO-MW-01` |
| `try { await next() } catch (e) { ... }` | `next()` nunca lança: Hono já capturou e converteu o erro. O `catch` é código morto que parece defesa | ler `c.error` depois do `await next()`, ou tratar em `app.onError` — `HONO-MW-04` |
| Middleware registrado depois do handler | não intercepta nada; a rota responde sem passar por ele | registrar acima da rota — `HONO-MW-05` |
| Auth depois de parse de body ou de consulta cara | o servidor paga o custo integral de todo request que vai terminar em 401 | auth e `bodyLimit` primeiro — `HONO-MW-10` |
| Middleware extraído para função solta, sem `createMiddleware` | `c` e `next` chegam sem tipo; `c.var` do middleware não aparece no handler | `createMiddleware<{ Variables }>()` — `HONO-MW-06` / `HONO-MW-07` |
| `cors()` sem `origin` em API pública | o default é `*`; com `credentials: true` o navegador recusa a resposta | `origin` explícito por ambiente — `HONO-MW-08` |
| `cors({ origin: c.env.CORS_ORIGIN })` direto em `app.use` | `c` não existe no momento do registro | wrapper `(c, next) => cors({...})(c, next)` — § 7 |
| `cors()` só em produção, porque "em dev é tudo localhost" | portas diferentes já são origens diferentes: a SPA do Vite não fala com a API sem CORS | origem por ambiente, dev incluído — `HONO-MW-08` / § 5 |
| `logger()` registrado antes de `requestId()` | a linha de entrada sai sem id; as duas pontas do mesmo request não correlacionam | `requestId()` primeiro — `HONO-MW-12` |
| `observar(c.req.path, ...)` como label de métrica | um label por valor de param; a série temporal explode e o painel fica inútil | `routePath(c)` de `hono/route` — `HONO-MW-13` |
| Setar header de resposta antes do `await next()` | o handler ainda vai construir `c.res`; o que foi setado pode ser sobrescrito | mover para depois do `await next()` — `HONO-MW-02` |
| Middleware que nem chama `next()` nem devolve `Response` | o request nunca termina | uma das duas saídas, sempre — `HONO-MW-03` |
| `compress()` em Cloudflare Workers | a plataforma já comprime; é trabalho duplicado | omitir nesses runtimes — [Hono](hono.md) § 3 |
| `cache()` em Deno sem `wait: true` | a escrita no cache não é aguardada e a entrada pode não existir | `wait: true` em Deno — § 5 |

---

## Checklist de revisão

- [ ] Todo `next()` tem `await`? → `HONO-MW-01`
- [ ] Toda lógica que depende de `c.res` está depois do `await next()`? → `HONO-MW-02`
- [ ] Todo middleware ou chama `next()` ou devolve `Response`? → `HONO-MW-03`
- [ ] Nenhum `try/catch` em volta de `next()`? → `HONO-MW-04`
- [ ] Todo middleware está registrado antes das rotas que afeta? → `HONO-MW-05`
- [ ] Middleware reutilizável usa `createMiddleware`? → `HONO-MW-06`
- [ ] Toda chave de `c.set` está declarada em `Variables`? → `HONO-MW-07`
- [ ] `cors()` declara `origin` explícito? → `HONO-MW-08`
- [ ] Os imports vêm dos subcaminhos corretos de `hono/*`? → `HONO-MW-09`
- [ ] Auth e `bodyLimit` vêm antes do trabalho caro? → `HONO-MW-10`
- [ ] Há dois middlewares disputando o mesmo header sem ordem decidida? → `HONO-MW-11`
- [ ] `requestId()` vem antes de `logger()` e dos demais emissores de log? → `HONO-MW-12`
- [ ] Métricas e spans rotulam a rota com `routePath(c)`, não com `c.req.path`? → `HONO-MW-13`
- [ ] Middleware configurado a partir de `c.env` está dentro de um wrapper? → § 7

---

## Relacionados

- [Hono](hono.md) — hub, matriz de runtimes, árvores de decisão
- [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) · [Hono - Validação e RPC](hono-validacao-e-rpc.md)
- · ·
- · · ·
- ·
- · ·
- [Bun - HTTP e Servidor](bun-http-e-servidor.md)

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Middleware (guia)](https://hono.dev/docs/guides/middleware) · [Middleware (conceito)](https://hono.dev/docs/concepts/middleware) · [Factory Helper](https://hono.dev/docs/helpers/factory)
- Built-in: [CORS](https://hono.dev/docs/middleware/builtin/cors) · [JWT](https://hono.dev/docs/middleware/builtin/jwt) · [Bearer Auth](https://hono.dev/docs/middleware/builtin/bearer-auth) · [Basic Auth](https://hono.dev/docs/middleware/builtin/basic-auth) · [Logger](https://hono.dev/docs/middleware/builtin/logger) · [Secure Headers](https://hono.dev/docs/middleware/builtin/secure-headers) · [CSRF](https://hono.dev/docs/middleware/builtin/csrf) · [Body Limit](https://hono.dev/docs/middleware/builtin/body-limit) · [Compress](https://hono.dev/docs/middleware/builtin/compress) · [Cache](https://hono.dev/docs/middleware/builtin/cache) · [ETag](https://hono.dev/docs/middleware/builtin/etag) · [Request ID](https://hono.dev/docs/middleware/builtin/request-id) · [Timing](https://hono.dev/docs/middleware/builtin/timing) · [Timeout](https://hono.dev/docs/middleware/builtin/timeout) · [Combine](https://hono.dev/docs/middleware/builtin/combine) · [Context Storage](https://hono.dev/docs/middleware/builtin/context-storage) · [Method Not Allowed](https://hono.dev/docs/middleware/builtin/method-not-allowed)
- [Third-party Middleware](https://hono.dev/docs/middleware/third-party) · [Context](https://hono.dev/docs/api/context)

**O que a verificação contrariou:**

- **`next()` nunca lança.** A doc diz textualmente que não há necessidade de `try/catch/finally` em volta dele. O padrão de Express de envolver o `next` é código morto aqui — e pior, dá falsa sensação de tratamento.
- **`secureHeaders()` não liga CSP.** `contentSecurityPolicy` aparece na tabela como "No Setting"; e `crossOriginEmbedderPolicy` é o único default **False**. Assumir que o middleware entrega CSP é o engano mais provável.
- **Sem `methodNotAllowed`, método errado em rota existente devolve 404**, não 405. É comportamento default do framework, não bug.
- **O default de `allowMethods` do CORS inclui `QUERY`**, o método HTTP novo — que Hono também expõe como `app.query()`.
- **`bodyLimit` acima de 128 MiB não funciona sozinho em Bun**: `Bun.serve` corta antes com 413 e o `onError` do middleware **não** é chamado.
- **`cache()` em Deno exige `wait: true`**, e Deno *"does not respect headers"* — o `Cache-Control` que funciona em Cloudflare não invalida nada lá.
- **Tipos de `Variables` se acumulam ao encadear `.use()`**, sem precisar declarar um `Env` combinado antecipadamente. É recente o suficiente para não estar no hábito.
- **`@hono/node-ws` está deprecado** — WebSocket em Node agora vem de `@hono/node-server` com a opção `websocket`.
- **`origin` e `allowMethods` do CORS aceitam função.** `origin: (origin, c) => string` e `allowMethods: (origin, c) => string[]` — decisão por origem em runtime, sem wrapper. O que **exige** wrapper é configuração vinda de `c.env` (§ 7).
- **A doc pede `server.cors: false` no Vite.** Sem isso o CORS embutido do Vite conflita com o middleware, e o sintoma é um header que aparece duplicado ou com origem errada.
- **`routePath(c)` aceita índice.** `routePath(c, 0)` e `routePath(c, -1)` escolhem entre as rotas casadas, como `Array.prototype.at()` — relevante quando há `app.all('/api/*', ...)` no caminho.
- **A doc descreve o Route Helper como ferramenta de "debugging and middleware development"** — não afirma nada sobre cardinalidade de métrica. Que `routePath(c)` devolve o padrão registrado e `c.req.path` o path concreto é o que está verificado; a consequência para o label é inferência desta nota, não citação.
