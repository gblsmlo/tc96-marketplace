---
titulo: HTTP - Negociação de Conteúdo e Range
Link: https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Content_negotiation
tags:
 - http
 - content-negotiation
 - range
 - agent-context
source: "MDN Web Docs — https://developer.mozilla.org/en-US/docs/Web/HTTP"
verificado-em: 2026-08-15
---

# HTTP - Negociação de Conteúdo e Range

> Negociação proativa × reativa · `Accept`, `Accept-Language`, `Accept-Encoding` e a sintaxe de qualidade (`q`) com a regra de desempate · `Content-Type` e `charset` · `Content-Encoding` × `Transfer-Encoding` · compressão (gzip, br, zstd) e o que não vale a pena comprimir · `Content-Disposition` · `415` e `406` · `Vary` como contrapartida obrigatória · `Range`, `206`, `Accept-Ranges`, `Content-Range`, `If-Range`, `416`.
>
> **Não cobre:** `Cache-Control`, revalidação condicional e `ETag` forte × fraco ([HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)) · `Range` como header safelisted de CORS ([HTTP - CORS](http-cors.md) § 3) · a semântica de `GET`/`HEAD` e corpo de request ([HTTP - Métodos e Semântica](http-metodos-e-semantica.md)) · a família 4xx completa ([HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md)).

Entrada: [HTTP](http.md) · Base normativa: [HTTP](http.md) § 6

---

## 1. Conceito: uma URL identifica um recurso, não um arquivo

`https://api.exemplo.com/pedidos/8814` não aponta para um arquivo. Aponta para um **recurso** — uma ideia — que pode trafegar como JSON ou como PDF, em português ou em inglês, comprimido com Brotli ou cru, inteiro ou em pedaços de um megabyte. Cada uma dessas é uma **representação** do mesmo recurso.

Negociação de conteúdo é o protocolo pelo qual cliente e servidor combinam qual representação vai no fio. O cliente descreve preferências em headers `Accept*`; o servidor escolhe e informa a escolha em headers `Content-*`. E — este é o passo que quase todo mundo esquece — o servidor precisa declarar **em que critério** escolheu, com `Vary`, senão um cache no caminho serve a representação de um cliente para outro.

Duas formas, e a fonte nomeia as duas:

**Proativa (server-driven).** *"the browser […] sends several HTTP headers along with the URL. These headers describe the user's preferred choice. The server uses them as hints and an internal algorithm chooses the best content to serve to the client."* É o modo normal, e é o que este arquivo cobre.

**Reativa (agent-driven).** *"the server sends back a page that contains links to the available alternative resources when faced with an ambiguous request. The user is presented the resources and chooses the one to use."* Custa uma requisição a mais — *"one more request is needed to fetch the real resource, slowing the availability of the resource to the user"* — e na prática vira uma página de escolha de idioma.

A fonte lista três defeitos da proativa que valem como critério de projeto:

> - "The server doesn't have total knowledge of the browser […] the server choice is always somewhat arbitrary."
> - "The information from the client is quite verbose […] and a privacy risk (HTTP fingerprinting)."
> - "As several representations of a given resource are sent, shared caches are less efficient and server implementations are more complex."

O terceiro é o mais concreto: **negociar fragmenta o cache**. Cada dimensão negociada multiplica as entradas armazenadas pela mesma URL. Negocie o que precisa; para o resto, prefira URLs distintas (`/pedidos/8814.pdf`, `/pt-BR/sobre`).

---

## 2. `Accept*` e a sintaxe de qualidade

Os três headers que decidem código:

| Header | O que negocia | Exemplo |
| --- | --- | --- |
| `Accept` | media type do corpo | `application/json, text/html;q=0.8` |
| `Accept-Language` | idioma | `pt-BR, pt;q=0.9, en;q=0.5` |
| `Accept-Encoding` | compressão | `br, gzip;q=0.8, *;q=0.1` |

### Quality values (`q`)

> "The importance of a value is marked by the suffix `';q='` immediately followed by a value between `0` and `1` included, with up to three decimal digits, the highest value denoting the highest priority."

> "When not present, the default value is `1`."

```
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
```

| Valor | Prioridade |
| --- | --- |
| `text/html`, `application/xhtml+xml` | `1.0` |
| `application/xml` | `0.9` |
| `*/*` | `0.8` |

**A regra de desempate é por especificidade**, e é o detalhe que uma implementação caseira erra:

> "more specific values have priority over less specific ones"

```
Accept: text/html;q=0.8,text/*;q=0.8,*/*;q=0.8
```

Todos com `q=0.8`, mas a ordem de preferência é `text/html` (totalmente especificado) → `text/*` (parcial) → `*/*` (nada especificado). **Ordem de aparecimento no header não conta.** Um parser que faz `split(',')[0]` e ignora `q` funciona em quase todo request de browser e falha exatamente no cliente que se importa.

`q=0` significa *não aceito*, não *aceito com prioridade baixa*.

### Sobre `Accept-Language`, uma ressalva da fonte

> "a modified value can be used to fingerprint the user. It's not recommended to change it and a website can't trust this value to reflect the actual intention of the user."

A prescrição que segue é operacional: sempre ofereça um seletor de idioma; e *"Once a user has overridden the server-chosen language, a site should no longer use language detection and should stick with the explicitly chosen language."* O header serve para a **página de entrada**, não para governar a sessão inteira.

### `Accept-Encoding`

Diretivas verificadas: `gzip`, `compress`, `deflate`, `br` (Brotli), `zstd` (Zstandard), `dcb`, `dcz`, `identity`, `*`.

Duas regras que mudam código:

> "`identity` […] This value is always considered as acceptable, even if omitted."

> "As long as the `identity;q=0` or `*;q=0` directives do not explicitly forbid the `identity` value that means no encoding, the server must never return a `406 Not Acceptable` error."

Ou seja: **não comprimir é sempre uma resposta válida.** Um servidor que responde `406` porque não fala Brotli está errado — ele deveria servir sem compressão. E o coringa: *"`*` […] Matches any content encoding not already listed in the header. This is the default value if the header is not present."*

| ID | Regra |
| --- | --- |
| `HTTP-NEG-06` | Servidor **NEVER** responde `406` a um `Accept-Encoding` que não proíbe `identity` explicitamente (`identity;q=0` ou `*;q=0`) — servir sem compressão é sempre aceitável. |

---

## 3. `Content-Type`, `charset` e a fronteira do request

> "The HTTP `Content-Type` representation header is used to indicate the original media type of a resource before any content encoding is applied."

Duas direções, dois significados: *"In responses, the `Content-Type` header informs the client about the media type of the returned data. In requests such as `POST` or `PUT`, the client uses the `Content-Type` header to specify the type of content being sent to the server."*

**`charset`** — *"Indicates the character encoding standard used. The value is case insensitive but lowercase is preferred."* Para tipos textuais, omitir `charset` deixa a decodificação a cargo de heurística do cliente, e o sintoma é acentuação corrompida em ambiente que difere do seu.

```http
Content-Type: text/html; charset=utf-8
Content-Type: application/json
Content-Type: multipart/form-data; boundary=ExampleBoundaryString
```

**`boundary` é obrigatório em multipart** — *"For multipart entities, the `boundary` parameter is required."* Detalhe em e.

**O browser pode ignorar o seu `Content-Type`.** *"This value may be ignored if browsers perform MIME sniffing (or content sniffing) on responses. To prevent browsers from using MIME sniffing, set the `X-Content-Type-Options` header value to `nosniff`."* Isto é relevante para qualquer rota que devolva arquivo enviado por usuário: sem `nosniff`, um `.txt` com HTML dentro pode ser interpretado como HTML — ver.

### `415` e `406`: erros de formato nas duas pontas

Eles não são simétricos, e confundi-los produz o status errado.

| | `415 Unsupported Media Type` | `406 Not Acceptable` |
| --- | --- | --- |
| Sobre | o `Content-Type`/`Content-Encoding` **do request** | o `Accept*` **do request** |
| Quem errou | o cliente mandou formato que o servidor não processa | o servidor não consegue produzir o que o cliente pede |
| Header de ajuda | `Accept-Post`, `Accept-Patch` | lista dos tipos suportados |

`415`: *"the server refused to accept the request because the message content format is not supported. The format problem might be due to the request's indicated `Content-Type` or `Content-Encoding`, or as a result of processing the request message content."* Uma rota que só aceita JSON e recebe `text/plain` devolve `415`, não `400` — e acompanha o header de dica:

```http
HTTP/1.1 415 Unsupported Media Type
Accept-Post: application/json; charset=UTF-8
Content-Length: 0
```

A fonte inclui um aviso sobre rigor: *"sending `UTF8` instead of `UTF-8` to specify the UTF-8 charset may cause the server to consider the media type invalid."*

**`406` é raro na prática, e a própria fonte explica por quê:**

> "A server may return responses that differ from the request's accept headers. In such cases, a `200` response with a default resource that doesn't match the client's list of acceptable content negotiation values may be preferable to sending a 406 response."

Servir um default útil ganha de recusar. Some-se a regra do `identity` (§ 2) e sobra pouquíssimo caso legítimo para `406`.

| ID | Regra |
| --- | --- |
| `HTTP-NEG-02` | Resposta com media type textual (`text/*`) **MUST** declarar `charset` no `Content-Type`. |
| `HTTP-NEG-07` | Rota que recusa o `Content-Type` do request **MUST** responder `415` — não `400` — acompanhado de `Accept-Post` ou `Accept-Patch`. |

---

## 4. Compressão: `Content-Encoding` × `Transfer-Encoding`

A confusão clássica, resolvida por uma distinção de escopo.

**`Content-Encoding` é end-to-end.** *"End-to-end compression refers to a compression of the body of a message that is done by the server and will last unchanged until it reaches the client. Whatever the intermediate nodes are, they leave the body untouched."*

O ciclo: *"The browser sends an `Accept-Encoding` header with the algorithm it supports and its order of precedence, the server picks one, uses it to compress the body of the response and uses the `Content-Encoding` header to tell the browser the algorithm it has chosen."*

**`Transfer-Encoding` é hop-by-hop.** *"the compression doesn't happen on the resource in the server […] but on the body of the message between any two nodes on the path"*, negociado com `TE`. E o veredito da fonte: *"In practice, hop-by-hop compression is transparent for the server and the client, and is rarely used."*

A consequência prática de escrever o header errado: `Content-Encoding: gzip` diz ao cliente "descomprima este corpo". Se você o define sem comprimir de fato, o cliente falha na descompressão. E `Content-Encoding` muda o significado dos metadados: *"When the `Content-Encoding` header is present, other metadata (e.g., `Content-Length`) refer to the encoded form of the data, not the original resource."* — `Content-Length` é o tamanho comprimido.

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Encoding: br
Content-Length: 1841
Cache-Control: private, no-cache
Vary: Accept-Encoding
ETag: "pedidos-p2-9f31"
```

### O que não vale a pena comprimir

> "As compression works better on a specific kind of files, it usually provides nothing to compress them a second time. In fact, this is often counterproductive as the cost of the overhead (algorithms usually need a dictionary that adds to the initial size) can be higher than the extra gain in compression resulting in a larger file."

> "it is recommended to activate it for all files except already compressed ones like images, audio files and videos."

Recomprimir JPEG, PNG, WebP, MP4, MP3 ou ZIP gasta CPU para **aumentar** o arquivo. A regra é: comprima texto (HTML, CSS, JS, JSON, SVG, fontes não-WOFF2); não comprima mídia.

Sobre os algoritmos, a fonte é conservadora: *"Nowadays, only two are relevant: `gzip`, the most common one, and `br` the new challenger."* `zstd`, `dcb` e `dcz` existem na lista de diretivas de `Accept-Encoding` e `Content-Encoding`, mas o guia de compressão não os discute — trate `zstd` como opção, não como default.

| ID | Regra |
| --- | --- |
| `HTTP-NEG-03` | `Content-Encoding` **NEVER** é definido manualmente sem que o corpo tenha sido de fato comprimido naquele formato — e `Content-Length`, quando presente, **MUST** ser o tamanho comprimido. |
| `HTTP-NEG-04` | Compressão **NEVER** é aplicada a formato já comprimido (JPEG, PNG, WebP, MP4, ZIP). |
| `HTTP-NEG-05` | Compressão end-to-end **MUST** ser declarada em `Content-Encoding`; `Transfer-Encoding` **NEVER** é usado para isso. |

---

## 5. `Vary`: a contrapartida obrigatória

Negociar sem declarar `Vary` é o defeito estrutural desta área. O mecanismo está em [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) § 6; aqui fica a obrigação:

> "The server uses the `Vary` header to indicate which headers it actually used for content negotiation (or more precisely, the associated request headers), so that caches can work optimally."

> "The `Vary` header is needed to inform the cache of the decision criteria so that it can reproduce it."

E na página da compressão, sem meio-termo: *"the server **must** send a `Vary` header containing at least `Accept-Encoding` alongside this header in the response; that way, caches will be able to cache the different representations of the resource."* RFC 9110 § 12.5.5 diz o mesmo em linguagem normativa.

O sintoma da omissão é sempre o mesmo, com o nome de **cache envenenado**: o cache chaveia pela URL, guarda a primeira representação que passou, e serve essa a todos. Concretamente:

| Negociou por | Sem `Vary`, o que acontece |
| --- | --- |
| `Accept-Encoding` | um cliente que não fala Brotli recebe corpo Brotli e não consegue decodificar |
| `Accept-Language` | quem chegou primeiro define o idioma do site para todos |
| `Accept` | um cliente que pediu JSON recebe HTML, ou vice-versa |
| `Origin` (CORS) | a resposta traz o `Access-Control-Allow-Origin` de outra origem — [HTTP - CORS](http-cors.md) § 4 |

Nenhum deles loga erro no servidor, e nenhum reproduz em desenvolvimento — em dev não há cache compartilhado entre clientes.

**`Vary: *`** *"prevents caching from occurring, as the cache can't know what element is behind it."* Não use como atalho; use `Cache-Control: no-store`.

| ID | Regra |
| --- | --- |
| `HTTP-NEG-01` | Resposta cujo conteúdo foi escolhido a partir de um header `Accept*` **MUST** declarar esse header em `Vary` — resposta comprimida **MUST** trazer no mínimo `Vary: Accept-Encoding`. |

---

## 6. `Range` e `206`: requisição parcial

O mesmo princípio da negociação, aplicado a **quanto** do recurso trafega em vez de **em que forma**.

### Anúncio

> "If an HTTP response includes the `Accept-Ranges` header with any value other than `none`, the server supports range requests. If responses omit the `Accept-Ranges` header, it indicates the server doesn't support partial requests."

*"`Accept-Ranges: bytes` indicates that 'bytes' can be used as units to define a range (currently, no other unit is possible)."* Não anunciar é uma decisão com efeito visível: *"download managers can disable pause buttons that relied on range requests to resume a download."*

### Requisição e resposta

```http
GET /notas/8814.pdf HTTP/1.1
Host: arquivos.exemplo.com
Range: bytes=0-1023
```

```http
HTTP/1.1 206 Partial Content
Content-Type: application/pdf
Content-Length: 1024
Content-Range: bytes 0-1023/146515
Accept-Ranges: bytes
Cache-Control: private, max-age=3600
ETag: "nota-8814-a91c"
```

> "The `Content-Length` header indicates the size of the requested range, not the full size of the image. The `Content-Range` response header indicates where this partial message belongs within the full resource."

É o erro de implementação mais comum ao servir `Range` à mão: devolver `Content-Length` com o tamanho total do arquivo e o corpo com o tamanho do trecho. O cliente fica esperando bytes que não vêm.

**Múltiplos intervalos** produzem `multipart/byteranges`, cada parte com seu próprio `Content-Type` e `Content-Range`:

```http
HTTP/1.1 206 Partial Content
Content-Type: multipart/byteranges; boundary=3d6b6a416f9b5
Content-Length: 282
```

### `If-Range`: a retomada correta

> "When resuming to request more parts of a resource, you need to guarantee that the stored resource has not been modified since the last fragment has been received."

> "if the condition is fulfilled, the range request will be issued and the server sends back a `206` `Partial Content` answer with the appropriate body. If the condition is not fulfilled, the full resource is sent back, with a `200` `OK` status. This header can be used either with a `Last-Modified` validator, or with an `ETag`, but not with both."

```http
GET /notas/8814.pdf HTTP/1.1
Host: arquivos.exemplo.com
Range: bytes=1024-
If-Range: "nota-8814-a91c"
```

Um `200` de volta não é erro: é o servidor dizendo "mudou, recomece". O cliente precisa tratar os dois status — ignorar isso concatena um pedaço da versão antiga com um pedaço da nova, e o arquivo final é corrompido sem que nada acuse.

**O validador precisa ser forte.** RFC 9110 § 8.8.1 restringe `Range` a validadores fortes, e a MDN confirma pelo avesso: *"weak ETags prevent caching when byte range requests are used, but strong ETags mean range requests can still be cached."* Um `ETag: W/"..."` faz o `If-Range` falhar sempre e o download reiniciar do zero toda vez — ver `HTTP-CACHE-09`.

A alternativa mais flexível, também documentada: *"The more flexible one makes use of `If-Unmodified-Since` and `If-Match` and the server returns an error if the precondition fails; the client then restarts the download from the beginning."* `If-Range` é mais eficiente e menos flexível — *"only one ETag can be used in the condition."*

### `416`

> "A range request that is out of bounds will result in a `416` `Requested Range Not Satisfiable` status, meaning that none of the range values overlap the extent of the resource."

Servir o recurso inteiro com `200` quando o intervalo é inválido é o antipadrão correspondente: o cliente acha que recebeu o trecho pedido.

### Os dois casos de uso reais

> "Range requests are useful for various clients, including media players that support random access, data tools that require only part of a large file, and download managers that let users pause and resume a download."

**Retomar download.** Um arquivo grande cai na metade; o cliente pede `bytes=<recebido>-` com `If-Range` e continua.

**Seek em mídia.** O `<video>` do browser depende de `Range` para arrastar a barra de progresso. Um servidor que responde sempre `200` com o arquivo inteiro força o browser a baixar tudo antes de qualquer salto — o vídeo "não busca" e ninguém entende por quê.

**Você provavelmente não precisa implementar isso.** [Bun - HTTP e Servidor](bun-http-e-servidor.md) serve `Range`, `ETag` e `304` sozinho ao devolver `Bun.file(caminho)` numa `Response`, com `Content-Range` e `Content-Length` preenchidos — inclusive em `Bun.file(p).slice(start, end)`. Escrever o parser à mão é onde os erros desta seção aparecem. Para gerar corpo em pedaços a partir de outra fonte, ver e.

| ID | Regra |
| --- | --- |
| `HTTP-NEG-09` | Endpoint que aceita requisição parcial **MUST** anunciar `Accept-Ranges: bytes`. |
| `HTTP-NEG-10` | Resposta `206` **MUST** incluir `Content-Range`, e o `Content-Length` **MUST** ser o tamanho do trecho, não do recurso. |
| `HTTP-NEG-11` | `Range` fora dos limites do recurso **MUST** produzir `416` — **NEVER** `200` com o recurso inteiro. |
| `HTTP-NEG-12` | Retomada de download **MUST** enviar `If-Range` (ou `If-Match`/`If-Unmodified-Since`) com validador forte, e o cliente **MUST** tratar o `200` de resposta como "recomece do zero". |

---

## 7. `Content-Disposition`

> "The HTTP `Content-Disposition` header indicates whether content should be displayed _inline_ in the browser as a web page or part of a web page or downloaded as an _attachment_ locally."

`inline` é o default; `attachment` força o diálogo de salvar, *"prefilled with the value of the `filename` parameters if present"*.

```http
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="nota-8814.pdf"; filename*=UTF-8''nota-8814-anota%C3%A7%C3%B5es.pdf
Cache-Control: private, no-store
```

Os dois parâmetros de nome existem por causa de acentuação:

> "The parameters `filename` and `filename*` differ only in that `filename*` uses the encoding defined in RFC 5987, section 3.2. When both `filename` and `filename*` are present in a single header field value, `filename*` is preferred over `filename` when both are understood."

> "It's recommended to include both for maximum compatibility, and you can convert `filename*` to `filename` by substituting non-ASCII characters with ASCII equivalents (such as converting `é` to `e`)."

O mesmo header aparece **dentro** de um corpo `multipart/form-data`, com outro papel: *"The first directive is always `form-data`, and the header must also include a `name` parameter to identify the relevant field."* — `Content-Disposition: form-data; name="arquivo"; filename="nota.pdf"`. É a mesma sintaxe em dois contextos distintos; ver e.

| ID | Regra |
| --- | --- |
| `HTTP-NEG-08` | Resposta que força download **MUST** usar `Content-Disposition: attachment` com `filename` ASCII, acrescido de `filename*` quando o nome tiver caractere não-ASCII. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| Comprimir a resposta e não emitir `Vary: Accept-Encoding` | o cache serve corpo Brotli a cliente que não decodifica; o erro é do próximo visitante, não seu | `Vary: Accept-Encoding` — `HTTP-NEG-01` |
| Escolher idioma por `Accept-Language` sem `Vary` | quem chegou primeiro define o idioma para todos que compartilham o cache | `Vary: Accept-Language` — `HTTP-NEG-01` |
| Parser de `Accept` que faz `split(',')[0]` | ignora `q` e a regra de especificidade; falha justamente no cliente que negocia de verdade | ordenar por `q` e desempatar por especificidade — § 2 |
| Responder `406` porque o cliente não pediu o encoding disponível | `identity` é sempre aceitável; a fonte proíbe o `406` nesse caso | servir sem compressão — `HTTP-NEG-06` |
| Responder `400` a `Content-Type` não suportado | o status existe e carrega o header de dica que o cliente precisa | `415` + `Accept-Post`/`Accept-Patch` — `HTTP-NEG-07` |
| `text/html` sem `charset` | a decodificação vira heurística do cliente; acentuação quebra em ambientes diferentes do seu | `charset=utf-8` — `HTTP-NEG-02` |
| Gzipar JPEG/MP4/ZIP no proxy | gasta CPU e o arquivo sai maior por causa do dicionário | comprimir só texto — `HTTP-NEG-04` |
| `Content-Encoding: gzip` sem comprimir o corpo | o cliente tenta descomprimir e falha | definir o header só junto com a compressão real — `HTTP-NEG-03` |
| Usar `Transfer-Encoding` para anunciar gzip do recurso | é hop-by-hop, não descreve a representação; intermediários podem trocá-lo | `Content-Encoding` — `HTTP-NEG-05` |
| `206` com `Content-Length` do arquivo inteiro | o cliente espera bytes que nunca chegam e a conexão trava | `Content-Length` = tamanho do trecho — `HTTP-NEG-10` |
| Servir `Range` sem anunciar `Accept-Ranges` | clientes desabilitam pausa/retomada por não saber que há suporte | `Accept-Ranges: bytes` — `HTTP-NEG-09` |
| Responder `200` com tudo quando o `Range` é inválido | o cliente grava o recurso inteiro achando que é o trecho pedido | `416` — `HTTP-NEG-11` |
| Retomar download sem `If-Range` | o arquivo mudou entre os pedaços; o resultado é a concatenação de duas versões, sem erro visível | `If-Range` com `ETag` forte — `HTTP-NEG-12` |
| `If-Range` com `ETag: W/"..."` | validador fraco nunca satisfaz a condição; todo retomar vira download completo | `ETag` forte — `HTTP-CACHE-09` |
| Escrever o parser de `Range` à mão sobre `Bun.serve` | `Bun.file` já resolve `Range`, `Content-Range` e `ETag` | `new Response(Bun.file(p))` — [Bun - HTTP e Servidor](bun-http-e-servidor.md) |

---

## Checklist de revisão

- [ ] Toda resposta negociada declara o header correspondente em `Vary`? → `HTTP-NEG-01`
- [ ] Respostas `text/*` declaram `charset`? → `HTTP-NEG-02`
- [ ] `Content-Encoding` só aparece quando o corpo foi realmente comprimido? → `HTTP-NEG-03`
- [ ] A compressão exclui mídia já comprimida? → `HTTP-NEG-04`
- [ ] Nenhum `Transfer-Encoding` usado para compressão de recurso? → `HTTP-NEG-05`
- [ ] Nenhum `406` onde `identity` seria aceitável? → `HTTP-NEG-06`
- [ ] `Content-Type` não suportado devolve `415` com `Accept-Post`/`Accept-Patch`? → `HTTP-NEG-07`
- [ ] Download forçado usa `attachment` com `filename` e `filename*`? → `HTTP-NEG-08`
- [ ] Endpoint com suporte parcial anuncia `Accept-Ranges: bytes`? → `HTTP-NEG-09`
- [ ] `206` traz `Content-Range` e `Content-Length` do trecho? → `HTTP-NEG-10`
- [ ] `Range` inválido devolve `416`? → `HTTP-NEG-11`
- [ ] Retomada usa `If-Range` com validador forte e trata o `200`? → `HTTP-NEG-12`

---

## Relacionados

- [HTTP](http.md) — hub; § 5 tem a árvore "o cliente e o servidor discordam do formato/idioma/encoding"
- [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) (§ 6, `Vary`; `HTTP-CACHE-09`, `ETag` forte) · [HTTP - CORS](http-cors.md) · [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) · [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) · [HTTP - Specs e RFCs](http-specs-e-rfcs.md)
- · · ·
- [Bun - HTTP e Servidor](bun-http-e-servidor.md) (`Bun.file` serve `Range`/`ETag`/`304`) · [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) (`compress`, `etag`)
- · · · ·
- · ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Content negotiation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Content_negotiation)
- [Quality values](https://developer.mozilla.org/en-US/docs/Glossary/Quality_values)
- [Accept-Encoding](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Accept-Encoding) · [Content-Encoding](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Encoding) · [Content-Type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Type)
- [Compression in HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Compression)
- [Content-Disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Disposition)
- [HTTP range requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Range_requests) · [Conditional requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Conditional_requests)
- [406 Not Acceptable](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/406) · [415 Unsupported Media Type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/415) · [Vary](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Vary)
- [RFC 9110 — HTTP Semantics](https://httpwg.org/specs/rfc9110.html) § 8.8.1 (validador forte exigido em `Range`), § 12.5.5 (`Vary`)

**O que a verificação contrariou:**

- **`q` empatado desempata por especificidade, não por ordem no header.** `text/html;q=0.8` vence `text/*;q=0.8` vence `*/*;q=0.8`. Implementações caseiras ordenam por aparecimento e erram.
- **`identity` é sempre aceitável, mesmo omitido**, e por isso a fonte proíbe `406` para `Accept-Encoding` que não o vete explicitamente. Contraria o hábito de tratar `Accept-Encoding` como lista fechada.
- **`406` é desencorajado pela própria MDN:** *"a `200` response with a default resource […] may be preferable to sending a 406 response."* É status de referência, não de uso corrente.
- **A fonte considera só `gzip` e `br` relevantes hoje** — *"only two are relevant"*. `zstd`, `dcb` e `dcz` existem nas listas de diretivas mas não são discutidos no guia de compressão.
- **Recomprimir mídia aumenta o arquivo.** O overhead do dicionário supera o ganho. Contraria o hábito de "ligar gzip para tudo" no proxy.
- **`Content-Length` refere-se à forma codificada**, não ao recurso original, quando há `Content-Encoding`.
- **Hop-by-hop compression é rara.** *"In practice, hop-by-hop compression is transparent for the server and the client, and is rarely used."* A confusão `Transfer-Encoding` × `Content-Encoding` é sobre algo que quase ninguém usa de fato.
- **`Accept-Language` não é confiável como intenção do usuário**, e a fonte trata mudá-lo como vetor de fingerprinting. A prescrição é usá-lo só na página de entrada e respeitar a escolha explícita depois.
- **`If-Range` que falha devolve `200` com o recurso inteiro**, não um erro. Um cliente que não trata isso corrompe o arquivo concatenando versões.
- **`bytes` é a única unidade possível de `Range`** — *"currently, no other unit is possible"*.
- **`Content-Disposition` tem dois contextos**: header de resposta (`inline`/`attachment`) e header de parte dentro de `multipart/form-data` (`form-data; name=...`). Mesma sintaxe, papéis diferentes.
- **Não verificado:** a sintaxe completa de `Accept-CH`/Client Hints (a fonte marca como experimental e o suporte é parcial), e negociação reativa além da definição — a MDN não documenta um formato padrão para a página de alternativas.
