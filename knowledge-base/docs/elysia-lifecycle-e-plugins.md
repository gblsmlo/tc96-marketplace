---
Link: https://elysiajs.com/essential/plugin.html
tags:
 - elysia
 - plugins
 - agent-context
source: "Documentação oficial — https://elysiajs.com/"
verificado-em: 2026-08-15
---
# Elysia - Lifecycle e Plugins

> A ordem completa do lifecycle e o que cada hook pode fazer · `state` × `decorate` × `derive` × `resolve` · `macro` · plugin como instância e `use` · deduplicação por `name`/`seed` · **escopo `local`/`scoped`/`global` e `as`** · `guard` · plugins oficiais de produção.
>
> **Não cobre:** rotas, contexto e respostas ([Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md)) · schema e Eden ([Elysia - Schema e Eden](elysia-schema-e-eden.md)) · o runtime por baixo ([Bun - Runtime e APIs](bun-runtime-e-apis.md)).

Entrada: [Elysia](elysia.md) · Base normativa: [Elysia](elysia.md) § 6

---

## 1. Conceito: escopo é a única coisa que decide se um plugin afeta uma rota — e o default é o mais restritivo

Em quase todo framework de servidor, registrar um middleware no app significa que ele roda para tudo. Em Elysia, não. Um hook registrado numa instância vale para **aquela instância e seus descendentes**, e para mais ninguém — nem para quem fez `.use` dela.

A doc escolheu uma analogia exata:

> "**Elysia isolate lifecycle by default** unless explicitly stated. This is similar to **export** in JavaScript, where you need to export the function to make it available outside the module."

O problema é que a falha é **silenciosa e invertida em relação à intuição**: você escreve um plugin de autenticação, aplica no app, e as rotas do app ficam desprotegidas. Nada quebra. Nenhum tipo reclama. Os testes do plugin passam, porque as rotas *dele* estão protegidas.

```ts
import { Elysia } from 'elysia'

const perfil = new Elysia
.onBeforeHandle(({ cookie }) => {
 // ⚠️ DEFEITO 2: `throw new Error` não é um erro de domínio. Elysia classifica
 // como UNKNOWN e responde 500 — não 401 — e o Eden não vê erro tipado.
 // O certo é `return status(401, { erro: 'Não autenticado' })` — ELYSIA-CORE-03.
 if (!sessaoValida(cookie)) throw new Error('não autenticado')
 })
.get('/perfil', => carregarPerfil)

const app = new Elysia
.use(perfil)
 // ⚠️ DEFEITO 1: NÃO tem checagem de sessão. Rota aberta. Nenhum aviso.
 // O hook acima é `local`: protege as rotas de `perfil` e mais nada.
.patch('/perfil/renomear', ({ body }) => renomear(body))
```

**São dois defeitos, e só um é de escopo.** O de escopo (`ELYSIA-LIFE-01`) deixa a rota do consumidor aberta; o de sinalização (`ELYSIA-CORE-03`) faz a rota *protegida* responder 500 em vez de 401 quando a sessão é inválida. Corrigir um sem o outro deixa o bloco errado. Esta nota existe em grande medida por causa desse bloco. A correção completa está em § 5.

Há uma segunda regra de alcance, ortogonal ao escopo e igualmente silenciosa: **evento só se aplica a rota registrada depois dele**. As duas se combinam, e diante de "meu hook não roda" as duas precisam ser checadas, nesta ordem: primeiro ordem, depois escopo.

---

## 2. A ordem do lifecycle

```
 request
 │
 ┌────▼──────────┐ onRequest PreContext apenas. GLOBAL (não respeita ordem
 │ │ de rota). Retorno curto-circuita tudo.
 ├───────────────┤ onParse preenche body para content-type não coberto
 ├───────────────┤ onTransform muta o contexto para passar na validação
 │ │ + derive acrescenta propriedade — MESMA fila do transform
 ├═══════════════┤ ►► VALIDAÇÃO do body/query/params/headers/cookie
 ├───────────────┤ onBeforeHandle autorização. Retorno != undefined PULA o handler.
 │ │ + resolve acrescenta propriedade — MESMA fila do beforeHandle
 ├───────────────┤ ►► HANDLER
 ├───────────────┤ onAfterHandle lê responseValue. Retornar NÃO pula os seguintes.
 ├───────────────┤ mapResponse produz Response. Retornar PULA os seguintes.
 └────┬──────────┘
 │ ►► resposta enviada
 ┌────▼──────────┐ onAfterResponse logging e analytics
 └───────────────┘
 onError intercepta erro lançado em QUALQUER fase acima
```

O que cada um pode e não pode:

| Hook | Vê | Pode | Não pode |
| --- | --- | --- | --- |
| `onRequest` | `request`, `set`, `store`, `status`, `redirect`, `server` e decorators | rate limit, cache, bloqueio por IP, header global, curto-circuitar tipado com `status(...)` | ler `body`, `query`, `params`, `cookie`, ou qualquer `derive` |
| `onParse` | contexto + `contentType` | devolver o body parseado | assumir que roda: se um parser anterior preencheu, para |
| `onTransform` | contexto cru | mutar o contexto | confiar no tipo — nada foi validado |
| `derive` | contexto cru | acrescentar propriedades | confiar no tipo do que leu |
| `onBeforeHandle` | contexto **validado** | autorizar, curto-circuitar | mudar o que já foi validado sem consequência |
| `resolve` | contexto **validado** | acrescentar propriedades tipadas | ser usado em hook local (só em `guard`, instância ou macro) |
| `onAfterHandle` | `responseValue` | transformar o retorno, setar header por tipo | interromper os `afterHandle` seguintes |
| `mapResponse` | `responseValue` | devolver uma `Response` | contar que roda, se um `mapResponse` anterior já retornou |
| `onError` | `error`, `code` | formatar, logar, responder | capturar `return status(...)` — só captura o que foi lançado |
| `onAfterResponse` | `responseValue`, `set` | logar, medir | alterar a resposta — já foi |

### O `PreContext` de `onRequest` — enumeração canônica

Esta é a enumeração que as três notas de Elysia devem repetir. Extraída de `PreContext` em `context.d.ts` de `elysia@1.4.29`, que é a fonte, não a página de Lifecycle (a página lista só `request`, `set`, `store` e decorators, e está incompleta):

| Propriedade | Observação |
| --- | --- |
| `request` | o `Request` Web Standard — é a única forma de ler qualquer coisa do corpo aqui |
| `set` | `{ headers, status?, redirect? }` da resposta |
| `store` | estado global da instância, criado por `.state` |
| `status` | **a função `status(code, valor)`** — é o que permite curto-circuitar com status tipado |
| `redirect` | função de redirect |
| `server` | `Server \| null` (**Bun only**) |
| decorators | tudo que `.decorate` acrescentou |

O item que mais falta em enumeração de segunda mão é `status`. Sem ele a única saída de um `onRequest` que quer barrar o request é montar uma `Response` na mão; com ele, `return status(429, { erro: 'Limite excedido' })` curto-circuita e é o mesmo valor tipado do resto do lifecycle.

Não estão no `PreContext`, porque ainda não existem quando `onRequest` roda: `body`, `query`, `params`, `headers`, `cookie`, `path`, `route`, `responseValue`, e qualquer `derive`/`resolve`.

Dois detalhes de fila que a doc verifica com exemplos executáveis: `onTransform` e `derive` compartilham a mesma fila (roda na ordem de registro, não "todos os transform depois todos os derive"), e o mesmo vale para `onBeforeHandle` e `resolve`.

Além do lifecycle de request existem `onStart` e `onStop`, que são do **servidor** — sobem e descem uma vez, não por requisição.

| ID | Regra |
| --- | --- |
| `ELYSIA-LIFE-04` | `onRequest` **NEVER** é usado para lógica que precise de `body`, `query`, `params` ou `cookie` — o `PreContext` não os contém. |

---

## 3. `state` × `decorate` × `derive` × `resolve`

Quatro APIs para "colocar algo no contexto", separadas por duas perguntas: **quando** o valor é calculado, e **se** o dado de entrada já foi validado.

| | `state` | `decorate` | `derive` | `resolve` |
| --- | --- | --- | --- | --- |
| Quando roda | uma vez, no boot | uma vez, no boot | a cada request | a cada request |
| Fase | — | — | `transform` (antes da validação) | `beforeHandle` (depois da validação) |
| Onde lê | `ctx.store.x` | `ctx.x` | `ctx.x` | `ctx.x` |
| Compartilhado entre requests | **sim** | **sim** | não | não |
| Vê `headers`/`body`/`query` | não | não | sim, **não validados** | sim, **validados e tipados** |
| Para que serve | contador, flag mutável | classe, singleton, conexão, logger | requestId, IP, timing | sessão, usuário, permissão |
| Mutar | sim, é o propósito | **não** — a doc diz `SHOULD NOT` | n/a | n/a |

A distinção que mais gera bug é a última coluna contra a penúltima. A doc não é ambígua:

> "You might want to use [resolve] instead of derive in most cases. Resolve is similar to derive but execute after validation. This makes resolve more secure as we can validate the incoming data before using it to derive new properties."

**Se o valor decide acesso, é `resolve`.** `derive` roda antes da validação; o que ele lê ainda não passou por schema nenhum, e a própria doc marca a página com o aviso *"Derive doesn't handle type integrity"*.

```ts
import { Elysia, t } from 'elysia'

const contexto = new Elysia
 // barato, não decide nada: derive serve
.derive(({ server, request }) => ({
 ip: server?.requestIP(request)?.address,
 recebidoEm: Date.now
 }))

const auth = new Elysia({ name: 'auth' })
.guard({
 headers: t.Object({
 authorization: t.TemplateLiteral('Bearer ${string}')
 })
 })
 // decide acesso: resolve, depois da validação. `authorization` é string garantida.
.resolve(({ headers: { authorization }, status }) => {
 const usuario = verificarToken(authorization.slice(7))
 if (!usuario) return status(401, { erro: 'Token inválido' })
 return { usuario }
 })
.get('/eu', ({ usuario }) => usuario) // usuario é tipado
```

Note que tanto `derive` quanto `resolve` podem **abortar** devolvendo `status(...)`: são hooks de lifecycle, e o retorno tem o mesmo efeito de curto-circuito. É o padrão para autenticação —.

### A armadilha do `store`

`store` é um objeto mutável compartilhado. Desestruturar um primitivo dele quebra a referência:

```ts
new Elysia
.state('contador', 0)
.get('/inc', ({ store }) => store.contador++) // ✅ muta o store
.get('/errado', ({ store: { contador } }) => contador) // ❌ cópia, sempre 0
```

`state` aceita também remapeamento — `.state(({ velho,...resto }) => ({...resto, novo: 1 }))` — e a doc avisa que o objeto devolvido **substitui** o store, removendo o que não estiver nele.

| ID | Regra |
| --- | --- |
| `ELYSIA-LIFE-02` | Decisão de autenticação ou autorização **NEVER** usa `derive` — **MUST** usar `resolve` ou `macro.resolve`, que rodam depois da validação. |
| `ELYSIA-LIFE-05` | Valor de `decorate` **NEVER** é mutado — para estado mutável use `state`. |
| `ELYSIA-LIFE-06` | Primitivo do `store` **NEVER** é desestruturado no parâmetro do handler — a referência se perde e a leitura fica congelada. |

---

## 4. Plugin é uma instância, e `use` é a única forma de compor

Não existe tipo `Plugin` em Elysia. Um plugin é uma instância de `Elysia`, que poderia rodar sozinha:

```ts
// auth/index.ts
import { Elysia } from 'elysia'
import { Auth } from './service'

export const auth = new Elysia({ name: 'auth', prefix: '/auth' })
.post('/entrar', ({ body, cookie: { sessao } }) => Auth.entrar(body, sessao), {
 body: AuthModel.entrarBody,
 response: { 200: AuthModel.entrarOk, 400: AuthModel.entrarInvalido }
 })

// index.ts
new Elysia.use(auth).use(pedidos).use(usuarios).listen(3000)
```

`use` aceita instância, função `(app) => app`, plugin assíncrono e `import('./plugin')` (lazy — o módulo registra depois do start, e `await app.modules` espera por ele).

A doc recomenda **instância** em vez de callback funcional, com a razão explicitada: callbacks *"make encapsulation and scope harder to handle correctly"*. Sobre custo, ela é direta: *"Elysia can create 10k instances in a matter of milliseconds"* — não é decisão de performance.

### Dependência é explícita

Aquilo que um plugin `decorate`/`state`/`model` **é** herdado por quem faz `.use` — mas só depois do `use`, e você precisa declará-lo:

```ts
const auth = new Elysia.decorate('Auth', ServicoAuth)

new Elysia
.get('/a', ({ Auth }) => Auth.perfil) // ❌ erro de tipo: 'Auth' não existe aqui
.use(auth)
.get('/b', ({ Auth }) => Auth.perfil) // ✅
```

O que **não** é herdado é o lifecycle — ver § 5. É a assimetria central de Elysia: propriedades sobem, hooks não.

### Deduplicação por `name` e `seed`

Sem `name`, um plugin aplicado por três instâncias **executa três vezes**. Com `name`, Elysia deduplica.

```ts
const ip = new Elysia({ name: 'ip' }) // sem isto, roda 1× por.use
.derive({ as: 'global' }, ({ server, request }) => ({
 ip: server?.requestIP(request)
 }))

const rotasA = new Elysia.use(ip).get('/a', ({ ip }) => ip)
const rotasB = new Elysia.use(ip).get('/b', ({ ip }) => ip)
new Elysia.use(rotasA).use(rotasB) // `ip` registra uma vez só
```

`seed` complementa: quando o mesmo plugin é aplicado com configurações diferentes e cada configuração precisa contar como instância distinta, o `seed` (qualquer valor, não só string) entra no checksum.

### Global × explícito: o critério da doc

| Faça **global** | Faça **explícito** |
| --- | --- |
| plugin que não acrescenta tipos — cors, compress, helmet | plugin que acrescenta tipos — macro, state, model |
| lifecycle que nenhuma instância deve controlar — tracing, logging | lógica de negócio com que a instância interage — Auth, Database |
| documento OpenAPI único, tracer único, logger único | store/sessão, ORM, módulo de feature |

| ID | Regra |
| --- | --- |
| `ELYSIA-LIFE-03` | Plugin aplicado por mais de uma instância **MUST** declarar `name` — sem ele o lifecycle roda uma vez por aplicação. |
| `ELYSIA-LIFE-07` | Plugin novo **MUST** ser uma instância `new Elysia`, não um callback `(app) => app` — o callback dificulta encapsulamento e escopo. |

---

## 5. Escopo: `local`, `scoped`, `global` e o método `as`

A seção mais importante desta nota.

### Os três níveis

| Escopo | Alcança |
| --- | --- |
| `local` (**default**) | a instância atual e seus descendentes |
| `scoped` | **+ o pai imediato** (quem fez `.use`) |
| `global` | todas as instâncias, em qualquer nível |

A tabela oficial, com quatro instâncias aninhadas (`child` dentro de `current` dentro de `parent` dentro de `main`), e o hook registrado em `current`:

| escopo do hook | child | current | parent | main |
| --- | --- | --- | --- | --- |
| `local` | ✅ | ✅ | ❌ | ❌ |
| `scoped` | ✅ | ✅ | ✅ | ❌ |
| `global` | ✅ | ✅ | ✅ | ✅ |

Repare em `scoped`: sobe **um** nível, não todos. É a fonte da segunda rodada de confusão, depois que a pessoa descobre que `local` não sobe.

### As três formas de declarar escopo

```ts
// 1. inline — um hook só
new Elysia
.derive({ as: 'scoped' }, => ({ requestId: crypto.randomUUID }))

// 2. guard — todos os hooks e schemas de um bloco
new Elysia
.guard({
 as: 'scoped',
 response: t.String,
 beforeHandle { /*... */ }
 })
.get('/filho', 'ok')

// 3. instância — tudo que a instância registrou, no fim do encadeamento
new Elysia
.derive( => ({ oi: 'ok' }))
.get('/filho', ({ oi }) => oi)
.as('scoped') // aceita 'scoped' | 'global', não 'local'
```

`guard` com `as` é conveniente mas tem um limite verificado: *"it doesn't support `derive` and `resolve` method"*. Para elevar o escopo de um `resolve`, use `as` inline no próprio `resolve` ou `.as` na instância.

### O plugin de autenticação, corrigido

O bloco quebrado da § 1, com as duas correções possíveis:

```ts
import { Elysia, t } from 'elysia'

// ── Opção A: escopo explícito no hook ──────────────────────────
const auth = new Elysia({ name: 'auth' })
.resolve({ as: 'scoped' }, ({ cookie: { sessao }, status }) => {
 const usuario = validarSessao(sessao.value)
 if (!usuario) return status(401, { erro: 'Não autenticado' })
 return { usuario }
 })

const app = new Elysia
.use(auth)
.get('/perfil', ({ usuario }) => usuario) // ✅ protegido
.patch('/perfil/renomear', ({ usuario, body }) => renomear(usuario, body)) // ✅ protegido

// ── Opção B: macro, aplicada rota a rota ───────────────────────
const authMacro = new Elysia({ name: 'auth.macro' })
.macro({
 autenticado: {
 resolve: ({ cookie: { sessao }, status }) => {
 const usuario = validarSessao(sessao.value)
 if (!usuario) return status(401, { erro: 'Não autenticado' })
 return { usuario }
 }
 }
 })

const publicoEPrivado = new Elysia
.use(authMacro)
.get('/saude', => 'ok') // aberta, por design
.get('/perfil', ({ usuario }) => usuario, { autenticado: true }) // protegida, explícita
```

**A escolha entre A e B é de arquitetura, não de gosto.** A opção A protege tudo dali para frente e falha para o lado seguro: esquecer é ficar protegido demais. A opção B torna cada rota autodocumentada e permite misturar rotas abertas e fechadas na mesma instância, mas falha para o lado inseguro: esquecer `autenticado: true` deixa a rota aberta. Em módulo inteiramente autenticado, A; onde há mistura, B com revisão de que toda rota nova declara o flag.

### Empilhar `as('scoped')`

Como `scoped` sobe só um nível, atravessar dois exige `as('scoped')` em cada instância intermediária:

```ts
const plugin = new Elysia
.guard({ response: t.String })
.onBeforeHandle( => { console.log('chamado') })
.get('/ok', => 'ok')
.as('scoped')

const intermediaria = new Elysia
.use(plugin)
.get('/tambem-ok', => 'ok')
.as('scoped') // sem esta linha, `parent` não é afetado

const parent = new Elysia
.use(intermediaria)
.get('/agora-vale', => 'ok')
```

Se a intenção é "vale em todo lugar, ponto" — tracing, logging, CORS — use `global` e evite a corrente de `as`.

| ID | Regra |
| --- | --- |
| `ELYSIA-LIFE-01` | Hook de plugin que precisa valer para quem o consome **MUST** declarar escopo (`{ as: 'scoped' }`, `guard({ as })` ou `.as`) — o default `local` não sobe, e a falha é silenciosa. |
| `ELYSIA-LIFE-08` | Plugin de autenticação **MUST** provar em teste que uma rota da instância **consumidora** é rejeitada sem credencial — testar só as rotas do próprio plugin não detecta erro de escopo. |
| `ELYSIA-LIFE-09` | Hook transversal que deve valer em toda a árvore (tracing, logging, CORS) **MUST** usar `global`, não uma corrente de `as('scoped')`. |

---

## 6. `macro`: hook reutilizável, ativado declarativamente

`macro` transforma um conjunto de hooks e schemas numa propriedade que rotas ativam no hook local. É o mecanismo que dá autenticação legível por rota.

```ts
import { Elysia, t, status } from 'elysia'

const rbac = new Elysia({ name: 'rbac' })
.macro({
 // forma abreviada: objeto vira função que recebe boolean
 autenticado: {
 resolve: ({ cookie: { sessao } }) => {
 const usuario = validarSessao(sessao.value)
 if (!usuario) return status(401, { erro: 'Não autenticado' })
 return { usuario }
 }
 },
 // forma parametrizada
 papel: (necessario: 'admin' | 'operador') => ({
 seed: necessario, // entra no checksum de deduplicação
 beforeHandle({ usuario, status }) {
 if (usuario.papel !== necessario) return status(403, { erro: 'Sem permissão' })
 }
 })
 })

new Elysia
.use(rbac)
.delete('/pedidos/:id', ({ params: { id } }) => cancelar(id), {
 autenticado: true,
 papel: 'admin'
 })
```

Quatro pontos verificados que mudam código:

1. **Macro pode declarar schema**, e ele se acumula com o schema da rota em vez de substituí-lo — inclusive schemas de bibliotecas diferentes.
2. **`return status(...)`, não `throw`.** A doc: *"It's recommended that you `return status` instead of `throw new Error`"*, porque `throw` vira 500, e porque só o retorno preserva a inferência para Eden e para o OpenAPI gerado a partir de tipos.
3. **Macro deduplica sozinha** o lifecycle, usando o valor da propriedade como seed. `seed` explícito cobre o caso parametrizado.
4. **Limitação de TypeScript:** um macro que estende outro não infere tipo dentro do `resolve`. O contorno documentado é usar a forma nomeada `.macro('nome', {... })`. O mesmo vale para usar o schema do próprio macro num hook dele.

| ID | Regra |
| --- | --- |
| `ELYSIA-LIFE-10` | Macro **MUST** sinalizar falha com `return status(...)` — `throw` vira 500 e perde a inferência para Eden e OpenAPI. |

---

## 7. `guard`: schema e hooks para várias rotas

`guard` aplica schema e hooks às rotas seguintes da instância (ou ao bloco, na forma com callback). É equivalente a repetir o hook local em cada rota.

```ts
new Elysia
.get('/publica', => 'ok') // fora do guard
.guard({
 headers: t.Object({ authorization: t.String }),
 beforeHandle: [verificarToken, registrarAcesso] // aceita array
 })
.get('/privada-1', => 'ok') // dentro
.get('/privada-2', => 'ok') // dentro
```

Precedência de schema, verificada: *"If multiple global schemas are defined for the same property, the latest one will take precedence. If both local and global schemas are defined, the local one will take precedence."*

E o comportamento que costuma surpreender: por padrão o schema da rota **substitui** o do guard, não se soma a ele. Para somar, `schema: 'standalone'` — detalhe e exemplo em [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 4.

`group` com três argumentos (`prefixo`, `guard`, `callback`) é a forma condensada de `group` + `guard`.

---

## 8. Plugins oficiais em produção

```ts
import { Elysia, env } from 'elysia' // `env`, não `process.env` — ELYSIA-APP-09
import { cors } from '@elysia/cors'
import { openapi } from '@elysia/openapi'
import { jwt } from '@elysia/jwt'
import { opentelemetry } from '@elysia/opentelemetry'

new Elysia
.use(opentelemetry) // primeiro: instrumenta o resto
.use(cors({ origin: /\.meudominio\.com$/, credentials: true }))
.use(openapi) // documentação em /openapi
.use(jwt({ name: 'jwt', secret: env.JWT_SECRET!, exp: '7d' }))
.use(auth)
.use(pedidos)
.listen(3000)
```

| Plugin | Nota de calibração |
| --- | --- |
| `@elysia/cors` | `origin` default é `true` (= `*`) e `credentials` default é `true` — combinação permissiva demais para API autenticada. Restrinja `origin` por regex ou lista. Ver |
| `@elysia/openapi` | expõe `/openapi` (Scalar) e `/openapi/json`. `fromTypes` gera doc a partir dos tipos, sem schema em runtime. Ver |
| `@elysia/jwt` | envolve `jose`; `alg` default `HS256` (simétrico). Para chave assimétrica e rotação via JWKS, ver |
| `@elysia/static` | pasta `public`, prefixo `/public`. Não funciona no Cloudflare Worker |
| `@elysia/opentelemetry` | `record`, `getCurrentSpan`, `setAttributes`. Ver |
| `@elysia/bearer`, `@elysia/cron`, `@elysia/html`, `@elysia/server-timing` | extração de token, cron, HTML/JSX, header `Server-Timing` |

### Nomeie suas funções de hook

Detalhe pequeno com efeito grande em observabilidade: o plugin de OpenTelemetry usa o **nome da função** do hook como nome do span. Arrow function anônima vira `anonymous` no trace.

```ts
// ⚠️ span: "anonymous"
.resolve(async ({ cookie: { sessao } }) => ({ usuario: await buscarPerfil(sessao.value) }))

// ✅ span: "buscarUsuario"
.resolve(async function buscarUsuario({ cookie: { sessao }, status }) {
 const usuario = await buscarPerfil(sessao.value)
 if (!usuario) return status(401, { erro: 'Não autenticado' })
 return { usuario }
})
```

O hook é `resolve`, não `derive`, e isso não é detalhe do exemplo: resolver sessão é decisão de acesso, e `derive` roda antes da validação — `ELYSIA-LIFE-02`. O ponto sobre observabilidade vale igual nos dois hooks; a escolha de qual hook usar é anterior a ele.

Duas notas de produção verificadas: instrumentações que dependem de monkey-patching (`PgInstrumentation`) exigem que o SDK carregue **antes** do módulo instrumentado — isole em `src/instrumentation.ts` e use `preload` no `bunfig.toml`. E ao compilar com `bun build`, a biblioteca instrumentada precisa sair do bundle (`--external pg`), senão o patch não pega.

| ID | Regra |
| --- | --- |
| `ELYSIA-LIFE-11` | Hook em app instrumentada com OpenTelemetry **MUST** ser função nomeada — arrow anônima produz span `anonymous` e inutiliza o trace. |
| `ELYSIA-LIFE-12` | `cors` em API autenticada **NEVER** fica com `origin` default (`*`) — a combinação com `credentials: true` é permissiva demais. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| **Plugin de auth sem escopo declarado** | `local` é o default: o `onBeforeHandle`/`resolve` protege só as rotas do próprio plugin. As rotas de quem deu `.use` ficam **abertas**, sem erro e sem aviso de tipo | `{ as: 'scoped' }`, `.as('scoped')` ou macro por rota — `ELYSIA-LIFE-01`, e teste do lado consumidor — `ELYSIA-LIFE-08` |
| `derive` para resolver sessão ou permissão | roda em `transform`, **antes** da validação: o header/cookie lido não passou por schema, e a doc marca `derive` como sem integridade de tipo | `resolve` ou `macro.resolve` — `ELYSIA-LIFE-02` |
| Plugin sem `name`, aplicado por vários módulos | o lifecycle roda uma vez **por aplicação** — hook duplicado, log duplicado, verificação duplicada | `new Elysia({ name: 'auth' })` — `ELYSIA-LIFE-03` |
| `.use(plugin)` depois das rotas que ele deve afetar | evento só vale para rota registrada depois; as rotas acima ficam sem o hook | mover o `.use` para antes — `ELYSIA-CORE-01` |
| `as('scoped')` esperando atravessar dois níveis | `scoped` sobe **um** nível; a instância intermediária precisa do seu próprio `as`, ou nada chega ao topo | encadear `as('scoped')` em cada nível, ou usar `global` — `ELYSIA-LIFE-09` |
| Macro que faz `throw new Error` ao negar acesso | vira `500 Internal Server Error` em vez de 401/403, e o Eden não vê o erro tipado | `return status(401,...)` — `ELYSIA-LIFE-10` |
| `decorate` de objeto que é mutado a cada request | `decorate` é compartilhado entre requests: a mutação vaza de um usuário para outro | `state` para mutável, `resolve` para valor por request — `ELYSIA-LIFE-05` |
| `({ store: { contador } }) => contador` | desestruturar primitivo do store copia o valor e perde a referência — a leitura fica congelada no inicial | `({ store }) => store.contador` — `ELYSIA-LIFE-06` |
| Lógica que lê `body` dentro de `onRequest` | `PreContext` não tem `body`, `query`, `params` nem `cookie` — ainda não foram parseados | `onParse`, `onTransform` ou `onBeforeHandle` — `ELYSIA-LIFE-04` |

---

## Checklist de revisão

- [ ] Todo hook de plugin que precisa afetar o consumidor declara escopo? → `ELYSIA-LIFE-01`
- [ ] Nenhuma decisão de acesso usa `derive`? → `ELYSIA-LIFE-02`
- [ ] Todo plugin reaproveitado tem `name`? → `ELYSIA-LIFE-03`
- [ ] Nenhum `onRequest` depende de `body`/`query`/`params`/`cookie`? → `ELYSIA-LIFE-04`
- [ ] Nenhum valor de `decorate` é mutado? → `ELYSIA-LIFE-05`
- [ ] Nenhum primitivo do `store` é desestruturado? → `ELYSIA-LIFE-06`
- [ ] Plugins novos são instâncias, não callbacks `(app) => app`? → `ELYSIA-LIFE-07`
- [ ] Existe teste que prova rejeição numa rota da instância **consumidora** do plugin de auth? → `ELYSIA-LIFE-08`
- [ ] Hooks transversais usam `global` em vez de corrente de `as('scoped')`? → `ELYSIA-LIFE-09`
- [ ] Macros negam acesso com `return status`, nunca `throw`? → `ELYSIA-LIFE-10`
- [ ] Hooks são funções nomeadas onde há OpenTelemetry? → `ELYSIA-LIFE-11`
- [ ] `cors` tem `origin` restrito? → `ELYSIA-LIFE-12`

---

## Relacionados

- [Elysia](elysia.md) — hub
- [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) · [Elysia - Schema e Eden](elysia-schema-e-eden.md)
- [Bun - Runtime e APIs](bun-runtime-e-apis.md) — o runtime por baixo dos plugins
- · ·
- · ·
- · `Arquivos.env não substituem secret management`

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Plugin](https://elysiajs.com/essential/plugin.html) — escopo, dependência, deduplicação, `as`
- [Lifecycle](https://elysiajs.com/essential/life-cycle.html) — ordem, hooks, filas
- [Key Concept](https://elysiajs.com/key-concept.html) — encapsulamento, ordem do código
- [Extend Context](https://elysiajs.com/patterns/extends-context.html) — `state`, `decorate`, `derive`, `resolve`
- [Macro](https://elysiajs.com/patterns/macro.html) · [Best Practice](https://elysiajs.com/essential/best-practice.html)
- [OpenTelemetry](https://elysiajs.com/patterns/opentelemetry.html) · [CORS](https://elysiajs.com/plugins/cors.html) · [JWT](https://elysiajs.com/plugins/jwt.html) · [Static](https://elysiajs.com/plugins/static.html) · [Plugins Overview](https://elysiajs.com/plugins/overview.html)
- `elysia@1.4.29` — `types.d.ts` (`LifeCycleType`, `GuardSchemaType`) e `index.d.ts` (sobrecargas de `as`)

**O que a verificação contrariou:**

- **`.as` só tem duas sobrecargas: `'scoped'` e `'global'`.** Não existe `as('local')` — `local` é o default e não há como "descer" para ele.
- **`scoped` sobe exatamente um nível.** A leitura intuitiva ("scoped = vale no escopo todo") está errada; para atravessar dois níveis é preciso `as` em cada um, ou `global`.
- **`guard` com `as` não cobre `derive` nem `resolve`** — a doc declara a limitação explicitamente. Para elevar um `resolve`, use `as` inline nele ou `.as` na instância.
- **`onTransform` e `derive` compartilham a mesma fila**, assim como `onBeforeHandle` e `resolve` — a ordem é a de registro, não por tipo de hook.
- **Retornar de `onAfterHandle` não interrompe os `afterHandle` seguintes**, ao contrário de `beforeHandle`, `parse` e `mapResponse`, que interrompem. A assimetria é declarada na fonte.
- **`onRequest` é global por natureza** e não obedece à regra de "só vale para rota registrada depois" — porque ainda não sabe qual rota vai atender.
- **A página de Lifecycle enumera o `PreContext` de forma incompleta.** Ela lista `request`, `set`, `store` e decorators; o tipo `PreContext` em `context.d.ts` de 1.4.29 tem também `status`, `redirect` e `server`. A enumeração desta nota (§ 2) vem do `.d.ts` e é a canônica das três notas de Elysia. A omissão que mais custa é `status`: é o que permite curto-circuitar um `onRequest` com status tipado em vez de montar uma `Response` na mão.
- **`env` de `elysia` não é uma solução de Cloudflare Worker.** O export é `Bun.env` no Bun, `process.env` fora dele, e `{}` onde nenhum dos dois existe (`universal/env.js` de 1.4.29). No Worker os bindings vêm de `import { env } from 'cloudflare:workers'`, como a própria página de integração mostra. O valor de `env` de `elysia` é não amarrar o código a `process`, não cobrir o Worker.
- **Macro deduplica lifecycle sozinha**, usando o valor da propriedade como seed, e Elysia limita a recursão em 16 níveis para evitar dependência circular.
- **`@elysia/cors` tem `credentials: true` e `origin: true` como defaults** — mais permissivo do que o esperado de um plugin de segurança.
