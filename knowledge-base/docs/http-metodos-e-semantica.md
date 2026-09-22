---
titulo: HTTP - Métodos e Semântica
Link: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods
tags:
 - http
 - metodos
 - api
 - agent-context
source: "MDN Web Docs — https://developer.mozilla.org/en-US/docs/Web/HTTP"
verificado-em: 2026-08-15
---
# HTTP - Métodos e Semântica

> As três propriedades (safe · idempotente · cacheável) e quais métodos têm quais · `GET` · `POST` × `PUT` × `PATCH` decididos por semântica · `DELETE` e a segunda chamada · `HEAD` e `OPTIONS` · `Allow` e `405` · corpo em `GET`, `HEAD` e `DELETE` · idempotência de desenho e retry seguro.
>
> **Não cobre:** qual status devolver em cada desfecho ([HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md)) · o que torna uma resposta cacheável na prática ([HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)) · o preflight `OPTIONS` do browser ([HTTP - CORS](http-cors.md)) · onde cada regra está escrita na spec ([HTTP - Specs e RFCs](http-specs-e-rfcs.md)).

Entrada: [HTTP](http.md) · Base normativa: [HTTP](http.md) § 6

---

## 1. Conceito: a semântica do método é um contrato com intermediários que você não controla

Entre o cliente e o seu handler há CDN, proxy, load balancer, o cache do browser, e — quando o cliente é um browser — o próprio agente do usuário. Nenhum deles lê o corpo da sua resposta nem entende o seu domínio. Todos eles leem o **método**, e agem sobre ele antes de o seu código existir na conversa.

O que eles fazem, verificado em RFC 9110 § 9.2:

- **Um cache guarda resposta de `GET` e de `HEAD`** sem que você autorize nada, e reutiliza para requisições subsequentes.
- **Um cliente pode repetir automaticamente uma requisição idempotente** cuja resposta se perdeu por falha de conexão. O texto é explícito: *"if a client sends a PUT request and the underlying connection is closed before any response is received, then the client can establish a new connection and retry the idempotent request"*.
- **Um proxy `MUST NOT` retentar automaticamente requisição não idempotente**, e um cliente `SHOULD NOT` fazê-lo sem saber que a operação é idempotente por desenho.
- **Um crawler faz `GET` em toda URL que encontra**, exatamente porque `GET` é safe.

Daí a consequência que decide o desenho: escolher `GET` para uma operação que escreve não é feio, é **entregar a terceiros a permissão de executá-la quantas vezes quiserem**. Escolher `POST` para uma operação retentável não é conservador, é **desligar o retry automático** que o cliente teria de graça.

E a responsabilidade é sua, não do servidor web. MDN é literal:

> "The web server itself (Apache, Nginx, or IIS) cannot enforce it by itself. In particular, an application should not allow `GET` requests to alter its state."

### As três propriedades

| Propriedade | Definição verificada | Quem age sobre ela |
| --- | --- | --- |
| **Safe** | *"a method is safe if it leads to a read-only operation"* — o cliente não pede, e não espera, mudança de estado | crawlers, prefetch de browser, ferramentas de link-check |
| **Idempotente** | *"the intended effect on the server of making a single request is the same as the effect of making several identical requests"* | clientes e proxies, ao decidir se podem retentar |
| **Cacheável** | a resposta pode ser armazenada e reutilizada para requisições subsequentes | todo cache no caminho |

Todo método safe é idempotente. A recíproca é falsa: `PUT` e `DELETE` são idempotentes e **não** são safe.

### A tabela que decide tudo

Reproduzida de MDN, sem edição:

| Método | Safe | Idempotente | Cacheável | Request tem corpo | Resposta de sucesso tem corpo |
| --- | --- | --- | --- | --- | --- |
| `GET` | sim | sim | sim | não | sim |
| `HEAD` | sim | sim | sim | não | **não** |
| `OPTIONS` | sim | sim | não | não¹ | sim |
| `TRACE` | sim | sim | não | não | sim |
| `PUT` | não | **sim** | não | sim | pode |
| `DELETE` | não | **sim** | não | não | pode |
| `POST` | não | não | condicional² | sim | sim |
| `PATCH` | não | não | condicional² | sim | pode |
| `CONNECT` | não | não | não | sim | sim |

¹ A página de `OPTIONS` registra "pode": um corpo é tecnicamente permitido mas *"has no defined semantics"*.
² *"`POST` and `PATCH` are cacheable when responses explicitly include freshness information and a matching `Content-Location` header."*

**`GET` e `HEAD` são os únicos obrigatórios.** RFC 9110 § 9.1: *"All general-purpose servers MUST support the methods GET and HEAD. All other methods are OPTIONAL."*

E o método é **case-sensitive** — `get` não é `GET`. Nome de header, na mesma mensagem, é case-insensitive. As duas regras convivem e são opostas.

| ID | Regra |
| --- | --- |
| `HTTP-METH-01` | Handler de `GET`, `HEAD` ou `OPTIONS` **NEVER** escreve estado de domínio; ação destrutiva **NEVER** é exposta por parâmetro de query numa rota safe (`?acao=excluir`). |

---

## 2. `GET`: recuperar uma representação, e nada mais

`GET` pede a transferência da representação selecionada do recurso. É o método sobre o qual toda a otimização da web foi construída — cache, prefetch, CDN, índice de busca — e o preço de entrada nessa otimização é a promessa de que ele não muda nada.

```http
GET /pedidos?pagina=2&status=aberto HTTP/1.1
Host: api.exemplo.com
Accept: application/json
If-None-Match: "a1b2c3"
```

Duas coisas que a spec diz sobre `GET` e que mudam código:

**A query string é parte do identificador do recurso, e ela vaza.** RFC 9110 § 9.3.1 alerta que dados construídos a partir de entrada do usuário *"might be provided that would not be appropriate for disclosure within a URI"* — a URL aparece em log de proxy, em `Referer`, no histórico do browser e na barra de endereços. Filtro e paginação pertencem à query; token, senha e documento não.

**`Range` transforma `GET` numa requisição parcial**, sem deixar de ser `GET`. Ver [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md).

> **"Meu filtro não cabe na URL, então vou usar `POST`."** É uma troca legítima e a própria spec a menciona, mas nomeie o que você está pagando: perde cache, perde prefetch, perde retry automático, e a rota deixa de ser marcável como somente-leitura por qualquer ferramenta. Se o motivo é comprimento, o limite prático é do servidor e do proxy, não do protocolo — meça antes de trocar.

---

## 3. `PUT` × `PATCH` × `POST`: decidido por semântica, não por hábito

O hábito diz "criar é `POST`, atualizar é `PUT`, atualizar um campo é `PATCH`". Isso acerta na maioria dos casos pelo motivo errado, e erra exatamente onde importa. O critério real são duas perguntas:

1. **Repetir a requisição idêntica deixa o recurso no mesmo estado?** → se sim, é `PUT` ou `DELETE`; se não, é `POST` ou `PATCH`.
2. **O corpo é o novo estado do recurso, ou é uma instrução sobre ele?** → estado é `PUT`; instrução é `PATCH`.

| | `PUT` | `PATCH` | `POST` |
| --- | --- | --- | --- |
| O corpo é | a representação **inteira** e nova | um conjunto de **instruções** de modificação | entrada para processamento específico do recurso |
| Idempotente | **sim** | **não** | não |
| Quem escolhe a URI | o **cliente** (o alvo é o recurso final) | — (o recurso já existe) | o **servidor** |
| Resposta típica | `201` se criou, `200`/`204` se alterou | `200` ou `204` | `201` + `Location` se criou |
| Campo omitido no corpo | é **apagado** — substituição é total | fica como está | — |

MDN é literal sobre a diferença:

> "In comparison with `PUT`, a `PATCH` serves as a set of instructions for modifying a resource, whereas `PUT` represents a complete replacement of the resource."

**O exemplo que fixa a assimetria de idempotência** é o do contador. Um recurso com campo auto-incremental: `PUT` sobrescreve o contador junto com o resto, e repetir dá o mesmo estado; `PATCH` pode conter a instrução "incremente", e repetir não dá. **`PUT` não é idempotente porque envia tudo — é idempotente porque substitui em vez de operar sobre o valor anterior.**

```http
PUT /pedidos/p-4471 HTTP/1.1
Host: api.exemplo.com
Content-Type: application/json

{"clienteId":"c-901","status":"confirmado","itens":[{"sku":"SKU-12","quantidade":2}]}
```

```http
HTTP/1.1 204 No Content
Content-Location: /pedidos/p-4471
ETag: "d4e5f6"
```

Repare no que o `PUT` acima significa: **`itens` agora é exatamente aquela lista.** Um cliente que quisesse só mudar o status e mandasse `{"status":"confirmado"}` num `PUT` estaria pedindo para apagar `clienteId` e `itens`. Esse é o bug mais comum de `PUT` mal implementado — e o servidor que "ignora campos ausentes" para ser gentil transformou seu `PUT` num `PATCH` mentindo o nome.

```http
PATCH /pedidos/p-4471 HTTP/1.1
Host: api.exemplo.com
Content-Type: application/merge-patch+json

{"status":"confirmado"}
```

O `Content-Type` de um `PATCH` importa mais que o de um `PUT`, porque ele declara **qual linguagem de instrução** o corpo usa. Um servidor que não reconhece o formato responde `415` ([HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) § 4). Um servidor pode anunciar o que aceita com `Accept-Patch` numa resposta de `OPTIONS`, e pode listar `PATCH` em `Allow`.

**`POST` é o método aberto.** RFC 9110 § 9.3.3 o define como *"requests that the target resource process the representation enclosed in the request according to the resource's own specific semantics"* — criar recurso ainda sem identificador, submeter formulário, anexar dado, enfileirar job, disparar ação. Quando nenhuma das outras semânticas cabe, `POST` é a resposta correta, não a preguiçosa.

Uma consequência de `POST` ser aberto: quando ele cria, a spec diz `SHOULD` responder `201` com `Location` apontando para o recurso criado. Sem o `Location`, o cliente que acabou de criar não sabe onde o recurso mora.

```http
POST /pedidos HTTP/1.1
Host: api.exemplo.com
Content-Type: application/json
Idempotency-Key: 8f14e45f-ea6a-4c1b-9a2e-3d5b7c0a1f22

{"clienteId":"c-901","itens":[{"sku":"SKU-12","quantidade":2}]}
```

```http
HTTP/1.1 201 Created
Location: /pedidos/p-4471
Content-Type: application/json; charset=utf-8

{"id":"p-4471","status":"aberto"}
```

| ID | Regra |
| --- | --- |
| `HTTP-METH-03` | `PUT` **MUST** substituir a representação inteira do recurso; endpoint que ignora campos ausentes **NEVER** se chama `PUT` — é `PATCH`. |
| `HTTP-METH-04` | Handler de `PUT` ou `DELETE` **MUST** produzir o mesmo estado final quando a mesma requisição chega duas vezes. |
| `HTTP-METH-05` | Resposta de `POST` que criou um recurso **MUST** ser `201` com `Location` apontando para ele. |

---

## 4. `DELETE`: idempotente, e a segunda chamada

`DELETE` é idempotente e **não** é safe. A confusão vem de olhar para o status em vez do estado: MDN mostra a sequência sem rodeios.

```http
DELETE /pedidos/p-4471 HTTP/1.1 → 204
DELETE /pedidos/p-4471 HTTP/1.1 → 404
DELETE /pedidos/p-4471 HTTP/1.1 → 404
```

> "The response returned by each request may differ: for example, the first call of a `DELETE` will likely return a `200`, while successive ones will likely return a `404`."

**Idempotente é sobre o efeito no servidor, não sobre a resposta.** Depois de qualquer número de chamadas, o pedido não existe — que é o efeito pretendido de uma. O `404` da segunda chamada não é violação: é a descrição honesta do estado atual.

Isso deixa uma decisão de desenho real, e ela não tem resposta única na spec:

| O que devolver na segunda chamada | Quando faz sentido | Custo |
| --- | --- | --- |
| `404 Not Found` | recurso pode nunca ter existido; é a leitura literal do estado | um cliente que retenta por timeout vê "falhou" quando na verdade deu certo |
| `204 No Content` | o cliente só quer garantir a ausência (o caso mais comum em API interna) | esconde erro de digitação de ID |
| `410 Gone` | remoção definitiva e você quer que caches e crawlers parem de perguntar | só vale se a ausência for permanente por desenho |

Os três desfechos possíveis de um `DELETE` bem-sucedido, verificados em MDN: `204` quando não há nada a dizer; `200` quando o corpo descreve o resultado; `202` quando a remoção foi aceita mas ainda não aconteceu — que é o caso de exclusão assíncrona e liga em.

---

## 5. `HEAD`, `OPTIONS`, `Allow` e o `405`

### `HEAD`

`HEAD` é *"identical to GET except that the server MUST NOT send content in the response"*. Serve para obter metadados — tamanho, validador, data de modificação, existência — sem transferir o corpo.

```http
HEAD /relatorios/2026-08.csv HTTP/1.1
Host: api.exemplo.com
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv; charset=utf-8
Content-Length: 4821904
Last-Modified: Fri, 15 Aug 2026 03:12:00 GMT
ETag: "9b7c1a"
Accept-Ranges: bytes
```

O servidor `SHOULD` mandar os mesmos headers que mandaria num `GET`, mas `MAY` omitir os que só são conhecidos ao gerar o corpo — `Content-Length` e `Vary` de uma resposta dinâmica são os exemplos que a spec dá. Um cliente que depende de `Content-Length` vindo de `HEAD` numa rota dinâmica está apostando num `MAY`.

Como `HEAD` e `GET` compartilham a rota, implementá-los separadamente é a fonte clássica de divergência: `HEAD` respondendo `404` numa URL onde `GET` responde `200`. A maioria dos frameworks deriva `HEAD` de `GET` sozinha — confirme antes de escrever um handler dedicado.

### `OPTIONS`

`OPTIONS` descreve as opções de comunicação de um recurso. Dois usos, e só um deles é seu:

```http
OPTIONS /pedidos HTTP/1.1
Host: api.exemplo.com
```

```http
HTTP/1.1 204 No Content
Allow: OPTIONS, GET, HEAD, POST
```

A forma **asterisco** (`OPTIONS * HTTP/1.1`) pergunta pelo servidor inteiro, não por um recurso.

O outro uso é o **preflight de CORS**, que o browser emite sozinho antes de uma requisição cross-origin não simples, com `Access-Control-Request-Method` e `Access-Control-Request-Headers`. É o mesmo método, com semântica combinada por outra spec — e é por isso que uma rota que não trata `OPTIONS` quebra o frontend inteiro sem nenhum erro no servidor. Ver [HTTP - CORS](http-cors.md).

### `Allow` e o `405`

`Allow` lista os métodos que o **recurso** suporta. A obrigação é normativa e verificada nas duas fontes — RFC 9110 § 15.5.6: *"The origin server MUST generate an Allow header field in a 405 response containing a list of the target resource's currently supported methods."*

```http
DELETE /pedidos/p-4471/itens HTTP/1.1
Host: api.exemplo.com
```

```http
HTTP/1.1 405 Method Not Allowed
Allow: GET, POST
Content-Length: 0
```

A distinção com `501`: `405` é *método conhecido, recurso não aceita*; `501` é *o servidor não implementa esse método em lugar nenhum*. Um `DELETE` numa coleção que só lê e escreve é `405`; um `PROPFIND` numa API REST é `501`.

**O ponto prático que mais custa:** vários frameworks devolvem `404` quando o path existe mas o método não. Isso é indistinguível de "recurso inexistente" para quem depura, e viola a obrigação do `Allow`. Em Hono, o middleware `hono/method-not-allowed` é o que corrige — sem ele, *método não suportado em rota existente devolve `404`* ([Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) § 5).

| ID | Regra |
| --- | --- |
| `HTTP-METH-06` | Toda rota que responde `GET` **MUST** responder `HEAD` na mesma URL, com os mesmos headers e **sem corpo**. |
| `HTTP-METH-07` | Resposta `405` **MUST** incluir `Allow` com os métodos que o recurso suporta; método não permitido em path existente **NEVER** é respondido com `404`. |

---

## 6. Corpo em `GET`, `HEAD` e `DELETE`: o que a spec realmente diz

"A spec proíbe corpo em `GET`" é impreciso. O texto de RFC 9110 § 9.3.1 é este, e se repete quase literalmente em `HEAD` (§ 9.3.2) e em `DELETE` (§ 9.3.5):

> "content received in a GET request has no generally defined semantics, cannot alter the meaning or target of the request, and might lead some implementations to reject the request and close the connection because of its potential as a request smuggling attack."

E a norma: *"A client SHOULD NOT generate content in a GET request unless it is made directly to an origin server that has previously indicated... that such a request has a purpose and will be adequately supported."* Mais: o origin server *"SHOULD NOT rely on private agreements to receive content, since participants in HTTP communication are often unaware of intermediaries along the request chain."*

Traduzindo para decisão:

- **Não é proibido, é indefinido.** Nada no protocolo dá sentido àqueles bytes.
- **Intermediários podem descartar ou rejeitar**, e o motivo citado é segurança — request smuggling.
- **Um acordo privado entre seu cliente e seu servidor não basta**, porque a spec avisa que há gente no meio que não sabe do acordo. É exatamente esse o modo de falha: funciona em `localhost`, quebra atrás da CDN.
- MDN acrescenta que *"some servers may reject the request with a 4XX client error response"*.

A saída para consulta grande é `POST` como transporte (§ 2), aceitando a perda de cache — ou, quando o dado cabe, query string.

| ID | Regra |
| --- | --- |
| `HTTP-METH-02` | Cliente **NEVER** envia corpo em `GET`, `HEAD` ou `DELETE`; servidor **NEVER** define contrato que dependa desse corpo. |

---

## 7. Idempotência é decisão de desenho, não do cliente

O cliente não pode inventar segurança de retry. Ele só sabe uma coisa: o método. E o que ele pode fazer com essa informação está escrito:

> "A client SHOULD NOT automatically retry a request with a non-idempotent method unless it has some means to know that the request semantics are actually idempotent, regardless of the method, or some means to detect that the original request was never applied."
> — RFC 9110 § 9.2.2

Duas leituras, ambas importantes.

**Primeira: retentar `POST` é escolha da API, não do cliente.** Se o desenho não oferece "algum meio de saber", o cliente correto **não** retenta — e uma criação que falhou por timeout de rede simplesmente falha, mesmo tendo sido aplicada no servidor. Configurar `retry` no cliente para uma mutation de `POST` sem esse meio é criar pedidos duplicados por conta própria. Ver.

**Segunda: o "meio de saber" é a chave de idempotência**, e ela é responsabilidade do servidor. O padrão é um header com um identificador gerado pelo cliente, que o servidor persiste junto com o resultado da primeira execução:

```http
POST /pedidos HTTP/1.1
Host: api.exemplo.com
Content-Type: application/json
Idempotency-Key: 8f14e45f-ea6a-4c1b-9a2e-3d5b7c0a1f22

{"clienteId":"c-901","itens":[{"sku":"SKU-12","quantidade":2}]}
```

A segunda chegada da mesma chave **não executa de novo** — devolve o resultado guardado, com o mesmo `201` e o mesmo `Location`. O conceito e as armadilhas de janela e colisão estão em.

```ts
// Hono — a chave é um header, e o target `header` usa chave minúscula (HONO-RPC-03).
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import * as z from 'zod'

const criarPedidoSchema = z.object({
 clienteId: z.string.uuid,
 itens: z.array(z.object({ sku: z.string, quantidade: z.number.int.positive })).min(1),
})

const chaveSchema = z.object({ 'idempotency-key': z.string.uuid })

const pedidos = new Hono.post(
 '/pedidos',
 zValidator('header', chaveSchema),
 zValidator('json', criarPedidoSchema),
 async (c) => {
 const chave = c.req.valid('header')['idempotency-key']

 const jaExecutado = await buscarResultadoPorChave(chave)
 if (jaExecutado) {
 // mesma resposta da primeira execução — o cliente não distingue
 return c.json(jaExecutado.corpo, 201, { Location: jaExecutado.location })
 }

 const pedido = await criarPedido(c.req.valid('json'))
 await guardarResultado(chave, pedido)
 return c.json({ id: pedido.id, status: pedido.status }, 201, {
 Location: `/pedidos/${pedido.id}`,
 })
 }
)
```

**O que a chave de idempotência não resolve:** ela não torna `POST` idempotente para intermediários. Um proxy continua proibido de retentar, porque ele não sabe que a chave existe. Quem passa a poder retentar é o **seu** cliente, que conhece o contrato — e é por isso que isso pertence à documentação da API, não a uma suposição.

Vale a recíproca também, e ela é menos lembrada: **um `PUT` só é retentável se o handler for realmente idempotente.** Um handler de `PUT` que faz `historico.push(...)` a cada chamada quebrou a promessa que o método faz aos intermediários, e o retry automático que a spec autoriza vai duplicar linhas. A propriedade é do método na spec e do seu código na prática; só uma das duas você controla.

| ID | Regra |
| --- | --- |
| `HTTP-METH-08` | Cliente **NEVER** configura retry automático para `POST` ou `PATCH` sem que a API declare suporte a chave de idempotência. |
| `HTTP-METH-09` | Endpoint `POST` que cria recurso e é chamado por cliente com retry **MUST** aceitar um header de chave de idempotência e devolver o resultado da primeira execução nas chamadas repetidas. |
| `HTTP-METH-10` | Resposta de `POST` ou `PATCH` **NEVER** declara frescor em `Cache-Control` sem `Content-Location` igual à URI alvo. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `GET /pedidos/p-4471/cancelar` | crawler, prefetch e link-checker cancelam pedidos; nenhum log mostra "quem clicou" | `POST /pedidos/p-4471/cancelamentos` — `HTTP-METH-01` |
| `PUT` que ignora campos ausentes no corpo | o nome promete substituição total e o comportamento é de merge; dois clientes com expectativas opostas na mesma rota | `PATCH` com media type declarado — `HTTP-METH-03` |
| `PATCH` para substituir o objeto inteiro | perde a idempotência de graça: o cliente não pode retentar o que poderia | `PUT` — § 3 |
| `POST` para tudo, inclusive substituição | desliga retry automático e cache; a API deixa de ser legível por ferramenta | escolher pela árvore de [HTTP](http.md) § 5.1 |
| `DELETE` que responde `500` na segunda chamada | o handler assume que o recurso existe; o retry legítimo de um timeout vira erro de servidor | `204` ou `404` — `HTTP-METH-04` |
| `GET` com corpo JSON para "consulta complexa" | indefinido pela spec; intermediário pode descartar o corpo ou fechar a conexão por suspeita de smuggling | `POST` como transporte, ou query string — `HTTP-METH-02` |
| Rota que responde `GET` e devolve `404` em `HEAD` | monitoramento e link-check reportam a rota como quebrada | derivar `HEAD` de `GET` — `HTTP-METH-06` |
| Método não permitido devolvendo `404` | indistinguível de recurso inexistente; o cliente não descobre quais métodos existem | `405` + `Allow` — `HTTP-METH-07` |
| Nenhuma rota tratando `OPTIONS` | o preflight do browser recebe `404`/`405` e a chamada real nunca sai | middleware de CORS — [HTTP - CORS](http-cors.md), [HTTP](http.md) § 8.2 |
| `retry: 3` no cliente para uma mutation de `POST` | cada timeout de rede vira um pedido duplicado; o erro aparece dias depois, na conciliação | chave de idempotência, ou nenhum retry — `HTTP-METH-08` |
| `PUT` cujo handler acumula histórico a cada chamada | o método promete idempotência aos intermediários e o código não cumpre; o retry autorizado pela spec duplica | tornar o efeito realmente substitutivo — `HTTP-METH-04` |
| Comparar `c.req.method` com `'get'` minúsculo | o token do método é case-sensitive e chega `GET` | comparar com o token em maiúsculas — § 1 |

---

## Checklist de revisão

- [ ] Nenhum handler de `GET`/`HEAD`/`OPTIONS` escreve? → `HTTP-METH-01`
- [ ] Nenhum cliente envia corpo em `GET`, `HEAD` ou `DELETE`? → `HTTP-METH-02`
- [ ] Todo `PUT` substitui a representação inteira? → `HTTP-METH-03`
- [ ] `PUT` e `DELETE` chamados duas vezes deixam o mesmo estado? → `HTTP-METH-04`
- [ ] `POST` que cria devolve `201` com `Location`? → `HTTP-METH-05`
- [ ] Toda rota `GET` responde `HEAD` sem corpo? → `HTTP-METH-06`
- [ ] Método não permitido devolve `405` com `Allow`, não `404`? → `HTTP-METH-07`
- [ ] Nenhum retry automático de `POST`/`PATCH` sem chave de idempotência? → `HTTP-METH-08`
- [ ] Endpoints de criação retentáveis aceitam chave de idempotência? → `HTTP-METH-09`
- [ ] Nenhuma resposta de `POST`/`PATCH` declara frescor sem `Content-Location`? → `HTTP-METH-10`
- [ ] Alguma rota trata `OPTIONS` para o preflight? → [HTTP - CORS](http-cors.md)

---

## Relacionados

- [HTTP](http.md) — hub; § 5.1 tem a árvore de escolha de método
- [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) · [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) · [HTTP - CORS](http-cors.md) · [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md) · [HTTP - Specs e RFCs](http-specs-e-rfcs.md)
- · ·
- · ·
- [Hono - Middleware e Ciclo de Vida](hono-middleware-e-ciclo-de-vida.md) · [Hono - Validação e RPC](hono-validacao-e-rpc.md) · [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Elysia - Roteamento e Handler](elysia-roteamento-e-handler.md)
- · ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [HTTP request methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods) — tabela-resumo de propriedades
- [GET](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods/GET) · [PUT](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods/PUT) · [PATCH](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods/PATCH) · [DELETE](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods/DELETE) · [OPTIONS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods/OPTIONS)
- [Glossary: Safe](https://developer.mozilla.org/en-US/docs/Glossary/Safe/HTTP) · [Glossary: Idempotent](https://developer.mozilla.org/en-US/docs/Glossary/Idempotent)
- [Allow](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Allow) · [405 Method Not Allowed](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/405)
- [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.txt) § 9.1, § 9.2.1, § 9.2.2, § 9.2.3, § 9.3.1 (GET), § 9.3.2 (HEAD), § 9.3.3 (POST), § 9.3.4 (PUT), § 15.5.6 (405)

**O que a verificação contrariou:**

- **Corpo em `GET` não é proibido — é indefinido**, e o motivo citado para rejeição é **request smuggling**, não pedantismo de spec. O mesmo parágrafo aparece em `HEAD` e em `DELETE`. A spec ainda diz que o origin server `SHOULD NOT` confiar em acordos privados sobre esse corpo, porque há intermediários que não sabem do acordo.
- **`POST` e `PATCH` são cacheáveis condicionalmente**, quando a resposta traz frescor explícito **e** `Content-Location` igual à URI alvo. RFC 9110 § 9.3.3 acrescenta que essa resposta cacheada pode satisfazer um `GET` ou `HEAD` posterior, nunca outro `POST`. E § 9.2.3 registra que *"the overwhelming majority of cache implementations only support GET and HEAD"* — a possibilidade existe na spec e quase não existe na prática.
- **`OPTIONS` pode ter corpo**, mas *"has no defined semantics"*. Não é a proibição que a tabela de "request tem corpo" sugere à primeira leitura.
- **Métodos safe podem ter efeito colateral.** RFC 9110 § 9.2.1 cita explicitamente log de acesso e até cobrança de conta de anúncio como aceitáveis. A garantia é sobre o que o **cliente pediu**, não sobre o que o servidor faz.
- **Idempotência é sobre o efeito, não sobre a resposta.** A própria MDN documenta `DELETE` devolvendo `200` e depois `404` como exemplo de método idempotente.
- **`PATCH` não é idempotente por definição do método** — a fonte usa o contador auto-incremental como contraexemplo, e mostra que o que torna `PUT` idempotente é a substituição, não o tamanho do corpo.
- **A obrigação do `Allow` em `405` é `MUST`** nas duas fontes. É das poucas obrigações duras de header em toda a spec de semântica.
- **Só `GET` e `HEAD` são obrigatórios** num servidor de propósito geral; todo o resto é `OPTIONAL` (RFC 9110 § 9.1).
- **O token do método é case-sensitive**, por design, para servir de gateway a sistemas orientados a objeto — ao contrário do nome de header, que é case-insensitive.
- **`HTTP-METH-06`, `HTTP-METH-08`, `HTTP-METH-09` e `HTTP-METH-10` são norma deste vault**, mais fortes que a spec: RFC 9110 usa `SHOULD NOT` para o retry não idempotente, e não define nenhum header de chave de idempotência. O nome `Idempotency-Key` é convenção de indústria, **não verificado em MDN nem em RFC 9110** — trate-o como escolha do seu contrato.
- **Não verificado nesta doc:** `CONNECT`, `TRACE`, os media types de `PATCH` (`application/json-patch+json`, `application/merge-patch+json`) e o header `Accept-Patch` além da menção de existência na página de `PATCH`.
