---
titulo: Backend no runtime Bun
Link: https://bun.com/docs/api/http
tags:
 - bun
 - hono
 - elysia
 - backend
 - decisao
 - agent-context
source: "Documentação oficial de Bun, Hono e Elysia — verificação registrada nas notas de cada estrutura"
verificado-em: 2026-08-15
---

# Backend no runtime Bun

> Escolher entre `Bun.serve` puro, [Hono](hono.md) e [Elysia](elysia.md) · os cinco eixos que decidem · árvore de decisão · o que os três custam para sair · por que benchmark não entra nesta decisão.
>
> **Não cobre:** a API de cada ferramenta — isso vive em [Bun - HTTP e Servidor](bun-http-e-servidor.md), [Hono](hono.md) e [Elysia](elysia.md) e seus satélites. Esta nota decide **qual abrir**.

Versões verificadas em 2026-08-15: **Bun 1.3.14** · **Hono 4.13.2** · **Elysia 1.4.29**.

---

## 1. Conceito: o que se escolhe é uma fronteira, não um framework

`Bun.serve` já entrega roteamento com parâmetros, WebSocket com pub/sub, cookies, TLS e streaming. Nenhuma das três opções existe porque falta servidor HTTP. O que se escolhe é **quanta estrutura a fronteira da aplicação carrega**, e a resposta muda três coisas de uma vez:

1. **Onde o código pode rodar** — e portanto que decisões de deploy ficam abertas depois.
2. **Se o tipo do servidor chega ao React sem ser reescrito** — o eixo mais caro de errar, porque o custo aparece meses depois, em cada endpoint novo.
3. **Quanto do contrato é declarado uma vez** — validação, tipo, documentação e cliente saem da mesma declaração, ou de quatro.

A decisão errada raramente é "escolhi o framework mais lento". É "escolhi uma fronteira que não me deixa fazer o que o produto pediu seis meses depois".

---

## 2. As três opções, uma frase cada

| Opção | O que é | Custo que impõe |
| --- | --- | --- |
| **`Bun.serve` puro** | A fronteira HTTP nativa do runtime, sem camada. Ver [Bun - HTTP e Servidor](bun-http-e-servidor.md). | Você escreve validação, composição de middleware, tratamento de erro padronizado e cliente tipado — ou vive sem eles. |
| **Hono** | Camada fina sobre `Request`/`Response` da Web Standards, portátil entre runtimes, com cliente RPC derivado do tipo do app. Ver [Hono](hono.md). | Validação é escolha sua (Zod, Valibot…). OpenAPI exige pacote à parte. A inferência exige encadeamento contínuo. |
| **Elysia** | Framework Bun-first onde uma declaração de schema produz validação, tipo, documentação OpenAPI e cliente Eden. Ver [Elysia](elysia.md). | Amarra em Bun na prática. Lifecycle e escopo de plugin são poder real e a maior fonte de bug próprio da ferramenta. |

---

## 3. Árvore de decisão

```
O serviço precisa rodar fora do Bun — Cloudflare Workers, Deno,
Node em infra existente, Lambda, edge?
├── SIM, ou é possibilidade real no horizonte do projeto
│ └── O alvo precisa só receber Request e devolver Response,
│ │ ou precisa das capacidades do host (arquivo estático,
│ │ info de conexão, upgrade de WebSocket)?
│ ├── Só Request → Response
│ │ → OS DOIS SERVEM. Elysia expõe app.fetch e roda em
│ │ Deno, Vercel, Netlify e API routes. Decida pelos
│ │ eixos seguintes, não por este. Ver § 4.1.
│ └── Precisa das capacidades do host
│ → HONO. É quem tem camada de adaptação por runtime
│ (serveStatic, getConnInfo, upgradeWebSocket por
│ adaptador — HONO-APP-08). Ver [Hono](hono.md) § 3.2.
│ Em Elysia o Cloudflare Worker é EXPERIMENTAL e é
│ justamente aí que as limitações caem: file e o
│ plugin static não funcionam por não haver filesystem.
└── NÃO. É Bun, e vai continuar sendo.
 │
 └── O frontend React consome esta API?
 ├── NÃO (worker, cron, webhook, serviço interno sem cliente próprio)
 │ └── Quantas rotas?
 │ ├── Poucas, contrato estável, sem validação complexa
 │ │ → Bun.serve PURO. Ver [Bun - HTTP e Servidor](bun-http-e-servidor.md).
 │ │ Uma dependência a menos é uma decisão legítima.
 │ └── Muitas, ou validação de entrada não trivial
 │ → HONO ou ELYSIA pelo critério abaixo
 └── SIM — e então o eixo é o contrato tipado
 │
 └── A API precisa de documentação OpenAPI publicada
 (cliente externo, time de mobile, parceiro)?
 ├── SIM → ELYSIA. O schema já é a documentação.
 │ Em Hono isso é pacote e trabalho a mais.
 └── NÃO → o que decide é o schema que você já usa:
 ├── Zod é o padrão do time e da base de código
 │ → HONO + zValidator. Ver.
 │ (Elysia aceita Zod por Standard Schema, mas
 │ aí perde o OpenAPI automático sem mapJsonSchema
 │ — ver ELYSIA-TYPE-07.)
 └── Sem preferência estabelecida
 → ELYSIA. Uma declaração cobre quatro necessidades.
```

---

## 4. Os cinco eixos que decidem

### 4.1 Onde o código roda

| | `Bun.serve` | Hono | Elysia |
| --- | --- | --- | --- |
| Bun | nativo | sim | nativo |
| Node | não | `@hono/node-server` | `@elysia/node` |
| Cloudflare Workers | não | sim | `elysia/adapter/cloudflare-worker` + `.compile` — **experimental**, com limitações declaradas |
| Deno | não | sim | `Deno.serve(app.fetch)` — suportado, sem adapter próprio |
| Vercel / Netlify / Next.js / Astro / TanStack Start | não | sim | via API route, chamando `app.fetch(request)` |
| Lambda / Fastly / Azure Functions | não | sim | não verificado |

**A diferença não é "roda × não roda" — é a forma do suporte.** Elysia roda fora do Bun mais do que a fama sugere, porque `app.fetch` é uma função Web Standards e qualquer host que aceite `Request → Response` a aceita. O que Hono tem e Elysia não é a **camada de adaptação por runtime**: helpers como `serveStatic`, `getConnInfo` e `upgradeWebSocket` existem por adaptador (`HONO-APP-08`), e é isso que faz o mesmo código servir arquivo estático no Workers e no Node. Em Elysia, as limitações declaradas do Cloudflare Worker são exatamente dessa natureza — `file` e o plugin static não funcionam por não haver filesystem.

Traduzindo para a decisão: se o alvo alternativo só precisa receber requisição e devolver resposta, os dois servem. Se ele precisa das capacidades do host, Hono é quem tem a camada pronta.

**Uma ressalva verificada que corta contra Elysia aqui.** O export `env` de `elysia`, que existe justamente para dar acesso a variável de ambiente independente de runtime, **devolve `{}` no Cloudflare Worker** — lá os bindings vêm de `import { env } from 'cloudflare:workers'`. Somado às limitações já declaradas (`file`, plugin static e OpenAPI Type Gen fora), o Worker em Elysia exige código consciente do host, que é exatamente o que a portabilidade deveria evitar. Ver [Elysia](elysia.md) § 3.

### 4.2 O contrato tipado até o React

Os dois frameworks resolvem o mesmo problema — o tipo do handler vira o tipo da chamada no componente, sem schema duplicado — e **falham do mesmo jeito na integração com TanStack Query**:

| | Hono `hc` | Elysia Eden Treaty |
| --- | --- | --- |
| Forma do retorno | `Response` do fetch | `{ data, error }` |
| Lança em status >= 400? | **não** — é "compatible with the fetch Response" | **não** — `throwHttpError` é `false` por padrão |
| Consequência numa `queryFn` ingênua | query fica `success` com o corpo de erro dentro de `data` | query fica `success` com `data: null` |
| Saída | `parseResponse`, que lança `DetailedError` | `throwHttpError: true`, ou lançar na `queryFn` |

Este é o achado mais acionável desta nota. Uma `queryFn` que só faz `res.json` (Hono) ou `.get` (Elysia) **nunca aciona o estado de erro do TanStack Query** — `isError` fica `false`, o `retry` não roda, o Error Boundary não pega. O bug some do radar porque a UI mostra um estado vazio em vez de quebrar. Ver `HONO-RPC-*` em [Hono - Validação e RPC](hono-validacao-e-rpc.md) e `ELYSIA-TYPE-08`/`ELYSIA-TYPE-09` em [Elysia - Schema e Eden](elysia-schema-e-eden.md).

**A falha é a mesma; a saída não é — e aqui Elysia leva vantagem.** Esta linha da tabela esconde a diferença que mais custa na prática:

- **Elysia** devolve `{ status, value }`, uma **união discriminada por código de status**. Um `switch (error.status)` estreita o tipo, e `value` vem tipado pelo `response[409]` que a rota declarou. O erro de domínio chega ao formulário sem trabalho extra.
- **Hono** oferece `parseResponse`, que lança um `DetailedError` genérico. Ele serve quando o erro é só "falhou" — mas **descarta a discriminação por status**, que é o que um formulário precisa. Para ter o 409 tipado é preciso não usar `parseResponse`, checar `res.status` à mão e ter escrito o handler com `return c.json(corpo, 409)` em vez de `throw new HTTPException` (`HONO-CORE-13`). O narrowing existe; só não vem pronto.

**Este eixo mudou depois da revisão de 2026-08-15.** A assimetria era maior: Hono não tinha nenhuma regra citável para a ponte, e o caminho correto não estava escrito em lugar nenhum. Hoje tem três — `HONO-CORE-13` (erro tipado é `return`, não `throw`), `HONO-RPC-13` (a `queryFn` **MUST** lançar) e `HONO-RPC-14` (o `signal` **MUST** atravessar) — contra `ELYSIA-TYPE-08/09/10` do outro lado, e [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 6.1 traz o `useMutation` completo com o erro chegando ao formulário.

O que sobra de diferença real: **Elysia dá o narrowing de graça** (o `error` já é união discriminada por status, tipada pelo `response` declarado) e **Hono exige que você o construa** (declarar status literal em cada `c.json`, e discriminar no cliente). Menos código em Elysia; mais passos que um revisor precisa conferir em Hono — e é para isso que os três IDs existem.

Consequência para a árvore do § 3: o nó do schema (Zod já estabelecido) continua apontando para Hono, e agora sem a contrapartida que antes pesava contra. Se o erro tipado por status for requisito de dezenas de rotas, Elysia ainda economiza escrita — e o custo de trocar é o OpenAPI automático se você insistir em Zod (`ELYSIA-TYPE-07`).

Duas outras diferenças reais entre eles:

- **Elysia converte strings de data em `Date` por padrão** (`parseDate: true`), o que quebra o structural sharing do cache — ver `TSQ-CACHE-04` em [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) e `ELYSIA-TYPE-10`.
- **Hono documenta um custo de tipo** em app grande, com seção própria de *known issues* e a recomendação de pré-compilar o cliente (`hcWithType`). Elysia documenta o equivalente ao sugerir Eden Fetch acima de ~500 rotas consumidas num só frontend.

Nos dois casos, os dois lados precisam de `strict: true` no `tsconfig.json` e da mesma versão do pacote. Não é recomendação — é requisito documentado.

### 4.3 Validação e OpenAPI

| | Hono | Elysia |
| --- | --- | --- |
| Schema | traga o seu (`@hono/zod-validator` aceita Zod **≥ 3.25** e Zod 4 — Zod 3.0–3.24 não serve) | `t` (TypeBox) nativo, **e** Standard Schema: Zod, Valibot, ArkType, Effect, Yup, Joi |
| Validação **de saída** | **não tem.** O tipo de resposta vem só dos literais de `c.json`; nada verifica que o handler devolveu o prometido | `response` por status valida o retorno em runtime (`ELYSIA-TYPE-06`) |
| Erro de validação sem configurar nada | não responde — sem middleware, não valida nem entrada nem saída | **422**, verificado em `error.js` de 1.4.29. É um número que o contrato da sua API herda sem você escolher |
| Envelope de listagem paginada | não há regra; o exemplo devolve o array sem `total`/`hasMore`, o que torna `TSQ-PATTERN-05` insatisfazível no frontend | `ELYSIA-TYPE-13` obriga `{ itens, total, hasMore }` no `response` |
| OpenAPI | pacote à parte (`@hono/zod-openapi`) — existe, **não verificado nesta doc**, e a fonte indica que muda a forma de escrever as rotas | `@elysia/openapi`, gerado do schema, servindo Scalar por padrão |
| Armadilha própria | o erro default do `zValidator` serializa o `SafeParseError` inteiro do Zod **e entra no tipo da rota** — vira contrato público por omissão (`HONO-RPC-04`) | Standard Schema sem `mapJsonSchema` valida mas **não documenta** (`ELYSIA-TYPE-07`); e coerção de tipo não vale para `body` (`ELYSIA-TYPE-04`) |

A promessa de "uma declaração, quatro efeitos" do Elysia é real, mas ela é **do TypeBox**. Trocar `t` por Zod para reaproveitar schemas existentes preserva validação e tipo, e custa o OpenAPI automático se `mapJsonSchema` não for configurado.

### 4.4 Superfície de aprendizado e armadilha própria

Cada um cobra o aprendizado em um lugar diferente. Vale saber qual antes, porque é onde o time vai perder tempo:

- **`Bun.serve`** — quase nada de framework. A armadilha é de runtime: `idleTimeout` de 10 s que conta **durante** a resposta e derruba SSE (`BUN-HTTP-04`), e autenticação depois do `server.upgrade`, que não tem mais como recusar (`BUN-HTTP-07`).
- **Hono** — a **cadeia contínua**. `HONO-CORE-01` é o que a nota de origem chama de erro nº 1: quebrar o encadeamento (`const app = new Hono` e depois `app.get(...)` em statements separados) compila, roda e serve as rotas — e o `AppType` exportado é o app **vazio**. Não há erro no servidor; a falha aparece do outro lado, como `unknown`. Depois dele vem o onion model e a fronteira do `await next` (`HONO-MW-01`). E não presuma familiaridade por vir de Express: a nota de origem lista três divergências de hábito — não existe `res.send`, não existe `next(err)`, e extrair o handler para um controller tipado com `Context` faz o path param perder a inferência (`HONO-CORE-06`).
- **Elysia** — o **escopo de plugin**. O default é `local` e não sobe; um plugin de autenticação registrado sem escopo simplesmente não protege as rotas de quem o consome, **sem erro nenhum** (`ELYSIA-LIFE-01`). E `.as('scoped')` sobe exatamente um nível, não "o escopo todo". É a maior fonte de bug da ferramenta e é silenciosa.

### 4.5 Custo de saída, e sinal de churn

**Hono** escreve handlers que recebem e devolvem `Request`/`Response` padrão. Sair dele é reescrever roteamento e middleware, não a lógica.

**Elysia** entrega mais e amarra mais: contexto próprio, lifecycle próprio, schema próprio. Sair custa a fronteira inteira.

Vale registrar dois sinais observados na verificação de 2026-08-15, porque afetam manutenção mais do que qualquer benchmark:

- O ecossistema de plugins do Elysia está publicado em **dois escopos npm ao mesmo tempo** — `@elysia/*` (atual, usado pela doc) e `@elysiajs/*` (legado, ainda publicado, versões atrasadas). `@elysiajs/swagger` está descontinuado por aviso na própria página.
- `error` foi renomeado para `status` e **não existe mais** em 1.4, mas exemplos com `error` ainda aparecem em páginas da doc oficial. Código copiado da doc pode não compilar.

Nada disso desqualifica a ferramenta. Significa que, com Elysia, **a doc oficial não é confiável linha a linha** e a nota do vault carrega mais peso — que é exatamente para isso que ela existe.

---

### 4.6 Eixos que esta nota ainda não decide

Declarados para que a ausência não seja lida como equivalência:

- **WebSocket tipado.** Elysia tem `.ws` com schema e cliente (`EdenWS`, `subscribe`); em Hono, WebSocket está **fora do mapa da API** da doc, embora `upgradeWebSocket` apareça na matriz de runtimes e seja governado por `HONO-APP-08`. Se WebSocket é requisito, este eixo pesa e ainda não foi verificado dos dois lados.
- **Validação de saída.** Elysia valida o retorno em runtime contra o `response` por status (`ELYSIA-TYPE-06`); **Hono não tem equivalente** — o tipo que chega ao `hc` é inferido do que o handler escreve, sem checagem. Pesa quando o dado vem de fonte que você não controla.
- **OpenAPI em Hono.** `@hono/zod-openapi` existe e não foi verificado. Como o nó de OpenAPI é o que inverte a árvore do § 3, esta é a lacuna que mais pode mudar uma decisão.

---

## 5. O que não decide: benchmark

Nenhuma das notas desta estrutura reproduz número de performance, por decisão deliberada e por um motivo verificável em cada fonte:

- Os números da página *At a glance* do Elysia são de **2023, medidos em Bun 0.7.2** — apurado durante a verificação de 2026-08-15 e registrado nas notas de verificação de [Elysia](elysia.md). Não sustentam afirmação sobre a versão corrente.
- Hono não publica tabela própria: linka um repositório de benchmark de terceiro — idem, registrado em [Hono](hono.md).

Os três rodam sobre o mesmo `Bun.serve`. A diferença de throughput entre eles é irrelevante perto de uma query N+1, de um `staleTime` mal calibrado ou de um middleware de autenticação registrado depois do handler caro (`HONO-MW-10`). **Se performance for o critério declarado, meça o seu caso** — e então o número é evidência, não folclore.

---

## 6. Regras normativas

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.

| ID | Regra |
| --- | --- |
| `BACKEND-01` | A escolha de framework **MUST** ser registrada com o eixo que a decidiu (§ 4) — "é mais rápido" **NEVER** é justificativa aceita. |
| `BACKEND-02` | Serviço que pode precisar rodar fora do Bun **MUST** usar Hono; Elysia **NEVER** é escolhido para alvo edge/Workers sem confirmar as limitações declaradas como experimentais. |
| `BACKEND-03` | `queryFn`/`mutationFn` que consome cliente tipado (`hc` ou Eden) **MUST** lançar em status de erro — nenhum dos dois lança por padrão. |
| `BACKEND-04` | Um projeto **MUST** ter um único framework HTTP na fronteira; misturar Hono e Elysia no mesmo serviço **NEVER** acontece sem decisão registrada. |
| `BACKEND-05` | Plugin Elysia em código novo **MUST** vir do escopo `@elysia/*` ou ter a exceção registrada no PR — os dois escopos convivem e `@elysiajs/*` está atrasado. `@elysiajs/swagger` **NEVER**, por estar descontinuado na fonte (`ELYSIA-APP-07`). |
| `BACKEND-06` | Afirmação de performance sobre qualquer das três opções **MUST** citar medição própria e a versão medida. |

---

## 7. Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| Adotar framework para ganhar roteamento | `Bun.serve` já tem `routes` com parâmetros e métodos desde 1.2.3 — o ganho real é validação, composição e cliente tipado | Decida pelo § 4, não pelo roteamento |
| Escolher por benchmark de blog | Os números públicos são de versões antigas e cargas sintéticas | § 5 — meça o seu caso ou não use o argumento |
| Usar o cliente tipado sem tratar erro | Nem `hc` nem Eden lançam; a query fica `success` e o erro fica invisível | `BACKEND-03` |
| Adotar Elysia por causa do OpenAPI e escrever os schemas em Zod | Standard Schema sem `mapJsonSchema` valida mas não documenta — perde-se justamente o motivo da escolha | `ELYSIA-TYPE-07`, ou fique em `t` |
| Copiar exemplo da doc do Elysia com `error` | `error` não existe mais em 1.4; a doc tem resíduo | `ELYSIA-APP-02` |
| Manter os dois frameworks "até decidir" | Dobra a superfície de middleware, erro e tipo, e a decisão nunca chega | `BACKEND-04` |

---

## Relacionados

- [Bun](bun.md) — runtime, e a fronteira HTTP nativa em [Bun - HTTP e Servidor](bun-http-e-servidor.md)
- [Hono](hono.md) · [Hono - Validação e RPC](hono-validacao-e-rpc.md) — o cliente RPC e seus limites
- [Elysia](elysia.md) · [Elysia - Schema e Eden](elysia-schema-e-eden.md) — schema como fonte única e o Eden
- [React.js](react-js.md) · [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) — o outro lado do contrato
- · ·
- ·
- · `Nest.js` · `Node.js` — as opções fora do runtime Bun

## Fontes consultadas

Esta nota **não faz verificação própria**: ela sintetiza o que foi verificado nas três estruturas em 2026-08-15, e cada afirmação factual aqui tem origem rastreável na nota correspondente.

- Fronteira HTTP nativa e `idleTimeout`: [Bun - HTTP e Servidor](bun-http-e-servidor.md)
- Matriz de runtimes, `hc` e custo de tipo: [Hono](hono.md) § 3.2 e [Hono - Validação e RPC](hono-validacao-e-rpc.md)
- Escopo de plugin, Standard Schema, Eden e os dois escopos npm: [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) e [Elysia - Schema e Eden](elysia-schema-e-eden.md)
- Versões conferidas no registry npm em 2026-08-15: Bun 1.3.14 · Hono 4.13.2 · Elysia 1.4.29

**Ao atualizar:** se uma das três notas de origem mudar de versão verificada, esta nota precisa ser relida — especialmente o § 4.1 (suporte a runtime do Elysia muda rápido) e o § 4.5 (a migração de escopo npm deve terminar em algum momento).
