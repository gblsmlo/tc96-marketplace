---
titulo: HTTP - Cache e Requisições Condicionais
Link: https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Caching
tags:
 - http
 - cache
 - agent-context
source: "MDN Web Docs — https://developer.mozilla.org/en-US/docs/Web/HTTP"
verificado-em: 2026-08-15
---

# HTTP - Cache e Requisições Condicionais

> Cache privado × compartilhado · `Cache-Control` diretiva a diretiva · frescor heurístico e `Age` · revalidação com `ETag`/`If-None-Match` e `Last-Modified`/`If-Modified-Since` · `304` · `ETag` forte × fraco · `If-Match`/`If-Unmodified-Since` e escrita concorrente com `412` · `Vary` e cache envenenado · por que não existe purge no protocolo.
>
> **Não cobre:** quais métodos são cacheáveis e o que invalida cache por escrita ([HTTP - Métodos e Semântica](http-metodos-e-semantica.md)) · a semântica completa de `304` como redirecionamento e a família 4xx/5xx ([HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md)) · `Vary` como contrapartida da negociação e `Range`/`206` ([HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)) · `staleTime`/`gcTime` de cache de cliente em React ([TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md)).

Entrada: [HTTP](http.md) · Base normativa: [HTTP](http.md) § 6

---

## 1. Conceito: o cache não é uma otimização que você liga — é um contrato que você já assinou

A frase de abertura do guia da MDN não é retórica de introdução, é a regra operacional:

> "HTTP is designed to cache as much as possible, so even if no `Cache-Control` is given, responses will get stored and reused if certain conditions are met."

Quem não escreve `Cache-Control` não desligou o cache. Entregou a política ao **frescor heurístico** (§ 3): o cache olha o `Last-Modified`, estima quanto tempo o recurso provavelmente continuará válido, e reutiliza a resposta por esse prazo. A recomendação da especificação é reutilizar por cerca de **10% do intervalo desde a última modificação** (RFC 9111 § 4.2.2). Um HTML modificado pela última vez há um ano pode ficar mais de um mês em cache sem que o servidor tenha dito nada.

E o cache não é só o do browser. Há três perguntas que uma resposta HTTP responde, com ou sem a sua participação:

1. **Quem pode guardar isto?** — privado (browser de um usuário) × compartilhado (CDN, proxy reverso, service worker)
2. **Por quanto tempo pode ser servido sem perguntar de novo?** — `max-age`, `s-maxage`, ou heurística
3. **Quando ficar velho, como se confere se ainda vale?** — `ETag`/`Last-Modified` e a requisição condicional

Não responder é responder mal. O bug característico não é "o cache não funciona" — é **um usuário vendo a página de outro** porque uma resposta personalizada foi armazenada em cache compartilhado, ou **um deploy que não chega** porque um `max-age` longo já saiu para o mundo e não há como recolhê-lo.

### A fronteira com o cache de cliente — leia isto antes de confundir as camadas

Este arquivo trata do **cache de protocolo**: um contrato entre o servidor e todo intermediário no caminho, expresso em headers, obedecido por software que você não controla (o browser, a CDN, o proxy da operadora). [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) trata do **cache de cliente em memória**: uma estrutura de dados dentro da sua aplicação React, com `staleTime` e `gcTime`, que some ao recarregar a página.

| | `Cache-Control` (protocolo) | `staleTime` (TanStack Query) |
| --- | --- | --- |
| Onde vive | headers da resposta HTTP | memória do processo do browser |
| Quem obedece | browser, CDN, proxy, service worker | só o seu `QueryClient` |
| Quem declara | **servidor** | **cliente** |
| Sobrevive a reload | sim (cache de disco do browser) | não |
| Alcança requisição de `<img>`, CSS, fetch de terceiro | sim | não |
| Unidade de chave | URL + headers de `Vary` | `queryKey` |

**Um não substitui o outro, e configurar um não configura o outro.** `staleTime: 60_000` não impede o browser de servir do cache HTTP uma resposta que o servidor marcou `max-age=3600` — a `queryFn` chama `fetch`, e o `fetch` pode nem chegar à rede. O sintoma clássico: subir `staleTime` para "reduzir requisições" e não ver diferença no painel de rede, porque as requisições já estavam sendo servidas do cache de disco. O inverso também: `Cache-Control: no-store` no servidor não faz a query refazer — o `staleTime` continua mandando na decisão de **se** vai haver `fetch`.

A regra de divisão de trabalho é: **frescor perceptível pelo usuário dentro da sessão é do cliente; reaproveitamento entre sessões, entre usuários e na borda é do protocolo.** O raciocínio comum aos dois está em.

---

## 2. Privado × compartilhado, e por que `private` existe

A MDN separa por quem pode ler o que foi guardado:

> "A private cache is a cache tied to a specific client — typically a browser cache. […] Since the stored response is not shared with other clients, a private cache can store a personalized response for that user."

> "The shared cache is located between the client and the server and can store responses that can be shared among users."

Cache compartilhado se subdivide em **proxy cache** (transparente, no caminho, você não controla) e **managed cache** (CDN, proxy reverso, service worker — você controla e pode purgar).

`private` existe porque **o default é errado para conteúdo autenticado**. Uma resposta com `Cache-Control: max-age=600` e o perfil do usuário no corpo é armazenável em cache compartilhado, e a próxima pessoa que pedir a mesma URL recebe o perfil da anterior. `private` diz: guarde, mas só no browser de quem pediu.

```http
HTTP/1.1 200 OK
Content-Type: application/json
Cache-Control: private, no-cache
ETag: "pedido-8814-v3"
Set-Cookie: __Host-SID=AHNtAyt3fvJrUL5g5tnGwER; Secure; Path=/; HttpOnly
```

`private` **não** é um mecanismo de segurança — é uma instrução de armazenamento. Dado que não pode ser gravado em disco nenhum usa `no-store`. Sintaxe e semântica do cookie acima: [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md).

`public` é o inverso e tem um uso específico: *"Responses for requests with `Authorization` header fields must not be stored in a shared cache; however, the `public` directive will cause such responses to be stored in a shared cache."* Fora desse caso, `public` é ruído — a MDN é explícita: *"It is not required otherwise, because a response will be stored in the shared cache as long as `max-age` is given."*

---

## 3. `Cache-Control`, diretiva a diretiva, no que decide código

Só as diretivas que mudam uma decisão. A relação completa está na fonte.

| Diretiva | O que faz (fonte) | Quando você escreve isto |
| --- | --- | --- |
| `max-age=N` | *"the response remains fresh until N seconds after the response is generated"* | sempre que houver prazo conhecido |
| `s-maxage=N` | *"indicates how long the response remains fresh in a shared cache […] ignored by private caches, and overrides […] max-age"* | CDN guarda muito, browser guarda pouco |
| `no-cache` | *"the response can be stored in caches, but the response must be validated with the origin server before each reuse"* | HTML de app, JSON de recurso mutável |
| `no-store` | *"any caches of any kind (private or shared) should not store this response"* | dado que não pode tocar disco |
| `must-revalidate` | *"can be reused while fresh. If the response becomes stale, it must be validated with the origin server before reuse"* | proibir servir stale em queda de rede |
| `stale-while-revalidate=N` | *"the cache could reuse a stale response while it revalidates it to a cache"* | latência baixa com frescor eventual |
| `immutable` | *"the response will not be updated while it's fresh"* | asset com hash na URL |
| `private` / `public` | § 2 | resposta personalizada / resposta autenticada cacheável na borda |

**`no-cache` não é "não cacheie".** É a confusão mais cara do protocolo, e a fonte a desfaz em uma frase: *"does not prevent the storing of responses but instead prevents the reuse of responses without revalidation."* A resposta é armazenada; o cache só não pode servi-la sem perguntar. Combinada com `ETag`, essa pergunta custa um `304` de poucas dezenas de bytes. Quem queria `no-cache` e escreveu `no-store` trocou uma revalidação barata por um download inteiro a cada request.

O equivalente documentado: *"It is often stated that the combination of `max-age=0` and `must-revalidate` has the same meaning as `no-cache`."*

**`s-maxage` é o que separa a política da borda da política do browser.** É a única forma de dizer "CDN, segure isto por uma hora; browser, revalide sempre" — e é o mecanismo que torna uma CDN útil para HTML. `s-maxage` é ignorado por cache privado e sobrepõe `max-age` no compartilhado (RFC 9111 § 5.2.2.10).

```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Cache-Control: no-cache, s-maxage=60
ETag: "home-2026-08-15-a91c"
Vary: Accept-Encoding
```

**`immutable` só faz sentido com URL versionada.** Ele elimina a revalidação em reload — *"That prevents unnecessary revalidation during reloads"* — e por isso é uma promessa que você não pode quebrar: se o conteúdo daquela URL mudar, não há como avisar.

```http
HTTP/1.1 200 OK
Content-Type: text/javascript
Cache-Control: public, max-age=31536000, immutable
ETag: "YsAIAAAA-QG4G6kCMAMBAAAAAAAoK"
```

**A "kitchen sink" `no-store, no-cache, max-age=0, must-revalidate, proxy-revalidate` é folclore.** `no-store` já é terminal: nada é armazenado, e as outras quatro diretivas não têm sobre o que agir. Escreva `no-store` sozinho, ou escreva `no-cache` — que é o que quase sempre se queria.

### Frescor heurístico: o que acontece quando você não diz nada

Este é o parágrafo que mais evita bug. Sem `Cache-Control` e sem `Expires`, o cache **estima**:

```http
HTTP/1.1 200 OK
Content-Type: text/html
Date: Tue, 22 Feb 2022 22:22:22 GMT
Last-Modified: Tue, 22 Feb 2021 22:22:22 GMT
```

> "It is heuristically known that content which has not been updated for a full year will not be updated for some time after that. Therefore, the client stores this response (despite the lack of `max-age`) and reuses it for a while. How long to reuse is up to the implementation, but the specification recommends about 10% (in this case 0.1 year) of the time after storing."

Consequências que aparecem em produção: uma rota que devolve JSON sem `Cache-Control` mas com `Last-Modified` pode ser servida do cache por horas; um `GET` de leitura que você julgava sempre fresco não chega ao servidor; e como a heurística é *"up to the implementation"*, o comportamento difere entre browser, CDN e proxy — o bug reproduz num ambiente e não no outro.

O antídoto é uma linha: **declare.** Mesmo `Cache-Control: no-cache` é uma decisão; a ausência não é.

### `Age`: por que o cliente vê menos tempo do que você configurou

Cache compartilhado devolve `Age` — *"the time elapsed since the response was generated"*. Com `max-age=604800` e `Age: 86400`, *"the client which receives that response will find it to be fresh for the remaining 518400 seconds"*. Se você está depurando "por que o browser revalidou antes da hora", `Age` costuma ser a resposta: a CDN já tinha a cópia há dias.

| ID | Regra |
| --- | --- |
| `HTTP-CACHE-01` | Toda resposta de `GET` **MUST** declarar `Cache-Control` explicitamente — a ausência entrega a política ao frescor heurístico do cache, que é implementação-dependente. |
| `HTTP-CACHE-02` | Resposta personalizada por usuário (autenticada, derivada de cookie de sessão) **MUST** conter `private` ou `no-store` no `Cache-Control`. |
| `HTTP-CACHE-03` | `no-store` **NEVER** é usado com a intenção de "sempre revalidar" — essa intenção se escreve `no-cache`. |
| `HTTP-CACHE-04` | `max-age` acima de 24 horas **MUST** ser servido em URL versionada (hash ou versão no nome ou na query). |

---

## 4. Revalidação: `ETag` e `Last-Modified`

Quando a resposta fica stale, o cache não descarta — ele **pergunta**. A pergunta é uma requisição condicional, e ela carrega o validador que a resposta anterior trouxe.

```http
GET /pedidos/8814 HTTP/1.1
Host: api.exemplo.com
Accept: application/json
If-None-Match: "pedido-8814-v3"
```

```http
HTTP/1.1 304 Not Modified
Date: Tue, 22 Feb 2022 23:22:22 GMT
Cache-Control: private, max-age=300
ETag: "pedido-8814-v3"
Vary: Accept-Encoding
```

> "Since this response only indicates 'no change', there is no response body — there's just a status code — so the transfer size is extremely small."

E o efeito no cache: *"the client reverts the stored stale response back to being fresh and can reuse it during the remaining 1 hour."* Revalidar **renova** o prazo; não é só economia de banda.

**`ETag` é preferível a `Last-Modified`, e a razão é mecânica.** A MDN lista os problemas da data: *"the time format is complex and difficult to parse, and distributed servers have difficulty synchronizing file-update times."* Some-se a granularidade de um segundo — duas escritas no mesmo segundo produzem o mesmo `Last-Modified` e a segunda fica invisível para o cache. O `ETag` não tem forma imposta: *"There are no restrictions on how the server must generate the value, so servers are free to set the value based on whatever means they choose — such as a hash of the body contents or a version number."* Uma coluna `version` de linha do banco serve.

Quando os dois estão presentes, a precedência é definida: *"if both `If-Modified-Since` and `If-None-Match` are present, then `If-None-Match` takes precedence for the validator"* (RFC 9110). E a recomendação é mandar os dois: *"RFC9110 prefers that servers send both `ETag` and `Last-Modified` for a `200` response if possible."*

### `ETag` forte × fraco

```http
ETag: "33a64df5" ← forte: byte a byte idêntico
ETag: W/"33a64df5" ← fraco: semanticamente equivalente
```

> "W/ (case-sensitive) indicates that a weak validator is used."

> "Weak ETag values of two representations of the same resources might be semantically equivalent, but not byte-for-byte identical."

A diferença é operacional, não filosófica. **O validador fraco não serve para requisição parcial:** *"this means weak ETags prevent caching when byte range requests are used, but strong ETags mean range requests can still be cached"* — e RFC 9110 § 8.8.1 restringe `Range` e `If-Match` a validadores fortes. Um servidor que gera `W/` e depois tenta oferecer retomada de download (`If-Range`, § 3 de [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)) entrega o arquivo inteiro toda vez e não entende por quê.

Regra prática: **fraco para revalidação de leitura, forte para tudo que compara** — `If-Match`, `If-Range`, controle de concorrência.

### O que um `304` pode e não pode conter

> "The response must not contain a body"

E deve repetir o que a `200` equivalente traria — a MDN nomeia `Cache-Control`, `Content-Location`, `Date`, `ETag`, `Expires` e `Vary`. Isto é o que quase todo handler escrito à mão erra: devolve `304` sem `ETag`, e o cache perde o validador; ou devolve `304` sem `Vary`, e o cache passa a chavear a entrada pela URL apenas. A MDN reforça o ponto na página do `Vary`: *"The same `Vary` header value should be used on all responses for a given URL, including `304` `Not Modified` responses."*

E há um detalhe de compatibilidade que vira bug intermitente: *"Browser behavior differs if this response erroneously includes a body on persistent connections."* Um framework que serializa o corpo antes de decidir o status produz exatamente isso.

| ID | Regra |
| --- | --- |
| `HTTP-CACHE-05` | Resposta `200` de recurso que pode ser revalidado **MUST** incluir `ETag`; `Last-Modified` sozinho **NEVER** é o único validador quando o recurso pode mudar mais de uma vez por segundo. |
| `HTTP-CACHE-06` | Resposta `304` **NEVER** tem corpo e **MUST** repetir `ETag`, `Cache-Control`, `Date` e `Vary` da resposta `200` equivalente. |
| `HTTP-CACHE-07` | Rota `GET` que emite `ETag` **MUST** tratar `If-None-Match` e responder `304` quando o validador casa. |

---

## 5. `If-Match` e `If-Unmodified-Since`: o uso mais valioso e menos conhecido

A requisição condicional não é só cache. É o mecanismo de **controle de concorrência otimista do HTTP** — e é o uso que quase nenhuma API implementa, embora resolva um problema que quase toda API tem.

> "Conditional requests allow implementing the *optimistic locking algorithm* (used by most wikis or source control systems). The concept is to allow all clients to get copies of the resource, then let them modify it locally, controlling concurrency by successfully allowing the first client to submit an update. All subsequent updates, based on the now obsolete version of the resource, are rejected"

> "This is implemented using the `If-Match` or `If-Unmodified-Since` headers. If the ETag doesn't match the original file, or if the file has been modified since it has been obtained, the change is rejected with a `412 Precondition Failed` error."

O problema que isso elimina é a **atualização perdida**: duas telas abrem o pedido 8814, a primeira muda o endereço, a segunda muda o status a partir da cópia antiga e sobrescreve o endereço sem que ninguém veja um erro. Sem `If-Match`, o servidor não tem como distinguir "o cliente quer mesmo isto" de "o cliente não viu a versão nova".

O fluxo completo:

```http
GET /pedidos/8814 HTTP/1.1
Host: api.exemplo.com
Accept: application/json
```
```http
HTTP/1.1 200 OK
Content-Type: application/json
ETag: "pedido-8814-v3"
Cache-Control: private, no-cache
```
```http
PATCH /pedidos/8814 HTTP/1.1
Host: api.exemplo.com
Content-Type: application/json
If-Match: "pedido-8814-v3"

{"status":"confirmado"}
```
```http
HTTP/1.1 412 Precondition Failed
Content-Type: application/json

{"error":"o pedido foi alterado por outra pessoa","etagAtual":"pedido-8814-v5"}
```

No servidor, o `ETag` costuma ser a coluna de versão que o ORM já mantém:

```ts
// Concorrência otimista sem inventar protocolo: o ETag É a versão da linha.
async function atualizarPedido(id: string, ifMatch: string | null, patch: PatchPedido) {
 if (!ifMatch) {
 return { status: 400 as const, body: { error: 'header If-Match obrigatório' } }
 }
 const versaoEsperada = Number(ifMatch.replaceAll('"', '').split('-v').at(-1))
 const linhas = await db
.update(pedidos)
.set({...patch, versao: sql`${pedidos.versao} + 1` })
.where(and(eq(pedidos.id, id), eq(pedidos.versao, versaoEsperada)))
.returning

 if (linhas.length === 0) {
 const atual = await db.query.pedidos.findFirst({ where: eq(pedidos.id, id) })
 return atual
 ? { status: 412 as const, body: { error: 'conflito de versão', etagAtual: etagDe(atual) } }
 : { status: 404 as const, body: { error: 'pedido não encontrado' } }
 }
 return { status: 200 as const, etag: etagDe(linhas[0]), body: linhas[0] }
}

const etagDe = (p: { id: string; versao: number }) => `"pedido-${p.id}-v${p.versao}"`
```

Repare que o `UPDATE... WHERE versao = ?` faz o trabalho atômico: não há janela entre ler e escrever. O `412` é derivado do número de linhas afetadas, não de uma leitura anterior.

**`If-None-Match: *` é a variante para criação.** *"by adding `If-None-Match` with the special value of `*`, representing any ETag. The request will succeed, only if the resource didn't exist before"* — é um `PUT` que não sobrescreve, e resolve o mesmo problema que uma chave de idempotência resolve para `POST`.

**A ordem de avaliação é normativa** (RFC 9110 § 13.2.2): `If-Match` antes de `If-Unmodified-Since`; `If-None-Match` antes de `If-Modified-Since`. Um handler que checa a data primeiro produz resultado diferente do especificado quando os dois chegam juntos.

| ID | Regra |
| --- | --- |
| `HTTP-CACHE-08` | Rota `PUT`/`PATCH`/`DELETE` sobre recurso que mais de um cliente pode editar **MUST** aceitar `If-Match` e responder `412` quando o validador não casa. |
| `HTTP-CACHE-09` | `ETag` usado em `If-Match` ou `If-Range` **MUST** ser forte — sem o prefixo `W/`. |

---

## 6. `Vary` e o cache envenenado

O cache identifica uma entrada pela **URL**. Quando duas representações diferentes moram na mesma URL, isso é insuficiente:

> "the response from the server can depend on the values of the `Accept`, `Accept-Language`, and `Accept-Encoding` request headers."

`Vary` acrescenta headers à chave:

> "That causes the cache to be keyed based on a composite of the response URL and the `Accept-Language` request header — rather than being based just on the response URL."

O sintoma da ausência é o **cache envenenado**: o primeiro visitante pede `Accept-Language: pt-BR`, a CDN guarda a resposta em português sob a URL, e o visitante seguinte com `Accept-Language: en-US` recebe português. Nada quebra, nada loga, e o bug depende de quem chegou primeiro — por isso não reproduz em dev. Vale igual para `Accept-Encoding` (um cliente sem suporte a Brotli recebendo corpo Brotli) e para `Origin` em CORS ([HTTP - CORS](http-cors.md) § 5).

RFC 9110 § 12.5.5 é normativo: servidor que faz negociação **deve** emitir `Vary` com os headers usados na seleção. A contrapartida detalhada está em [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) § 5.

Dois cuidados que a fonte destaca:

**`Vary: User-Agent` é quase sempre errado.** *"the `User-Agent` request header generally has a very large number of variations, which drastically reduces the chance that the cache will be reused."* Você não fragmentou o cache — você o desligou.

**`Vary: Cookie` não é a forma de proteger conteúdo personalizado.** *"For applications that employ cookies to prevent others from reusing cached personalized content, you should specify `Cache-Control: private` instead of specifying a cookie for `Vary`."* O motivo é o mesmo: cada cookie de sessão é um valor único, e a chave composta nunca colide — mais entradas armazenadas, zero reaproveitamento, e o dado sensível continua num cache compartilhado.

**`Vary: *`** *"implies that the response is uncacheable"* — é uma forma obscura de dizer `no-store`; prefira `no-store`.

| ID | Regra |
| --- | --- |
| `HTTP-CACHE-10` | Resposta cujo corpo depende de algum header de request **MUST** listar esse header em `Vary`. |
| `HTTP-CACHE-11` | `Vary` **NEVER** inclui `Cookie` ou `User-Agent` para proteger conteúdo personalizado — use `Cache-Control: private`. |

---

## 7. Invalidação: por que não existe "purge" no protocolo

Não há verbo, header ou status que diga a um cache intermediário "descarte o que você tem". A MDN é direta:

> "There is no way to delete responses on an intermediate server that have been stored with a long `max-age`."

> "You may want to overwrite that response once it expired on the server, but there is nothing the server can do once the response is stored — since no more requests reach the server due to caching."

Os três recursos que existem, e o que cada um alcança:

| Mecanismo | Alcança | Não alcança |
| --- | --- | --- |
| Invalidação por método inseguro (RFC 9111 § 4.4): um `POST`/`PUT`/`DELETE` bem-sucedido invalida a URL alvo | o cache que **viu** aquela requisição passar | qualquer cache no caminho de outro cliente |
| `Clear-Site-Data: cache` | cache do browser | *"has no effect on intermediate caches"* |
| Purge de CDN (API ou painel) | o managed cache que você opera | o cache do browser do usuário |

Ou seja: **o que saiu com `max-age` longo saiu.** *"responses will remain in the browser cache until `max-age` expires, unless the user manually performs a reload, force-reload, or clear-history action."*

Isso produz duas estratégias, e a escolha entre elas é a decisão de cache mais consequente de um deploy:

**Subrecurso (JS, CSS, imagem, fonte): URL versionada + `max-age` longo + `immutable`.** *"Since the cache distinguishes resources from one another based on their URLs, the cache will not be reused again if the URL changes when a resource is updated."* Não há invalidação porque não há o que invalidar — a URL nova nunca esteve em cache. Ver.

**Recurso principal (HTML, JSON de API): `no-cache` + `ETag`.** *"Unlike subresources, main resources cannot be cache busted because their URLs can't be decorated in the same way."* A MDN prescreve:

> "If the server does not want to lose control of a URL — for example, in the case that a resource is frequently updated — you should add `no-cache` so that the server will always receive requests and send the intended responses."

```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Cache-Control: no-cache
ETag: "AAPuIbAOdvAGEETbgAAAAAAABAAE"
Last-Modified: Tue, 22 Feb 2022 20:20:20 GMT
```

E a nota que fecha o assunto: `no-cache`, não `no-store` — *"since we don't want to store HTML, but instead just want it to always be up-to-date"*. Armazenar e revalidar custa um `304`; não armazenar custa o documento inteiro.

**Uma ressalva sobre navegação de histórico:** *"the `no-cache` directive (or equivalent, such as `max-age=0, must-revalidate`) does not guarantee revalidation for history navigations — such as those made using the Back button."* Voltar não é recarregar.

| ID | Regra |
| --- | --- |
| `HTTP-CACHE-12` | Recurso cujo cache o servidor precisa poder derrubar antes do prazo **MUST** usar `no-cache` ou URL versionada — não existe purge de cache intermediário no protocolo. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| Não declarar `Cache-Control` em rota de leitura | o frescor heurístico assume o comando; a resposta é reutilizada por um prazo que a implementação escolhe | `Cache-Control` explícito, mesmo que seja `no-cache` — `HTTP-CACHE-01` |
| `no-store` quando se queria "revalide sempre" | proíbe armazenar; cada request baixa o corpo inteiro em vez de trocar um `304` | `no-cache` — `HTTP-CACHE-03` |
| `no-store, no-cache, max-age=0, must-revalidate, proxy-revalidate` | `no-store` já é terminal; as outras quatro não têm sobre o que agir | `no-store` sozinho, ou `no-cache` se o objetivo era revalidar |
| Resposta autenticada com `max-age` e sem `private` | é armazenável em cache compartilhado; o próximo usuário recebe o dado do anterior | `private` ou `no-store` — `HTTP-CACHE-02` |
| `max-age=31536000` em URL sem hash | não há como recolher; o deploy não chega a quem já baixou | URL versionada — `HTTP-CACHE-04` / § 7 |
| `immutable` em URL estável (`/app.js`) | promete que o conteúdo não muda; o browser nem revalida em reload | `immutable` só com hash na URL |
| `304` sem `ETag` ou sem `Vary` | o cache perde o validador ou a chave composta; a próxima revalidação vira download completo, ou a entrada passa a colidir entre representações | repetir os headers da `200` — `HTTP-CACHE-06` |
| `ETag: W/"..."` usado em `If-Match` ou `If-Range` | validador fraco não permite comparação byte a byte; a retomada de download baixa tudo de novo | `ETag` forte para comparação — `HTTP-CACHE-09` |
| `PATCH` sem `If-Match` em recurso multiusuário | atualização perdida silenciosa: a segunda escrita sobrescreve a primeira e ninguém vê erro | `If-Match` + `412` — `HTTP-CACHE-08` |
| Negociar idioma/encoding e não emitir `Vary` | a primeira resposta armazenada é servida a todos; o bug depende de quem chegou primeiro e não reproduz em dev | `Vary` com os headers usados — `HTTP-CACHE-10` |
| `Vary: Cookie` para isolar conteúdo por usuário | cada sessão vira uma entrada única; cache com 0% de reaproveitamento e o dado ainda no cache compartilhado | `Cache-Control: private` — `HTTP-CACHE-11` |
| Subir `staleTime` do TanStack Query para "reduzir requisições" | as requisições já podiam estar sendo servidas do cache HTTP; a camada errada foi ajustada | verificar `Cache-Control` da resposta antes — § 1 |
| Esperar que `Cache-Control: no-store` force refetch na tela | `no-store` age sobre armazenamento HTTP, não sobre o cache em memória do `QueryClient` | `staleTime`/invalidação no cliente — [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) |

---

## Checklist de revisão

- [ ] Toda rota de leitura declara `Cache-Control`? → `HTTP-CACHE-01`
- [ ] Resposta autenticada tem `private` ou `no-store`? → `HTTP-CACHE-02`
- [ ] Nenhum `no-store` onde a intenção era revalidar? → `HTTP-CACHE-03`
- [ ] `max-age` longo só em URL com hash/versão? → `HTTP-CACHE-04`
- [ ] `ETag` presente nas respostas revalidáveis? → `HTTP-CACHE-05`
- [ ] O `304` sai sem corpo e com `ETag`/`Cache-Control`/`Date`/`Vary`? → `HTTP-CACHE-06`
- [ ] O handler lê `If-None-Match` e devolve `304`? → `HTTP-CACHE-07`
- [ ] Escrita concorrente exige `If-Match` e devolve `412`? → `HTTP-CACHE-08`
- [ ] Os `ETag` usados em comparação são fortes? → `HTTP-CACHE-09`
- [ ] `Vary` declara todo header que influenciou o corpo? → `HTTP-CACHE-10`
- [ ] Nenhum `Vary: Cookie` nem `Vary: User-Agent`? → `HTTP-CACHE-11`
- [ ] Recurso que precisa ser derrubado usa `no-cache` ou URL versionada? → `HTTP-CACHE-12`

---

## Relacionados

- [HTTP](http.md) — hub; § 5 tem a árvore "este recurso pode ser cacheado, e por quanto tempo?"
- [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) · [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) · [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) · [HTTP - CORS](http-cors.md) · [HTTP - Specs e RFCs](http-specs-e-rfcs.md)
- · ·
- [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) — a outra camada; § 1 desta nota traça a fronteira
- · ·
- [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) · [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [HTTP caching](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Caching)
- [Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cache-Control)
- [Conditional requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Conditional_requests)
- [ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/ETag) · [Vary](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Vary)
- [304 Not Modified](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/304)
- [RFC 9111 — HTTP Caching](https://httpwg.org/specs/rfc9111.html) § 4.2.2 (frescor heurístico), § 4.4 (invalidação), § 5.2.2
- [RFC 9110 — HTTP Semantics](https://httpwg.org/specs/rfc9110.html) § 8.8.1 (validadores), § 12.5.5 (`Vary`), § 13.1.1 (`If-Match`/412), § 13.2.2 (precedência de precondições)

**O que a verificação contrariou:**

- **`no-cache` armazena.** A fonte é explícita: *"does not prevent the storing of responses but instead prevents the reuse of responses without revalidation."* O nome sugere o contrário e é a confusão mais cara do protocolo.
- **Não declarar `Cache-Control` não desliga o cache.** O frescor heurístico reutiliza a resposta por cerca de 10% do intervalo desde o `Last-Modified` (RFC 9111 § 4.2.2). A ausência de header é uma política, não a falta de uma.
- **A "kitchen sink" de diretivas é redundante.** A MDN lista `no-store, no-cache, max-age=0, must-revalidate, proxy-revalidate` como algo que se vê no mundo real; `no-store` já basta e as demais não agem.
- **`public` quase nunca é necessário.** Só muda o comportamento quando há `Authorization` no request. *"It is not required otherwise, because a response will be stored in the shared cache as long as `max-age` is given."*
- **`ETag` fraco quebra requisição parcial.** *"weak ETags prevent caching when byte range requests are used"* — a consequência não é teórica: retomada de download deixa de funcionar.
- **Não existe purge no protocolo.** *"There is no way to delete responses on an intermediate server that have been stored with a long `max-age`."* Purge é recurso de CDN, fora do HTTP; `Clear-Site-Data: cache` só alcança o browser.
- **`no-cache` não garante revalidação ao voltar no histórico.** *"does not guarantee revalidation for history navigations — such as those made using the Back button."*
- **`Vary: Cookie` é desaconselhado pela fonte** como forma de isolar conteúdo personalizado; o instrumento correto é `Cache-Control: private`.
- **`304` deve repetir `Vary`.** A página do `Vary` pede o mesmo valor em *todas* as respostas da URL, inclusive nos `304` — detalhe que handlers escritos à mão omitem.
- **Não verificado:** o comportamento exato de `stale-while-revalidate` além da definição de uma linha da MDN (janela, interação com `must-revalidate`, suporte por CDN) não foi confirmado nesta sessão. `Pragma: no-cache` e `Expires` foram deliberadamente omitidos como superfície de escrita — são compatibilidade com HTTP/1.0, não decisão de código novo.
