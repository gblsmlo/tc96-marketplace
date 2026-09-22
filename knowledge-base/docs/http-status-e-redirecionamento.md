---
Link: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status
tags:
 - http
 - status
 - redirecionamento
 - api
 - agent-context
source: "MDN Web Docs — https://developer.mozilla.org/en-US/docs/Web/HTTP"
verificado-em: 2026-08-15
---

# HTTP - Status e Redirecionamento

> As cinco classes e o que cada uma autoriza · os status de sucesso que decidem código (`200` · `201` · `202` · `204`) · a árvore de redirect (`301` · `302` · `303` · `307` · `308`), `Location` e `Retry-After` · `401` × `403` × `404` × `410` · `400` × `415` × `422` · `409` × `412` · `429` · `500` × `502` × `503` × `504`.
>
> **Não cobre:** que método usar em cada operação ([HTTP - Métodos e Semântica](http-metodos-e-semantica.md)) · `304` e o ciclo de revalidação ([HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)) · `406` e negociação, `206` e `416` ([HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)) · onde cada status está definido ([HTTP - Specs e RFCs](http-specs-e-rfcs.md)).

Entrada: [HTTP](http.md) · Base normativa: [HTTP](http.md) § 6

---

## 1. Conceito: o status é a parte da resposta que intermediários leem sem abrir o corpo

Um cache decide se guarda olhando o número. Um cliente decide se retenta olhando o número. Um dashboard de erro conta olhando o número. Um browser decide se segue o `Location` olhando o número. Nenhum deles parseia o seu JSON.

Por isso errar o status quebra coisas na ordem inversa da que se espera: **quebra cache, retry e monitoramento antes de quebrar a UI** — e a UI costuma continuar funcionando, porque o frontend lê o corpo. É o que torna o erro invisível em desenvolvimento e caro em produção.

O caso canônico é o `200` com `{"erro":...}` dentro. Ele funciona na tela, e simultaneamente: diz ao cache compartilhado que aquela resposta é reutilizável; diz ao cliente que não há nada a retentar; conta como sucesso na taxa de erro; e faz o Error Boundary do frontend nunca disparar.

### As cinco classes, e o que cada uma autoriza o cliente a fazer

| Classe | Significado | O que o cliente pode fazer |
| --- | --- | --- |
| **`1xx` Informational** | resposta interina; a requisição continua | nada — esperar a resposta final |
| **`2xx` Successful** | a requisição foi recebida, entendida e aceita | seguir em frente; e o cache **pode** guardar, se o método e os headers permitirem |
| **`3xx` Redirection** | *"further action needs to be taken by the user agent in order to fulfill the request"* | seguir `Location` — com regras de método que dependem do código exato (§ 3) |
| **`4xx` Client Error** | *"the client seems to have erred"* | **não** repetir a mesma requisição sem mudá-la. `429` é a exceção: repetir depois de esperar |
| **`5xx` Server Error** | o servidor errou ou não consegue cumprir | repetir **se, e somente se**, o método for idempotente ([HTTP - Métodos e Semântica](http-metodos-e-semantica.md) § 7) |

Para `4xx` e `5xx`, RFC 9110 pede um corpo explicando a situação — *"the server SHOULD send a representation containing an explanation of the error situation, and whether it is a temporary or permanent condition"* — exceto em resposta a `HEAD`, que não tem corpo.

A implicação prática de `4xx` × `5xx` é a que mais se ignora: **é o status que decide se o retry do cliente é legítimo.** Devolver `500` para um corpo inválido do cliente faz o cliente retentar três vezes um payload que nunca vai passar, e enche o log de erro de servidor com um problema de contrato.

| ID | Regra |
| --- | --- |
| `HTTP-STATUS-01` | Falha **NEVER** é respondida com `2xx`; erro de domínio **MUST** ser expresso no status, não só no corpo. |
| `HTTP-STATUS-02` | Erro causado pela requisição **MUST** ser `4xx` e erro causado pelo servidor **MUST** ser `5xx`; entrada inválida **NEVER** vira `500`. |

---

## 2. Sucesso: qual dos quatro

`200` é o default e quase sempre está certo. Os outros três existem porque significam algo que o `200` não consegue dizer.

| Status | Diz | Corpo | Header que acompanha |
| --- | --- | --- | --- |
| `200 OK` | *"The request succeeded."* | sim | — |
| `201 Created` | a requisição *"resulted in one or more new resources being created"* | descreve e linka o recurso criado | **`Location`** apontando para o recurso principal criado |
| `202 Accepted` | aceito para processar, *"but the processing has not been completed"* | descreve o estado atual e aponta para um monitor de status | — |
| `204 No Content` | sucesso, e não há nada a mandar | **nenhum** | metadados de resposta se referem ao recurso após a ação |

**`201` sem `Location` é meio-status.** RFC 9110 § 15.3.2: o recurso criado é identificado *"by either a Location header field in the response or, if no Location header field is received, by the target URI"* — ou seja, sem `Location`, o cliente é obrigado a supor que o recurso está na URL para onde ele fez `POST`, o que é falso sempre que o servidor gera o ID.

**`202` é deliberadamente não comprometido.** A spec avisa: *"There is no facility in HTTP for re-sending a status code from an asynchronous operation."* Devolver `202` sem devolver junto um caminho para consultar o resultado deixa o cliente sem nenhuma forma de descobrir o desfecho. É o par natural de fila e job — ver e.

**`204` não pode ter corpo.** É estrutural, não estilo: *"A 204 response is terminated by the end of the header section; it cannot contain content or trailers."* Um framework que serializa `{}` num `204` produz uma mensagem que alguns clientes leem como corpo da resposta seguinte na mesma conexão.

E `204` **é heuristicamente cacheável** — assim como `301`, `308` e `405`. Um `204` de uma operação de escrita precisa de `Cache-Control` explícito, ou um cache pode reutilizá-lo.

```http
POST /pedidos HTTP/1.1
Host: api.exemplo.com
Content-Type: application/json

{"clienteId":"c-901","itens":[{"sku":"SKU-12","quantidade":2}]}
```

```http
HTTP/1.1 201 Created
Location: /pedidos/p-4471
Content-Type: application/json; charset=utf-8
Cache-Control: no-store

{"id":"p-4471","status":"aberto"}
```

| ID | Regra |
| --- | --- |
| `HTTP-STATUS-03` | Resposta `201` **MUST** trazer `Location` apontando para o recurso criado. |
| `HTTP-STATUS-04` | Resposta `204` **NEVER** tem corpo. |
| `HTTP-STATUS-05` | Resposta `202` **MUST** trazer, no corpo, o identificador ou a URL por onde o cliente consulta o desfecho. |

---

## 3. Redirecionamento: a árvore que decide `301` · `302` · `303` · `307` · `308`

Este é o ponto onde mais se erra, e o motivo é histórico, não conceitual.

### O que aconteceu

`301` e `302` foram definidos em HTTP/1.0 como **preservadores de método**. Os primeiros user agents se dividiram sobre o que fazer com `POST`, e a prática convergiu para trocar por `GET`. RFC 9110 § 15.4 registra o desfecho sem eufemismo:

> "Prevailing practice eventually converged on changing the method to GET. 307 (Temporary Redirect) and 308 (Permanent Redirect) were later added to unambiguously indicate method-preserving redirects, and status codes 301 and 302 have been adjusted to allow a POST request to be redirected as GET."

Ou seja: **`301` e `302` foram ajustados para permitir a troca.** Não é bug de browser tolerado; é o texto atual. A nota que acompanha cada um dos dois é a mesma: *"For historical reasons, a user agent MAY change the request method from POST to GET for the subsequent request."*

### A tabela

| Código | Permanência | Método e corpo | Caso típico |
| --- | --- | --- | --- |
| `301 Moved Permanently` | permanente | `GET` inalterado; outros **podem** virar `GET` | reorganização de site, só leitura |
| `308 Permanent Redirect` | permanente | **preservados** | reorganização com operações não-`GET` |
| `302 Found` | temporária | `GET` inalterado; outros **podem** virar `GET` | página temporariamente indisponível |
| `307 Temporary Redirect` | temporária | **preservados** | idem, quando há operações não-`GET` |
| `303 See Other` | — | `GET` inalterado; outros **trocados** para `GET`, **corpo perdido** | POST-redirect-GET |

Para `307`, o texto é `MUST NOT`: *"the user agent MUST NOT change the request method if it performs an automatic redirection"*.

### A árvore

```
Preciso apontar o cliente para outra URI.
├── A mudança é PERMANENTE (a antiga URI nunca mais vale)?
│ ├── SIM
│ │ ├── existe alguma operação não-GET nessa URI → 308
│ │ └── só leitura (páginas, canonical, SEO) → 301
│ └── NÃO
│ ├── preciso que método e corpo cheguem intactos → 307
│ ├── só leitura → 302
│ └── é a resposta de um POST/PUT bem-sucedido, e quero
│ que a próxima requisição seja um GET → 303
└── Em qualquer ramo: Location é obrigatório.
```

### `303` e o POST-redirect-GET

`303` é o único que troca o método **deliberadamente**, e é para isso que ele serve. RFC 9110 § 15.4.4:

> "It is primarily used to allow the output of a POST action to redirect the user agent to a different resource, since doing so provides the information corresponding to the POST response as a resource that can be separately identified, bookmarked, and cached."

O problema que ele resolve: um `POST` que responde `200` com HTML deixa o browser com um `POST` no histórico. Um `F5` reenvia o formulário — e cria o segundo pedido. Redirecionar com `303` faz a página final ser um `GET` marcável, e o refresh recarrega a página em vez de reexecutar a operação.

```http
POST /pedidos HTTP/1.1
Host: app.exemplo.com
Content-Type: application/x-www-form-urlencoded

clienteId=c-901&sku=SKU-12&quantidade=2
```

```http
HTTP/1.1 303 See Other
Location: /pedidos/p-4471
```

**O erro clássico é usar `302` aqui.** Funciona nos browsers, porque eles trocam o método por `GET` de qualquer forma — e é exatamente esse "funciona por acidente" que quebra o cliente não-browser: `fetch`, `curl -L`, um SDK ou um serviço a montante podem preservar o `POST` e reenviar o corpo para a nova URI. Com `303`, o comportamento é o mesmo em todos.

**E o erro simétrico é usar `303` para redirecionar uma API.** Um `POST /pedidos` numa API JSON que responde `303` faz o cliente virar `GET` e perder o corpo — quando o que você queria era `307` (mesma operação, outro host) ou nenhum redirect (responda `201` e acabou).

### `Location`

`Location` é o alvo do redirecionamento. Ele também aparece em `201`, com outro significado: ali ele identifica o **recurso criado**, não um lugar para onde ir. E `Content-Location`, que se confunde com ele, é header de **representação** — diz de onde vieram os bytes desta resposta, e é o que uma resposta de `PUT` usa para apontar o recurso alterado.

### `Retry-After`

Duas formas, ambas válidas: data HTTP ou número de segundos.

```http
Retry-After: 120
Retry-After: Fri, 15 Aug 2026 12:00:00 GMT
```

Os usos documentados: em `503`, quanto tempo o serviço deve ficar indisponível; em `429`, quanto esperar antes de nova requisição; em resposta `3xx`, o tempo mínimo antes de emitir a requisição redirecionada.

Sem ele, um cliente com backoff exponencial adivinha — e uma frota de clientes adivinhando ao mesmo tempo produz o thundering herd que derrubou o serviço de novo. Ver.

| ID | Regra |
| --- | --- |
| `HTTP-STATUS-06` | Toda resposta `301`, `302`, `303`, `307` ou `308` **MUST** incluir `Location`. |
| `HTTP-STATUS-07` | Redirecionamento que precisa preservar método e corpo **MUST** ser `307` ou `308`; `301` e `302` **NEVER**. |
| `HTTP-STATUS-08` | Redirecionamento de um `POST` para uma página de resultado **MUST** ser `303`. |
| `HTTP-STATUS-09` | Resposta `429` ou `503` **MUST** incluir `Retry-After`. |

---

## 4. Erro de cliente: os pares que se confundem

### `401` × `403`

A distinção é sobre **credencial**, não sobre permissão em abstrato.

| | `401 Unauthorized` | `403 Forbidden` |
| --- | --- | --- |
| Significa | falta credencial válida — na prática, **não autenticado** | credencial válida, e ainda assim não pode |
| Reautenticar resolve | sim | **não** — *"authenticating or re-authenticating makes no difference"* |
| Header obrigatório | **`WWW-Authenticate`** com o esquema esperado | — |

```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer
```

O nome do `401` é o problema: MDN registra que *"although the HTTP standard specifies 'unauthorized', semantically this response means 'unauthenticated'"*. Um handler que responde `401` para "usuário logado sem o papel de admin" faz o cliente tentar renovar o token em loop, porque `401` é o sinal universal de "sua credencial não serve". Política de autorização é assunto de e `OWASP - Sessão e Autorização`; aqui está só o sinal de protocolo.

### `403` × `404`

MDN registra a escolha deliberada: *"Server owners may decide to send a 404 response instead of a 403 if acknowledging the existence of a resource to clients with insufficient privileges is not desired."*

Responder `404` para recurso existente que o usuário não pode ver é **prática recomendada** quando a existência é informação — o ID de um pedido de outro cliente, um repositório privado. Não é mentira: é evitar o oráculo de enumeração. A contrapartida é que você perde a capacidade de distinguir "não existe" de "não é seu" nos seus próprios logs, então registre a diferença do lado de dentro.

### `404` × `410`

| | `404 Not Found` | `410 Gone` |
| --- | --- | --- |
| Significa | não encontrado — permanência **desconhecida** | removido em **definitivo**, sem endereço de encaminhamento |
| Cacheável | não por default | **cacheável por default** |
| Efeito no cliente | pode tentar de novo depois | *"clients should not repeat requests for resources that return a 410"* |

A regra de escolha é literal: *"if server owners don't know whether this condition is temporary or permanent, a 404 status code should be used instead."* Na dúvida, `404`. `410` é uma afirmação forte, e o cache leva a sério.

### `400` × `415` × `422` — o eixo de validação

Os três dizem "seu corpo não serve", em três camadas diferentes.

| Status | A camada que falhou | Exemplo |
| --- | --- | --- |
| `415 Unsupported Media Type` | **formato do envelope** — o servidor não processa esse `Content-Type` ou `Content-Encoding` | cliente mandou `text/xml` numa rota que só aceita `application/json` |
| `400 Bad Request` | **sintaxe** — o corpo não parseia, ou a requisição está malformada | JSON truncado, chave sem aspas |
| `422 Unprocessable Content` | **semântica** — parseou, mas as instruções não podem ser executadas | `quantidade: -3`, `clienteId` que não é UUID, SKU inexistente |

O texto de `422` em RFC 9110 § 15.5.21 encaixa as três explicitamente: o servidor *"understands the content type of the request content (hence a 415 status code is inappropriate), and the syntax of the request content is correct, but it was unable to process the contained instructions"*. E MDN acrescenta a consequência para o cliente: *"clients that receive a 422 response should expect that repeating the request without modification will fail with the same error."*

`415` tem um detalhe útil: se a causa foi o **content coding**, o servidor pode responder com `Accept-Encoding`; se foi o media type, com `Accept`. Assim o cliente descobre o que fazer sem ler documentação.

> **Sobre a crença de que `422` "não é HTTP de verdade".** Ela nasceu de o código ter sido definido no WebDAV, e está desatualizada: `422` está no **core** de RFC 9110, na § 15.5.21, e MDN aponta a definição para HTTP Semantics. O código que de fato não está no RFC 9110 é o `429` — ele vem de RFC 6585. Ver [O que a verificação contrariou](#o-que-a-verificacao-contrariou) e [HTTP - Specs e RFCs](http-specs-e-rfcs.md).

### `409` × `412`

Os dois são conflito de estado. A diferença é **quem detectou**.

- **`409 Conflict`** — o servidor descobriu o conflito ao processar: *"a request conflicts with the current state of the target resource"*. Criar algo que já existe, mudar de estado a partir de um estado incompatível, apagar um recurso com dependentes. O corpo deve descrever o conflito de forma acionável — MDN mostra um exemplo com o ID do job concorrente no corpo, que é o que permite ao cliente fazer algo além de mostrar um erro.
- **`412 Precondition Failed`** — o **cliente** declarou uma precondição (`If-Match`, `If-Unmodified-Since`) e ela não valeu. É o mecanismo de lost-update: o cliente diz "só altere se ainda estiver na versão `"a1b2c3"`", e o servidor recusa se alguém alterou no meio. Mecânica em [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md).

A diferença que decide código: `412` é **optimistic locking funcionando**; `409` é a aplicação encontrando um conflito de domínio. Um `PUT` sem `If-Match` nunca pode devolver `412`, porque não havia precondição a falhar.

### `429`

Limite de taxa excedido. `Retry-After` é o que transforma o `429` em algo tratável — sem ele, cada cliente escolhe seu próprio backoff.

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 30
Content-Type: application/json; charset=utf-8

{"error":"rate_limit","limite":100,"janelaSegundos":60}
```

| ID | Regra |
| --- | --- |
| `HTTP-STATUS-10` | Resposta `401` **MUST** trazer `WWW-Authenticate`; requisição com credencial válida e permissão insuficiente **MUST** responder `403` ou `404`, **NEVER** `401`. |
| `HTTP-STATUS-11` | Corpo sintaticamente válido reprovado por regra de negócio **MUST** responder `422`; media type não suportado **MUST** responder `415`. Nenhum dos dois **NEVER** vira `400` genérico. |

---

## 5. Erro de servidor: `500` × `502` × `503` × `504`

Os quatro não são intercambiáveis, e a diferença é sobre **onde** a falha ocorreu.

| Status | Definição verificada | Quando |
| --- | --- | --- |
| `500 Internal Server Error` | *"the server encountered an unexpected condition that prevented it from fulfilling the request"* | o seu código falhou — exceção não tratada, bug |
| `502 Bad Gateway` | o servidor, *"while acting as a gateway or proxy, received an invalid response from an inbound server"* | você é gateway/BFF e o upstream devolveu lixo |
| `503 Service Unavailable` | *"temporary overload or scheduled maintenance, which will likely be alleviated after some delay"* | sobrecarga, deploy, circuit breaker aberto |
| `504 Gateway Timeout` | gateway ou proxy *"did not receive a timely response from an upstream server"* | você é gateway/BFF e o upstream não respondeu a tempo |

**`502` e `504` são status de papel de gateway**, não de "um serviço qualquer que eu chamei falhou". Um backend que chama o próprio banco e falha está em `500` — ele não é gateway do banco. Um BFF ou API gateway que agrega serviços está exatamente no papel descrito e deve usar `502`/`504`, porque é isso que permite ao cliente distinguir "a plataforma caiu" de "uma dependência caiu".

A nota de `503` merece leitura: *"The existence of the 503 status code does not imply that a server has to use it when becoming overloaded. Some servers might simply refuse the connection."* Ou seja, ausência de `503` no log não significa ausência de sobrecarga.

E a distinção com `4xx` é o que fecha o ciclo do § 1: **`5xx` autoriza o cliente a retentar** — desde que o método seja idempotente. Emitir `500` para entrada inválida é convidar um cliente bem-comportado a repetir três vezes uma requisição que nunca vai passar.

| ID | Regra |
| --- | --- |
| `HTTP-STATUS-12` | Serviço no papel de gateway ou proxy (BFF, API gateway) **MUST** responder `502` quando o upstream devolve resposta inválida e `504` quando ela não chega a tempo; `500` fica reservado a falha do próprio código. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `200` com `{"success": false}` | cache guarda, cliente não retenta, monitoramento conta como sucesso, Error Boundary não dispara | status carrega o resultado — `HTTP-STATUS-01` |
| `500` para corpo inválido do cliente | o cliente retenta três vezes um payload que nunca vai passar; a taxa de erro de servidor mente | `400`, `415` ou `422` — `HTTP-STATUS-02` |
| `201` sem `Location` | o cliente não sabe a URI do que acabou de criar e passa a inventá-la | `Location: /pedidos/{id}` — `HTTP-STATUS-03` |
| `204` com `{}` no corpo | a spec proíbe corpo em `204`; alguns clientes leem os bytes como início da resposta seguinte | `200` com corpo, ou `204` sem — `HTTP-STATUS-04` |
| `202` sem caminho para consultar o desfecho | não há mecanismo em HTTP para reenviar o status depois; o cliente fica sem saber se deu certo | devolver o id/URL do job — `HTTP-STATUS-05` |
| `302` num POST-redirect-GET | funciona no browser por acidente histórico; um cliente não-browser pode preservar o `POST` e reenviar o corpo | `303` — `HTTP-STATUS-08` |
| `301`/`302` para redirecionar API com `POST` | agentes trocam o método por `GET` e o corpo se perde, sem erro em lugar nenhum | `307` (temporário) ou `308` (permanente) — `HTTP-STATUS-07` |
| `303` num endpoint de API JSON | o cliente vira `GET` e perde o corpo; era `307` ou nenhum redirect | responder `201` diretamente — § 3 |
| `301` "temporário" para testar uma migração | permanente é heuristicamente cacheável, e browsers guardam agressivamente; reverter não alcança quem já cacheou | `302`/`307` enquanto houver dúvida — § 3 |
| `401` para "logado, sem permissão" | `401` é o sinal de credencial inválida: o cliente entra em loop de renovação de token | `403` (ou `404`, se a existência é sigilosa) — `HTTP-STATUS-10` |
| `403` para recurso de outro usuário numa API pública | confirma a existência do recurso a quem não deveria saber | `404` deliberado, com o motivo registrado no log interno — § 4 |
| `410` "para ser explícito" quando o recurso pode voltar | `410` é cacheável por default e diz ao cliente para parar de perguntar | `404` na dúvida — § 4 |
| `400` genérico para falha de validação de campo | o cliente não distingue "não parseou" de "regra reprovou", e retenta o que nunca vai passar | `422` com os campos — `HTTP-STATUS-11` |
| `429` sem `Retry-After` | cada cliente inventa o backoff; a frota volta junta e derruba de novo | `Retry-After` em segundos — `HTTP-STATUS-09` |
| `500` num BFF quando o upstream deu timeout | some a informação de que a falha é de dependência; o alerta acorda o time errado | `504` — `HTTP-STATUS-12` |
| Depender da reason phrase (`"Not Found"`) no cliente | a frase é opcional e livre; só o número é contrato | comparar o número — § 1 |

---

## Checklist de revisão

- [ ] Nenhuma resposta `2xx` carrega falha no corpo? → `HTTP-STATUS-01`
- [ ] Entrada inválida devolve `4xx` e nunca `500`? → `HTTP-STATUS-02`
- [ ] Todo `201` traz `Location`? → `HTTP-STATUS-03`
- [ ] Nenhum `204` tem corpo? → `HTTP-STATUS-04`
- [ ] Todo `202` diz como consultar o desfecho? → `HTTP-STATUS-05`
- [ ] Todo `3xx` de redirecionamento traz `Location`? → `HTTP-STATUS-06`
- [ ] Redirecionamento que precisa do método usa `307`/`308`? → `HTTP-STATUS-07`
- [ ] POST-redirect-GET usa `303`, não `302`? → `HTTP-STATUS-08`
- [ ] `429` e `503` trazem `Retry-After`? → `HTTP-STATUS-09`
- [ ] `401` traz `WWW-Authenticate`, e permissão insuficiente não vira `401`? → `HTTP-STATUS-10`
- [ ] Falha de validação semântica é `422`, e media type é `415`? → `HTTP-STATUS-11`
- [ ] Falha de upstream num gateway é `502`/`504`, não `500`? → `HTTP-STATUS-12`
- [ ] O cliente compara o número do status, não a reason phrase?

---

## Relacionados

- [HTTP](http.md) — hub; § 5.2 tem a árvore completa de escolha de status
- [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) · [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) · [HTTP - CORS](http-cors.md) · [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) · [HTTP - Specs e RFCs](http-specs-e-rfcs.md)
- · · ·
- · `OWASP - Sessão e Autorização` ·
- · · ·
- `Hono - Validação e RPC` · [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md) ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [HTTP response status codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status) — lista completa das cinco classes
- [Redirections](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Redirections) — tabelas de redirect permanente e temporário
- [401](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/401) · [403](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/403) · [405](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/405) · [409](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/409) · [410](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/410) · [422](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/422)
- [Retry-After](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Retry-After)
- [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.txt) § 15.3.2 (201), § 15.3.3 (202), § 15.3.5 (204), § 15.4 (3xx e a nota histórica), § 15.4.2–15.4.9, § 15.5 (4xx), § 15.5.6 (405), § 15.5.13 (412), § 15.5.16 (415), § 15.5.21 (422), § 15.6 (5xx), § 15.6.1–15.6.5, § 10.2.3 (Retry-After)

**O que a verificação contrariou:**

- **`422` está no core do RFC 9110** (§ 15.5.21), e MDN aponta a definição para HTTP Semantics. A crença de que ele "é do WebDAV e não conta" está desatualizada. O que **não** está no RFC 9110 é o **`429`** — ele vem de RFC 6585 —, exatamente o inverso do que se supõe.
- **`301` e `302` foram *ajustados* para permitir a troca de método**, não apenas tolerados. RFC 9110 § 15.4: *"status codes 301 and 302 have been adjusted to allow a POST request to be redirected as GET"*. Tratar a troca como bug de browser é ler uma spec antiga.
- **`303` é aplicável a qualquer método**, não só a `POST`. A associação exclusiva com POST-redirect-GET é do uso primário descrito, não da definição.
- **`204`, `301`, `308` e `405` são heuristicamente cacheáveis**, e `410` é cacheável por default. Nenhum deles precisa de `Cache-Control` para ser guardado — precisa para **não** ser.
- **`Retry-After` é `MAY` em `503`** (RFC 9110 § 15.6.4) e opcional em `429` (RFC 6585). `HTTP-STATUS-09` é norma **deste vault**, mais forte que a spec.
- **`401` significa não autenticado**, apesar do nome. MDN diz isso explicitamente, e a spec obriga o `WWW-Authenticate` junto.
- **Responder `404` no lugar de `403` é documentado como escolha legítima** pelo MDN, não como gambiarra de segurança.
- **`410` é uma afirmação de permanência, e caches a levam a sério.** MDN: na dúvida entre temporário e permanente, use `404`.
- **`502` e `504` pressupõem papel de gateway ou proxy** na definição do RFC. Usá-los num serviço que apenas chamou uma dependência é esticar a semântica.
- **A reason phrase é opcional.** Só o número é contrato — o que invalida qualquer cliente que compare a string.
- **`HTTP-STATUS-03`, `-05`, `-08`, `-09` e `-12` são norma deste vault**, mais fortes que o `SHOULD`/`MAY` da spec. Estão marcadas para que ninguém as cite como obrigação do protocolo.
- **Não verificado nesta doc:** `1xx` (incluindo `103 Early Hints`), `300 Multiple Choices`, `304` e o ciclo de revalidação, `206`/`416`, `406`, `451`, e os status de WebDAV (`207`, `423`, `424`).
