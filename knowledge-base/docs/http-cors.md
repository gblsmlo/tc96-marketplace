---
titulo: HTTP - CORS
Link: https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS
tags:
  - http
  - cors
  - browser
  - agent-context
source: "MDN Web Docs — https://developer.mozilla.org/en-US/docs/Web/HTTP"
verificado-em: 2026-08-15
---

# HTTP - CORS

> A direção real do mecanismo · o que é uma origem · requisição simples × preflighted e o que exatamente dispara o preflight · o `OPTIONS` e os `Access-Control-Request-*` · `Access-Control-Allow-Origin` e o veto do `*` com credenciais · `Allow-Credentials`, `Expose-Headers`, `Allow-Methods`, `Allow-Headers`, `Max-Age` · `Vary: Origin` · o modelo de falha e o que CORS não protege.
>
> **Não cobre:** política de cookie, `SameSite` e prefixos ([RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md)) · autenticação, sessão e autorização ([OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) · [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md)) · `Vary` como mecanismo de chave de cache ([HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) § 6) · a semântica geral do método `OPTIONS` ([HTTP - Métodos e Semântica](http-metodos-e-semantica.md)).

Entrada: [HTTP](http.md) · Base normativa: [HTTP](http.md) § 6

---

## 1. Conceito: CORS é o browser pedindo permissão ao servidor para entregar a resposta ao JavaScript

A frase que quase todo mundo carrega é "o servidor bloqueia a origem". Ela inverte o mecanismo, e quem a carrega depura o lado errado por horas.

O que acontece de fato: o **browser** aplica a same-origin policy sobre o que o JavaScript da página pode **ler**. CORS é a exceção negociada — a resposta do servidor traz headers que autorizam o browser a entregar aquele corpo àquele script. O servidor não bloqueia ninguém; ele **consente**. E quem recusa, quando o consentimento falta, é o browser da própria pessoa que fez a chamada.

Três consequências que decidem código:

1. **A requisição foi executada.** Numa requisição simples (§ 3), o servidor recebeu, processou e respondeu. O `POST` gravou. O browser apenas se recusou a mostrar a resposta ao script. CORS **não** protege efeito colateral.
2. **O erro não é do servidor.** O log do backend mostra `200`. O console do browser mostra bloqueio. Não há contradição — são camadas diferentes. Procurar o problema nos logs da API é o desvio mais comum.
3. **O JS não sabe o que houve.** A MDN: *"For security reasons, specifics about what went wrong with a CORS request are not available to JavaScript code. All the code knows is that an error occurred."* No `fetch`, isso chega como uma `TypeError` genérica — sem status, sem corpo. Diagnóstico só pelo console do browser ou pela aba de rede.

O conceito conciso está em; esta nota é a mecânica que gera código.

---

## 2. Origem: esquema + host + porta

> "a URL indicating the server from which the request is initiated. It does not include any path information, only the server name."

Origem é a **tupla esquema + host + porta**. Qualquer um dos três diferente é outra origem — e é aqui que a intuição falha, porque "mesmo site" e "mesma origem" não são a mesma coisa.

| A | B | Mesma origem? | Por quê |
| --- | --- | --- | --- |
| `https://app.exemplo.com` | `https://app.exemplo.com/pedidos` | sim | path não conta |
| `https://app.exemplo.com` | `https://api.exemplo.com` | **não** | host diferente — subdomínio é outra origem |
| `https://exemplo.com` | `http://exemplo.com` | **não** | esquema diferente |
| `http://localhost:5173` | `http://localhost:3000` | **não** | porta diferente |

A última linha é o dia 1 de qualquer stack Vite + API separada, e a razão de "em dev não precisa de CORS" ser falso. [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 7.1 e [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5 tratam exatamente desse cenário.

Duas notas da fonte: o header `Origin` *"is **always** sent"* em requisição de controle de acesso, e *"the `origin` value can be `null`"* — o que acontece com `file://`, sandbox de iframe e alguns redirects. Comparar `origin` contra allowlist precisa tratar `null` como não pertencente, nunca como coringa.

---

## 3. Simples × preflighted: o que exatamente dispara o preflight

> "Some requests don't trigger a CORS preflight. Those are called _simple requests_ from the obsolete CORS spec."

Uma requisição é simples quando **satisfaz todas** as condições abaixo. Basta violar uma para o browser mandar um `OPTIONS` antes.

**1. O método é `GET`, `HEAD` ou `POST`.** Qualquer outro — `PUT`, `PATCH`, `DELETE` — preflighta.

**2. Os únicos headers definidos manualmente são os CORS-safelisted request-headers.** A lista verificada:

`Accept` · `Accept-Language` · `Content-Language` · `Content-Type` (com a restrição do item 3) · `Range` (*"only with a single range header value; e.g., `bytes=256-` or `bytes=127-255`"*)

Fora dessa lista, qualquer header seu preflighta — inclusive `Authorization`, `X-Request-Id`, `X-CSRF-Token`, `Idempotency-Key`.

**3. O `Content-Type` é um de três valores.** *"The only type/subtype combinations allowed for the media type specified in the `Content-Type` header are:"*

`application/x-www-form-urlencoded` · `multipart/form-data` · `text/plain`

**`application/json` não está na lista.** Este é o item que explica quase todo preflight que aparece sem que ninguém tenha pedido: um `POST` de JSON — a chamada mais banal de qualquer SPA — **não é** uma requisição simples.

**4. Não há listener em `XMLHttpRequest.upload`.** *"no code has called `xhr.upload.addEventListener()` to add an event listener to monitor the upload."* Relevante para: instrumentar progresso torna a requisição preflighted.

**5. Nenhum `ReadableStream` é usado no request.**

### O preflight

```http
OPTIONS /pedidos HTTP/1.1
Host: api.exemplo.com
Origin: https://app.exemplo.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: content-type,x-request-id
```

> "the browser first sends an HTTP request using the `OPTIONS` method to the resource on the other origin, in order to determine if the actual request is safe to send."

`Access-Control-Request-Method` anuncia o método da chamada real; `Access-Control-Request-Headers` anuncia os headers que ela vai carregar — e *"This browser-side header will be answered by the complementary server-side header of `Access-Control-Allow-Headers`."*

```http
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://app.exemplo.com
Access-Control-Allow-Methods: GET, POST, PATCH, DELETE
Access-Control-Allow-Headers: Content-Type, X-Request-Id
Access-Control-Max-Age: 86400
Vary: Origin
```

**O preflight nunca carrega credenciais.** A fonte é categórica: *"CORS-preflight requests must never include credentials."* Consequência direta e frequentemente violada: **um middleware de autenticação que responde `401` a requisição sem sessão vai responder `401` ao `OPTIONS`** — e o browser trata isso como preflight falho (`CORSPreflightDidNotSucceed`). O `OPTIONS` precisa passar antes da auth. Em [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) isso é uma questão de ordem: `cors()` antes de `auth`.

**Depois do preflight, a requisição real acontece.** *"Once the preflight request is complete, the real request is sent."* Não são duas tentativas — são duas requisições, e a segunda é a que grava.

### `Access-Control-Max-Age`

> "The `Access-Control-Max-Age` header indicates how long the results of a preflight request can be cached."

Sem ele, **toda** chamada JSON paga um round-trip extra. Com `86400`, o browser reusa a autorização por 24 horas. A ressalva da fonte: *"Each browser has a maximum internal value that takes precedence when the `Access-Control-Max-Age` exceeds it."* — o valor que você pede é um teto solicitado, não garantido.

| ID | Regra |
| --- | --- |
| `HTTP-CORS-05` | A resposta ao `OPTIONS` de preflight **MUST** ser 2xx sem exigir autenticação — o preflight nunca carrega credenciais. |
| `HTTP-CORS-06` | Todo header não-safelisted que a chamada real envia (`Authorization`, `Content-Type: application/json`, headers `X-*`) **MUST** aparecer em `Access-Control-Allow-Headers`. |
| `HTTP-CORS-07` | Método fora de `GET`/`HEAD`/`POST` **MUST** aparecer em `Access-Control-Allow-Methods`. |

---

## 4. `Access-Control-Allow-Origin` e o veto do `*` com credenciais

> "`Access-Control-Allow-Origin` specifies either a single origin which tells browsers to allow that origin to access the resource; or else — for requests **without** credentials — the `*` wildcard tells browsers to allow any origin to access the resource."

O `*` não é "permissivo demais mas funciona". Com credenciais, ele **não funciona**:

> "If a request includes a credential (most commonly a `Cookie` header) and the response includes an `Access-Control-Allow-Origin: *` header (that is, with the wildcard), the browser will block access to the response, and report a CORS error in the devtools console."

> "When responding to a credentialed request, the server **must** specify an origin in the value of the `Access-Control-Allow-Origin` header, instead of specifying the `*` wildcard."

Isto é decisivo porque `origin: '*'` é o **default** de vários middlewares — `cors()` do Hono entre eles ([Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 4, `HONO-MW-08`). A combinação `origin: '*'` + `credentials: true` é a configuração que o navegador recusa, e o sintoma (*"blocked by CORS policy"*) não menciona qual das duas está errada.

A restrição vale para os outros três headers também. Em requisição com credenciais, o servidor *"must not specify the `*` wildcard"* para `Access-Control-Allow-Methods`, `Access-Control-Allow-Headers` nem `Access-Control-Expose-Headers` — cada um precisa da lista explícita.

### O que "credenciais" inclui

Cookies, certificados cliente TLS e headers de autenticação — a definição usada em. E o lado do cliente decide junto com o servidor: `fetch` só envia credenciais se você pedir.

| `credentials` do `fetch` | Comportamento |
| --- | --- |
| `omit` | nunca envia nem lê credenciais |
| `same-origin` (**default**) | só em requisição de mesma origem |
| `include` | sempre, inclusive cross-origin |

O par que funciona é **`credentials: 'include'` no cliente + origem explícita e `Access-Control-Allow-Credentials: true` no servidor**. Faltando qualquer um dos três, a resposta é descartada. A nota da fonte sobre o caso mais silencioso: *"simple `GET` requests are not preflighted, and so if a request is made for a resource with credentials, if this header is not returned with the resource, the response is ignored by the browser and not returned to web content."* — o `GET` executou, o servidor respondeu `200`, e o JS recebe erro.

```ts
// Cliente: sessão por cookie exige include explícito.
const res = await fetch('https://api.exemplo.com/pedidos', {
  method: 'POST',
  credentials: 'include',
  headers: { 'Content-Type': 'application/json' },   // <- isto já preflighta
  body: JSON.stringify({ clienteId, itens }),
})
```

### `Vary: Origin` — a ligação com o cache

Quando o servidor ecoa a origem em vez de mandar `*`, o corpo da resposta passa a depender de um header de request. A fonte:

> "If the server specifies a single origin (that may dynamically change based on the requesting origin as part of an allowlist) rather than the `*` wildcard, then the server should also include `Origin` in the `Vary` response header to indicate to clients that server responses will differ based on the value of the `Origin` request header."

Sem isso, o mecanismo de [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) § 6 age contra você: a CDN chaveia a entrada só pela URL, guarda a resposta com `Access-Control-Allow-Origin: https://app-a.exemplo.com`, e serve essa mesma resposta a quem veio de `app-b`. O segundo cliente é bloqueado por um header que nem era para ele. O bug depende de quem chegou primeiro ao cache — não reproduz em dev, aparece só depois do deploy.

```ts
// Servidor: allowlist + eco da origem + Vary. Os três, sempre juntos.
const ORIGENS = new Set(['https://app.exemplo.com', 'http://localhost:5173'])

function headersCors(origin: string | null): Record<string, string> {
  const base = { Vary: 'Origin' }
  if (!origin || !ORIGENS.has(origin)) return base
  return {
    ...base,
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Credentials': 'true',
    'Access-Control-Expose-Headers': 'ETag, X-Request-Id',
  }
}
```

O `Vary: Origin` sai **mesmo quando a origem é recusada** — é o mesmo recurso na mesma URL variando por header, e omitir na resposta negativa envenena o cache com a negativa.

| ID | Regra |
| --- | --- |
| `HTTP-CORS-01` | API exposta a browser **MUST** declarar `Access-Control-Allow-Origin` a partir de uma allowlist explícita; `*` **NEVER** é usado em API que aceita credenciais. |
| `HTTP-CORS-02` | Resposta com `Access-Control-Allow-Credentials: true` **MUST** trazer a origem concreta em `Access-Control-Allow-Origin`. |
| `HTTP-CORS-03` | Resposta cujo `Access-Control-Allow-Origin` é derivado do header `Origin` **MUST** incluir `Vary: Origin`, inclusive quando a origem é recusada. |
| `HTTP-CORS-09` | A configuração de CORS **MUST** incluir as origens de desenvolvimento — porta diferente já é origem diferente. |

---

## 5. `Access-Control-Expose-Headers`: o sintoma clássico

> "The HTTP `Access-Control-Expose-Headers` response header allows a server to indicate which response headers should be made available to scripts running in the browser in response to a cross-origin request."

O default é restritivo, e a lista de exceções é curta e verificada:

> "The CORS-safelisted response headers are: `Cache-Control`, `Content-Language`, `Content-Length`, `Content-Type`, `Expires`, `Last-Modified`, `Pragma`."

Tudo fora dessas sete é invisível ao JavaScript numa resposta cross-origin. **Inclusive `ETag`.** O sintoma: `res.headers.get('ETag')` devolve `null`, o servidor jura que mandou, a aba de rede mostra o header presente. Não há erro no console — a leitura simplesmente retorna `null`, e o código segue com um `undefined` que só quebra três camadas adiante.

Os casos que aparecem com mais frequência:

| Header que o JS precisa ler | Para quê |
| --- | --- |
| `ETag` | concorrência otimista — [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) § 5 |
| `Location` | ler a URL do recurso criado num `201` |
| `Content-Range` | posição do trecho numa requisição parcial — [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) § 6 |
| `X-Total-Count` / cabeçalho de paginação | |
| `X-Request-Id` | correlacionar o erro do usuário com o trace — |
| `Retry-After` | backoff — |

E o coringa tem a mesma restrição do `Allow-Origin`: *"The value `*` only counts as a special wildcard value for requests without credentials […] In requests with credentials, it is treated as the literal header name `*`."* Ou seja, com credenciais, `Expose-Headers: *` não expõe nada — ele expõe um header chamado `*`.

| ID | Regra |
| --- | --- |
| `HTTP-CORS-04` | Header de resposta que o JavaScript precisa ler cross-origin **MUST** estar em `Access-Control-Expose-Headers` — só as sete safelisted são visíveis por default. |
| `HTTP-CORS-10` | `Access-Control-Expose-Headers: *` **NEVER** é usado em rota que aceita credenciais — o `*` vira nome literal de header. |

---

## 6. O modelo de falha, e o que CORS não protege

### Diagnóstico por sintoma

Os nomes são os que o Firefox registra no console; o Chrome usa frases equivalentes.

| Mensagem | O que falta | Onde corrigir |
| --- | --- | --- |
| `CORSMissingAllowOrigin` | resposta sem `Access-Control-Allow-Origin` | servidor — a rota respondeu sem passar pelo middleware de CORS |
| `CORSAllowOriginNotMatchingOrigin` | o valor ecoado não bate com a origem | allowlist; conferir esquema e porta |
| `CORSNotSupportingCredentials` | `Allow-Origin: *` com credenciais | trocar `*` por origem concreta — `HTTP-CORS-02` |
| `CORSMissingAllowCredentials` | falta `Access-Control-Allow-Credentials: true` | servidor |
| `CORSPreflightDidNotSucceed` | o `OPTIONS` não respondeu 2xx | ordem de middleware: auth antes do CORS — `HTTP-CORS-05` |
| `CORSMethodNotFound` | método ausente em `Allow-Methods` | `HTTP-CORS-07` |
| `CORSMissingAllowHeaderFromPreflight` | header ausente em `Allow-Headers` | `HTTP-CORS-06` |
| `CORSMultipleAllowOriginNotAllowed` | dois `Access-Control-Allow-Origin` na resposta | middleware duplicado — proxy **e** app emitindo |

A última linha merece atenção em stack com proxy reverso, CDN ou dev server: dois lugares adicionando o header produzem uma resposta inválida, e o sintoma parece "o CORS não está configurado" quando está configurado duas vezes. É a razão de a doc do Hono pedir `server.cors: false` no `vite.config.ts`.

### O que CORS **não** é

**Não é controle de acesso ao endpoint.** A requisição chegou, autenticou, executou e respondeu. O browser barrou só a leitura. Um `POST /pedidos/8814/cancelar` bloqueado por CORS **cancelou o pedido**. Autorização mora no handler, sempre — [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md).

**Não é proteção contra CSRF.** São problemas ortogonais: CORS governa leitura cross-origin por script; CSRF explora o browser **enviando cookies** numa requisição que o atacante provoca e cujo resultado ele não precisa ler. Um formulário HTML cross-origin com `Content-Type: application/x-www-form-urlencoded` é requisição simples — não preflighta, o cookie vai junto, a escrita acontece. A defesa é `SameSite` ([RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md)) mais token anti-CSRF.

**Não vale fora do browser.** `curl`, cliente HTTP de servidor, script, mobile: nada disso executa a same-origin policy. Como diz *"CORS não impede chamadas feitas por servidores, scripts ou clientes HTTP."*

**`mode: 'no-cors'` não é uma saída.** aceita `no-cors`, e o resultado é uma resposta opaca: *"The response is _opaque_, meaning that its headers and body are not available to JavaScript."* Silencia o erro no console e devolve nada útil.

| ID | Regra |
| --- | --- |
| `HTTP-CORS-08` | Autorização de rota **MUST** estar no handler — CORS **NEVER** é o mecanismo que impede a execução de uma requisição cross-origin. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `cors()` com `origin` default (`*`) e `credentials: true` | a especificação proíbe curinga com credenciais; o browser recusa a resposta | allowlist explícita por ambiente — `HTTP-CORS-01` / `HTTP-CORS-02` |
| Middleware de auth antes do CORS | o `OPTIONS` de preflight não leva credenciais e leva `401`; toda chamada JSON quebra | `cors()` primeiro na cadeia — `HTTP-CORS-05` |
| Ecoar `Origin` sem `Vary: Origin` | a CDN serve a resposta com o `Allow-Origin` da primeira origem que passou; o segundo cliente é bloqueado | `Vary: Origin` sempre — `HTTP-CORS-03` |
| Emitir `Vary: Origin` só quando a origem é aceita | a resposta negativa cacheada envenena a URL igual | `Vary: Origin` também na recusa — `HTTP-CORS-03` |
| Ler `res.headers.get('ETag')` cross-origin sem `Expose-Headers` | só sete headers são visíveis por default; a leitura devolve `null` sem erro | `Access-Control-Expose-Headers` — `HTTP-CORS-04` |
| `Access-Control-Expose-Headers: *` em rota com sessão por cookie | com credenciais o `*` é nome literal de header; nada é exposto | lista explícita — `HTTP-CORS-10` |
| Configurar CORS "só em produção" | Vite em `:5173` e API em `:3000` já são origens diferentes | origens por ambiente, dev incluído — `HTTP-CORS-09` |
| Adicionar origem por `Access-Control-Allow-Origin` no app **e** no proxy | dois headers na resposta invalidam o CORS (`CORSMultipleAllowOriginNotAllowed`) | um único emissor; `server.cors: false` sob Vite |
| Depurar CORS nos logs do backend | o backend respondeu `200`; a recusa é do browser | console e aba de rede do browser — § 1 |
| Contar com CORS para impedir escrita cross-origin | a requisição executa antes de o browser barrar a leitura | autorização no handler — `HTTP-CORS-08` |
| Trocar `mode: 'cors'` por `no-cors` para "resolver" o erro | a resposta vira opaca: sem headers, sem corpo, sem status legível | corrigir os headers no servidor — § 6 |
| Tratar `null` como origem válida na allowlist | `file://`, iframe sandbox e alguns redirects mandam `Origin: null` | comparação por igualdade contra a lista — § 2 |

---

## Checklist de revisão

- [ ] `Access-Control-Allow-Origin` vem de allowlist, nunca `*` com credenciais? → `HTTP-CORS-01` / `HTTP-CORS-02`
- [ ] Toda resposta que ecoa a origem traz `Vary: Origin`, inclusive na recusa? → `HTTP-CORS-03`
- [ ] Os headers que o JS lê estão em `Access-Control-Expose-Headers`? → `HTTP-CORS-04`
- [ ] O `OPTIONS` responde 2xx sem passar pela auth? → `HTTP-CORS-05`
- [ ] `Content-Type`, `Authorization` e headers `X-*` estão em `Allow-Headers`? → `HTTP-CORS-06`
- [ ] `PUT`/`PATCH`/`DELETE` estão em `Allow-Methods`? → `HTTP-CORS-07`
- [ ] Cada rota de escrita autoriza no handler, independentemente do CORS? → `HTTP-CORS-08`
- [ ] As origens de desenvolvimento estão na configuração? → `HTTP-CORS-09`
- [ ] Nenhum `Expose-Headers: *` em rota com credenciais? → `HTTP-CORS-10`
- [ ] Um único ponto emite os headers de CORS (app ou proxy, não os dois)? → § 6

---

## Relacionados

- [HTTP](http.md) — hub; § 5 tem a árvore "minha requisição foi bloqueada pelo browser — é CORS?"
- [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) · [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) · [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) · [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) · [HTTP - Specs e RFCs](http-specs-e-rfcs.md)
- — Zettel conceitual · (`mode`, `credentials`)
- [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) (`cors()`, `origin` default `*`) · [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 7.1 (sem CORS nativo) · [Elysia - Lifecycle e Plugins](elysia-lifecycle-e-plugins.md)
- [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) · [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) · ·
- · · ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Cross-Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS)
- [CORS errors](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS/Errors)
- [Access-Control-Expose-Headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Access-Control-Expose-Headers)
- [Request: mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/mode)
- [Vary](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Vary)

**O que a verificação contrariou:**

- **`application/json` não está entre os `Content-Type` de requisição simples.** Os três permitidos são `application/x-www-form-urlencoded`, `multipart/form-data` e `text/plain`. É a causa da maioria dos preflights que aparecem "sem motivo" numa SPA.
- **`Range` é um header safelisted**, com a restrição de um único intervalo. Não é intuitivo — a lista costuma ser lembrada só como `Accept`/`Accept-Language`/`Content-Language`/`Content-Type`.
- **Listener em `xhr.upload` torna a requisição preflighted.** Instrumentar progresso de upload muda a classificação da requisição.
- **`ReadableStream` no request também preflighta** — item raramente citado, e relevante para upload em streaming.
- **O preflight nunca leva credenciais.** *"CORS-preflight requests must never include credentials."* É o que explica o `401` no `OPTIONS` quando a auth roda antes do CORS.
- **Só sete headers de resposta são legíveis por default:** `Cache-Control`, `Content-Language`, `Content-Length`, `Content-Type`, `Expires`, `Last-Modified`, `Pragma`. `ETag` e `Location` **não** estão na lista — o hábito de assumir que estão produz `null` silencioso.
- **`*` em `Expose-Headers` com credenciais vira nome literal de header**, não coringa. Mesma armadilha do `Allow-Origin`, com sintoma mais silencioso.
- **`Vary: Origin` é recomendação explícita da fonte** quando a origem é dinâmica, e é o ponto onde CORS e cache se cruzam.
- **O JS nunca sabe a causa do erro de CORS**, por decisão de segurança. Toda ferramenta de diagnóstico é externa ao código.
- **Não verificado:** o comportamento de `Access-Control-Allow-Private-Network`/Private Network Access, e os tetos internos concretos de `Access-Control-Max-Age` por browser (a fonte diz que existem, sem dar os valores). `Timing-Allow-Origin` e `Cross-Origin-Resource-Policy` ficaram deliberadamente fora — são mecanismos vizinhos, não CORS.
