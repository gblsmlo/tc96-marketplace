---
Link: https://elysiajs.com/
tags:
 - elysia
 - backend
 - agent-context
source: "Documentação oficial — https://elysiajs.com/"
verificado-em: 2026-08-15
---
# Elysia — referência conduzida

> **O que esta nota é.** O ponto de entrada único para Elysia neste vault: para mim ao consultar, e para agentes de código ao gerar ou revisar servidores Elysia. Não é um resumo linear da documentação — é um **roteador**. Ela decide o que carregar, oferece o modelo mental que faz o resto fazer sentido, e expõe regras citáveis que uma skill ou um code review pode referenciar por ID.
>
> **O que não é.** Não substitui a fonte. Quando houver divergência, [elysiajs.com](https://elysiajs.com/) vence, e esta nota deve ser corrigida.

Inventário verificado em elysiajs.com e no pacote publicado em **2026-08-15**.
Versão verificada: **elysia 1.4.29** (`registry.npmjs.org/elysia/latest`), `@elysia/eden` 1.4.10, `@elysia/openapi` 1.4.15.
Ver [Fontes consultadas](#fontes-consultadas).

---

## 1. Como usar esta doc

### Para um humano

Leia a seção 2 uma vez — o escopo de plugin (§ 2, afirmação 3) é o conceito que mais custa caro quando não se conhece. Depois use § 4 como índice e § 5 quando estiver na dúvida entre duas APIs próximas. Os satélites são leitura sob demanda.

### Para um agente de código

Carregue nesta ordem, parando assim que tiver o suficiente:

| Passo | Carregar | Quando |
| ----- | -------- | ------ |
| 1 | Esta nota (§ 2, § 5, § 6) | Sempre que a tarefa envolver Elysia |
| 2 | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) | Escrever ou alterar rotas, respostas, erros |
| 3 | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) | Escrever plugin, hook, auth, ou quando "o plugin não funciona" |
| 4 | [Elysia - Schema e Eden](elysia-schema-e-eden.md) | Declarar schema, `response`, OpenAPI, ou consumir a API do frontend |
| 5 | [Bun - HTTP e Servidor](bun-http-e-servidor.md) | Detalhe do servidor por baixo — TLS, sockets, `Bun.serve` |

**Regra de economia de contexto:** nunca carregue todos os satélites.

### Convenções e vocabulário

**Todos os exemplos são TypeScript.** Elysia sem TypeScript perde a maior parte do seu valor: a inferência é o produto.

Termos usados sem redefinição nos satélites:

| Termo | Significado nesta doc |
| --- | --- |
| **instância** | um objeto `new Elysia`. É simultaneamente app, plugin, controller e unidade de escopo |
| **tipo acumulado** | o tipo que cada método de encadeamento devolve, carregando tudo que foi registrado até ali |
| **escopo** (`local`/`scoped`/`global`) | até onde um hook registrado numa instância alcança — ver § 2, afirmação 3, e [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 5 |
| **contexto** | o objeto único por request passado ao handler e a todo hook |
| **hook local** | hook passado no 3º argumento de uma rota; vale só para aquela rota |
| **interceptor** | hook registrado com `.onX`; vale para as rotas registradas **depois** dele |
| **guard** | bloco que aplica schema e hooks a várias rotas de uma vez |
| **macro** | hook reutilizável ativado por uma propriedade booleana ou parametrizada no hook local |
| **schema** | uma declaração `t.*` (ou Standard Schema) que produz validação, tipo, OpenAPI e contrato do Eden |
| **Eden** | o cliente tipado que consome `typeof app` sem geração de código |
| **Standard Schema** | a interface comum que permite usar Zod/Valibot/ArkType/Effect no lugar de `t` |

---

## 2. Modelo mental

Cinco afirmações. Quase todo erro que um agente comete em Elysia viola uma delas.

**1. Um schema não é validação — é quatro coisas de uma declaração só.** A doc é literal: *"A single Elysia/TypeBox schema can be used for: Runtime validation · Data coercion · TypeScript type · OpenAPI schema"*. E há uma quinta, que a doc trata em outra página: é o contrato que o Eden consome no frontend. Consequência prática: qualquer `interface` TypeScript escrita à mão para descrever um body já validado é duplicação, e vai divergir. O tipo se extrai com `typeof MeuSchema.static`. É a mesma tese de e só que aqui a ferramenta impõe.

**2. O encadeamento de métodos é o que guarda o tipo. Quebrá-lo perde inferência silenciosamente.** Cada método devolve um **novo** tipo de instância. `const app = new Elysia; app.state('build', 1); app.get(...)` compila e roda — mas `store.build` não existe no tipo, e o Eden do frontend não vê a rota. A doc é enfática: *"Elysia code should **ALWAYS** use method chaining"*. Não é estilo, é o mecanismo.

**3. Escopo de plugin é `local` por default, e é a classe de bug mais comum.** Hooks de uma instância **não vazam** para quem faz `.use` dela. A doc compara com `export` em JavaScript: você precisa exportar. Um `onBeforeHandle` de autenticação dentro de um plugin protege as rotas *daquele plugin* e nada mais — o `app` que o consome fica aberto, sem erro, sem aviso. Os três níveis (`local` / `scoped` / `global`) e o `as` estão em [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 5.

**4. A ordem do código é a ordem de aplicação.** Um evento só vale para rotas registradas **depois** dele. `onError` declarado no fim do arquivo não captura nada do que veio antes; um plugin registrado antes de um `onBeforeHandle` não o herda. A única exceção verificada é `onRequest`, que é global por não saber ainda qual rota vai atender.

**5. Elysia é Bun-first, não Bun-only — e a diferença é feature a feature.** O runtime alvo por padrão é Bun, e coisas como `context.server` são explicitamente marcadas *"Bun only"* na doc. Fora do Bun existem adapters reais (Node, Cloudflare Worker, Deno via `Deno.serve(app.fetch)`), com limitações declaradas — ver § 3. Escolher Elysia sem Bun é possível e documentado; escolher sem saber o que se perde é que não.

> **Sobre a relação com Zod.** O schema nativo é TypeBox (`t`), mas Elysia 1.4 suporta **Standard Schema**: Zod, Valibot, ArkType, Effect Schema, Yup, Joi funcionam direto no lugar de `t`, e *"You can use any validator together in the same handler without any issue"* — verificado. A escolha é real e tem trade-offs concretos (coerção, OpenAPI, validação de arquivo). Detalhe em [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 2 e § 8 desta nota.

---

## 3. Fronteiras de import e runtime

Saber de onde algo vem evita metade dos erros de import. Lista extraída dos `export` de `elysia@1.4.29`.

### O pacote `elysia`

| Export | Para que serve |
| --- | --- |
| `Elysia` | a classe. Default export **e** named export |
| `t` | o schema builder (TypeBox + tipos de servidor) |
| `status` | retorna resposta com status tipado — **é o nome atual**, ver nota abaixo |
| `redirect` | redireciona (também disponível no contexto) |
| `file`, `ElysiaFile` | responde um arquivo |
| `form` | responde `FormData` |
| `sse` | formata um chunk como Server-Sent Event |
| `env` | acesso a variáveis de ambiente independente de runtime |
| `validationDetail`, `fileType` | detalhe de erro de validação; checagem de tipo de arquivo por magic number |
| `NotFoundError`, `ParseError`, `ValidationError`, `InvalidCookieSignature`, `InvalidFileType`, `InternalServerError` | classes de erro embutidas |
| `StatusMap`, `InvertedStatusMap`, `ERROR_CODE` | mapas de status e símbolo de código de erro |
| `Cookie`, `serializeCookie` | utilitários de cookie |
| tipos: `Context`, `PreContext`, `ErrorContext`, `Static`, `TSchema`, … | tipagem |

> **Renomeação confirmada:** `error` **não é mais exportado** por `elysia`, e **não existe mais no contexto**. O nome atual é `status`, tanto como export (`import { status } from 'elysia'`) quanto como propriedade do contexto (`({ status }) => status(418)`). Verificado nos `.d.ts` de 1.4.29 — `Context` lista `status`, não `error`. Alguns exemplos remanescentes na doc oficial ainda usam `error`; são resíduo. `.error` continua existindo, mas é **método da instância** para registrar classes de erro customizadas, coisa diferente.

### Escopos npm: `@elysia/*` e `@elysiajs/*` coexistem

Os plugins oficiais estão publicados **nos dois escopos**. A documentação atual usa `@elysia/*`, e é esse o escopo mais adiantado em versão (ex.: `@elysia/eden` 1.4.10 × `@elysiajs/eden` 1.4.9; `@elysia/static` 1.4.11 × `@elysiajs/static` 1.4.10). Prefira `@elysia/*` em código novo; `@elysiajs/*` é o que você vai encontrar em tutoriais e projetos anteriores.

| Pacote | Contém | Estado |
| --- | --- | --- |
| `@elysia/openapi` | `openapi`, `fromTypes`, `withHeader` — documentação em `/openapi` (Scalar por default) | atual |
| `@elysia/eden` | `treaty`, `edenFetch`, `edenTreaty` (legado), `Treaty` (tipos) | atual |
| `@elysia/cors` | CORS | atual |
| `@elysia/jwt` | assinar/verificar JWT (sobre `jose`) | atual |
| `@elysia/static` | servir pasta estática | atual |
| `@elysia/bearer` | extrair token Bearer | atual |
| `@elysia/html` | resposta HTML/JSX, `isHtml` | atual |
| `@elysia/cron` | cron jobs | atual |
| `@elysia/opentelemetry` | tracing, `record`, `getCurrentSpan`, `setAttributes` | atual |
| `@elysia/server-timing` | header `Server-Timing` | atual |
| `@elysia/node` | adapter Node.js (`node`) | atual |
| `@elysiajs/swagger` | Swagger UI | **descontinuado** — a doc diz *"deprecated and is no longer maintained"* |

### Runtimes

| Runtime | Como | Estado verificado |
| --- | --- | --- |
| **Bun** | default, `.listen(3000)` | alvo primário; `context.server`, `Bun.serve.static`, `Bun.serve.routes` só aqui |
| **Node.js** | `@elysia/node` + `new Elysia({ adapter: node })` | suportado e documentado |
| **Deno** | `Deno.serve(app.fetch)` — sem `.listen` | suportado, sem adapter próprio |
| **Cloudflare Worker** | `new Elysia({ adapter: CloudflareAdapter })` de `elysia/adapter/cloudflare-worker`, com `.compile` antes do export | **experimental**, assim marcado na doc |
| **Vercel / Netlify / Next.js / Astro / Expo / TanStack Start** | via API route, chamando `app.fetch(request)` | documentado |

Limitações declaradas no Cloudflare Worker: `file` e o plugin static não funcionam (sem `fs`), OpenAPI Type Gen não funciona, e **valor inline em rota (`.get('/', 'Hello')`) lança erro** porque não se pode criar `Response` antes do start. Bindings vêm de `import { env } from 'cloudflare:workers'`, **não** do export `env` de `elysia` — ver § 6, `ELYSIA-APP-09`.

Sobre `aot` no Worker: até 1.4.6 era preciso passar `aot: false`, porque o Worker não permitia compilação de função no start. A partir de **1.4.7** isso deixou de ser necessário e a doc recomenda deixar o AoT ligado, *"for better performance and accurate plugin encapsulation"*. O default de `aot` é `true` no pacote publicado, apesar de a página de Config dizer o contrário — ver [Fontes consultadas](#fontes-consultadas).

---

## 4. Mapa da API

Superfície verificada nos `.d.ts` de 1.4.29 e nas páginas correspondentes. A coluna **Satélite** diz o que carregar.

**Deliberadamente fora deste mapa:** `mount` (interop com Hono/H3 e outros frameworks Web Standard), `trace`, `wrap`, `Ref`, `affix`/`suffix`, `mapDerive`/`mapResolve`, `options`, `connect`, `headers`, os plugins de GraphQL (Apollo e Yoga), o JIT compiler interno e o ecossistema de plugins da comunidade. Ausência aqui significa **"não verificado nesta doc"**, não "não existe" — consulte elysiajs.com.

`compile` e `prefix` **estão** no mapa: o primeiro na tabela de construtor e ciclo abaixo (é obrigatório no Cloudflare Worker, § 3), o segundo entre as opções verificadas do construtor.

### Construtor e ciclo do servidor

| API | Para que serve | Satélite |
| --- | --- | --- |
| `new Elysia(config)` | cria instância. Opções verificadas: `name`, `seed`, `prefix`, `adapter`, `aot`, `precompile`, `normalize`, `strictPath`, `serve`, `websocket`, `cookie`, `detail`, `tags`, `sanitize`, `encodeSchema`, `nativeStaticResponse`, `systemRouter`, `allowUnsafeValidationDetails` | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.listen(port)` | sobe o servidor (Bun/Node) | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.fetch(request)` / `.handle(request)` | processa um `Request` sem servidor — base dos testes e da integração com API routes | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.compile` | força a compilação do encadeamento sem `listen` — **obrigatório antes de exportar no Cloudflare Worker** (§ 3) | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.onStart`, `.onStop` | ciclo do **servidor**, não do request | — |
| `.modules` | promise dos módulos lazy/async carregados | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |

### Rotas

| API | Para que serve | Satélite |
| --- | --- | --- |
| `.get/.post/.put/.patch/.delete/.head` | rota por verbo | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.all(path, handler)` | qualquer método | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.route(method, path, handler)` | verbo customizado (case-sensitive, use MAIÚSCULA) | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.group(prefix, [guard], cb)` | prefixo comum, com guard opcional no 2º argumento | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.ws(path, handler)` | WebSocket com schema (`body`, `query`, `params`, `header`, `cookie`, `response`) | [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| `.mount` | montar outro app Web Standard | — |

### O objeto de contexto

O que o handler recebe. Lista dos `.d.ts` de `context.d.ts`; a coluna Satélite aponta para onde o comportamento é tratado.

| Propriedade | Para que serve | Satélite |
| --- | --- | --- |
| `body`, `query`, `params`, `headers` | entrada do request; tipo exato só com schema | [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 3 |
| `cookie` | jar reativo (Proxy): lê e escreve `.value`, sincroniza o header | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) § 4 |
| `set` | `{ headers, status }` da resposta. `set.status` **não** é checado contra o `response` schema | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) § 4 |
| `set.headers` | headers de saída, sempre em minúsculas — imutável depois do primeiro `yield` | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) § 4 |
| `status` | `status(code, valor)` — resposta com status tipado; substitui o antigo `error` | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) § 4 e § 5 |
| `store` | estado global da instância, criado por `.state`; primitivo não se desestrutura | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 3 |
| `redirect` | função de redirect; `set.redirect` está deprecado | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) § 4 |
| `request` | o `Request` Web Standard — escape hatch | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) § 3 |
| `server` | instância do servidor — **Bun only**, `null` fora dele | [Bun - HTTP e Servidor](bun-http-e-servidor.md) |
| `path` × `route` | URL concreta (`/pedidos/9`) × caminho registrado (`/pedidos/:id`) — use `route` como rótulo de métrica | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) § 3 |
| `responseValue` | o valor de retorno, visível em `onAfterHandle`/`mapResponse` (substitui `response`, deprecado) | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 2 |
| `PreContext` (só em `onRequest`) | subconjunto: `request`, `set`, `store`, `status`, `redirect`, `server` e decorators | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 2 |

### Contexto e extensão

| API | Fase | Satélite |
| --- | --- | --- |
| `.state(k, v)` | uma vez, no boot → `store` (mutável, global) | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.decorate(k, v)` | uma vez, no boot → propriedade do contexto (não mutar) | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.derive(fn)` | por request, em `transform` — **antes** da validação | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.resolve(fn)` | por request, em `beforeHandle` — **depois** da validação | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.macro({...})` | hook reutilizável ativável por propriedade | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.model({...})` | registra schemas nomeados, referenciáveis por string | [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| `.error({...})` | registra classes de erro com código para narrowing | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.parser(nome, fn)` | body parser customizado | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |

### Lifecycle (ordem de execução)

`onRequest` → `onParse` → `onTransform` (+`derive`) → **validação** → `onBeforeHandle` (+`resolve`) → **handler** → `onAfterHandle` → `mapResponse` → *resposta enviada* → `onAfterResponse`. `onError` intercepta erro de qualquer fase.

| API | O que pode fazer | Satélite |
| --- | --- | --- |
| `.onRequest(fn)` | contexto mínimo (`PreContext`), global; retorno curto-circuita | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.onParse(fn)` | preencher `body` para content-types não cobertos | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.onTransform(fn)` | mutar contexto para passar na validação | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.onBeforeHandle(fn)` | autorização; retorno pula o handler | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.onAfterHandle(fn)` | transformar o valor de retorno; lê `responseValue` | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.mapResponse(fn)` | mapear para `Response` (compressão etc.) | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.onError(fn)` | tratar erro; `code` narroweia o tipo de `error` | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `.onAfterResponse(fn)` | logging/analytics após envio | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.guard(obj, [cb])` | schema + hooks para várias rotas; aceita `as` e `schema: 'standalone'` | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.as('scoped' \| 'global')` | eleva o escopo de tudo que a instância registrou | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `.use(plugin)` | aplica outra instância, função, promise ou `import` | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |

### `t` — tipos que Elysia acrescenta ao TypeBox

Além de toda a superfície do TypeBox (`t.Object`, `t.String`, `t.Number`, `t.Array`, `t.Union`, `t.Optional`, `t.Partial`, `t.Literal`, `t.Intersect`, `t.Tuple`, `t.Record`, `t.KeyOf`, …), estes são de Elysia — lista extraída de `type-system/index.d.ts`:

| Tipo | O que faz de diferente |
| --- | --- |
| `t.Numeric` | aceita string numérica e **transforma em `number`** |
| `t.Integer`, `t.Date` | inteiro; data com coerção |
| `t.BooleanString` | aceita `"true"`/`"false"` como boolean |
| `t.ObjectString(props)` | string JSON que vira objeto — para query, header, FormData |
| `t.ArrayString`, `t.ArrayQuery` | array a partir de string / de query repetida |
| `t.File(opts)`, `t.Files(opts)` | upload, com `type`, `minSize`, `maxSize` (sufixos `k`/`m`) |
| `t.Form(props)` | valida retorno de `form` (FormData) |
| `t.Cookie(props, opts)` | objeto + opções de cookie: `secrets`, `sign`, `httpOnly`, `secure`, … |
| `t.Nullable(s)` | permite `null` (não `undefined`) |
| `t.MaybeEmpty(s)` | permite `null` **e** `undefined` |
| `t.UnionEnum([...])` | união de literais em um único schema |
| `t.NumericEnum(enum)` | enum numérico |
| `t.NoValidate(s)` | desliga validação mantendo o tipo |
| `t.Uint8Array`, `t.ArrayBuffer` | corpo binário |
| `t.String({ trusted: true })` | pula validação de escape JSON no acelerador |
| `t.Transform(s)` | encode/decode customizado (ver `encodeSchema` no construtor) |

Superfície completa e comportamento de coerção em [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 3.

### Plugins oficiais

Inventário e estado de cada pacote na tabela da § 3. Onde carregar: `@elysia/openapi` e `@elysia/eden` → [Elysia - Schema e Eden](elysia-schema-e-eden.md); `@elysia/cors`, `@elysia/jwt`, `@elysia/bearer`, `@elysia/static` e `@elysia/opentelemetry` → [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 8.

---

## 5. Árvores de decisão

Mapeiam **sintoma → API correta**. É onde código Elysia gerado costuma errar.

### Preciso de um valor disponível no handler. Qual API?

Esta é a decisão que mais gera código errado em Elysia, porque as quatro APIs se parecem e duas delas diferem **só na fase do lifecycle**.

```
O valor depende do request (headers, body, query, cookie)?
├── NÃO — é constante durante a vida do processo
│ └── É primitivo e alguém vai MUTAR (contador, flag)?
│ ├── SIM →.state('k', v) → lê em ctx.store.k
│ │ ⚠ desestruturar primitivo do store perde a referência
│ └── NÃO →.decorate('k', v) → lê em ctx.k
│ (classe, singleton, conexão de banco, logger)
│ ⚠ decorate NÃO deve ser mutado
│
└── SIM — precisa ser calculado a cada request
 └── O valor depende de dado que PRECISA estar validado?
 ├── SIM →.resolve(fn) roda em beforeHandle, DEPOIS da validação
 │ → é o caso de auth: sessão, userId, permissões
 │ → o tipo do que você lê é o tipo do schema
 └── NÃO →.derive(fn) roda em transform, ANTES da validação
 → o que você lê é `unknown`-ish: ainda não passou por schema
 → use para coisa que não decide segurança (requestId, IP, timing)
```

> A doc é explícita sobre o default: *"You might want to use resolve instead of derive in most cases. Resolve is similar to derive but execute after validation. This makes resolve more secure"*. Regra prática: **se o valor decide acesso, é `resolve`**. Tabela completa em [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 3.

### Onde plugo esta lógica no lifecycle?

```
Preciso rejeitar/responder ANTES de qualquer parse (rate limit, IP block, cache)
 → onRequest PreContext: request, set, store, status, redirect, server
 e decorators — e nada mais. É GLOBAL, não respeita ordem
 de rota. `status(...)` está lá: curto-circuita tipado.

O content-type não é json/text/form-data/urlencoded
 → onParse devolva o body; ou `parse: 'none'` para não parsear
 (necessário ao delegar o Request cru a outra lib)

Preciso mexer no dado para ele PASSAR na validação (coerção manual)
 → onTransform / derive

Preciso decidir se o request continua (autenticação, autorização)
 → onBeforeHandle / resolve retorno != undefined pula o handler
 →

Preciso transformar o valor de retorno (header por tipo, envelope)
 → onAfterHandle lê ctx.responseValue
 ⚠ retornar aqui NÃO pula os afterHandle seguintes

Preciso produzir uma Response Web Standard (gzip, formato binário)
 → mapResponse retornar aqui PULA os mapResponse seguintes

Algo falhou
 → onError code: NOT_FOUND | PARSE | VALIDATION |
 INTERNAL_SERVER_ERROR | INVALID_COOKIE_SIGNATURE |
 INVALID_FILE_TYPE | UNKNOWN | <número de status>

Já respondi, quero registrar
 → onAfterResponse logging e analytics —
```

### Por que meu plugin não afeta esta rota?

A árvore que resolve a classe de bug mais comum de Elysia.

```
A rota está registrada DEPOIS do hook/plugin no encadeamento?
├── NÃO → é isso. Evento só vale para rota registrada depois.
│ Mova o.use/.onX para cima. (exceção: onRequest é global)
└── SIM
 └── O hook está numa instância que a rota NÃO pertence?
 ├── NÃO (mesma instância) → deveria funcionar; cheque nome/typo
 └── SIM → é escopo. Default é `local`: não sobe para o pai.

 Quem precisa ser afetado?
 ├── só esta instância e filhos → local (default, não faça nada)
 ├── + a instância que deu.use → scoped
 └── todas, em qualquer nível → global

 Como aplicar:
 ├── um hook só →.onBeforeHandle({ as: 'scoped' }, fn)
 ├── todos de um guard →.guard({ as: 'scoped',... })
 └── todos da instância →.as('scoped') no fim do encadeamento
 (só aceita 'scoped' | 'global')
```

> `as('scoped')` sobe **um** nível. Para atravessar dois, cada instância intermediária precisa do seu próprio `as('scoped')` — ou use `global`. Exemplo completo, com o caso que falha, em [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 5.

### Como devolvo um erro?

```
É erro ESPERADO do domínio (validação de negócio, 404, 401, 409)?
│ →
├── e eu quero que o TIPO do erro chegue ao frontend pelo Eden
│ → return status(code, valor) + declare `response: { 200: …, 4xx: … }`
│ ⚠ RETORNAR não passa por onError. É o caminho recomendado pela doc.
├── e eu quero que o onError central formate/logue
│ → throw status(code, valor) ⚠ THROW passa por onError
└── e é uma condição recorrente com corpo próprio
 → class MinhaErro extends Error { status = 409; toResponse {…} }
 +.error({ MINHA: MinhaErro }) → onError narroweia por code === 'MINHA'

É erro INESPERADO (bug, indisponibilidade)?
 → deixe estourar. Vira UNKNOWN / 500 e cai no onError.
 Logue lá — — e devolva mensagem genérica.

É erro de VALIDAÇÃO e quero customizar a mensagem?
 → t.String({ error: 'mensagem' }) por campo
 → onError com code === 'VALIDATION' central; error.all lista todas as causas
 ⚠ em NODE_ENV=production o detalhe é omitido por padrão
```

> **Retornar × lançar** é uma distinção real e citada: *"If a `status` is **throw**, it will be caught by `onError` middleware. If a `status` is **return**, it will be **NOT** caught"*. A doc recomenda a abordagem **never-throw** (retornar) porque só ela dá checagem contra o `response` schema, narrowing por status e tipagem do erro no Eden. Ver.

---

## 6. Regras normativas

Regras citáveis por ID. O corpo completo de cada família vive no satélite correspondente; aqui ficam as que valem para qualquer código Elysia.

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.

### `ELYSIA-APP-*` — instância e projeto

| ID | Regra |
| --- | --- |
| `ELYSIA-APP-01` | Toda construção de instância **MUST** usar method chaining contínuo — atribuir a instância e chamar métodos em statements separados perde a inferência de tipo. |
| `ELYSIA-APP-02` | Código novo **NEVER** usa `error` do contexto ou de `elysia` — o nome atual é `status`, e `error` não existe mais em 1.4. |
| `ELYSIA-APP-03` | Handler que precisa do contexto **MUST** ser função inline desestruturando o que usa, e **NEVER** uma função externa anotada com `Context` — valor literal (`.get('/status', 'ok')`) e `file` no lugar do handler seguem válidos e não são handlers. |
| `ELYSIA-APP-04` | `tsconfig.json` do servidor **e** de todo cliente Eden **MUST** ter `strict: true` e TypeScript >= 5.0. |
| `ELYSIA-APP-05` | A instância exportada para o Eden **MUST** ser exportada como tipo (`export type App = typeof app`) do módulo onde o encadeamento termina. |
| `ELYSIA-APP-06` | Código que usa `context.server`, `Bun.*` ou valor inline em rota **MUST** declarar Bun como runtime alvo — nenhum dos três funciona igual fora dele. |
| `ELYSIA-APP-07` | `@elysiajs/swagger` **NEVER** entra em código novo — está descontinuado na fonte; use `@elysia/openapi`. |
| `ELYSIA-APP-08` | Segredo (`jwt.secret`, `cookie.secrets`) **NEVER** é literal no código — carregue na inicialização, ver. |
| `ELYSIA-APP-09` | Código de aplicação **NEVER** lê `process.env` diretamente — **MUST** usar o export `env` de `elysia`, que resolve para `Bun.env` no Bun e `process.env` fora dele. |

> **O alcance de `ELYSIA-APP-09`, verificado.** `env` de `elysia` é `Bun.env` quando o runtime é Bun, `process.env` quando existe `process`, e `{}` quando nenhum dos dois existe (`universal/env.js` de 1.4.29). O ganho é não amarrar o código a `process`, que é o que quebra ao trocar de runtime. **Não é uma solução de Cloudflare Worker:** lá `env` de `elysia` devolve `{}`, e os bindings vêm de `import { env } from 'cloudflare:workers'` — os dois nomes são `env` e não são a mesma coisa. Em Worker, importe o de `cloudflare:workers`; em qualquer outro alvo, o de `elysia`.

### 6.1 Regras críticas dos satélites

As famílias completas vivem nos satélites, mas **estas precisam viajar com o caminho mínimo** — são as que mais aparecem em código gerado.

> **O satélite é canônico.** As linhas abaixo reproduzem o texto do satélite **verbatim**, e não uma paráfrase. Em qualquer divergência entre esta tabela e o satélite, o satélite vence e esta tabela é o bug — a § 7 manda citar por ID sem parafrasear, e duas cópias divergentes de uma regra normativa inviabilizam isso.

| ID | Regra | Satélite |
| --- | --- | --- |
| `ELYSIA-CORE-01` | Hook, plugin e `onError` **MUST** ser registrados antes das rotas que devem afetar — evento só se aplica a rota registrada depois dele. | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `ELYSIA-CORE-03` | Erro esperado **MUST** ser `return status(...)`, não `throw`, quando o tipo precisa chegar tipado ao Eden. | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `ELYSIA-CORE-06` | `set.headers` **NEVER** é alterado depois do primeiro `yield` de um handler generator — a alteração é silenciosamente ignorada. | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `ELYSIA-LIFE-01` | Hook de plugin que precisa valer para quem o consome **MUST** declarar escopo (`{ as: 'scoped' }`, `guard({ as })` ou `.as`) — o default `local` não sobe, e a falha é silenciosa. | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `ELYSIA-LIFE-02` | Decisão de autenticação ou autorização **NEVER** usa `derive` — **MUST** usar `resolve` ou `macro.resolve`, que rodam depois da validação. | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `ELYSIA-LIFE-03` | Plugin aplicado por mais de uma instância **MUST** declarar `name` — sem ele o lifecycle roda uma vez por aplicação. | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `ELYSIA-TYPE-01` | Tipo TypeScript de um payload validado **MUST** derivar do schema (`typeof S.static`) — **NEVER** ser reescrito à mão. | [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| `ELYSIA-TYPE-06` | Rota que devolve mais de um status **MUST** declarar `response` como mapa por status — sem ele o erro chega ao Eden como `unknown`. | [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| `ELYSIA-TYPE-08` | Retorno do Eden **MUST** ter `error` verificado antes de usar `data` — `data` é `null` em qualquer status >= 300. | [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| `ELYSIA-TYPE-09` | `queryFn`/`mutationFn` que chama Eden **MUST** lançar em caso de erro (ou o cliente **MUST** usar `throwHttpError: true`) — sem isso a query fica `success` com dado nulo. | [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| `ELYSIA-TYPE-11` | Cliente e servidor **MUST** resolver a mesma versão de `elysia`, com `strict: true` e TypeScript >= 5.0 nos dois. | [Elysia - Schema e Eden](elysia-schema-e-eden.md) |

### 6.2 IDs canônicos

Três princípios aparecem em mais de uma família, porque cada satélite precisa se sustentar sozinho. **Para citar, use sempre o ID canônico** — o outro é apelido e não deve aparecer em revisão.

| Princípio | Canônico | Apelido |
| --- | --- | --- |
| `strict: true` e TypeScript >= 5.0 nos dois lados da fronteira Eden | `ELYSIA-APP-04` | `ELYSIA-TYPE-11`, **só nesta cláusula** |
| Falha esperada se sinaliza com `return status(...)`, não com `throw` | `ELYSIA-CORE-03` | `ELYSIA-LIFE-10` (aplicação do mesmo princípio dentro de `macro`) |
| Handler desestrutura o contexto; função externa anotada com `Context` não é aceita | `ELYSIA-CORE-02` | `ELYSIA-APP-03`, **só nesta cláusula** |

Os dois "só nesta cláusula" são deliberados, porque as duas regras não são redundantes por inteiro:

- **`ELYSIA-TYPE-11` continua citável por si** para o que é só dele: **a paridade de versão de `elysia` entre cliente e servidor**, que `ELYSIA-APP-04` não cobre e é a causa mais comum de o Eden degradar para `any`. É por isso que ele está na § 6.1 — a paridade de versão precisa viajar com o caminho mínimo. Ao citar o requisito de `strict: true` isoladamente, use `ELYSIA-APP-04`.
- **`ELYSIA-APP-09` não é apelido de nada.** Ele espelha `HONO-APP-03` na estrutura vizinha, mas ali a motivação é outra; aqui existe um export `env` no próprio pacote.
- **`ELYSIA-APP-03` continua citável por si** para o que é só dele: a legitimidade de valor literal e `file` no lugar do handler. Ao citar a desestruturação do contexto, use `ELYSIA-CORE-02`.

### Famílias completas nos satélites

| Família | Onde vive |
| --- | --- |
| `ELYSIA-APP-*` | esta nota (§ 6) |
| `ELYSIA-CORE-*` | [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) |
| `ELYSIA-LIFE-*` | [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) |
| `ELYSIA-TYPE-*` | [Elysia - Schema e Eden](elysia-schema-e-eden.md) |

São 44 regras no total (`ELYSIA-APP-*` 9 · `ELYSIA-CORE-*` 10 · `ELYSIA-LIFE-*` 12 · `ELYSIA-TYPE-*` 13); a § 6.1 acima seleciona 11.

---

## 7. Contrato de skill

Como uma skill de Elysia deve consumir esta doc.

### O que uma skill de Elysia deve carregar

```
SEMPRE: Docs/Elysia.md § 2 (modelo mental)
 Docs/Elysia.md § 5 (árvores de decisão)
 Docs/Elysia.md § 6 + § 6.1 (regras normativas e críticas)

AO ESCREVER/EDITAR rotas e respostas:
 Docs/Elysia - Roteamento e Handler.md

AO ESCREVER plugin, hook, auth, ou ao investigar
"o plugin não está sendo aplicado":
 Docs/Elysia - Lifecycle e Plugins.md

AO DECLARAR schema, response, OpenAPI,
ou ao consumir a API no frontend:
 Docs/Elysia - Schema e Eden.md

EM CONSUMO PELO REACT:
 Docs/Elysia.md § 8 + Docs/Elysia - Schema e Eden.md § 7
 (§ 7 é Eden, queryFn/mutationFn e envelope paginado.
 § 6 é OpenAPI — só carregue se a tarefa for documentação.)

NUNCA: todos os satélites de uma vez
```

### Como citar

Achados de revisão citam o ID da regra e o satélite, não parafraseiam:

> `ELYSIA-LIFE-02` — `derive` usado para resolver a sessão do usuário. Roda antes da validação; use `resolve`.
> Ver [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md).

### Invariantes que a skill deve fazer valer

1. **Verificar antes de afirmar.** Se uma API não está na § 4, ela não foi verificada nesta doc. Consulte elysiajs.com e atualize a nota — não invente assinatura.
2. **A fonte vence.** Divergência entre esta nota e elysiajs.com é bug desta nota.
3. **Encadeamento antes de estilo.** Nenhuma preferência de formatação justifica quebrar o chaining (`ELYSIA-APP-01`).
4. **Escopo é a primeira hipótese.** Diante de "o hook não roda", cheque escopo e ordem antes de qualquer outra coisa (§ 5).
5. **Uma declaração de schema.** Qualquer tipo escrito à mão para um payload já validado é regressão (`ELYSIA-TYPE-01`).
6. **Preferir a ponte.** Quando a § 8 indica que o stack resolve o problema, use o stack.

### Ao criar uma nova skill de Elysia

Derive-a de um satélite, não desta nota inteira: uma skill focada em autenticação carrega [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) + § 2 + § 6; uma skill de contrato de API carrega [Elysia - Schema e Eden](elysia-schema-e-eden.md) + § 8. Registre no início da skill qual satélite é a fonte, para que a atualização da doc propague.

---

## 8. Pontes com o stack

O stack do vault é [React.js](react-js.md) + [TanStack Router](tanstack-router.md) + [TanStack Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) + `TypeScript` + Zod. Elysia entra como servidor, e a ponte tem um nome: **Eden**.

| Problema | Primitiva crua | O que usar no stack |
| --- | --- | --- |
| Tipar a resposta da API no frontend | `interface` escrita à mão | `export type App = typeof app` + Eden Treaty |
| Validar payload na fronteira | checagem manual | schema `t` (ou Zod via Standard Schema) — |
| Documentar a API | manter YAML separado | `@elysia/openapi` gera de `t` — |
| Buscar dado no componente | `fetch` + `useEffect` | `queryFn` chamando Eden — |
| Propagar erro tipado por status | `any` no `catch` | `{ error }` do Eden com `error.status` narrowing |
| Cancelar request em voo | manual | `fetch: { signal }` do Eden — |
| Paginar uma listagem | devolver o array cru | envelope `{ itens, total, hasMore }` no `response` (`ELYSIA-TYPE-13`) — [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 7 |
| Mostrar erro de domínio no formulário | `catch` genérico + toast | `error.status` do Eden na `useMutation` — [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 7 |

### O tipo sai do servidor sem gerar código

```ts
// server.ts
import { Elysia, t } from 'elysia'
import { openapi } from '@elysia/openapi'

const app = new Elysia
.use(openapi)
.get('/pedidos/:id', ({ params: { id }, status }) => {
 const pedido = repositorio.buscar(id)
 if (!pedido) return status(404, { erro: 'Pedido não encontrado' })
 return pedido
 }, {
 params: t.Object({ id: t.Numeric }),
 response: {
 200: t.Object({ id: t.Number, total: t.Number, cliente: t.String }),
 404: t.Object({ erro: t.String })
 }
 })
.listen(3000)

export type App = typeof app // única coisa que o frontend importa
```

```ts
// client.ts (frontend)
import { treaty } from '@elysia/eden'
import type { App } from '../server/server' // import de TIPO — nada vai para o bundle

// `parseDate: false` é obrigatório se este cliente alimenta o cache do
// TanStack Query — ELYSIA-TYPE-10. A armadilha está explicada abaixo.
export const api = treaty<App>('localhost:3000', { parseDate: false })
```

Não há build step, não há geração de código, não há schema duplicado. É a mesma promessa do tRPC, com a diferença de que o mesmo schema também virou validação em runtime e documentação OpenAPI.

### A forma do retorno do Eden

Verificado nos tipos de `@elysia/eden` 1.4.10. Cada chamada devolve uma **união discriminada**:

```ts
| { data: T, error: null, response: Response, status: number, headers }
| { data: null, error: { status: C, value: V }, response: Response, status: number, headers }
```

Três consequências que decidem código:

1. **`data` é `null` sempre que o status for >= 300.** Sem checar `error`, o tipo de `data` é `T | null` e o TypeScript vai reclamar — corretamente.
2. **`error` não é um `Error`.** É `{ status, value }`, onde `status` é o código literal e `value` é o corpo tipado *daquele status*. É o que permite o `switch` com narrowing por status.
3. **Eden não lança por padrão.** `throwHttpError` tem default `false`, e a doc confirma: *"By default, Eden will not throw an error and return as `{ error }` instead"*.

### O ponto de atrito com TanStack Query

O item 3 acima é o que quebra na integração, e quebra em silêncio. A [Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) decide sucesso ou falha pelo fato de a `queryFn` **lançar**. Uma `queryFn` que só devolve o envelope do Eden nunca lança — logo a query fica `success` com um `data.data === null` dentro, `isError` é `false`, retry não acontece, e o error boundary não vê nada.

O exemplo oficial de integração com React Query (na página de TanStack Start) é `queryFn: => getTreaty.get` — correto como demonstração mínima, insuficiente como código de produção, porque devolve o envelope e não trata erro. A forma correta desfaz o envelope na fronteira:

```ts
// api/pedidos.ts — a queryFn desembrulha e lança. Uma vez, num lugar só.
import { queryOptions } from '@tanstack/react-query'
import { api } from './client'

export const pedidoOptions = (id: number) =>
 queryOptions({
 queryKey: ['pedidos', 'detalhe', id] as const, // o nível de escopo não é decorativo
 queryFn: async ({ signal }) => {
 const { data, error } = await api.pedidos({ id }).get({ fetch: { signal } })
 if (error) throw error // sem isto a query "tem sucesso" com data: null
 return data // tipo estreitado: sem null
 },
 staleTime: 60_000 // TSQ-CACHE-01
 })
```

```tsx
function Pedido({ id }: { id: number }) {
 const { data, error } = useQuery(pedidoOptions(id))
 // `error` aqui é o { status, value } do Eden — narrowing por status funciona
 if (error && error.status === 404) return <NaoEncontrado />
 return <Total valor={data!.total} />
}
```

Alternativa: `treaty<App>(url, { throwHttpError: true })` faz o Eden lançar sozinho. É menos verboso, mas você perde o retorno `{ error }` tipado em todos os pontos de chamada, inclusive nos que preferem tratar sem exceção. Escolha uma política e aplique no cliente inteiro.

> **`queryKey` não vem do Eden.** O Eden dá o tipo e a chamada; a chave de cache continua sendo decisão sua e do domínio. Não derive `queryKey` do path automaticamente — [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) trata a identidade da key como contrato, e ela precisa casar com o que as mutations invalidam ([TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md)).
>
> **A forma da key é `[recurso, escopo, parâmetro]`** — `['pedidos', 'detalhe', id]` e `['pedidos', 'lista', { pagina }]`, seguindo a convenção de [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md). O nível de escopo é o que permite invalidar só as listas (`{ queryKey: ['pedidos', 'lista'] }`) sem derrubar cada detalhe já carregado. Uma key `['pedidos', id]` colide com esse prefixo e transforma toda invalidação em invalidação total. As notas desta estrutura usam essa forma em todos os exemplos; se você encontrar uma que não usa, é bug desta doc.

### `parseDate: true` — a armadilha silenciosa do cache

Eden Treaty tem `parseDate` com **default `true`**: ele converte strings de data da resposta em objetos `Date`. Isso é conveniente e colide diretamente com `TSQ-CACHE-04` de [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md): structural sharing só funciona com dado compatível com JSON, e um `Date` parece novo a cada refetch. O efeito é re-render de tudo que consome a query, mesmo quando nada mudou.

Se o dado entra no cache da Query, passe `parseDate: false` e converta no `select` ou no componente. É `ELYSIA-TYPE-10`, e é por isso que o `treaty<App>` do exemplo acima já nasce com a opção — um cliente Eden construído sem ela, num app que usa TanStack Query, é violação mesmo que nada quebre visivelmente.

### Eden Treaty × Eden Fetch

| | `treaty` | `edenFetch` |
| --- | --- | --- |
| Sintaxe | `api.pedidos({ id }).get` | `fetch('/pedidos/:id', { params: { id } })` |
| Custo de tipos | mapeia todas as rotas de uma vez | resolve por rota, sob demanda |
| Recomendação da doc | **padrão** | acima de ~500 rotas consumidas num só frontend |

A doc é direta: *"Unlike Elysia < 1.0, Eden Fetch is not faster than Eden Treaty anymore"* — a escolha hoje é performance do **TypeScript**, não do runtime. `edenTreaty` (minúsculo, "Treaty 1") é **legado**; a doc recomenda `treaty` para projeto novo.

### Onde a responsabilidade muda de dono

- **Do servidor:** o schema, a validação, o status HTTP, o formato do erro. O `response` schema é o contrato —.
- **Do cache de cliente:** `queryKey`, `staleTime`, invalidação, otimismo. Nada disso o Eden sabe nem deve saber.
- **Nunca duplicado:** o formato do payload. Se existe um `t.Object` no servidor e uma `interface` no frontend descrevendo a mesma coisa, uma das duas vai apodrecer.

### E o Zod?

Elysia 1.4 aceita Zod via Standard Schema, então a pergunta não é "posso" — é "onde". Resposta calibrada, com os trade-offs verificados, em [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 2. O resumo: `t` na fronteira HTTP (coerção de query/params, validação de arquivo por magic number, OpenAPI sem configuração extra), Zod onde o schema já é compartilhado com o frontend ou com estabelecido — sabendo que com Zod o OpenAPI exige `mapJsonSchema: { zod: z.toJSONSchema }` e a coerção passa a ser sua (`z.coerce.number`).

---

## Relacionados

- [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) · [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) · [Elysia - Schema e Eden](elysia-schema-e-eden.md)
- [Bun](bun.md) · [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Bun - Runtime e APIs](bun-runtime-e-apis.md) · [Bun - Testes](bun-testes.md)
- [React.js](react-js.md) · [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Router](tanstack-router.md) · `TypeScript`
- · ·
- · · ·
- `Node.js` · · `Nest.js` — as alternativas que Elysia substitui neste stack

## Fontes consultadas

Verificadas em **2026-08-15**:

- [At a glance](https://elysiajs.com/at-glance.html) · [Key Concept](https://elysiajs.com/key-concept.html) · [Quick Start](https://elysiajs.com/quick-start.html)
- [Route](https://elysiajs.com/essential/route.html) · [Handler](https://elysiajs.com/essential/handler.html) · [Lifecycle](https://elysiajs.com/essential/life-cycle.html) · [Plugin](https://elysiajs.com/essential/plugin.html) · [Validation](https://elysiajs.com/essential/validation.html) · [Best Practice](https://elysiajs.com/essential/best-practice.html)
- [Config](https://elysiajs.com/patterns/configuration.html) · [Error Handling](https://elysiajs.com/patterns/error-handling.html) · [Extend Context](https://elysiajs.com/patterns/extends-context.html) · [Macro](https://elysiajs.com/patterns/macro.html) · [TypeBox](https://elysiajs.com/patterns/typebox.html) · [OpenAPI](https://elysiajs.com/patterns/openapi.html) · [Cookie](https://elysiajs.com/patterns/cookie.html) · [WebSocket](https://elysiajs.com/patterns/websocket.html) · [Unit Test](https://elysiajs.com/patterns/unit-test.html)
- [Eden Overview](https://elysiajs.com/eden/overview.html) · [Eden Treaty](https://elysiajs.com/eden/treaty/overview.html) · [Response](https://elysiajs.com/eden/treaty/response.html) · [Config](https://elysiajs.com/eden/treaty/config.html) · [Eden Fetch](https://elysiajs.com/eden/fetch.html) · [Legacy](https://elysiajs.com/eden/treaty/legacy.html)
- [Plugins Overview](https://elysiajs.com/plugins/overview.html) · [OpenAPI](https://elysiajs.com/plugins/openapi.html) · [Swagger](https://elysiajs.com/plugins/swagger.html) · [CORS](https://elysiajs.com/plugins/cors.html) · [JWT](https://elysiajs.com/plugins/jwt.html) · [Static](https://elysiajs.com/plugins/static.html) · [OpenTelemetry](https://elysiajs.com/plugins/opentelemetry.html)
- [Node.js](https://elysiajs.com/integrations/node.html) · [Deno](https://elysiajs.com/integrations/deno.html) · [Cloudflare Worker](https://elysiajs.com/integrations/cloudflare-worker.html) · [TanStack Start](https://elysiajs.com/integrations/tanstack-start.html)
- `elysia@1.4.29` e `@elysia/eden@1.4.10` — declarações `.d.ts` do pacote publicado (`index.d.ts`, `context.d.ts`, `error.d.ts`, `types.d.ts`, `type-system/index.d.ts`, `treaty2/types.d.ts`)
- `elysia@1.4.29` — **código publicado**, não só os tipos: `index.js` (defaults efetivos do construtor), `error.js` (status default de cada classe de erro), `universal/env.js` (o que o export `env` resolve por runtime). Onde o código e a doc divergem, as notas abaixo registram os dois.

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **`error` foi renomeado para `status` e não existe mais.** Não está entre os exports de `elysia@1.4.29` nem no tipo `Context`. Exemplos com `error` ainda aparecem em páginas da doc oficial (Lifecycle § Local Error, JWT) — são resíduo, não API viva.
- **Os plugins existem em dois escopos npm simultâneos.** `@elysia/*` (usado pela doc atual, versões mais recentes) e `@elysiajs/*` (legado, ainda publicado). `@elysia/openapi` e `@elysiajs/openapi` estão ambos em 1.4.15; `@elysia/eden` está em 1.4.10 contra 1.4.9 do `@elysiajs/eden`.
- **`@elysiajs/swagger` está descontinuado**, com aviso explícito na própria página: *"Swagger plugin is deprecated and is no longer maintained"*. Está travado em 1.3.1 enquanto o resto do ecossistema está em 1.4.x.
- **`context.response` em hooks está deprecado em favor de `context.responseValue`.** Os `.d.ts` marcam `response` com `@deprecated use context.responseValue instead` em `AfterHandler`, `MapResponse` e `AfterResponseHandler`. A doc oficial usa os dois nomes em páginas diferentes.
- **Elysia suporta Zod, Valibot, ArkType, Effect Schema, Yup e Joi** via Standard Schema, e schemas de bibliotecas diferentes podem coexistir no mesmo handler. Isso contraria a suposição corrente de que Elysia obriga TypeBox.
- **Eden Treaty não lança em erro HTTP por padrão** (`throwHttpError: false`), e **converte strings de data em `Date` por padrão** (`parseDate: true`). As duas defaults têm consequência direta na integração com TanStack Query — § 8.
- **`.as` só aceita `'scoped'` e `'global'`.** Não há `as('local')` — os `.d.ts` têm exatamente duas sobrecargas. `local` é o default e não se "desce" para ele.
- **A página de Config diz que `aot` tem default `false`, e o pacote publicado diz `true`.** O construtor de `elysia@1.4.29` (`index.js`) monta a config com `aot: env.ELYSIA_AOT !== 'false'` — ou seja, ligado por padrão, e desligável pela variável de ambiente `ELYSIA_AOT=false`. A página de Cloudflare Worker corrobora o pacote: se o default fosse `false`, não haveria por que a doc dizer que "antes era preciso passar `aot: false`". **Trate o default como `true`.** A anotação `@default false` da página de Config é o que cai, e é a única divergência conhecida entre doc e pacote nesta estrutura.
- **`normalize` tem default `true`**: propriedades fora do schema são removidas silenciosamente na entrada e na saída. Com `normalize: false` viram erro. Confirmado nos dois lugares — página de Config e `index.js`.
- **O status default de erro de validação é 422**, e nenhuma página da doc o declara. `ValidationError.status = 422` em `error.js`. Um app **sem `onError`** já responde 422 a payload inválido; o reflexo de esperar 400 vem de outros frameworks. Tabela por classe de erro em [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) § 5.
- **O `PreContext` de `onRequest` tem `status`, `redirect` e `server`**, além de `request`, `set`, `store` e decorators. A página de Lifecycle lista só os quatro primeiros. A ausência de `status` numa enumeração de segunda mão é o que faz alguém montar uma `Response` na mão para barrar um request. Enumeração canônica em [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 2.
- **`env` de `elysia` não cobre Cloudflare Worker.** É `Bun.env` no Bun, `process.env` fora dele, e `{}` onde nenhum existe. Bindings de Worker vêm de `cloudflare:workers` — dois exports chamados `env`, coisas diferentes.
- **Em `NODE_ENV=production`, detalhes de erro de validação são omitidos por padrão** — comportamento deliberado para não vazar a forma do schema. `allowUnsafeValidationDetails: true` reverte.
- **`edenTreaty` (Treaty 1) é legado**; `treaty` (Treaty 2) é a API atual. Os dois convivem no mesmo pacote, o que faz exemplo antigo compilar sem aviso.
