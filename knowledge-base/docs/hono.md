---
titulo: Hono
Link: https://hono.dev/docs
tags:
 - hono
 - backend
 - agent-context
source: "Documentação oficial — https://hono.dev/docs"
verificado-em: 2026-08-15
---
# Hono — referência conduzida

> **O que esta nota é.** O ponto de entrada único para Hono neste vault: para mim ao consultar, e para agentes de código ao gerar ou revisar um servidor Hono. Não é um resumo linear da documentação — é um **roteador**. Ela decide o que carregar, oferece o modelo mental que faz o resto fazer sentido, e expõe regras citáveis que uma skill ou um code review pode referenciar por ID.
>
> **O que não é.** Não substitui a fonte. Quando houver divergência, [hono.dev/docs](https://hono.dev/docs) vence, e esta nota deve ser corrigida.

Inventário verificado diretamente em hono.dev em **2026-08-15**. Versão verificada: **hono 4.13.2** (`registry.npmjs.org/hono/latest`). Pacotes companheiros verificados: `@hono/zod-validator` 0.9.0, `@hono/node-server` 2.1.1.
Ver [Fontes consultadas](#fontes-consultadas).

---

## 1. Como usar esta doc

### Para um humano

Leia a seção 2 uma vez — as cinco afirmações explicam por que Hono é escrito de um jeito que parece estranho vindo de Express. Depois use a seção 4 como índice e a seção 5 quando estiver entre duas APIs. A seção 8 é a que importa para quem escreve o frontend.

### Para um agente de código

Carregue nesta ordem, parando assim que tiver o suficiente:

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (§ 2, § 5, § 6) | Sempre que a tarefa envolver Hono |
| 2 | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) | Sempre que for **declarar rota** ou ler/escrever no `Context` |
| 3 | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) | Quando houver auth, CORS, log, cache, timeout, ou qualquer coisa que rode antes/depois do handler |
| 4 | [Hono - Validação e RPC](hono-validacao-e-rpc.md) | Quando o input vier do request, ou quando o tipo tiver que chegar no frontend |
| 5 | Esta nota § 3 | Antes de escolher import, adaptador ou alvo de deploy |
| 6 | Esta nota § 8 + [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 6.1 | Quando a tarefa tocar o consumo pelo React — inclui a `queryFn` que precisa lançar (`HONO-RPC-13`) e o CORS do passo 3, porque SPA + API é origem cruzada já em dev |

**Regra de economia de contexto:** nunca carregue todos os satélites.

### Convenções e vocabulário

**Todos os exemplos são TypeScript.** Hono é escrito em TS e a maior parte do valor da ferramenta está na inferência — exemplos em JS perderiam o ponto.

Termos usados sem redefinição nos satélites:

| Termo | Significado nesta doc |
| --- | --- |
| **encadeamento** (chaining) | escrever `new Hono.get(...).post(...)` numa expressão só. Não é estilo: cada chamada devolve uma instância com um tipo **maior**, e é esse tipo acumulado que o cliente RPC consome |
| **handler** | função que recebe `c` e **retorna** uma `Response`. Só um handler roda por request |
| **middleware** | função que recebe `(c, next)`, faz `await next` e **não** retorna nada — ou retorna uma `Response` para curto-circuitar |
| **onion model** | o encadeamento de middlewares como camadas de cebola: tudo antes do `await next` roda na entrada, na ordem de registro; tudo depois roda na saída, na ordem inversa |
| **`Bindings`** | generic do app com os recursos injetados pelo runtime (env vars, KV, D1, R2, socket do Node). Lido em `c.env` |
| **`Variables`** | generic do app com o que middleware grava no request. Escrito com `c.set`, lido com `c.get` / `c.var` |
| **target de validação** | a parte do request que um validator inspeciona: `json`, `form`, `query`, `param`, `header`, `cookie` |
| **`AppType`** | o `typeof` da variável que recebeu a cadeia de rotas. É o contrato que `hc<AppType>` lê |
| **adaptador** | pacote ou subcaminho que liga o app a um runtime concreto (`hono/bun`, `@hono/node-server`, `hono/deno`) |
| **preset** | import alternativo de `Hono` que só troca o roteador (`hono`, `hono/quick`, `hono/tiny`) |
| **runtime key** | identificador do runtime em execução: `workerd`, `deno`, `bun`, `node`, `edge-light`, `fastly`, `other` |

---

## 2. Modelo mental

Cinco afirmações. Quase todo erro que um agente comete em Hono viola uma delas.

**1. Hono é uma camada fina sobre Web Standards, não um framework com runtime próprio.** O que entra no handler é um `Request` da Fetch API embrulhado por `HonoRequest`; o que sai é uma `Response`. A doc é explícita: *"Hono uses only Web Standards like Fetch."* Consequência prática: `return new Response('ok')` é código Hono válido, e qualquer coisa que funcione com `Request`/`Response` funciona aqui. É também **a razão** de o mesmo código rodar em Bun, Node, Deno, Workers e edge — não há um servidor Hono, há um `fetch(request) => Response` que cada runtime chama do seu jeito.

**2. O tipo do app é acumulativo, e quebrar o encadeamento quebra a inferência.** Cada `.get`/`.post` devolve uma instância com um tipo maior que o anterior. Escrever `const app = new Hono; app.get(...); app.post(...)` descarta esse tipo: `typeof app` fica sendo o app **vazio**. A doc registra isso como pré-condição do RPC e do `testClient`: *"all included methods must be chained, and the endpoint or app type must be inferred from a declared variable."* Este é o erro nº 1 em Hono, ele **não** gera erro de compilação no servidor, e só aparece do outro lado como `data: unknown` ou como um cliente sem autocomplete.

**3. Middleware é onion, e a fronteira é o `await next`.** Tudo antes do `await next` é fase de entrada e roda na ordem de registro; tudo depois é fase de saída e roda na ordem inversa. Um middleware que esquece o `await` continua compilando, continua "funcionando" no happy path, e perde silenciosamente toda a fase de saída — headers, medição de tempo, log de resposta. Ver [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md).

**4. `c` é o request inteiro, e o que ele te devolve é tipado pelo generic do app.** `c.env` vem de `Bindings`, `c.var`/`c.get` vêm de `Variables`, `c.req.valid(target)` vem do validator registrado naquela rota. Nada disso é mágica de runtime: se você não declarou o generic, o tipo é `any`-ish e o erro aparece só em produção. `c.set`/`c.get` valem **um request** — a doc é literal: *"They cannot be shared or persisted across different requests."*

**5. O roteador é uma escolha, não uma constante.** Hono tem cinco roteadores e três presets. O default (`SmartRouter` com `RegExpRouter` + `TrieRouter`) troca registro mais lento por match mais rápido — o que é certo em servidor de vida longa e errado em ambiente que reinicializa a cada request. Escolher o preset é uma decisão de deploy, tomada uma vez, no `import`. Ver § 5.

> **Onde isso difere do hábito de Express.** Não há `res.send`: o handler **retorna**. Não há `next(err)`: erro se lança, e `app.onError` decide. Não há "controller" separado sem custo: extrair o handler para `(c: Context) =>...` faz o path param perder a inferência — a própria doc desaconselha ([Best Practices](https://hono.dev/docs/guides/best-practices)).

---

## 3. Fronteiras de import e runtime

Metade dos erros de import em Hono nasce de dois enganos: procurar tudo em `hono` (os middlewares moram em subcaminhos) e assumir que o que existe em um runtime existe em todos.

### 3.1 De onde vem cada coisa

| Import | Contém | Observação |
| --- | --- | --- |
| `hono` | `Hono`, tipos `Context`, `MiddlewareHandler`, `TypedResponse`, `ValidationTargets` | o único import que existe em qualquer runtime |
| `hono/quick`, `hono/tiny` | a **mesma** classe `Hono`, com outro roteador | intercambiáveis com `hono` — só muda o preset |
| `hono/<middleware>` | **um** middleware built-in por subcaminho — `hono/cors`, `hono/jwt`, `hono/logger`, `hono/body-limit`, `hono/secure-headers`… (lista com defaults em [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5) | built-in = **sem dependência externa**. Nenhum é exportado por `hono` |
| `hono/factory` | `createFactory`, `createMiddleware` | middleware e handler tipados fora da linha de registro |
| `hono/validator` | `validator`, tipo `InferInput` | validator manual, sem biblioteca de schema |
| `hono/client` | `hc`, `parseResponse`, `DetailedError`; tipos `InferRequestType`, `InferResponseType`, `ApplyGlobalResponse`, `ClientRequestOptions`, `ClientResponse` | **roda no frontend**, não no servidor |
| `hono/testing` | `testClient` | cliente tipado sobre a instância do app, sem rede |
| `hono/http-exception` | `HTTPException` | erro com status e `getResponse` |
| `hono/adapter` | `env(c)`, `getRuntimeKey` | a forma portátil de ler env var |
| `hono/cookie` | `getCookie`, `setCookie`, `deleteCookie`, `getSignedCookie`, `setSignedCookie` | assinados são `async` (WebCrypto) |
| `hono/streaming` | `stream`, `streamText`, `streamSSE` | |
| `hono/route` | `routePath`, `matchedRoutes`, `baseRoutePath`, `basePath` | substitui `c.req.routePath` e `c.req.matchedRoutes`, **deprecados na v4.8.0** |
| `hono/request` | `cloneRawRequest` | clona o `Request` cru mesmo depois de o body ter sido consumido |
| `hono/router/*` | `RegExpRouter`, `TrieRouter`, `SmartRouter`, `LinearRouter`, `PatternRouter` | só quando se passa `router:` ao construtor |
| `hono/bun`, `hono/deno`, `hono/cloudflare-workers`, `hono/cloudflare-pages`, `hono/service-worker` | adaptadores: `serveStatic`, `getConnInfo`, `upgradeWebSocket` | **por runtime** — o nome é igual, o import é diferente |
| `@hono/node-server` | `serve`, `upgradeWebSocket`, tipo `HttpBindings`; `@hono/node-server/serve-static`, `@hono/node-server/conninfo` | pacote separado; Node não tem adaptador dentro de `hono` |
| `@hono/zod-validator` | `zValidator` | pacote separado, peer deps `zod ^3.25 \|\| ^4` e `hono >=4.11.2` |
| `@hono/standard-validator` | `sValidator` | qualquer biblioteca Standard Schema (Zod, Valibot, ArkType) |

### 3.2 Matriz de runtimes

O corpo da aplicação é o mesmo em todos. O que muda é o **entrypoint**, o adaptador e um punhado de middlewares.

| | Bun | Node.js | Cloudflare Workers | Deno |
| --- | --- | --- | --- | --- |
| Entrypoint | `export default app` ou `export default { port, fetch: app.fetch }` | `serve(app)` de `@hono/node-server` | `export default app` | `Deno.serve(app.fetch)` |
| Instalação | `bun add hono` | `npm i hono @hono/node-server` | `npm i hono` | sem instalação explícita |
| Porta default | 3000 | 3000 (`serve({ fetch, port })` para mudar) | 8787 no dev (wrangler) | 8000 |
| `c.env` é | `process.env` via `env(c)` | `HttpBindings` (`incoming`/`outgoing`) | os **bindings** do worker (KV, D1, R2, secrets) | `Deno.env` via `env(c)` |
| Arquivos estáticos | `serveStatic` de `hono/bun` | `serveStatic` de `@hono/node-server/serve-static` | feature *Static Assets* do wrangler, não middleware | `serveStatic` de `hono/deno` |
| `getConnInfo` | `hono/bun` | `@hono/node-server/conninfo` | `hono/cloudflare-workers` | `hono/deno` |
| WebSocket | `upgradeWebSocket` de `hono/bun` | `upgradeWebSocket` de `@hono/node-server` + `ws` com `{ noServer: true }` | `upgradeWebSocket` de `hono/cloudflare-workers` | `upgradeWebSocket` de `hono/deno` |
| Requisito de versão | — | Node ≥ 18.14.1 / 19.7 / 20.0 | — | — |

**O que não está disponível em toda parte:**

| Recurso | Restrição verificada |
| --- | --- |
| `compress` | *"On Cloudflare Workers and Deno Deploy, the response body will be compressed automatically, so there is no need to use this middleware."* |
| `cache` | só Cloudflare Workers **com domínio custom** e Deno 1.26+/Deno Deploy. Em Deno exige `wait: true`. Cloudflare respeita `Cache-Control`; Deno **não** |
| `contextStorage` | exige `AsyncLocalStorage`. Em Cloudflare, precisa da flag `nodejs_compat` ou `nodejs_als` no `wrangler.toml` |
| `requestId` | usa `crypto.randomUUID`. Em Node < 20 o `crypto` global não existe — `@hono/node-server` o define automaticamente; fora dele, passe `generator` |
| `timing` | em Cloudflare Workers as métricas podem ser imprecisas: *"timers only show the time of last I/O"* |
| `c.executionCtx` / `waitUntil` | Cloudflare Workers |
| `c.event` | só na sintaxe Service Worker, e a doc diz que **não é recomendada** |
| `bodyLimit` acima de 128 MiB | em Bun é preciso subir também `maxRequestBodySize` no `Bun.serve` — senão Bun corta em 413 antes de o middleware rodar |
| `streamText` no Wrangler | pode não funcionar; a doc sugere `c.header('Content-Encoding', 'Identity')` |
| `app.fire` | **deprecado** — use `fire` de `hono/service-worker` |

**Consequência de arquitetura.** Se o alvo é Bun (o caso deste vault — ver [Bun](bun.md) e [Bun - HTTP e Servidor](bun-http-e-servidor.md)), o app é um `export default` e nada mais: `Bun.serve` consome o `fetch` da instância. Trocar de runtime depois custa quatro linhas de entrypoint e a origem dos env vars — não os handlers.

---

## 4. Mapa da API

Superfície ativa da documentação oficial — o que se usa em código novo. A coluna **Satélite** diz o que carregar.

**Deliberadamente fora deste mapa:** renderização no servidor (`hono/jsx`, `jsxRenderer`, `c.render`/`c.setRenderer`, helpers `html` e `css`), geração estática (`hono/ssg`), `app.mount`, `app.fire`, Service Worker, os middlewares de nicho (`languageDetector`, `methodOverride`, `prettyJSON`, `ipRestriction`, `trailingSlash`, `accepts`, `proxy`, `jwk`, helper `dev`) e as plataformas de deploy que não uso (AWS Lambda, Lambda@Edge, Vercel, Netlify, Fastly, Azure, Alibaba, Google Cloud Run, Supabase, WASI). **Ausência aqui significa "não verificado nesta doc", não "não existe".**

**Cobertos só pela fronteira de runtime, não pela superfície de API:** `upgradeWebSocket` (WebSocket) e `getConnInfo` (`conninfo`). Os dois **existem** nesta doc — a § 3.2 diz de qual adaptador cada um vem, e `HONO-APP-08` legisla sobre isso. O que não foi verificado é a API deles: assinatura de handler de socket, formato de `ConnInfo`, opções. Escrever WebSocket em Hono exige abrir [WebSocket Helper](https://hono.dev/docs/helpers/websocket) antes.

### `Hono` — a instância

| API | Para que serve | Satélite |
| --- | --- | --- |
| `new Hono<{ Bindings, Variables }>` | criar o app com os tipos de runtime e de contexto | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `app.get/post/put/delete/patch/query` | registrar handler por método | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `app.all(path,...)` | qualquer método | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `app.on(method \| method[], path \| path[],...)` | método customizado, ou vários métodos/paths de uma vez | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `app.use([path,] middleware)` | registrar middleware global ou por path | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) |
| `app.route(path, subApp)` | montar sub-app | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `app.basePath(path)` | prefixar todas as rotas da instância | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `app.notFound(handler)` | resposta 404 customizada — **só é chamada do app de topo** | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `app.onError((err, c) =>...)` | erro não capturado. Handler de rota tem prioridade sobre o do pai | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `app.fetch(request, env, ctx)` | o entrypoint. É o que o runtime chama | § 3 |
| `app.request(path \| Request, init?, env?)` | disparar um request sem rede — base de teste | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `new Hono({ strict: false })` | tratar `/hello` e `/hello/` como a mesma rota (default `true`) | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `new Hono({ router })` | trocar o roteador | § 5 |
| `new Hono({ getPath })` | rotear por hostname ou por header | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 3 |

### `Context` (`c`)

| API | Para que serve | Satélite |
| --- | --- | --- |
| `c.req` | o `HonoRequest` | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 5 |
| `c.json(body, status?, headers?)` | resposta `application/json` — **a forma que o RPC entende** | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 6 |
| `c.text(str, status?, headers?)` | resposta `text/plain` | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 6 |
| `c.html(content)` | resposta `text/html` | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 6 |
| `c.body(data, status?, headers?)` | corpo cru; equivale a construir uma `Response` | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 6 |
| `c.header(name, value)` | header de resposta | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 6 |
| `c.status(code)` | status de resposta (default `200`) | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 6 |
| `c.redirect(url, status?)` | redirect (default `302`) | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 6 |
| `c.notFound` | a resposta 404 — **não é inferida pelo cliente RPC** | [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 5 |
| `c.res` | a `Response` que será devolvida; mutável **depois** do `await next` | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) |
| `c.set(k, v)` / `c.get(k)` / `c.var` | passar valor de middleware para handler, tipado por `Variables` | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) |
| `c.env` | bindings/env vars do runtime, tipados por `Bindings` | § 3 |
| `c.error` | o erro lançado pelo handler, legível no middleware após `await next` | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) |
| `c.executionCtx.waitUntil(p)` | trabalho em background — **Cloudflare Workers** | § 3 |

### `HonoRequest` (`c.req`)

| API | Para que serve | Satélite |
| --- | --- | --- |
| `c.req.param` / `param('id')` | path params, tipados a partir do padrão da rota | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `c.req.query` / `query('q')` | query string | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `c.req.queries('tags')` | query repetida → `string[]` | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `c.req.header('X-Foo')` | header. **Sem argumento, as chaves vêm minúsculas** | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `c.req.json` / `text` / `formData` / `parseBody` / `arrayBuffer` / `blob` | ler o body cru | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `c.req.valid(target)` | o dado **já validado** — a única leitura correta em rota com validator | [Hono - Validação e RPC](hono-validacao-e-rpc.md) |
| `c.req.path` / `url` / `method` / `raw` | metadados e o `Request` original | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |

### Roteadores e presets

| Preset | Composição | Trade-off |
| --- | --- | --- |
| `hono` (default) | `SmartRouter([RegExpRouter, TrieRouter])` | registro mais lento, match mais rápido |
| `hono/quick` | `SmartRouter([LinearRouter, TrieRouter])` | registro rápido — para app reinicializado a cada request |
| `hono/tiny` | `PatternRouter` | o menor: app só com ele fica **abaixo de 15 KB** (14,68 KiB, gzip 5,38 KiB) |

`RegExpRouter` compila todas as rotas em **uma** expressão regular e resolve em um match, mas *"doesn't support all routing patterns"* — por isso vem em `SmartRouter` junto do `TrieRouter`, que suporta todos; o `SmartRouter` escolhe o mais rápido no boot. Critério de escolha em § 5.

### Helpers e middlewares built-in

| Item | Para que serve | Satélite |
| --- | --- | --- |
| `createMiddleware` (`hono/factory`) | middleware tipado fora da linha de registro | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 4 |
| `createFactory` / `factory.createApp` / `initApp` (`hono/factory`) | declarar o `Env` uma vez e criar apps já tipados | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 4 |
| `factory.createHandlers(...)` (`hono/factory`) | **a única forma de mover o handler para outro arquivo sem perder a inferência de param** — `HONO-CORE-06` | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 4 |
| `env(c)` / `getRuntimeKey` (`hono/adapter`) | env var e detecção de runtime, portáveis | § 3 |
| `getCookie` / `setCookie` / `deleteCookie` (`hono/cookie`) | cookies não assinados | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 9 |
| `getSignedCookie` / `setSignedCookie` (`hono/cookie`) | cookie assinado com HMAC SHA-256 — **`async`** | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 9 |
| `generateCookie` / `generateSignedCookie` (`hono/cookie`) | montar a string do cookie sem escrevê-la na resposta | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 9 |
| `stream` / `streamText` / `streamSSE` (`hono/streaming`) | resposta incremental; erro no callback **não** passa por `app.onError` | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 6 |
| `HTTPException` (`hono/http-exception`) | erro com status e `getResponse` — **não chega tipado ao `hc`** | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 7 |
| `routePath` / `matchedRoutes` / `baseRoutePath` / `basePath` (`hono/route`) | padrão de rota casado — label de observabilidade | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 6 |
| `cloneRawRequest` (`hono/request`) | reler o `Request` cru depois de o body ter sido consumido | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 5 |
| `cors`, `csrf`, `secureHeaders`, `bodyLimit` | fronteira de browser e de tamanho | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5 |
| `jwt`, `bearerAuth`, `basicAuth` | identidade — não autorização | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5 |
| `logger`, `requestId`, `timing` | observabilidade | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5 |
| `cache`, `etag`, `compress` | resposta e frescor — os três com restrição por runtime (§ 3) | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5 |
| `timeout`, `methodNotAllowed` | corte de rota lenta; 405 em vez de 404 | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5 |
| `some` / `every` / `except` (`hono/combine`) | composição condicional de middleware | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 7 |
| `contextStorage` / `getContext` | `c` fora da cadeia de chamada — exige `AsyncLocalStorage` (§ 3) | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5 |
| `validator` (`hono/validator`), `zValidator` (`@hono/zod-validator`), `sValidator` (`@hono/standard-validator`) | validação na fronteira — **só de input; Hono não valida saída** | [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 2–4 |
| `hc`, `InferRequestType`, `InferResponseType`, `ApplyGlobalResponse` (`hono/client`) | cliente tipado end-to-end | [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 5–6 |
| `parseResponse` e `DetailedError` (`hono/client`) | parsear pelo Content-Type e **lançar** quando `!res.ok` — `HONO-RPC-13` | [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 6.1 |
| `$url` / `$path` (métodos do cliente `hc`) | URL ou path da rota; `$url` exige base absoluta — `HONO-RPC-12` | [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 5 |
| `testClient` (`hono/testing`) | o mesmo cliente tipado, sem rede — `HONO-CORE-15` | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 8 |

---

## 5. Árvores de decisão

Mapeiam **sintoma → API correta**. É aqui que código Hono gerado costuma errar.

### Como retorno esta resposta?

```
O consumidor é o cliente RPC (hc) ou o frontend tipado?
├── SIM → c.json(body, status) ← SEMPRE com status literal
│ └── É "não encontrado"?
│ ├── c.json({ error: 'not found' }, 404) ← recomendado
│ └── c.notFound só se você augmentou
│ `interface NotFoundResponse` (module augmentation)
│ senão o cliente recebe `unknown` (HONO-RPC-06)
└── NÃO
 ├── Texto puro (health check, robots.txt) → c.text
 ├── HTML → c.html
 ├── Bytes / Content-Type manual → c.body(data, status, headers)
 ├── Resposta longa ou incremental
 │ ├── SSE → streamSSE(c, cb)
 │ ├── texto em pedaços → streamText(c, cb)
 │ └── binário / pipe de ReadableStream → stream(c, cb)
 │ ⚠ erro dentro do callback NÃO passa por app.onError
 │ ⚠ timeout não funciona com stream — use stream.close
 └── Já tenho uma Response pronta (proxy, upstream) → return ela
```

> `c.body('x', 201, { 'X-Message': 'Hello!' })` é literalmente `new Response('x', { status: 201, headers: {...} })`. A doc mostra os dois lado a lado. Prefira `c.text`/`c.html` quando o conteúdo for texto ou HTML — a própria doc recomenda isso sobre `c.body`.

### Onde ponho esta lógica?

```
Ela precisa rodar em TODAS as rotas (log, request id, secure headers, CORS)?
├── SIM → app.use(mw) no topo, antes de qualquer rota
│ (middleware registrado depois do handler NÃO intercepta — HONO-MW-05)
└── NÃO
 └── Ela protege ou prepara um SUBCONJUNTO de rotas?
 ├── SIM, definido por prefixo (/api/*, /admin/*)
 │ → app.use('/admin/*', mw)
 ├── SIM, mas só nesta rota
 │ → app.post('/upload', bodyLimit({...}), handler)
 │ (fica no encadeamento; não quebra o tipo)
 └── NÃO — é regra de negócio
 └── Ela produz um valor que o handler precisa?
 ├── SIM → middleware que faz c.set(...)
 │ MUST ser criado com createMiddleware<{ Variables }>
 │ para o c.var chegar tipado no handler (HONO-MW-06/07)
 └── NÃO → é código de domínio. Não vire middleware:
 chame uma função pura dentro do handler
```

> **A ordem tem custo.** Auth registrada depois de um middleware caro (parse de body grande, consulta a cache, hidratação de sessão) faz o servidor pagar esse custo para requests que vão terminar em 401. Auth e `bodyLimit` vêm cedo — `HONO-MW-10`.

### Meu tipo não chega no cliente RPC. O que checar?

Na ordem. Cada passo é mais comum que o seguinte.

```
1. A cadeia está contínua?
 const app = new Hono; app.get(...) ❌ tipo é o app VAZIO
 const app = new Hono.get(...).post(...) ✅
 → HONO-CORE-01. Vale também para app.route: o tipo exportado
 tem de vir da variável que recebeu a CADEIA de.route

2. O tipo exportado é o da variável certa?
 export type AppType = typeof routes ← a que recebeu a cadeia
 (exportar `typeof app` quando a cadeia foi para `routes` devolve vazio)

3. A rota tem validator no target que o cliente envia?
 Sem validator, não há tipo de INPUT. O cliente aceita qualquer coisa
 ou não aceita nada. → zValidator('json' | 'query' | 'param' |...)

4. O handler devolve c.json com status literal?
 c.json({...}) → tipo existe, mas sem discriminação por status
 c.json({...}, 200) → InferResponseType<..., 200> funciona
 c.notFound → data vira `unknown` (HONO-RPC-06)
 return new Response(...) → sem tipo

5. As versões de `hono` batem entre servidor e cliente?
 "Type instantiation is excessively deep and possibly infinite"
 é o sintoma canônico de versão divergente

6. `"strict": true` está nos DOIS tsconfig?
 A doc registra isso como requisito para RPC em monorepo

7. Só então: o cliente aponta para o base path certo?
 hc<AppType>('/api') quando o app foi montado com app.route('/api', api)
```

### Qual roteador escolher?

```
Onde este app roda?
├── Servidor de vida longa (Bun, Node, Deno, container) → `hono`
├── Isolate que persiste entre requests (Cloudflare Workers,
│ Deno Deploy) → `hono`
├── Rotas registradas no BUILD (Fastly Compute) → `hono`
├── Processo reinicializado a cada request → `hono/quick`
└── Orçamento de bundle apertado (<15 KB) → `hono/tiny`
```

A doc é direta: `hono` é *"highly recommended for most use cases"*. Só saia dele com um motivo nomeável — cold start medido, ou limite de tamanho. Trocar de preset é trocar o `import`; nada mais no app muda.

---

## 6. Regras normativas

Regras citáveis por ID. Uma skill, um prompt de revisão ou um comentário de PR pode referenciar `HONO-APP-01` sem repetir o texto. O corpo completo de cada família vive no satélite correspondente; aqui ficam as invioláveis do app.

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.

### `HONO-APP-*` — a aplicação e o runtime

| ID | Regra |
| --- | --- |
| `HONO-APP-01` | O tipo consumido por `hc` ou `testClient` **MUST** ser o `typeof` da variável que recebeu a cadeia completa de rotas. |
| `HONO-APP-02` | `Bindings` e `Variables` **MUST** ser declarados no generic de `new Hono<...>` ou de `createFactory<...>` — `c.env` e `c.var` **NEVER** são acessados sem tipo. |
| `HONO-APP-03` | Código de aplicação **NEVER** lê `process.env`, `Bun.env` ou `Deno.env` diretamente; usa `env(c)` de `hono/adapter` ou `c.env`. |
| `HONO-APP-04` | `app.notFound` e o `app.onError` de fallback **MUST** ser registrados no app de topo — `notFound` só é chamado a partir dele. |
| `HONO-APP-05` | Servidor e cliente **MUST** usar a mesma versão de `hono` quando o `AppType` cruza a fronteira de pacote. |
| `HONO-APP-06` | Rota `HEAD` dedicada (`app.head`, `app.on('HEAD',...)`) **NEVER** é registrada — Hono converte HEAD em GET antes do match e o handler nunca roda. |
| `HONO-APP-07` | O preset **MUST** ser `hono` em servidor de vida longa; `hono/quick` e `hono/tiny` exigem justificativa nomeada (reinicialização por request, limite de bundle). |
| `HONO-APP-08` | Middleware ou helper específico de runtime (`serveStatic`, `getConnInfo`, `upgradeWebSocket`) **MUST** ser importado do adaptador daquele runtime, nunca de `hono`. |

### 6.1 Regras críticas dos satélites

As famílias completas vivem nos satélites, mas **estas precisam viajar com o caminho mínimo** — são as que mais aparecem em código gerado e não podem depender de o agente ter aberto o satélite certo.

> **O satélite é canônico.** As linhas abaixo reproduzem o texto do satélite **verbatim**, e não uma paráfrase. Em qualquer divergência entre esta tabela e o satélite, o satélite vence e esta tabela é o bug — a § 7 manda citar por ID sem parafrasear, e duas cópias divergentes de uma regra normativa inviabilizam isso.

| ID | Regra | Satélite |
| --- | --- | --- |
| `HONO-CORE-01` | Rotas **MUST** ser registradas em cadeia contínua a partir de `new Hono` quando o tipo do app for consumido por `hc` ou `testClient`, e o tipo exportado **MUST** vir da variável que recebeu a cadeia. | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `HONO-CORE-03` | Rota específica **MUST** ser registrada antes do curinga que a cobriria — o primeiro match responde e a execução para. | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `HONO-CORE-06` | Handler **NEVER** é extraído para uma função anotada como `(c: Context) =>...` — o path param perde a inferência; use `factory.createHandlers`. | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `HONO-CORE-07` | `app.route(base, sub)` **MUST** ser chamado depois de o sub-app já ter registrado suas rotas. | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `HONO-CORE-09` | Resposta destinada ao cliente RPC **MUST** declarar o status literal em `c.json(body, status)`. | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `HONO-CORE-10` | `app.onError` **MUST** distinguir `HTTPException` (devolver `err.getResponse`) de erro inesperado (logar e devolver 500 genérico sem detalhe interno). | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `HONO-CORE-11` | Rota `HEAD` dedicada **NEVER** é registrada — HEAD vira GET antes do match; use middleware com `c.req.method`. | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `HONO-CORE-13` | Erro de domínio que o cliente RPC precisa discriminar por status **MUST** ser `return c.json(corpo, status)` no handler — `throw new HTTPException` sai por `app.onError` e **NEVER** chega tipado ao `hc`. | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `HONO-CORE-14` | Cookie de sessão ou de autenticação **MUST** ser escrito com `setSignedCookie` e as opções `httpOnly: true` e `secure: true`; `setCookie` cru **NEVER** carrega identidade. | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) |
| `HONO-MW-01` | Toda chamada a `next` no corpo do middleware **MUST** ser `await`ed — a única forma legítima sem `await` é delegar com `return mw(c, next)`, que não chama `next` e sim o repassa. | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) |
| `HONO-MW-04` | `next` **NEVER** é envolvido em `try/catch` para tratar erro do handler — Hono já captura; leia `c.error` após o `await next` ou use `app.onError`. | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) |
| `HONO-MW-05` | Middleware **MUST** ser registrado antes do handler que ele afeta — registro posterior não intercepta. | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) |
| `HONO-MW-08` | `cors` **MUST** declarar `origin` explicitamente em API exposta a browser — o default é `*`. | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) |
| `HONO-MW-10` | Autenticação e `bodyLimit` **MUST** ser registrados antes de qualquer middleware ou handler que faça trabalho caro. | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) |
| `HONO-RPC-01` | Todo input vindo do request **MUST** passar por um validator antes de alimentar lógica de domínio — `c.req.json` cru **NEVER** é lido diretamente numa rota que aceita input externo. | [Hono - Validação e RPC](hono-validacao-e-rpc.md) |
| `HONO-RPC-02` | O handler **MUST** ler o dado por `c.req.valid(target)`; reler `c.req.json`/`c.req.query` depois do validator **NEVER** acontece. | [Hono - Validação e RPC](hono-validacao-e-rpc.md) |
| `HONO-RPC-04` | Rota pública **MUST** customizar a resposta de erro do validator via `hook` — o default serializa o `SafeParseError` do Zod no corpo e no tipo da rota. | [Hono - Validação e RPC](hono-validacao-e-rpc.md) |
| `HONO-RPC-06` | Rota consumida por `hc` **NEVER** responde `c.notFound` sem augmentar `interface NotFoundResponse`. | [Hono - Validação e RPC](hono-validacao-e-rpc.md) |
| `HONO-RPC-08` | `param` e `query` enviados por `hc` **MUST** ser `string`; valor com `/` **MUST** ter regex na rota ou `encodeURIComponent`. | [Hono - Validação e RPC](hono-validacao-e-rpc.md) |
| `HONO-RPC-09` | Erro produzido por `app.onError` ou middleware global que o cliente precise tratar **MUST** ser declarado com `ApplyGlobalResponse`. | [Hono - Validação e RPC](hono-validacao-e-rpc.md) |
| `HONO-RPC-13` | `queryFn`/`mutationFn` que consome `hc` **MUST** usar `parseResponse` ou lançar explicitamente quando `!res.ok` — `hc` **NEVER** lança sozinho, e a query fica em `success` com o corpo do erro dentro de `data`. | [Hono - Validação e RPC](hono-validacao-e-rpc.md) |
| `HONO-RPC-14` | O `signal` fornecido pela `queryFn` do TanStack Query **MUST** ser repassado ao `hc` via `{ init: { signal } }` — é a única forma de o cancelamento chegar à rede. | [Hono - Validação e RPC](hono-validacao-e-rpc.md) |

### 6.2 IDs canônicos

Seis princípios aparecem em mais de uma família, porque cada satélite precisa se sustentar sozinho. **Para citar, use o ID canônico** — os demais são apelidos e não devem aparecer em revisão.

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| A cadeia contínua é o que constrói o tipo do app | `HONO-CORE-01` | `HONO-APP-01`, `HONO-RPC-05` |
| Status literal em `c.json` discrimina a resposta no cliente | `HONO-CORE-09` | `HONO-RPC-07` |
| Rota `HEAD` dedicada nunca é registrada | `HONO-CORE-11` | `HONO-APP-06` |
| `Bindings` e `Variables` vão no generic, sem cast | `HONO-CORE-02` | `HONO-APP-02` |
| Chave de `header` é minúscula | `HONO-CORE-08` | `HONO-RPC-03` |
| Servidor e cliente na mesma versão de `hono` | `HONO-RPC-11` | `HONO-APP-05` |

### Famílias completas nos satélites

| Família | Onde vive | IDs |
| --- | --- | --- |
| `HONO-APP-*` | esta nota, § 6 | 01–08 |
| `HONO-CORE-*` | [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) | 01–15 |
| `HONO-MW-*` | [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) | 01–13 |
| `HONO-RPC-*` | [Hono - Validação e RPC](hono-validacao-e-rpc.md) | 01–14 |

**50 regras no total**, das quais 6 são apelidos de um ID canônico (§ 6.2) e 22 viajam com o caminho mínimo (§ 6.1). Numeração contínua, sem lacunas: um ID ausente é bug desta estrutura.

---

## 7. Contrato de skill

Como uma skill de Hono deve consumir esta doc.

### O que uma skill de Hono deve carregar

```
SEMPRE: Docs/Hono.md § 2 (modelo mental)
 Docs/Hono.md § 5 (árvores de decisão)
 Docs/Hono.md § 6 + § 6.1 (regras normativas e críticas)

AO DECLARAR ROTA ou ler/escrever no Context:
 Docs/Hono - Roteamento e Contexto.md

AO TOCAR auth, CORS, log, cache, timeout, headers:
 Docs/Hono - Middleware e Ciclo de Vida.md

AO RECEBER INPUT do request, ou quando o tipo tiver que chegar no frontend:
 Docs/Hono - Validação e RPC.md

EM CONSUMO PELO REACT (queryFn, mutationFn, hc, formulário, cancelamento):
 Docs/Hono - Validação e RPC.md § 6.1 ← a ponte normativa
 Docs/Hono.md § 8 ← o panorama e o critério de adoção
 Docs/Hono - Middleware e Ciclo de Vida.md § 5 ← CORS: SPA + API é
 origem cruzada já em dev

ANTES DE ESCOLHER import, adaptador ou alvo de deploy:
 Docs/Hono.md § 3

NUNCA: todos os satélites de uma vez
```

> **Por que a § 8 entra no contrato.** A invariante 5 abaixo manda "preferir a ponte", e o defeito mais caro do stack — a `queryFn` que nunca lança (`HONO-RPC-13`) — vive exatamente nela. Um agente que carrega § 2 + § 6 e escreve o handler correto ainda produz um frontend que engole todo erro 4xx, porque nada no caminho mínimo o mandou olhar para o lado do cliente.

### Como citar

Achados de revisão citam o ID da regra e o satélite, não parafraseiam:

> `HONO-MW-01` — `next` chamado sem `await`. Tudo depois dele roda antes da resposta existir.
> Ver [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md).

### Invariantes que a skill deve fazer valer

1. **Verificar antes de afirmar.** Se uma API não está na seção 4, ela não foi verificada nesta doc. Consulte hono.dev e atualize a nota — não invente opção nem assinatura.
2. **A fonte vence.** Divergência entre esta nota e hono.dev é bug desta nota.
3. **Encadeamento antes de estilo.** Quebrar a cadeia para "ficar mais legível" é regressão funcional silenciosa, não preferência estética (`HONO-CORE-01`).
4. **Validar na fronteira, sempre.** Nenhum handler lê `c.req.json` cru para alimentar domínio (`HONO-RPC-01`). Ver.
5. **Preferir a ponte, e fechá-la.** Quando a seção 8 indica que o stack resolve, use o stack: o cliente do frontend é `hc<AppType>`, não um `fetch` escrito à mão. E `hc` não lança: toda `queryFn`/`mutationFn` usa `parseResponse` ou lança quando `!res.ok` (`HONO-RPC-13`), e repassa o `signal` (`HONO-RPC-14`).
6. **`return`, não `throw`, para erro que a tela discrimina.** O que sai por `app.onError` não entra na inferência do cliente (`HONO-CORE-13` / `HONO-RPC-09`). Um 409 lançado como `HTTPException` chega ao React sem tipo.

### Ao criar uma nova skill de Hono

Derive-a de **um** satélite, não desta nota inteira: uma skill de endpoint novo carrega [Hono - Validação e RPC](hono-validacao-e-rpc.md) + § 2 + § 6, e nada mais. Registre no início da skill qual satélite é sua fonte, para que a atualização da doc propague.

---

## 8. Pontes com o stack

O stack deste vault é [React.js](react-js.md) + [TanStack Router](tanstack-router.md) + [TanStack Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) + `TypeScript` + Zod, sobre [Bun](bun.md). Hono entra como a camada HTTP — e a razão de ele estar em avaliação é uma só: **o tipo do servidor pode chegar no componente sem que ninguém escreva o contrato duas vezes.**

| Problema | Primitiva crua | O que usar no stack |
| --- | --- | --- |
| Chamar a API do frontend | `fetch('/api/...')` + tipo escrito à mão | `hc<AppType>` de `hono/client` |
| Descrever o formato do input | tipo TS + checagem manual | `zValidator(target, schema)` — |
| Tipar o retorno da chamada | interface duplicada | `InferResponseType<typeof client.x.$get>` |
| Erro do servidor virar `error` na query | `try/catch` ad hoc | `parseResponse` ou checar `res.ok` e lançar na `queryFn` |
| Compartilhar o contrato entre times | OpenAPI + geração de código | `export type AppType` — |
| Ler env var portável | `process.env` | `env(c)` de `hono/adapter` |

### 8.1 Como o tipo sai do servidor e chega no componente

Não há geração de código, não há build step, não há schema intermediário. O caminho é: **cadeia de rotas → `typeof` → generic de `hc`**.

```ts
// server/routes.ts
import { Hono } from 'hono'
import * as z from 'zod'
// O wrapper com `hook`, não o zValidator cru: sem ele o SafeParseError do Zod
// vira contrato público, no corpo e no tipo da rota — HONO-RPC-04.
import { zValidator } from './validator-wrapper'

const pedidoInput = z.object({
 clienteId: z.string.uuid,
 itens: z.array(z.object({ sku: z.string, quantidade: z.number.int.positive })).min(1),
})

const idPedido = z.object({ id: z.string.uuid })

const listagem = z.object({
 pagina: z.coerce.number.int.positive.default(1),
 porPagina: z.coerce.number.int.min(1).max(100).default(20),
})

// A cadeia é o contrato. Quebrá-la aqui apaga o tipo lá.
const routes = new Hono
.get('/pedidos', zValidator('query', listagem), async (c) => {
 const { pagina, porPagina } = c.req.valid('query') // number, number
 const { itens, total } = await listarPedidos({ pagina, porPagina })
 // Envelope de página: o frontend precisa de `hasMore` para desabilitar
 // a navegação, e de `total` para o contador. Ver § 8.6.
 return c.json({ pedidos: itens, total, pagina, hasMore: pagina * porPagina < total }, 200)
 })
 // param também passa por validator: nada cru alimenta domínio — HONO-RPC-01
.get('/pedidos/:id', zValidator('param', idPedido), async (c) => {
 const { id } = c.req.valid('param')
 const pedido = await buscarPedido(id)
 if (!pedido) return c.json({ error: 'pedido não encontrado' as const }, 404)
 return c.json({ pedido }, 200)
 })
.post('/pedidos', zValidator('json', pedidoInput), async (c) => {
 const input = c.req.valid('json') // { clienteId: string; itens:... }
 const resultado = await criarPedido(input)
 // Erro de domínio que o formulário discrimina: `return`, não `throw` —
 // o que sai por app.onError não chega tipado ao hc — HONO-CORE-13.
 if (!resultado.ok) {
 return c.json({ error: 'cliente sem crédito' as const, limite: resultado.limite }, 409)
 }
 return c.json({ pedido: resultado.pedido }, 201)
 })

export type AppType = typeof routes
export default routes
```

O `validator-wrapper` é o arquivo de [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 4: um `hook` que devolve `{ error, campos }` com status 400, para o formulário React mapear erro por campo. Sem ele, o 400 desta rota é o dump do Zod — e o dump entra no tipo, então o frontend passa a depender dele.

```ts
// web/src/api.ts — o único lugar do frontend que sabe onde a API mora
import { hc } from 'hono/client'
import type { AppType } from '../../server/routes'

export const api = hc<AppType>('/api')
```

O que atravessou: o formato do input (do schema Zod), o formato de cada resposta **por status**, e os paths com seus params. O que **não** atravessou: nada de runtime. `hono/client` é um Proxy sobre `fetch`; `AppType` é apagado na compilação.

### 8.2 O ponto que decide se isso funciona: `res` não lança

`hc` devolve algo *"compatible with the fetch Response"*. Isso significa que **um 404 ou um 500 chegam como `res` resolvido, não como exceção**. Uma `queryFn` que só faz `return res.json` nunca vai acionar o `error` do TanStack Query — a query fica em `success` com o corpo do erro dentro de `data`. É o bug mais fácil de introduzir nesta ponte.

Duas saídas verificadas:

```ts
// A. parseResponse — lança DetailedError se !res.ok, e o tipo de retorno
// já exclui 4xx/5xx. É a opção certa em queryFn.
import { parseResponse } from 'hono/client'
import { queryOptions } from '@tanstack/react-query'

export const pedidosOptions = (pagina: number) =>
 queryOptions({
 // ['recurso', 'escopo',...variáveis] — o nível de escopo é o que permite
 // invalidar só as listas sem derrubar os detalhes. Ver TSQ-KEY-*.
 queryKey: ['pedidos', 'lista', { pagina }] as const,
 queryFn: ({ signal }) =>
 parseResponse(
 api.pedidos.$get({ query: { pagina: String(pagina) } }, { init: { signal } })
 ),
 staleTime: 60_000,
 })
```

```ts
// B. Discriminar por status quando o erro faz parte do domínio da tela.
export const pedidoOptions = (id: string) =>
 queryOptions({
 queryKey: ['pedidos', 'detalhe', id] as const,
 queryFn: async ({ signal }) => {
 const res = await api.pedidos[':id'].$get({ param: { id } }, { init: { signal } })
 if (res.status === 404) {
 const { error } = await res.json // { error: 'pedido não encontrado' }
 throw new PedidoNaoEncontrado(error)
 }
 if (!res.ok) throw new Error('falha ao carregar pedido')
 return res.json // { pedido: Pedido }
 },
 })
```

As duas formas são normativas: `HONO-RPC-13` exige uma delas, e `HONO-RPC-14` exige o `{ init: { signal } }` em ambas. O corpo completo da família, com o exemplo de `useMutation` que leva erro de domínio tipado ao formulário, está em [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 6.1.

`DetailedError` estende `Error` e carrega `detail`, `code`, `statusCode` e `log` (todos opcionais). No React, é isso que aparece em `error` do `useQuery` — ver [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md).

**`signal` atravessa.** O segundo argumento de `$get`/`$post` aceita `{ init: RequestInit }`, e a doc mostra `signal` como caso de uso. Passar o `signal` que o TanStack Query fornece na `queryFn` faz o cancelamento chegar até a rede — ver e.

### 8.3 `queryKey`, `queryFn` e mutations

**A `queryKey` não sai do tipo.** Nada em `hono/client` gera key de cache — a key é decisão de cliente e continua sendo escrita à mão. O que o cliente oferece é `$url` e `$path`, que **podem** servir de base estável para a key. `$url` exige base URL absoluta (`hc<AppType>('/')` faz `$url` lançar `TypeError`); `$path` funciona com qualquer base porque não inclui a origem.

Mutations são o espelho: `InferRequestType` dá o tipo do argumento, `InferResponseType` dá o do retorno.

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query'
import type { InferRequestType, InferResponseType } from 'hono/client'
import { parseResponse } from 'hono/client'

const $post = api.pedidos.$post

export function useCriarPedido {
 const queryClient = useQueryClient
 return useMutation<
 InferResponseType<typeof $post, 201>,
 Error,
 InferRequestType<typeof $post>['json']
 >({
 mutationFn: (novoPedido) => parseResponse($post({ json: novoPedido })),
 onSuccess: => queryClient.invalidateQueries({ queryKey: ['pedidos', 'lista'] }),
 })
}
```

Esta é a forma **curta**, e serve quando qualquer erro é "falhou". Ela não serve quando o formulário precisa saber qual campo falhou ou distinguir o 409 do 500: `parseResponse` colapsa todo status de erro num `DetailedError` genérico. A variante que discrimina por `res.status` e leva `campos` até o `setError` do formulário está em [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 6.1.

A invalidação continua sendo responsabilidade do cliente — ver [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md). O que Hono elimina é a duplicação do **formato**, não a política de cache.

### 8.4 Onde a responsabilidade muda de dono

| Responsabilidade | Dono | Nunca duplique |
| --- | --- | --- |
| Formato do input aceito | schema Zod no servidor, dentro de `zValidator` | não reescreva o tipo no frontend — derive de `InferRequestType` |
| Autorização e regra de negócio | handler no servidor | validação de formulário no cliente é UX, não segurança — |
| Formato e status da resposta | `c.json(body, status)` no handler | não escreva `interface PedidoResponse` no frontend |
| Frescor, dedupe, retry, cache | TanStack Query no cliente | o servidor não sabe nem precisa saber |
| Chave de cache (`queryKey`) | cliente | não tente derivar do path sem pensar na granularidade |
| Formulário e mensagem de erro por campo | cliente, a partir do mesmo schema Zod | compartilhe o **schema**, não uma cópia dele — |

### 8.5 O que **não** funciona

Honestidade sobre os limites, porque é o que decide se essa ponte vale o custo:

- **Só funciona com `hono/client` sobre o mesmo `AppType`.** Não há OpenAPI, não há artefato: qualquer outro consumidor (outra linguagem, um webhook, um cliente móvel) volta a precisar de contrato escrito à mão. Para publicar spec existe `@hono/zod-openapi`, que é **outro pacote e outra forma de escrever as rotas** — não verificado nesta doc.
- **`c.notFound` apaga o tipo.** A doc é literal: *"The data that the client gets from the server cannot be inferred correctly."* Use `c.json({ error }, 404)`, ou augmente `interface NotFoundResponse`.
- **`app.onError` e middleware global não entram na inferência.** *"Hono RPC client doesn't automatically infer response types from global error handlers."* Se o 500 padronizado precisa chegar tipado, declare com `ApplyGlobalResponse<typeof app, { 500: { json: { error: string } } }>`.
- **Hono valida input, não saída.** Não há equivalente ao `response` de [Elysia](elysia.md) (`ELYSIA-TYPE-06`), que checa o retorno em runtime. O tipo que chega ao `hc` é **inferido do que o handler escreve** — se o objeto que sai de `c.json` não corresponde ao que o domínio realmente produziu, o cliente é tipado com a mentira e recebe `undefined` em runtime, sem erro em lugar nenhum. Quem leu os dois frameworks supõe simetria; ela não existe. Ver [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 7, item 6.
- **`param` e `query` são sempre `string` no cliente**, mesmo quando o validator os converte. `z.coerce.number` funciona no servidor; o cliente manda `'1'`.
- **`hc` não faz URL-encode de `param`.** Valor com `/` exige regex na rota (`:id{.+}`) ou `encodeURIComponent` antes.
- **Custo de compilação real, e a doc admite.** *"the more routes you have, the slower your IDE will become"* — cada rota gera instanciações de tipo que o `tsserver` refaz. Mitigações verificadas, em ordem de eficácia: (1) pré-compilar o cliente com `export type Client = ReturnType<typeof hc<typeof routes>>` e usar um `hcWithType` — *"recommended"*; o `typeof` aqui é o da **variável da cadeia** (`HONO-RPC-05`): a doc escreve `typeof app` porque no exemplo dela `app` é essa variável, e copiar literalmente num projeto que encadeou em `routes` pré-compila o cliente do app vazio; (2) dividir o app e criar um cliente por sub-app; (3) TypeScript project references quando back e front são projetos separados; (4) anotar o type argument de path manualmente (`app.get<'foo/:id'>(...)`). E o pré-requisito de todas: mesma versão de `hono` dos dois lados, `"strict": true` nos dois `tsconfig`.

### 8.6 O envelope de resposta paginada

Hono não impõe formato de resposta — e é por isso que este ponto precisa ser decidido aqui, uma vez, em vez de rota a rota. O caso é concreto: o exemplo de `TSQ-PATTERN-05` em [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) desabilita a navegação com `disabled={isPlaceholderData || !data?.hasMore}` — lê um booleano "tem mais páginas" **do corpo da resposta**. Uma rota Hono que devolve `{ pedidos }` cru não produz esse campo. **A nota do frontend consome um campo que a do backend não emite**, e o sintoma é um botão "próxima" ativo na última página.

O envelope mínimo, para paginação por offset:

```ts
const paginado = <T>(itens: T[], total: number, pagina: number, porPagina: number) => ({
 itens,
 total, // contador da UI
 pagina, // eco do input, para o cliente conferir
 hasMore: pagina * porPagina < total, // o que TSQ-PATTERN-05 lê
})
```

Três decisões que o envelope carrega, e por que cada uma:

| Campo | Por que existe | O que quebra sem ele |
| --- | --- | --- |
| `itens` | nome estável em toda rota de lista | cada rota inventa o seu (`pedidos`, `clientes`), e o frontend não consegue um hook genérico |
| `total` | contador e cálculo de páginas | a UI não sabe quantas páginas existem |
| `hasMore` | é **do servidor**, que conhece o total | derivado no cliente a partir de `itens.length < porPagina`, erra quando a última página está cheia |

**O nome do campo é contrato.** `hasMore` é o nome adotado em todo o vault, e a razão é que o consumidor veio primeiro: `TSQ-PATTERN-05`, em [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md), lê `data?.hasMore`. Esta estrutura e a de [Elysia](elysia.md) emitem o mesmo nome — a convergência é deliberada, não coincidência.

Se você renomear o campo em um lado só, o sintoma é silencioso: o `hc` não inventa a chave ausente, `data.hasMore` vira `undefined`, o `!` dá `true`, e o botão "próxima" fica **desabilitado sempre**. Não há erro de tipo se o envelope não estiver no `response` declarado, e não há erro de runtime nunca. É por isso que o nome vale uma linha de contrato e não uma escolha por rota.

Para cursor em vez de offset, o envelope troca `pagina`/`total` por `proximoCursor: string | null`, e `hasMore` vira `proximoCursor !== null`. `useInfiniteQuery` consome exatamente isso — ver [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md).

Nada disto é API de Hono: é decisão de contrato desta estrutura, que Hono não tem opinião sobre. Registrada aqui porque é o ponto em que duas estruturas do vault se desencontram.

**Critério de adoção.** A ponte compensa quando back e front vivem no mesmo repositório, na mesma versão de TypeScript, e um time só mexe nos dois. Fora disso — clientes heterogêneos, versionamento independente, contrato público — o custo de acoplamento de tipo supera o ganho, e uma spec explícita volta a ser a resposta certa.

---

## Relacionados

- [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) — declarar rota, ler o request, formar a resposta
- [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) — onion model, ordem, built-ins
- [Hono - Validação e RPC](hono-validacao-e-rpc.md) — validator, `AppType`, `hc`, limitações
- [Bun](bun.md) · [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Bun - Runtime e APIs](bun-runtime-e-apis.md) · [Bun - Testes](bun-testes.md) — o runtime alvo
- `Node.js` · · `Nest.js` — as alternativas já documentadas no vault
- [React.js](react-js.md) · [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) · [TanStack Router](tanstack-router.md) · `TypeScript`
- ·
- · ·
- · · ·

## Fontes consultadas

Verificadas diretamente em **2026-08-15**, a partir de `https://hono.dev/llms-full.txt` com confirmação nas páginas específicas:

- [Docs index](https://hono.dev/docs) · [Web Standards](https://hono.dev/docs/concepts/web-standard) · [Routers](https://hono.dev/docs/concepts/routers) · [Hono Stacks](https://hono.dev/docs/concepts/stacks)
- [App - Hono](https://hono.dev/docs/api/hono) · [Context](https://hono.dev/docs/api/context) · [HonoRequest](https://hono.dev/docs/api/request) · [Routing](https://hono.dev/docs/api/routing) · [Presets](https://hono.dev/docs/api/presets) · [HTTPException](https://hono.dev/docs/api/exception)
- [Middleware](https://hono.dev/docs/guides/middleware) · [Validation](https://hono.dev/docs/guides/validation) · [RPC](https://hono.dev/docs/guides/rpc) · [Best Practices](https://hono.dev/docs/guides/best-practices) · [Testing](https://hono.dev/docs/guides/testing)
- Helpers: [Adapter](https://hono.dev/docs/helpers/adapter) · [Factory](https://hono.dev/docs/helpers/factory) · [Cookie](https://hono.dev/docs/helpers/cookie) · [Streaming](https://hono.dev/docs/helpers/streaming) · [Testing](https://hono.dev/docs/helpers/testing) · [Route](https://hono.dev/docs/helpers/route)
- Runtimes: [Bun](https://hono.dev/docs/getting-started/bun) · [Node.js](https://hono.dev/docs/getting-started/nodejs) · [Cloudflare Workers](https://hono.dev/docs/getting-started/cloudflare-workers) · [Deno](https://hono.dev/docs/getting-started/deno)
- Middlewares built-in em `https://hono.dev/docs/middleware/builtin/<nome>`: `cors`, `jwt`, `bearer-auth`, `basic-auth`, `logger`, `secure-headers`, `csrf`, `body-limit`, `cache`, `compress`, `etag`, `timeout`, `timing`, `request-id`, `combine`, `context-storage`, `method-not-allowed`
- Versões: `registry.npmjs.org/hono/latest` → **4.13.2**; `@hono/zod-validator` → 0.9.0 (peer `zod ^3.25.0 || ^4.0.0`, `hono >=4.11.2`); `@hono/node-server` → 2.1.1
- Tipos publicados: `hono@4.13.2/dist/types/client/index.d.ts` e `client/utils.d.ts` (exports e assinatura de `parseResponse`/`DetailedError`); fonte de `@hono/zod-validator` (resposta default de falha)

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **`app.head` não funciona.** Hono converte HEAD em GET *"before route matching occurs"*. A doc marca handler HEAD dedicado como ❌: *"This handler will NEVER be called."* Lógica específica de HEAD vai em middleware que checa `c.req.method` depois do `await next`.
- **`next` nunca lança.** *"hono will catch it and either pass it to your app.onError callback or automatically convert it to a 500 response... so there is no need to wrap it in a try/catch/finally."* Envolver `next` em `try/catch` não só é inútil como intercepta um erro que já foi tratado.
- **`app.query` existe.** O método HTTP QUERY está na doc de Routing e no default de `allowMethods` do CORS (`['GET','HEAD','PUT','POST','DELETE','PATCH','QUERY']`). O middleware `cache` já documenta chave de cache por digest do corpo para QUERY, com `maxQueryBodySize` default de 64 KiB.
- **`c.req.header` sem argumento devolve chaves em minúsculas.** `headerRecord['X-Foo']` é `undefined`; `c.req.header('X-Foo')` funciona. O mesmo vale para o target `header` do validator.
- **`c.req.routePath` e `c.req.matchedRoutes` estão deprecados desde a v4.8.0** — o substituto é o helper `hono/route`.
- **`ContextVariableMap` é uma armadilha tipada.** A própria doc avisa: ele adiciona o tipo **globalmente**, *"regardless of whether the middleware that sets the variable has actually run"* — `c.get('x')` fica tipado como definido em handlers onde o middleware nunca rodou.
- **`app.notFound` só é chamado do app de topo.** Registrar em sub-app montado com `app.route` não tem efeito (a doc aponta a issue #3465).
- **`HTTPException.getResponse` ignora o `Context`.** Headers já setados em `c` não entram na resposta gerada — é preciso reaplicá-los numa nova `Response`.
- **`app.fire` está deprecado** em favor de `fire` de `hono/service-worker`.
- **Erro dentro do callback de `stream`/`streamSSE` não dispara `app.onError`** — quando o callback roda, o stream já começou e a resposta não pode mais ser sobrescrita. E `timeout` não funciona com stream.
- **`zValidator` sem `hook` responde `c.json(result, 400)`** — o objeto `SafeParseError` **inteiro** do Zod vai no corpo, e esse formato entra no tipo da rota como `TypedResponse<..., 400, 'json'>`. Vazamento de estrutura interna do schema para o cliente é o default; customizar isso é decisão, não detalhe.
- **`@hono/zod-validator` 0.9.0 aceita Zod v3.25+ e v4** (`peerDependencies: zod ^3.25.0 || ^4.0.0`) e exige `hono >= 4.11.2`.
- **A doc admite o custo de tipo do RPC.** A seção "Known issues → IDE performance" existe e recomenda pré-compilar o cliente. Não é folclore de comunidade: está na fonte.
- **Hono não valida a saída.** O guia de Validation cobre exclusivamente o request — targets `json`, `form`, `query`, `param`, `header`, `cookie`. Não existe na fonte nada equivalente ao `response` de Elysia verificado em runtime. A simetria que se supõe entre os dois frameworks não existe; ver [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 7, item 6.
- **O `hcWithType` da doc usa `typeof app` porque `app` é a variável da cadeia no exemplo dela.** Copiado literalmente num projeto que encadeou em `routes`, pré-compila o cliente do app **vazio** — falha silenciosa, só visível como perda de autocomplete (`HONO-RPC-05`).
- **O `signal` não atravessa sozinho para o `fetch`.** A doc mostra `AbortController` como caso de uso do `init` no segundo argumento da chamada do `hc`. Não há repasse implícito — `HONO-RPC-14`.
- **O cookie helper valida prefixo e prazo, e lança.** `__Secure-`/`__Host-` mal configurados, `maxAge` acima de 400 dias e `expires` além de 400 dias produzem `Error`. E `getSignedCookie` tem três resultados: valor, `false` (assinatura inválida) e `undefined` (não é cookie assinado). Ver [Hono - Roteamento e Contexto](hono-roteamento-e-contexto.md) § 9.
- **`generateCookie` e `generateSignedCookie` existem** em `hono/cookie` e só montam a string, sem escrever no header. Não constavam do inventário anterior desta nota.
- **`origin` e `allowMethods` do CORS aceitam função de `(origin, c)`.** E a doc pede `server.cors: false` no `vite.config.ts` quando Hono roda sob Vite, para não conflitar com o CORS embutido.
- **`hc` aceita a base URL como segundo parâmetro de tipo** — `hc<typeof route, 'http://localhost:8787'>(...)` devolve `TypedURL` em `$url`. Não verificado em uso; registrado por existir.
- **WebSocket e `conninfo` não estão verificados nesta doc.** A § 3.2 diz de qual adaptador cada um vem e `HONO-APP-08` legisla sobre isso, mas a API (`upgradeWebSocket`, formato de `ConnInfo`) não foi conferida — é preciso abrir o [WebSocket Helper](https://hono.dev/docs/helpers/websocket) e o [ConnInfo Helper](https://hono.dev/docs/helpers/conninfo) antes de escrever.
- **O envelope de resposta paginada não é assunto de Hono.** Não há convenção na fonte; o formato da § 8.6 é decisão desta estrutura, tomada porque a estrutura de TanStack Query consome um campo que ninguém emitia.
