---
titulo: HTTP
Link: https://developer.mozilla.org/en-US/docs/Web/HTTP
tags:
  - http
  - protocolo
  - backend
  - agent-context
source: "MDN Web Docs — https://developer.mozilla.org/en-US/docs/Web/HTTP"
verificado-em: 2026-08-15
---
# HTTP — referência conduzida

> **O que esta nota é.** O ponto de entrada único para HTTP neste vault: para mim ao consultar, e para agentes de código ao gerar ou revisar servidor e cliente. Não é um resumo do MDN — é um **roteador**. Ela decide o que carregar, dá o modelo mental que faz o resto fazer sentido, e expõe regras citáveis por ID.
>
> **O que não é.** Não substitui a fonte. Em divergência, [MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP) e o RFC citado vencem, e esta nota deve ser corrigida. Também não é doc de framework: como Hono, Elysia ou `Bun.serve` implementam cada mecanismo é assunto das notas daqueles, referenciadas na § 8.

Inventário verificado em MDN e em RFC 9110 em **2026-08-15**. Ver [Fontes consultadas](#fontes-consultadas).

---

## 1. Como usar esta doc

### Para um humano

Leia a § 2 e a § 3 uma vez — elas são o que torna o resto legível. Depois use a § 4 como índice e a § 5 quando estiver entre duas opções. Os satélites são leitura sob demanda.

### Para um agente de código

Carregue nesta ordem, parando assim que tiver o suficiente:

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (§ 2, § 5, § 6) | Sempre que a tarefa envolver requisição ou resposta HTTP |
| 2 | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) · [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) | Sempre que for **desenhar ou alterar** um endpoint |
| 3 | O satélite do mecanismo tocado | Use a § 4 para descobrir qual |
| 4 | § 8 desta nota | Antes de implementar à mão qualquer coisa que o stack já resolva |
| 5 | [HTTP - Specs e RFCs](http-specs-e-rfcs.md) | Quando a pergunta for "o que a spec obriga" e não "o que se costuma fazer" |

**Regra de economia de contexto:** nunca carregue todos os satélites. Cache, CORS e negociação de conteúdo são independentes entre si — uma tarefa raramente precisa de dois.

### Convenções e vocabulário

Exemplos de protocolo aparecem como **mensagem HTTP crua**; exemplos de código são TypeScript, com domínio de pedidos e clientes.

Termos usados sem redefinição nos satélites:

| Termo | Significado nesta doc |
| --- | --- |
| **recurso** | o alvo de uma requisição, identificado por URI. HTTP não limita o que ele é — arquivo, linha de banco, função |
| **representação** | os bytes que descrevem o estado do recurso num formato transferível, mais os metadados que os descrevem. Não é o recurso |
| **representação selecionada** | a representação que a negociação de conteúdo escolheu para *esta* requisição; é sobre ela que `ETag` e requisição condicional operam |
| **origin server** | quem detém a definição do recurso e produz a resposta autoritativa |
| **intermediário** | proxy, gateway (reverse proxy) ou túnel entre o cliente e o origin server. CDN e API gateway são gateways |
| **cache compartilhado** | cache que serve mais de um usuário (CDN, proxy corporativo, cache do gateway). Oposto de cache privado (o do browser) |
| **safe** | o método tem semântica somente-leitura: o cliente não pede mudança de estado |
| **idempotente** | o efeito pretendido de N requisições idênticas é o mesmo de uma |
| **cacheável** | a resposta pode ser armazenada e reutilizada para requisições subsequentes |
| **revalidação** | perguntar ao servidor se a cópia cacheada ainda serve, sem baixar o corpo de novo |
| **preflight** | requisição `OPTIONS` que o browser envia por conta própria antes da requisição real, em CORS |

---

## 2. Modelo mental

Cinco afirmações. Quase todo erro de HTTP que um agente comete viola uma delas.

**1. HTTP é sem estado, e todo mecanismo de estado é uma camada por cima que herda esse problema.** A definição é literal em RFC 9110 § 3.3: cada mensagem *"can be understood in isolation"*, e — a consequência que se esquece — *"a server MUST NOT assume that two requests on the same connection are from the same user agent unless the connection is secured and specific to that agent"*. Sessão, token e cache são reconstruções de estado feitas com headers, e cada uma carrega a pergunta "e se esta requisição chegar sozinha, fora de ordem, ou duplicada?". É por isso que idempotência é um assunto de protocolo e não de biblioteca, e por que cookie é um mecanismo à parte ([RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md)).

**2. A semântica do método não é convenção de estilo — proxies, browsers e CDNs agem sobre ela.** Um cliente pode **repetir automaticamente** uma requisição idempotente cuja resposta se perdeu; RFC 9110 § 9.2.2 é explícito de que *"a proxy MUST NOT automatically retry non-idempotent requests"*. Um crawler faz `GET` em toda URL que encontra. Um cache guarda resposta de `GET` e de `HEAD` sem perguntar. Escrever num handler de `GET` não é feio: é entregar a alguém que você não controla a permissão de executar aquilo quantas vezes quiser. Ver [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 1.

**3. A resposta é uma representação do recurso, não o recurso.** RFC 9110 § 3.2 define representação como *"information that is intended to reflect a past, current, or desired state of a given resource"*. Um recurso pode ter várias — JSON e HTML, português e inglês, comprimida e crua — e um algoritmo escolhe uma por requisição. Essa indireção é o que torna cache e negociação de conteúdo possíveis: `ETag` identifica a **representação selecionada**, não o recurso, e é por isso que trocar de idioma ou de encoding troca o validador. Ver [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) e [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md).

**4. Header é contrato entre intermediários, não só entre cliente e servidor.** Entre o browser e o seu código há CDN, load balancer, proxy corporativo e o cache do próprio browser, todos lendo os mesmos headers. `Cache-Control` instrui um cache que você nunca viu; `Vary` diz a esse cache **quais headers do request entram na chave** dele. Omitir `Vary` quando a resposta varia por `Accept-Encoding`, `Accept-Language` ou `Origin` não produz erro no seu servidor: produz um cache compartilhado entregando a resposta de um usuário a outro. O sintoma aparece longe da causa — para quem não fez a requisição.

**5. Extensibilidade por header significa que o desconhecido é ignorado, não rejeitado.** RFC 9110 § 5.1: *"A proxy MUST forward unrecognized header fields... Other recipients SHOULD ignore unrecognized header and trailer fields."* É o que permitiu CORS, `Retry-After` e tracing distribuído existirem sem mudar a versão do protocolo. A leitura prática para quem escreve servidor: um header a mais nunca é motivo de `400`, e um header seu que o cliente não conhece nunca quebra o cliente — mas também **nunca é garantido que chegou**, porque um intermediário pode ter sido configurado para removê-lo.

> **O erro que junta as cinco.** Um `POST /pedidos` que responde `200` com `{"erro": "estoque insuficiente"}`. Sem estado no protocolo, o cliente não sabe se a chamada anterior passou; o status diz "deu certo" a todo intermediário que só lê a status line; o retry automático fica proibido porque `POST` não é idempotente; e o monitoramento conta como sucesso. Nada disso é visível na UI, que exibe a mensagem corretamente..

---

## 3. Anatomia de mensagem

Saber onde cada coisa vive é o que faz o resto da doc ser navegável. Requisição e resposta compartilham a mesma estrutura: **start line · headers · linha em branco · body**. Start line e headers formam o *head*.

### Requisição

```http
POST /pedidos HTTP/1.1
Host: api.exemplo.com
Content-Type: application/json
Content-Length: 74
Accept: application/json
Idempotency-Key: 8f14e45f-ea6a-4c1b-9a2e-3d5b7c0a1f22

{"clienteId":"c-901","itens":[{"sku":"SKU-12","quantidade":2}]}
```

A **request line** é `<método> <request-target> <protocolo>`. O request-target tem quatro formas, e três delas quase nunca aparecem em código de aplicação: *origin form* (`/pedidos?pagina=2`, a comum), *absolute form* (URL completa, para proxy), *authority form* (`host:porta`, só em `CONNECT`) e *asterisk form* (`OPTIONS * HTTP/1.1`, para o servidor inteiro).

Corpo em requisição é de `POST`, `PUT` e `PATCH`. Corpo em `GET`, `HEAD` e `DELETE` tem semântica **indefinida** — ver [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 6.

### Resposta

```http
HTTP/1.1 201 Created
Location: /pedidos/p-4471
Content-Type: application/json; charset=utf-8
ETag: "a1b2c3"
Cache-Control: no-store
Vary: Accept-Encoding

{"id":"p-4471","status":"aberto"}
```

A **status line** é `<protocolo> <status-code> <reason-phrase>`. A reason phrase é opcional e nenhum cliente deve depender dela — o número é o contrato.

### As quatro categorias de header

Confundir as categorias é o que produz `Content-Type` numa resposta `204` e `Cache-Control` num header de representação.

| Categoria | Descreve | Exemplos | Onde aparece |
| --- | --- | --- | --- |
| **Request** | contexto da requisição e como processá-la | `Host`, `Authorization`, `Accept`, `If-None-Match`, `Origin`, `Range` | só em requisição |
| **Response** | contexto da resposta e o que o cliente deve fazer depois | `Server`, `Date`, `Cache-Control`, `Location`, `Retry-After`, `WWW-Authenticate`, `Allow`, `Vary` | só em resposta |
| **Representation** | a forma dos bytes que estão no body | `Content-Type`, `Content-Language`, `Content-Encoding`, `Content-Location`, `ETag`, `Last-Modified` | requisição **e** resposta, quando há body |
| **Payload / framing** | como o corpo foi enfiado na conexão | `Content-Length`, `Transfer-Encoding`, `Content-Range` | requisição e resposta |

A distinção que mais rende: **`Content-Type` descreve o corpo desta mensagem; `Accept` descreve o que o remetente aceita de volta.** Um cliente que manda JSON e quer JSON de volta precisa dos dois, e eles não são redundantes.

### HTTP/2 e HTTP/3 não mudam nada disto

HTTP/2 troca o texto por framing binário, multiplexa streams numa conexão e comprime headers com HPACK; a start line vira pseudo-headers (`:method`, `:scheme`, `:authority`, `:path` na requisição, `:status` na resposta). **A semântica é a mesma** — método, status, headers e corpo significam exatamente o que significavam. Toda regra desta estrutura vale nas três versões. O que muda é o folclore de performance construído em cima do HTTP/1.1: ver [Notas de verificação](#notas-de-verificacao).

---

## 4. Mapa da superfície

Uma linha por mecanismo que uma tarefa pede sozinho. A coluna **Onde** diz o que carregar.

**Deliberadamente fora deste mapa:** autenticação como política (esquemas, sessão, escopo) — cobertos por [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md), [RFC 8725 - JWT Best Current Practices](rfc-8725-jwt-best-current-practices.md) e [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md); sintaxe e atributos de cookie — [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md); `CONNECT` e `TRACE`; WebSocket e SSE como protocolos; HTTP/2 e HTTP/3 como transporte; e headers de segurança (`CSP`, `HSTS`, `X-Frame-Options`). Ausência aqui significa **"não verificado nesta doc"**, não "não existe".

Todo ponteiro de seção abaixo foi verificado contra o satélite. Uma linha da § 4 que aponte para seção que não cobre o item é bug desta nota.

### Métodos e semântica

| Item | Onde |
| --- | --- |
| As três propriedades: safe · idempotente · cacheável, e qual método tem quais | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 1 |
| `GET` — recuperar representação | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 2 |
| `HEAD` — metadados sem corpo | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 5 |
| `POST` — processamento específico do recurso | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 3 |
| `PUT` — substituir a representação inteira | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 3 |
| `PATCH` — modificação parcial, e por que não é idempotente | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 3 |
| `DELETE` — e o que devolver na segunda chamada | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 4 |
| `OPTIONS`, forma asterisco e a relação com preflight | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 5 |
| `Allow` e a obrigação do `405` | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 5 |
| Corpo em `GET`, `HEAD` e `DELETE` — o que a spec diz | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 6 |
| Idempotência de desenho: chave de idempotência e retry seguro | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 7 |

### Status e redirecionamento

| Item | Onde |
| --- | --- |
| As cinco classes e o que cada uma autoriza o cliente a fazer | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 1 |
| `200` · `201` · `202` · `204` — qual sucesso | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 2 |
| A árvore de redirect: `301` · `302` · `303` · `307` · `308` | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 3 |
| `Location` e `Retry-After` | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 3 |
| `401` × `403` × `404` × `410` | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 4 |
| `400` × `415` × `422` — o eixo de validação | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 4 |
| `409` × `412` — conflito e precondição | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 4 |
| `429` e limite de taxa | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 4 |
| `500` × `502` × `503` × `504` | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 5 |

### Cache e requisições condicionais

| Item | Onde |
| --- | --- |
| `Cache-Control` e suas diretivas de request e de response | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)  § 3 |
| Cache privado × compartilhado (`private`, `public`, `s-maxage`) | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)  § 2 |
| `ETag` forte e fraco | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)  § 4 |
| `Last-Modified` e a granularidade de um segundo | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)  § 4 |
| `If-None-Match`, `If-Modified-Since`, `If-Match`, `If-Unmodified-Since` | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)  § 4 e § 5 |
| Revalidação e o ciclo `304` | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)  § 4 |
| Frescor heurístico — o que o cache faz sem `Cache-Control` | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)  § 3 |
| `Vary` e a chave do cache | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)  § 6 |
| `Age` e `Expires`, e a precedência entre eles | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)  § 3 |

### CORS

| Item | Onde |
| --- | --- |
| Origem, e por que a mesma-origem é o default | [HTTP - CORS](http-cors.md)  § 2 |
| Requisição simples × preflight `OPTIONS` | [HTTP - CORS](http-cors.md)  § 3 |
| `Access-Control-Allow-Origin` e a incompatibilidade do `*` com credenciais | [HTTP - CORS](http-cors.md)  § 4 |
| `Access-Control-Allow-Methods` / `-Headers` / `-Max-Age` | [HTTP - CORS](http-cors.md)  § 3 |
| `Access-Control-Expose-Headers` — por que o cliente não lê seu header | [HTTP - CORS](http-cors.md)  § 5 |
| O modelo de falha: o browser bloqueia a **leitura**, não necessariamente o envio | [HTTP - CORS](http-cors.md)  § 6 |
| `Vary: Origin` e o cache envenenado | [HTTP - CORS](http-cors.md)  § 4 |

### Negociação de conteúdo e range

| Item | Onde |
| --- | --- |
| `Accept`, `Accept-Language`, `Accept-Encoding` e os fatores `q` | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)  § 2 |
| `Content-Type`, media type e parâmetro `charset` | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)  § 3 |
| `Content-Encoding` e compressão | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)  § 4 |
| `Content-Language`, `Content-Location` | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)  § 3 |
| `406` e quando não emiti-lo | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)  § 3 |
| `Range`, `Accept-Ranges`, `Content-Range`, `206` e `416` | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)  § 6 |

### Specs

| Item | Onde |
| --- | --- |
| Mapa spec → o que ela rege → nota do vault | [HTTP - Specs e RFCs](http-specs-e-rfcs.md)  § 3 |
| Onde um status ou header está definido, quando a dúvida é normativa | [HTTP - Specs e RFCs](http-specs-e-rfcs.md)  § 4 |

---

## 5. Árvores de decisão

Sintoma → resposta. É aqui que servidor gerado costuma errar.

### 5.1 Qual método uso?

Decida por **semântica**, não por hábito. A primeira pergunta é a única que importa de verdade.

```
A operação muda estado no servidor?
├── NÃO → GET
│         └── precisa só dos metadados (tamanho, validador, existência)?
│             → HEAD
│         └── precisa saber quais métodos o recurso aceita? → OPTIONS
│         └── "mas os parâmetros não cabem na URL"
│             → ainda não é POST por isso. Ver § 5.1 nota, abaixo.
└── SIM
    └── Repetir a MESMA requisição N vezes deve deixar o
        recurso no MESMO estado que uma vez?
        ├── SIM
        │   ├── o corpo é a representação INTEIRA do recurso,
        │   │   e o cliente escolhe a URI → PUT
        │   └── remoção do recurso → DELETE
        └── NÃO
            ├── modificação PARCIAL de um recurso existente
            │   (o corpo é um conjunto de instruções) → PATCH
            └── processamento específico do recurso: criar sob
                URI escolhida pelo servidor, enfileirar, executar
                ação, submeter formulário → POST
```

**A pergunta que decide `PUT` × `PATCH` não é "envio tudo ou parte".** É *"o corpo é o novo estado ou é uma instrução?"*. `PUT` substitui; `PATCH` instrui. Um `PATCH` que incrementa um contador não é idempotente, e um `PUT` que envia o objeto inteiro é — mesmo que o objeto tenha um contador dentro, porque ele sobrescreve o valor em vez de somar.

> **Nota — "o payload não cabe na URL".** Isso não transforma uma leitura em escrita. Você pode usar `POST` como transporte de uma consulta grande (é o que a própria RFC 9110 § 9.3.1 sugere quando os dados não devem aparecer na URI), mas então você **perde cache, retry automático e prefetch** e precisa aceitar isso conscientemente. Não é o default; é uma troca.

### 5.2 Qual status devolvo?

```
A requisição foi processada com sucesso?
├── SIM
│   ├── criou recurso → 201 + Location
│   ├── aceitou para processar depois (fila, job) → 202
│   ├── sucesso sem nada a devolver (DELETE, PUT de update) → 204
│   └── caso geral → 200
├── NÃO, e a culpa é do cliente (4xx)
│   ├── não autenticado → 401 + WWW-Authenticate
│   ├── autenticado, sem permissão → 403
│   ├── recurso inexistente → 404
│   ├── recurso removido em definitivo → 410
│   ├── método conhecido, recurso não aceita → 405 + Allow
│   ├── sintaxe do corpo quebrada / JSON inválido → 400
│   ├── media type que o servidor não processa → 415
│   ├── sintaxe válida, regra de negócio reprovou → 422
│   ├── conflito com o estado atual → 409
│   ├── precondição (If-Match) falhou → 412
│   └── excedeu limite de taxa → 429 + Retry-After
└── NÃO, e a culpa é do servidor (5xx)
    ├── o próprio código falhou → 500
    ├── upstream devolveu resposta inválida → 502
    ├── indisponível temporariamente / manutenção → 503 + Retry-After
    └── upstream não respondeu a tempo → 504
```

Subárvore de redirect — é onde mais se erra:

```
Preciso mandar o cliente para outra URI.
├── A mudança é PERMANENTE?
│   ├── SIM
│   │   ├── e existe operação não-GET nessa URI → 308
│   │   └── só há GET (páginas, SEO) → 301
│   └── NÃO
│       ├── quero PRESERVAR método e corpo → 307
│       ├── só há GET → 302
│       └── quero DELIBERADAMENTE virar GET
│           (POST-redirect-GET, para o refresh não reenviar) → 303
└── Em todos os casos: Location é obrigatório.
```

`301` e `302` **não** garantem preservação do método: agentes trocam `POST` por `GET`, e RFC 9110 registra isso como comportamento permitido por razões históricas. `307` e `308` existem exatamente para remover essa ambiguidade. Detalhe e citações em [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 3.

### 5.3 Este recurso pode ser cacheado, e por quanto tempo?

```
A resposta contém dado específico de um usuário autenticado?
├── SIM
│   ├── e não pode nem tocar disco (token, dado sensível)
│   │   → Cache-Control: no-store
│   └── pode ficar no browser dele, nunca num cache compartilhado
│       → Cache-Control: private, max-age=<n>
└── NÃO
    └── O conteúdo tem URL versionada / hash no nome?
        ├── SIM → Cache-Control: public, max-age=31536000, immutable
        └── NÃO
            └── Muda com que frequência?
                ├── nunca durante a sessão (enums, flags)
                │   → max-age alto + ETag
                ├── de vez em quando, e servir velho é aceitável por
                │   alguns segundos → s-maxage curto + stale-while-revalidate
                └── a cada escrita → max-age=0, must-revalidate + ETag
                    (o cliente pergunta sempre; o 304 é barato)

E, em qualquer ramo: a resposta varia por header de request
(Accept, Accept-Encoding, Accept-Language, Origin)?
  → Vary com esses headers, senão o cache compartilhado
    serve a representação errada para outro cliente.
```

Diretivas, sintaxe e a mecânica do `304` em [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md). Política de frescor como decisão de produto em e.

### 5.4 Minha requisição foi bloqueada pelo browser — é CORS?

```
O erro aparece no console do browser e menciona "CORS policy"?
├── NÃO → não é CORS. É rede, TLS, DNS ou o servidor caiu.
│         Confira se a requisição saiu (aba Network / log do servidor).
└── SIM
    └── A requisição chegou ao servidor (aparece no log)?
        ├── NÃO → o preflight falhou ou nem foi respondido.
        │   ├── há um OPTIONS no log? → o handler de OPTIONS não
        │   │   devolve os Access-Control-Allow-*
        │   └── não há → a rota não trata OPTIONS
        │       (framework devolvendo 404/405 no preflight)
        └── SIM, respondeu 2xx, e ainda assim falhou
            ├── usa cookie/credencial? → Allow-Origin: * é inválido
            │   com credenciais; ecoe a origem + Allow-Credentials: true
            ├── o header que preciso ler vem undefined
            │   → falta Access-Control-Expose-Headers
            └── funciona num usuário e falha noutro, ou funciona
                depois de hard refresh → cache compartilhado sem
                Vary: Origin servindo a resposta de outra origem
```

O modelo de falha completo em [HTTP - CORS](http-cors.md), e o conceito em. **CORS não é autorização:** ele restringe o que um script de outra origem pode **ler**, e não impede o request de chegar ao servidor.

### 5.5 O cliente e o servidor discordam do formato, idioma ou encoding

```
Que status o servidor devolveu?
├── 415 → o servidor não processa o Content-Type que VOCÊ enviou.
│         Erro está no request. Confira Content-Type e charset.
├── 406 → o servidor não tem representação que satisfaça o seu Accept.
│         Frequentemente o Accept é restritivo demais no cliente.
├── 200, mas o corpo veio no formato errado
│   ├── o servidor ignora Accept e sempre devolve o mesmo
│   │   → é falha de implementação do servidor, não sua
│   └── um cache serviu a representação de outro cliente
│       → falta Vary no servidor
└── 200, mas os acentos vieram quebrados
    → charset. Content-Type: application/json é UTF-8 por
      definição do media type; text/* não é — declare
      `; charset=utf-8` explicitamente.
```

Detalhe, fatores `q` e o caso do `Range` em [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md).

---

## 6. Regras normativas

Regras citáveis por ID. Uma skill, um prompt de revisão ou um comentário de PR referencia `HTTP-CORE-02` sem repetir o texto.

**Convenção:** `MUST` / `NEVER` são normativos desta doc. Onde a spec diz `SHOULD` e esta doc diz `MUST`, é decisão do vault e está marcada em [Notas de verificação](#notas-de-verificacao).

### `HTTP-CORE-*` — invariantes do protocolo

| ID | Regra |
| --- | --- |
| `HTTP-CORE-01` | Handler **NEVER** deduz identidade ou sessão da conexão: toda requisição **MUST** carregar sua própria credencial (cookie ou `Authorization`). |
| `HTTP-CORE-02` | Handler de método safe (`GET`, `HEAD`, `OPTIONS`) **NEVER** escreve estado de domínio. |
| `HTTP-CORE-03` | Toda resposta com corpo **MUST** declarar `Content-Type`; `text/*` **MUST** incluir `charset`. |
| `HTTP-CORE-04` | Resposta cujo corpo depende de um header do request (`Accept*`, `Origin`, `Authorization`) **MUST** declarar esses headers em `Vary`. |
| `HTTP-CORE-05` | Header de request não reconhecido **NEVER** faz o servidor rejeitar a requisição. |
| `HTTP-CORE-06` | Falha **NEVER** é sinalizada por corpo dentro de uma resposta `2xx` — o status **MUST** carregar o resultado. |
| `HTTP-CORE-07` | Dado sensível (token, credencial, documento) **NEVER** trafega em query string. |
| `HTTP-CORE-08` | Leitura de header **MUST** ser case-insensitive; comparação por chave literal com maiúsculas **NEVER**. |

### 6.1 Regras críticas dos satélites

As famílias completas vivem nos satélites, mas estas viajam com o caminho mínimo — são as que mais aparecem em código gerado.

| ID | Regra | Satélite |
| --- | --- | --- |
| `HTTP-METH-02` | Cliente **NEVER** envia corpo em `GET`, `HEAD` ou `DELETE`; servidor **NEVER** define contrato que dependa desse corpo. | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) |
| `HTTP-METH-03` | `PUT` **MUST** substituir a representação inteira do recurso; endpoint que ignora campos ausentes **NEVER** se chama `PUT` — é `PATCH`. | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) |
| `HTTP-METH-08` | Cliente **NEVER** configura retry automático para `POST` ou `PATCH` sem que a API declare suporte a chave de idempotência. | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) |
| `HTTP-METH-07` | Resposta `405` **MUST** incluir `Allow` com os métodos que o recurso suporta; método não permitido em path existente **NEVER** é respondido com `404`. | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) |
| `HTTP-STATUS-02` | Erro causado pela requisição **MUST** ser `4xx` e erro causado pelo servidor **MUST** ser `5xx`; entrada inválida **NEVER** vira `500`. | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |
| `HTTP-STATUS-04` | Resposta `204` **NEVER** tem corpo. | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |
| `HTTP-STATUS-07` | Redirecionamento que precisa preservar método e corpo **MUST** ser `307` ou `308`; `301` e `302` **NEVER**. | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |
| `HTTP-STATUS-08` | Redirecionamento de um `POST` para uma página de resultado **MUST** ser `303`. | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |
| `HTTP-STATUS-10` | Resposta `401` **MUST** trazer `WWW-Authenticate`; requisição com credencial válida e permissão insuficiente **MUST** responder `403` ou `404`, **NEVER** `401`. | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |
| `HTTP-STATUS-11` | Corpo sintaticamente válido reprovado por regra de negócio **MUST** responder `422`; media type não suportado **MUST** responder `415`. Nenhum dos dois **NEVER** vira `400` genérico. | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |

| `HTTP-CACHE-01` | Toda resposta de `GET` **MUST** declarar `Cache-Control` explicitamente — a ausência entrega a política ao frescor heurístico do cache, que é implementação-dependente. | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| `HTTP-CACHE-02` | Resposta personalizada por usuário (autenticada, derivada de cookie de sessão) **MUST** conter `private` ou `no-store` no `Cache-Control`. | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| `HTTP-CACHE-03` | `no-store` **NEVER** é usado com a intenção de "sempre revalidar" — essa intenção se escreve `no-cache`. | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| `HTTP-CACHE-09` | `ETag` usado em `If-Match` ou `If-Range` **MUST** ser forte — sem o prefixo `W/`. | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| `HTTP-CACHE-10` | Resposta cujo corpo depende de algum header de request **MUST** listar esse header em `Vary`. | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| `HTTP-CACHE-12` | Recurso cujo cache o servidor precisa poder derrubar antes do prazo **MUST** usar `no-cache` ou URL versionada — não existe purge de cache intermediário no protocolo. | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| `HTTP-CORS-02` | Resposta com `Access-Control-Allow-Credentials: true` **MUST** trazer a origem concreta em `Access-Control-Allow-Origin`. | [HTTP - CORS](http-cors.md) |
| `HTTP-CORS-04` | Header de resposta que o JavaScript precisa ler cross-origin **MUST** estar em `Access-Control-Expose-Headers` — só as sete safelisted são visíveis por default. | [HTTP - CORS](http-cors.md) |
| `HTTP-CORS-05` | A resposta ao `OPTIONS` de preflight **MUST** ser 2xx sem exigir autenticação — o preflight nunca carrega credenciais. | [HTTP - CORS](http-cors.md) |
| `HTTP-CORS-08` | Autorização de rota **MUST** estar no handler — CORS **NEVER** é o mecanismo que impede a execução de uma requisição cross-origin. | [HTTP - CORS](http-cors.md) |
| `HTTP-NEG-01` | Resposta cujo conteúdo foi escolhido a partir de um header `Accept*` **MUST** declarar esse header em `Vary` — resposta comprimida **MUST** trazer no mínimo `Vary: Accept-Encoding`. | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) |
| `HTTP-NEG-03` | `Content-Encoding` **NEVER** é definido manualmente sem que o corpo tenha sido de fato comprimido naquele formato — e `Content-Length`, quando presente, **MUST** ser o tamanho comprimido. | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) |
| `HTTP-NEG-11` | `Range` fora dos limites do recurso **MUST** produzir `416` — **NEVER** `200` com o recurso inteiro. | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) |
| `HTTP-SPEC-02` | Texto do projeto **NEVER** cita RFC 7230, 7231, 7232, 7233, 7234, 7235, 7538, 7540, 7807 ou 2818 como fonte vigente — os substitutos estão na § 2. | [HTTP - Specs e RFCs](http-specs-e-rfcs.md) |
| `HTTP-SPEC-04` | Regra de CORS, preflight, `fetch()` ou `Cross-Origin-Resource-Policy` **NEVER** é atribuída a um número de RFC — a fonte é o Fetch Standard (WHATWG). | [HTTP - Specs e RFCs](http-specs-e-rfcs.md) |
### 6.2 IDs canônicos

Dois princípios aparecem em mais de um arquivo, com IDs diferentes, porque cada satélite precisa se sustentar sozinho. **Para citar, use o ID canônico.**

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| O status carrega o resultado; corpo de erro dentro de `2xx` não existe | `HTTP-CORE-06` | `HTTP-STATUS-01` |
| Resposta que varia por header de request declara `Vary` | `HTTP-CORE-04` | — ver abaixo |

**`Vary` é o caso que não é apelido, e a distinção importa.** Três regras exigem `Vary` e **nenhuma delas é redundante**: cada uma acrescenta uma obrigação concreta que as outras não cobrem. Cite a específica quando o contexto for específico.

| O que acrescenta ao princípio geral | Cite |
| --- | --- |
| O enunciado geral — e o único que viaja no caminho mínimo | `HTTP-CORE-04` |
| A consequência de cache: sem `Vary`, o cache serve a representação errada a outro cliente | `HTTP-CACHE-10` |
| Resposta comprimida traz no mínimo `Vary: Accept-Encoding` | `HTTP-NEG-01` |
| Com origem dinâmica, `Vary: Origin` vale inclusive quando a origem é **recusada** | `HTTP-CORS-03` |

O mesmo vale para `ETag` forte: `HTTP-CACHE-09` é o canônico, e `HTTP-NEG-12` é a aplicação dele em retomada de download.

### Famílias completas

| Família | Onde vive | IDs |
| --- | --- | --- |
| `HTTP-CORE-*` | esta nota, § 6 | 01–08 |
| `HTTP-METH-*` | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) | 01–10 |
| `HTTP-STATUS-*` | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) | 01–12 |
| `HTTP-CACHE-*` | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) | 01–12 |
| `HTTP-CORS-*` | [HTTP - CORS](http-cors.md) | 01–10 |
| `HTTP-NEG-*` | [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) | 01–12 |
| `HTTP-SPEC-*` | [HTTP - Specs e RFCs](http-specs-e-rfcs.md) | 01–10 |

**74 regras no total**, das quais 25 viajam com o caminho mínimo (§ 6.1). Numeração contínua, sem lacunas: um ID ausente é bug desta estrutura.

### Famílias completas nos satélites

`HTTP-METH-*` · `HTTP-STATUS-*` · `HTTP-CACHE-*` · `HTTP-CORS-*` · `HTTP-NEG-*` · `HTTP-SPEC-*`

---

## 7. Contrato de skill

Como uma skill de backend ou de cliente HTTP deve consumir esta doc.

### O que carregar

```
SEMPRE:   HTTP.md § 2 (modelo mental)
          HTTP.md § 5 (árvores de decisão)
          HTTP.md § 6 + § 6.1 (regras normativas e críticas)

AO DESENHAR OU ALTERAR ENDPOINT:
          HTTP - Métodos e Semântica.md
          HTTP - Status e Redirecionamento.md

SOB DEMANDA, via § 4 (mapa da superfície):
          o satélite do mecanismo tocado

ANTES DE IMPLEMENTAR À MÃO:
          HTTP.md § 8 (pontes com o stack)

EM DÚVIDA NORMATIVA ("a spec obriga?"):
          HTTP - Specs e RFCs.md

NUNCA:    todos os satélites de uma vez
```

### Como citar

Achados de revisão citam o ID e o satélite, sem parafrasear:

> `HTTP-STATUS-07` — redirect de `POST` com `302`; o agente trocará o método por `GET` e perderá o corpo. Use `307`.
> Ver [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 3.

### Invariantes que a skill deve fazer valer

1. **Verificar antes de afirmar.** Se um header ou status não está na § 4, ele não foi verificado nesta doc. Consulte o MDN e atualize a nota — não invente comportamento nem default.
2. **A fonte vence.** Divergência entre esta nota e MDN/RFC é bug desta nota.
3. **Semântica antes de convenção.** Uma violação de `HTTP-CORE-*` ou `HTTP-METH-*` tem precedência sobre qualquer preferência de estilo de API.
4. **Preferir a ponte.** Quando a § 8 indica que o stack resolve o problema, use o stack em vez de escrever o header à mão.
5. **Nunca inferir cabeçalho de comportamento observado.** "Funcionou no Chrome" não é verificação; `Vary` e `Cache-Control` faltando produzem falhas que só aparecem com cache compartilhado no meio.

### Ao criar uma nova skill

Derive-a de um satélite, não desta nota inteira: uma skill de cache carrega [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) + § 2 + § 6, e nada mais. Registre no início da skill qual satélite é sua fonte.

---

## 8. Pontes com o stack

O corpo desta doc é HTTP puro. Mas quase tudo que os satélites descrevem, o stack do vault ([Bun.serve](bun-http-e-servidor.md), [Hono](hono.md), [Elysia](elysia.md), [TanStack Query](tanstack-query.md)) **já resolve ou já erra por você**. Implementar à mão o que o framework embute é como a maioria dos bugs de header nasce.

### 8.1 O que `Bun.serve` faz sozinho — e o que não faz

`Bun.serve` é `Request` e `Response` padrão da plataforma, e resolve algumas coisas de HTTP sem que você peça:

| Mecanismo | O que `Bun.serve` faz |
| --- | --- |
| Requisição condicional em arquivo | `new Response(await file.bytes())` responde `304` a `If-None-Match` via `ETag`; `new Response(Bun.file(p))` responde `304` a `If-Modified-Since` via `Last-Modified` |
| `Range` | suportado ao servir `Bun.file` diretamente, com `Content-Range`; `Bun.file(p).slice(a, b)` preenche `Content-Range` e `Content-Length` |
| Transferência | `sendfile(2)` quando possível — cópia zero no kernel |

E a lista do que **não** existe é o motivo de [Hono](hono.md) e [Elysia](elysia.md) existirem — verificado como ausente na doc de `Bun.serve`, ver [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 7:

- **CORS**: nada. O preflight `OPTIONS` é tratado por você, rota a rota, incluindo `Vary: Origin`.
- **Middleware componível**: nada. Cada rota repete auth, log e headers de cache.
- **Mapeamento de erro de domínio para status**: nada. Um `throw` vira `500` genérico.
- **`Cache-Control`, `ETag` de resposta dinâmica, compressão, negociação**: nada. São headers que você escreve.

O ponto para um agente: em `Bun.serve` cru, **toda regra desta estrutura é sua responsabilidade explícita**, e esquecê-la não gera erro — gera uma resposta que funciona no teste e falha atrás de uma CDN.

### 8.2 O que Hono e Elysia embutem

Hono traz built-ins no próprio pacote, em subcaminhos, verificados em [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5:

| Middleware | Import | O que resolve desta estrutura | Cuidado |
| --- | --- | --- | --- |
| `cors` | `hono/cors` | origem, métodos, headers, `maxAge`, credenciais | `origin` default é **`*`**, o que é inválido com `credentials: true` — `HONO-MW-08` |
| `etag` | `hono/etag` | gera `ETag` e responde `304` | `weak` default `false`; `retainedHeaders` decide o que sobrevive no `304` |
| `cache` | `hono/cache` | integra com a Cache API da plataforma | `cacheName` obrigatório; `cacheableStatusCodes` default `[200]`; só Workers com domínio custom e Deno 1.26+ |
| `compress` | `hono/compress` | `Content-Encoding` gzip/deflate | `threshold` default 1024 bytes; **desnecessário** em Cloudflare Workers e Deno Deploy, que já comprimem |
| `methodNotAllowed` | `hono/method-not-allowed` | devolve `405` com `Allow` | **sem ele, método não suportado em rota existente devolve `404`** — violação silenciosa de `HTTP-METH-07` |
| `bodyLimit` | `hono/body-limit` | `413` antes de ler o corpo inteiro | `maxSize` default `100 * 1024` |
| `secureHeaders` | `hono/secure-headers` | headers de segurança | CSP **não** vem por default |

Elysia tem `@elysia/cors`, cujos defaults são ainda mais permissivos — `origin: true` (equivalente a `*`) **e** `credentials: true`, combinação que os browsers recusam (`ELYSIA-LIFE-12`, [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md) § 8). Equivalentes de `etag`, `cache` e `compress` em Elysia **não foram verificados** neste vault; ver [Elysia](elysia.md) antes de assumir que existem.

**A leitura que interessa.** O que o framework embute não isenta você da decisão — ele embute o *mecanismo*, não a *política*. `cors()` sabe montar o preflight; ele não sabe quais origens você aceita. `etag()` sabe calcular o validador; ele não sabe se aquela resposta pode ser cacheada por um cache compartilhado. Os defaults permissivos de CORS nos dois frameworks são a prova: o mecanismo veio pronto e errado para produção.

### 8.3 Onde o cache HTTP e o cache do TanStack Query se sobrepõem — e onde não

Este é o ponto do stack que mais confunde, porque os dois usam a palavra "stale".

| | `Cache-Control` (HTTP) | `staleTime` (TanStack Query) |
| --- | --- | --- |
| Quem obedece | browser, CDN, proxy, gateway — todo cache no caminho | só a instância do `QueryClient` naquela aba |
| Quem escreve | o **servidor**, na resposta | o **frontend**, na configuração da query |
| Granularidade | por URL + `Vary` | por `queryKey` |
| Chave | a requisição inteira, incluindo headers em `Vary` | a key que você escolheu, que pode não corresponder à URL |
| Sobrevive a refresh | sim (cache do browser em disco) | não, a menos que haja persistência explícita |
| Alcança outros usuários | sim, se o cache for compartilhado | nunca |
| Efeito de estar fresco | a requisição **não sai** da máquina | a `queryFn` não é chamada |

**Onde se sobrepõem:** ambos podem impedir uma ida à rede. Uma query com `staleTime: 60_000` não chama a `queryFn`; se ela chamasse, e a resposta estivesse fresca no cache do browser, o `fetch` retornaria sem ir à rede de qualquer forma. É por isso que aumentar os dois ao mesmo tempo produz um app cujo dado velho tem duas fontes possíveis e um refresh que não resolve nenhuma.

**Onde não se sobrepõem, e é o que decide:**

- **A invalidação do TanStack Query não invalida o cache HTTP.** `queryClient.invalidateQueries` marca a query como stale e chama a `queryFn` de novo — mas se o servidor mandou `Cache-Control: max-age=300`, o `fetch` dessa nova chamada pode ser servido pelo cache do browser, e você recebe o mesmo dado velho, agora com `isFetching` tendo ficado `true` e voltado a `false`. O sintoma é "invalidei e não atualizou". A correção é do lado do **servidor**.
- **O cache HTTP é compartilhado; o do Query não.** Um `Cache-Control: public, max-age=60` numa resposta específica de usuário é um vazamento entre contas. Nenhum `staleTime` protege disso, porque o problema acontece antes da resposta chegar ao JavaScript.
- **O `304` é invisível para o TanStack Query.** A revalidação condicional acontece na camada do `fetch`; a query só vê o corpo. Um endpoint bem configurado com `ETag` economiza banda mesmo com `staleTime: 0`.

**Por que `staleTime` não substitui `Cache-Control`.** São camadas diferentes, com **donos diferentes**: `staleTime` é uma decisão de um cliente sobre a própria memória; `Cache-Control` é uma instrução do servidor a toda a infraestrutura. Um app com `staleTime` bem calibrado e sem `Cache-Control` continua sem política de cache — a política existe só enquanto aquela aba estiver aberta, e não vale para o segundo cliente, para o mobile, nem para a CDN. Ver [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) § 1 e.

Regra prática de divisão: **o servidor decide por quanto tempo a resposta é válida para qualquer um; o cliente decide com que agressividade ele revalida o que já tem.** As duas decisões coexistem, e nenhuma cobre a outra.

### 8.4 Onde o resto do stack encosta

| Problema desta doc | Onde o stack resolve |
| --- | --- |
| Validar corpo e devolver `400`/`422` com formato próprio | `zValidator` + `hook` — [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 4 |
| Status literal chegando tipado ao cliente | `c.json(body, status)` + `hc` — [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 5 |
| `hc` não lança em `4xx`/`5xx` e a query fica em `success` | `parseResponse()` — [Hono - Validação e RPC](hono-validacao-e-rpc.md) § 6.1 |
| `AbortSignal` do cliente chegando à rede | `{ init: { signal } }` — |
| Correlacionar requisição em log | `hono/request-id` — |
| Cache de borda e invalidação | |
| Onde encerrar CORS e rate limit numa arquitetura | |

---

## Relacionados

- [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) · [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) · [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) · [HTTP - CORS](http-cors.md) · [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) · [HTTP - Specs e RFCs](http-specs-e-rfcs.md)
- · · · ·
- · ·
- [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) · [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md) · [RFC 8725 - JWT Best Current Practices](rfc-8725-jwt-best-current-practices.md) · [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md)
- [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Hono](hono.md) · [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) · [Hono - Validação e RPC](hono-validacao-e-rpc.md) · [Elysia](elysia.md) · [Backend no runtime Bun](backend-no-runtime-bun.md)
- [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) · [React.js](react-js.md) ·
- · · · · ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [HTTP (índice)](https://developer.mozilla.org/en-US/docs/Web/HTTP) · [Overview](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Overview) · [Messages](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Messages)
- [Methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods) · [Status](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status) · [Redirections](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Redirections)
- [Glossary: Safe](https://developer.mozilla.org/en-US/docs/Glossary/Safe/HTTP) · [Glossary: Idempotent](https://developer.mozilla.org/en-US/docs/Glossary/Idempotent) · [Vary](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Vary)
- [RFC 9110 — HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.txt), texto integral: § 3.1 (Resources), § 3.2 (Representations), § 3.3 (Connections), § 3.7 (Intermediaries), § 3.8 (Caches), § 5.1 (Field Names), § 9.1 (Overview), § 9.2.1–9.2.3, § 9.3.1–9.3.4, § 15.3–15.6

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **`422` está no RFC 9110 core.** É a § 15.5.21, definida junto com todos os outros status. A crença de que `422` "é do WebDAV e não é HTTP de verdade" está desatualizada: RFC 9110 absorveu o código e o MDN o marca como definido em HTTP Semantics. O que **não** está no RFC 9110 é `429` — ele vem de RFC 6585 —, o inverso do que se costuma supor.
- **`301` e `302` foram *ajustados* para permitir a troca de método, não apenas "tolerados".** A nota histórica de RFC 9110 § 15.4 diz que a prática convergiu para trocar `POST` por `GET`, e que `307`/`308` foram criados depois para o caso method-preserving. Não é bug de browser; é o texto atual da spec.
- **`303` também é heuristicamente redirecionador para qualquer método**, e o RFC diz que ele é *"applicable to any HTTP method"* — não é exclusivo de `POST`.
- **Corpo em `GET` não é proibido, é indefinido.** RFC 9110 § 9.3.1: o cliente `SHOULD NOT` gerar conteúdo em `GET`, e implementações podem rejeitar a requisição por risco de **request smuggling**. O mesmo texto se repete literalmente em `HEAD` e em `DELETE`. "Proibido pela spec" é impreciso; "indefinido, e alguns servidores derrubam a conexão" é o que está escrito.
- **`POST` é cacheável — condicionalmente.** MDN marca `POST` e `PATCH` como cacheáveis *"when responses explicitly include freshness information and a matching `Content-Location` header"*. RFC 9110 § 9.3.3 acrescenta que uma resposta `POST` cacheada pode satisfazer um `GET` ou `HEAD` posterior, mas nunca outro `POST`. A crença "`POST` nunca é cacheável" é falsa; a prática de que quase nenhuma implementação faz isso é verdadeira (§ 9.2.3: *"the overwhelming majority of cache implementations only support GET and HEAD"*).
- **`PATCH` não é idempotente, e `PUT` é — mas por um motivo que não é o tamanho do corpo.** MDN dá o exemplo do contador auto-incremental: `PUT` sobrescreve, `PATCH` pode somar.
- **Métodos safe não são "sem efeito colateral".** RFC 9110 § 9.2.1 permite explicitamente log, estatística e até cobrança de conta de anúncio. O que a propriedade garante é que **o cliente não pediu** a mudança e não pode ser responsabilizado por ela.
- **Apenas `GET` e `HEAD` são obrigatórios.** RFC 9110 § 9.1: *"All general-purpose servers MUST support the methods GET and HEAD. All other methods are OPTIONAL."*
- **Método é case-sensitive.** RFC 9110 § 9.1 — o token do método é sensível a maiúsculas por poder servir de gateway para sistemas orientados a objeto. Nome de **header**, ao contrário, é case-insensitive (§ 5.1). São regras opostas na mesma mensagem.
- **`Retry-After` em `429` é `MAY`, não `MUST`.** RFC 9110 § 10.2.3 documenta o header para `503` e para `3xx`; `429` vem de RFC 6585, onde o header é opcional. `HTTP-STATUS-08` é norma **deste vault**, mais forte que a spec — e declarada como tal.
- **`Vary: *` implica que a resposta é incacheável**, além de sinalizar que fatores fora dos headers influenciaram a geração. Não é "varia por tudo": é "não guarde".
- **HTTP/2 e HTTP/3 não mudam a semântica.** O folclore de performance do HTTP/1.1 — domain sharding, concatenar assets, sprites, `Pragma: no-cache` — nasceu de limitações de conexão que o multiplexing removeu. Este ponto está registrado aqui porque é a crença mais comum a contradizer, mas o **detalhe verificado por versão de protocolo não faz parte desta estrutura**: não abra exceção sem consultar a fonte.
- **Não verificado nesta doc:** as diretivas individuais de `Cache-Control`, o algoritmo de frescor heurístico, a lista de headers simples de CORS, os fatores `q` da negociação e a sintaxe de `Range`. Todos pertencem aos satélites correspondentes; a ausência aqui é de escopo, não de existência.
