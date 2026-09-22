---
Link: https://bun.com/docs/runtime/http/server
tags:
 - bun
 - http
 - agent-context
source: "Documentação oficial — https://bun.com/docs"
verificado-em: 2026-08-15
---
# Bun - HTTP e Servidor

> `Bun.serve` e o handler `fetch` · o objeto `routes` (roteamento nativo, params tipados, precedência) · `Response`, `Bun.file` e streaming/SSE · cookies via `CookieMap` · WebSockets, upgrade e pub/sub · TLS, `unix`, `idleTimeout` · ciclo de vida (`reload`, `stop`, `timeout`) · o que **não** existe nativamente.
>
> **Não cobre:** a escolha entre `Bun.serve` cru, `Hono` e [Elysia](elysia.md) (`Backend no runtime Bun`) · APIs de runtime e I/O de arquivo ([Bun - Runtime e APIs](bun-runtime-e-apis.md)) · bundling do frontend servido pelo mesmo processo ([Bun - Bundler e Build](bun-bundler-e-build.md)) · drivers de banco chamados de dentro do handler ([Bun - Dados e Persistência](bun-dados-e-persistencia.md)) · compat com `node:http` e deploy ([Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)).

Entrada: [Bun](bun.md) § 5 (árvores de decisão) · § 6 (regras normativas) · Base normativa: [Bun](bun.md)

Versão verificada: **Bun 1.3.14** (`bun@latest` no registry npm, 2026-08-15).

---

## 1. Conceito: `Bun.serve` é a fronteira HTTP inteira, não um `createServer` mais rápido

`Bun.serve` não é a versão Bun de `http.createServer`. É uma superfície completa: roteador com params, resposta estática de custo zero, servidor de arquivos com `Range` e `ETag`, cookies, WebSockets com pub/sub, TLS e hot reload de rotas — tudo sem dependência.

A consequência prática é a decisão que abre qualquer projeto novo: **o que sobra para um framework fazer?** A resposta é curta e é o que justifica [Bun - Runtime e APIs](bun-runtime-e-apis.md) não ser suficiente sozinha: sobram *middleware componível*, *validação tipada de entrada* e *cliente tipado end-to-end*. Nada disso existe em `Bun.serve`. Tudo o mais — roteamento, params, cookies, arquivos, sockets — já está aqui.

Escolher `Bun.serve` cru quando você precisa de middleware produz o mesmo resultado toda vez: uma função `withAuth(handler)` caseira, depois `withLogging`, depois uma composição manual das duas, e em três semanas você reimplementou metade de um framework sem os tipos. Escolher um framework quando o serviço tem seis rotas e nenhum cross-cutting concern adiciona uma dependência e uma camada de indireção por nada.

O critério de desempate está na **§ 7 desta nota** — a tabela do que `Bun.serve` não tem — e, desenvolvido em cinco eixos com árvore de decisão, em `Backend no runtime Bun`. Esta nota estabelece **onde a linha cai**, seção a seção; a nota irmã decide qual das três portas abrir (`Hono`, [Elysia](elysia.md) ou `Bun.serve` cru).

---

## 2. `routes` decide; `fetch` é só o fallback

**Conceito.** O roteador nativo entrou em **Bun v1.2.3** (literal da doc: `// `routes` requires Bun v1.2.3+`). Antes disso, `fetch` era obrigatório e todo mundo parseava `new URL(req.url).pathname` na mão. Depois disso, `fetch` virou o handler de *nada casou* — e escrever roteamento manual dentro dele é regressão.

O `routes` aceita quatro formas de valor, e a diferença entre elas é de custo, não de estilo:

| Valor da rota | Forma | Custo |
| --- | --- | --- |
| Função | `req => Response` ou `async req => Response` | chamada por request |
| Objeto de métodos | `{ GET, POST, PUT, DELETE }` | idem, com dispatch por método |
| `Response` literal | `new Response("OK")` | **dispatch sem alocação**, cacheado pela vida do servidor |
| `Bun.file(...)` / `{ dir }` | arquivo ou árvore de diretório | leitura por request, com `Range`/`ETag`/`304` |

Sobre a resposta estática, a fonte é explícita: *"Static responses do not allocate additional memory after initialization"*, com **pelo menos 15% de ganho** sobre devolver um `Response` construído no handler. Health check, redirect e config fixa pertencem a esta forma.

**A assinatura do handler de rota é `(req, server)`.** Toda rota em forma de função — e todo método dentro do objeto de métodos — recebe dois argumentos: o `BunRequest` e o próprio objeto `server`. O segundo argumento é o que a maioria dos exemplos omite por não precisar dele, e é ele que carrega as operações **por request**: `server.timeout(req, segundos)` (§ 3, e a correção inteira de SSE), `server.requestIP(req)` e `server.publish(...)`. O handler `fetch` recebe a mesma dupla.

**A precedência é fixa e não depende da ordem de declaração:** exata → parâmetro → wildcard → catch-all global.

```ts
import type { BunRequest } from "bun";

Bun.serve({
 routes: {
 // 1. exata vence, mesmo declarada depois de /users/:id
 "/api/users/me": => Response.json({ id: currentUserId }),

 // 2. parâmetro — o tipo de req.params é derivado do literal da chave
 "/api/orgs/:orgId/repos/:repoId": (req) => {
 const { orgId, repoId } = req.params; // { orgId: string; repoId: string }
 return Response.json({ orgId, repoId });
 },

 // método a método, com o corpo lido só onde faz sentido
 "/api/pedidos": {
 GET: => Response.json(listarPedidos),
 POST: async (req) => {
 const corpo = await req.json;
 return Response.json(criarPedido(corpo), { status: 201 });
 },
 },

 // 3. resposta estática: zero alocação por request
 "/health": new Response("OK"),

 // 4. wildcard antes do catch-all global
 "/api/*": Response.json({ erro: "rota inexistente" }, { status: 404 }),
 },

 // roda apenas para o que nenhuma rota casou
 fetch: => new Response("Not Found", { status: 404 }),
});
```

O TypeScript deriva `req.params` do literal da chave — `"/orgs/:orgId"` produz `{ orgId: string }` sem anotação. Só é preciso `BunRequest<"/rota/:param">` explícito quando o handler é extraído para fora do objeto e perde o contexto do literal.

Duas garantias verificadas que evitam bug de segurança em rota de diretório: Bun decodifica percent-encoding dos params automaticamente (substituindo Unicode inválido por `�`), e rejeita caminho não canônico com `404` em `{ dir }` — `.`, `..`, segmento vazio, `%2F`. Em Linux o `open` usa `openat2(RESOLVE_IN_ROOT)`. **Mas** a doc adverte: roteamento é case-sensitive e o filesystem de macOS/Windows não é, então `/static/Admin/secret.txt` cai no wildcard de diretório e ainda abre `admin/secret.txt`. A recomendação literal é manter conteúdo com controle de acesso **fora** do `dir`.

| ID | Regra |
| --- | --- |
| `BUN-HTTP-01` | Servidor novo **MUST** declarar suas rotas em `routes`, e `fetch` **NEVER** contém roteamento manual por `URL(req.url).pathname` — com uma única exceção nomeada: o `fetch` que existe apenas para chamar `server.upgrade` (§ 5), porque a doc documenta o upgrade de WebSocket somente dentro de `fetch`. |
| `BUN-HTTP-02` | Conteúdo sob controle de acesso **NEVER** fica dentro do `dir` de uma rota de diretório — o gate por rota sobreposta falha em filesystem case-insensitive. |

---

## 3. `Response`, `Bun.file` e o custo de bufferizar

**Conceito.** As duas formas de servir um arquivo parecem equivalentes e não são. `new Response(await Bun.file(p).bytes)` **bufferiza em memória na inicialização**; `new Response(Bun.file(p))` lê do disco a cada request. A escolha errada aparece em produção como consumo de RAM ou como 404 que nunca acontece.

| | `new Response(await file.bytes)` | `new Response(Bun.file(path))` |
| --- | --- | --- |
| I/O por request | nenhum | leitura do filesystem |
| Memória | arquivo inteiro na RAM | chunks, com backpressure |
| Cache condicional | `ETag` + `If-None-Match` → `304` | `Last-Modified` + `If-Modified-Since` → `304` |
| `Range` | não documentado | suportado, com `Content-Range` |
| Arquivo ausente | **erro de inicialização** | `404` em runtime |
| Serve para | asset pequeno e quente | arquivo grande, upload de usuário, conteúdo que muda |

Ao servir `Bun.file` diretamente, Bun usa `sendfile(2)` quando possível — cópia zero no kernel. Para servir um pedaço, `Bun.file(p).slice(start, end)` já preenche `Content-Range` e `Content-Length` sozinho.

**Streaming e SSE.** `new Response` aceita uma **função geradora assíncrona** direto como corpo. Cada `yield` faz flush de um chunk, e o `finally` do gerador roda quando o cliente desconecta. Com `ReadableStream`, o equivalente é o `cancel`, que Bun chama automaticamente na desconexão.

E aqui está a armadilha que mais derruba SSE em Bun: **o `idleTimeout` padrão é de 10 segundos e conta durante a resposta**. Um stream que fica quieto mais que isso tem a conexão fechada no meio. A fonte é literal: *"If your stream goes quiet for longer than `idleTimeout`, Bun closes the connection mid-response."*

```ts
Bun.serve({
 routes: {
 "/eventos": (req, server) => {
 // sem isto, um SSE silencioso por 10s morre — não é bug do cliente
 server.timeout(req, 0);

 return new Response(
 async function* {
 yield `data: ${JSON.stringify({ tipo: "conectado" })}\n\n`;
 for await (const evento of assinarFilaDePedidos) {
 yield `data: ${JSON.stringify(evento)}\n\n`;
 }
 },
 {
 headers: {
 "Content-Type": "text/event-stream",
 "Cache-Control": "no-cache",
 },
 },
 );
 },
 },
});
```

`server.timeout(req, segundos)` é por request. O `idleTimeout` global aceita no máximo `255` segundos e `0` desliga — subir o global para acomodar um endpoint de stream penaliza todos os outros.

**Se o `idleTimeout` global já for `0`, `BUN-HTTP-04` continua valendo.** Os dois desligam o mesmo timer: a fonte descreve `idleTimeout: 0` como *"disables the timeout entirely"* e `server.timeout(req, 0)` como o mesmo, para aquele request. Então sim, com o global em `0` o stream sobrevive sem a chamada. O que muda é a quem o desligamento pertence:

- `idleTimeout: 0` desliga para **todo** request do servidor — inclusive o handler travado que nunca escreve byte nenhum, que é precisamente o que o timer existe para cortar. A doc é explícita de que a conexão conta como ociosa *"including in-flight requests where your handler is still running but hasn't written any bytes to the response yet"*.
- `server.timeout(req, 0)` deixa o endpoint de stream correto **independentemente** do valor global, que alguém vai mexer num commit de tuning sem saber que um endpoint dependia dele.

Regra prática: o global é política de proteção do servidor, não mecanismo de manter stream vivo.

### O formato de fio do SSE, e o que não é do Bun

O exemplo acima é a parte que Bun documenta. O resto do SSE é o **padrão HTML de server-sent events**, não API de Bun, e é onde mora a falha mais silenciosa da lista: **o delimitador de evento é a linha em branco, ou seja `\n\n`**. Trocar por um `\n` só produz um endpoint que abre a conexão, transfere bytes, não dá erro nenhum e **nunca dispara um evento no cliente** — o `EventSource` fica acumulando um evento que nunca é despachado.

| Campo | Para que serve |
| --- | --- |
| `data: <texto>` | o payload. Linhas `data:` consecutivas são concatenadas com `\n` entre elas |
| `event: <nome>` | despacha no cliente como listener nomeado (`es.addEventListener("pedido", …)`) em vez de `onmessage` |
| `id: <valor>` | grava o *last event ID* do `EventSource` |
| `retry: <ms>` | tempo de reconexão, em milissegundos inteiros; valor não inteiro é ignorado |
| `: <qualquer coisa>` | linha de comentário, ignorada pelo cliente — é o **heartbeat**, o jeito de não deixar o stream ficar quieto |
| linha em branco | **despacha o evento**. Sem ela, nada chega |

Duas consequências de arquitetura que o `Content-Type` não deixa adivinhar: o `EventSource` **reconecta sozinho** quando a conexão cai (a menos que o servidor responda `204` ou o cliente chame `close`), e ao reconectar ele manda o header **`Last-Event-ID`** com o último `id:` recebido. Um endpoint que emite `id:` e ignora `Last-Event-ID` no request de volta entrega eventos duplicados a cada reconexão; um que não emite `id:` nenhum não tem como retomar. Isso é decisão sua, não default.

```ts
"/eventos": (req, server) => {
 server.timeout(req, 0);
 // o cliente manda isto sozinho ao reconectar; retomar a partir dele é sua responsabilidade
 const desde = req.headers.get("last-event-id");

 return new Response(
 async function* {
 yield `retry: 5000\n\n`; // política de reconexão do cliente
 for await (const evento of assinarFilaDePedidos({ desde })) {
 yield `id: ${evento.seq}\n`; // permite retomada
 yield `event: pedido\n`; // listener nomeado no cliente
 yield `data: ${JSON.stringify(evento)}\n\n`; // \n\n despacha — com \n simples, nada chega
 }
 },
 { headers: { "Content-Type": "text/event-stream", "Cache-Control": "no-cache" } },
 );
}
```

### "Funciona em dev, cai em produção" não é o `idleTimeout`

Vale desfazer o diagnóstico fácil. O `idleTimeout` de 10 s **dispara igual em dev** — é o mesmo binário, o mesmo default. Se o sintoma só aparece em produção, a diferença está no que foi acrescentado entre o Bun e o browser, e a assinatura clássica é **proxy reverso**:

| Sintoma | Camada provável |
| --- | --- |
| Cai em ~10 s de silêncio, em dev **e** em prod | `idleTimeout` do Bun → `server.timeout(req, 0)` |
| Nenhum evento chega, mas a conexão fica aberta e a resposta "acumula" | **buffering** no proxy — ele segura o corpo esperando encher um buffer |
| Cai em um intervalo redondo (30 s, 60 s) só em prod | **read timeout** do proxy, não do Bun |
| Chega tudo de uma vez quando o handler termina | buffering, ou compressão aplicada na borda sobre o corpo inteiro |

**Limite explícito: nada disso está na doc do Bun, e não é configurável do lado do Bun.** O que foi verificado nesta sessão, na doc do nginx, é que ele desliga o buffering de uma resposta específica quando ela traz o header `X-Accel-Buffering: no` (*"Buffering can also be enabled or disabled by passing `yes` or `no` in the `X-Accel-Buffering` response header field"*), que a diretiva geral é `proxy_buffering` e que o timeout de leitura é `proxy_read_timeout`, com default de **60 s**. Emitir `X-Accel-Buffering: no` é barato e inofensivo para quem não usa nginx.

Para **ALB, Cloudflare, Cloud Run ou qualquer outra borda: não foi verificado nesta sessão** e cada um tem nome e default próprios para as duas coisas (buffering e idle/read timeout). Procure esses dois conceitos na doc do seu proxy antes de mexer no código — e mantenha um **heartbeat** (`: ping\n\n` a cada 15–30 s) no endpoint, que é a defesa que funciona contra qualquer read timeout sem depender de configuração de infraestrutura.

| ID | Regra |
| --- | --- |
| `BUN-HTTP-03` | Arquivo grande, de tamanho variável ou enviado por usuário **MUST** ser servido como `new Response(Bun.file(path))`, nunca bufferizado com `.bytes`. |
| `BUN-HTTP-04` | Resposta em streaming ou SSE **MUST** chamar `server.timeout(req, 0)` — o `idleTimeout` padrão de 10 s fecha a conexão no meio da resposta, e o global em `0` não substitui a chamada — e cada evento SSE **MUST** terminar em `\n\n`, porque é a linha em branco que despacha o evento no cliente. |

---

## 4. Cookies: `CookieMap` escreve na resposta sozinho, e só em `routes`

**Conceito.** Bun tem API dedicada: `Bun.CookieMap` e `Bun.Cookie`. Dentro de uma rota de `routes`, o request é um `BunRequest`, que expõe `cookies: CookieMap`. A parte que muda o código é a última frase da doc: *"When using `routes`, `Bun.serve` automatically tracks calls to `request.cookies.set` and applies them to the response."*

Ou seja: você **não** monta `Set-Cookie` à mão. Chama `req.cookies.set(...)` e devolve qualquer `Response`; o header é aplicado. `delete` vira um `Set-Cookie` com valor vazio e `Expires` no passado.

O default do `set` é `{ path: "/", sameSite: "lax" }` — o resto é sua responsabilidade, e `httpOnly` **não** está no default.

```ts
Bun.serve({
 routes: {
 "/sessao": {
 POST: async (req) => {
 const { email, senha } = await req.json;
 const sessao = await autenticar(email, senha);

 req.cookies.set("sid", sessao.id, {
 httpOnly: true, // não vem por default
 secure: true, // não vem por default
 sameSite: "lax", // default, explícito para não depender dele
 path: "/",
 maxAge: 60 * 60 * 24 * 7,
 });

 return Response.json({ usuario: sessao.usuario });
 },

 DELETE: (req) => {
 req.cookies.delete("sid", { path: "/" }); // path precisa bater com o do set
 return new Response(null, { status: 204 });
 },
 },
 },
});
```

`CookieMap` também é construível fora do servidor — `new Bun.CookieMap(req.headers.get("cookie")!)` — e é o caminho no handler `fetch`, que recebe um `Request` comum, sem `.cookies`. Nesse caminho, porém, **a escrita não é automática**: você tem que montar o `Set-Cookie` você mesmo.

| ID | Regra |
| --- | --- |
| `BUN-HTTP-05` | Cookie de sessão **MUST** ser escrito por `req.cookies.set` dentro de `routes`, com `httpOnly` e `secure` explícitos — nenhum dos dois é default. |
| `BUN-HTTP-06` | `delete` de cookie **MUST** repetir o `path` (e `domain`, se houver) usado na criação — o browser só apaga quando ambos batem. |

---

## 5. WebSockets: um handler por servidor, estado no `data` do upgrade

**Conceito.** A API é deliberadamente diferente da do browser. No cliente, `WebSocket` estende `EventTarget` e você registra listener por socket. No servidor, você declara **um** objeto `websocket` para o servidor inteiro. A justificativa da doc é custo: com muitas conexões, registrar/remover listener e guardar closures por socket domina memória e tempo.

**O upgrade é a exceção nomeada de `BUN-HTTP-01`, e é por isso que ela existe.** Toda ocorrência de `server.upgrade` na doc oficial está dentro de `fetch` — a página de WebSockets é literal: *"Inside `fetch`, `server.upgrade` attempts to upgrade incoming `ws:` or `wss:` requests"*. Não há exemplo de upgrade dentro de um handler de `routes`, e isso **não foi verificado** nesta sessão (ver Notas de verificação). Então o `fetch` continua existindo num servidor que usa `routes` para tudo o mais, e existe para isso.

O que a regra proíbe é rotear por caminho dentro do `fetch`. Dá para evitar isso inteiramente: o request de upgrade se identifica pelo header `Upgrade`, e o dado por conexão sai da query string — que é leitura de parâmetro, não roteamento. É o que a própria doc faz (`new URL(req.url).searchParams.get("channelId")`).

A regra do retorno é rígida: se `server.upgrade(req)` devolveu `true`, o handler **não pode** devolver `Response`. Retorne `undefined`.

Isso torna o `fetch` o **único ponto de autenticação** do socket. Depois do `101 Switching Protocols` não existe mais resposta HTTP para recusar a conexão. Cookies da página vêm no header do upgrade e são legíveis ali.

```ts
type DadosSocket = {
 usuarioId: string;
 canalId: string;
 conectadoEm: number;
};

const server = Bun.serve({
 // todo caminho HTTP continua declarado aqui — BUN-HTTP-01
 routes: {
 "/health": new Response("OK"),
 "/api/canais": { GET: => Response.json(listarCanais) },
 },

 // o fetch existe só para o upgrade e para o 404 de fallback:
 // nenhuma comparação de pathname, nenhuma rota escondida aqui
 fetch(req, server) {
 if (req.headers.get("upgrade") !== "websocket") {
 return new Response("Not Found", { status: 404 });
 }

 // única chance de recusar: depois do upgrade não há mais resposta HTTP
 const cookies = new Bun.CookieMap(req.headers.get("cookie") ?? "");
 const sessao = validarSessao(cookies.get("sid"));
 if (!sessao) return new Response("Unauthorized", { status: 401 });

 const ok = server.upgrade(req, {
 data: {
 usuarioId: sessao.usuarioId,
 // query string é parâmetro, não roteamento
 canalId: new URL(req.url).searchParams.get("canal") ?? "geral",
 conectadoEm: Date.now,
 } satisfies DadosSocket,
 });

 // upgrade bem-sucedido: NÃO retornar Response
 return ok ? undefined : new Response("Upgrade failed", { status: 400 });
 },

 websocket: {
 // tipagem de ws.data em todos os hooks
 data: {} as DadosSocket,

 open(ws) {
 ws.subscribe(`canal:${ws.data.canalId}`);
 server.publish(`canal:${ws.data.canalId}`, `${ws.data.usuarioId} entrou`);
 },

 message(ws, mensagem) {
 // ws.publish exclui quem publicou; server.publish inclui todos
 server.publish(`canal:${ws.data.canalId}`, `${ws.data.usuarioId}: ${mensagem}`);
 },

 close(ws) {
 ws.unsubscribe(`canal:${ws.data.canalId}`);
 },
 },
});
```

**Pub/sub.** Tópico é string. `ws.subscribe(topico)` / `ws.unsubscribe(topico)`; `ws.isSubscribed(topico)`; `ws.subscriptions` lista os atuais. A diferença que causa bug silencioso: **`ws.publish` envia a todos os assinantes _exceto_ o próprio socket** — `server.publish` envia a todos. O default de `publishToSelf` é `false`. `server.subscriberCount(topico)` dá a contagem.

**Backpressure.** `ws.send` devolve número: `-1` enfileirado com backpressure, `0` descartado por problema de conexão, `1+` bytes enviados. Ignorar esse retorno em um broadcast de alta frequência é como se perde mensagem sem nenhum erro aparecer.

**Defaults verificados** (diferentes do HTTP): `idleTimeout` de **120 s**, `maxPayloadLength` de **16 MB**, `backpressureLimit` de 16 MB, `sendPings: true`, `perMessageDeflate` desligado.

| ID | Regra |
| --- | --- |
| `BUN-HTTP-07` | Autenticação e autorização do WebSocket **MUST** ocorrer antes de `server.upgrade` — após o `101` não há resposta HTTP para recusar. |
| `BUN-HTTP-08` | Handler cujo `server.upgrade` retornou `true` **NEVER** devolve um `Response`; **MUST** retornar `undefined`. |
| `BUN-HTTP-09` | Estado por conexão **MUST** ser passado em `server.upgrade(req, { data })` e lido em `ws.data`, nunca guardado em `Map` global indexado pelo socket. |

---

## 6. Ciclo de vida, erro e binding

**Conceito.** O servidor é um objeto vivo com operações que importam em produção.

`server.reload({ routes, fetch, error, websocket })` troca handlers sem reiniciar e sem downtime — e é **o único jeito de invalidar uma resposta estática**, que fica cacheada pela vida do objeto servidor.

`await server.stop` para de aceitar conexões novas, fecha keep-alive ociosas na hora e espera as requisições em voo terminarem; a promise resolve quando toda conexão fechou. `server.stop(true)` mata tudo imediatamente. Este é o par de um shutdown limpo — ver [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) para os sinais.

O handler `error(err)` devolve o `Response` servido quando algo lança. Sem ele em `development: true`, Bun serve uma página de erro embutida com stack. **Essa página não pertence a produção**, e nem o `error.stack` no corpo — o exemplo da doc oficial devolve o stack em `<pre>`, o que é apropriado para o contexto de aprendizado dela e não para um serviço exposto.

```ts
const server = Bun.serve({
 port: Number(process.env.PORT ?? 3000), // default: $BUN_PORT, $PORT, $NODE_PORT, senão 3000
 hostname: "0.0.0.0", // default
 idleTimeout: 30, // segundos; máx 255, 0 desliga
 development: false, // NUNCA ligado em produção — nem `true`, nem o objeto

 routes: { "/health": new Response("OK") },

 error(err) {
 // stack para o log estruturado, corpo genérico para o cliente
 console.error({ msg: "erro nao tratado", err });
 return Response.json({ erro: "internal_error" }, { status: 500 });
 },
});
```

**Binding.** `port: 0` escolhe porta livre (leia em `server.port`) — é o padrão para testes. `unix: "/tmp/app.sock"` troca TCP por socket de domínio Unix; no Linux, prefixar com byte nulo (`"\0nome"`) usa o namespace abstrato, que não toca no filesystem. `reusePort: true` compartilha a porta entre processos com `SO_REUSEPORT` — e a doc é explícita: **Linux apenas**, Windows e macOS ignoram a opção.

**TLS.** `tls: { key, cert }` espera o **conteúdo**, não o caminho — `Bun.file("./key.pem")`, `Buffer` ou string. Um array de objetos com `serverName` faz SNI multi-domínio. Definir `ca` **substitui** a lista de CAs da Mozilla, não acrescenta.

`http3: true` (requer TLS) está marcado **experimental** na fonte.

**Observabilidade embutida:** `server.pendingRequests`, `server.pendingWebSockets`, `server.subscriberCount(topico)`, `server.requestIP(req)` (retorna `null` para socket Unix). É o mínimo para um `/metrics` — ver.

| ID | Regra |
| --- | --- |
| `BUN-HTTP-10` | `development` **NEVER** é ligado em produção em **nenhuma** das duas formas que a opção aceita — nem o booleano `true`, nem o objeto (`{ hmr, console }`, que também liga o modo de desenvolvimento) — e o `error` handler **NEVER** inclui `error.stack` no corpo da resposta. |
| `BUN-HTTP-11` | Servidor de produção **MUST** definir um handler `error` que devolva corpo genérico e registre o erro no log estruturado. |
| `BUN-HTTP-12` | `reusePort: true` **MUST** ser tratado como recurso exclusivo de Linux — em macOS e Windows a opção é ignorada em silêncio. |

---

## 7. O que não existe — e é por isso que `Hono` e [Elysia](elysia.md) existem

Ausência aqui significa *verificado como ausente na doc de `Bun.serve`*, não "impossível de fazer". **Esta tabela é o critério prometido na § 1**; a decisão desenvolvida — cinco eixos, árvore e custo de saída de cada opção — está em `Backend no runtime Bun`.

| Não existe em `Bun.serve` | Consequência de fingir que existe | Onde resolver |
| --- | --- | --- |
| **Middleware componível** | cada rota repete auth/log/CORS, ou nasce um `compose` caseiro sem tipos | `Hono` / [Elysia](elysia.md) — `Backend no runtime Bun` |
| **Validação tipada do corpo e da query** | `await req.json` devolve `any`; o handler confia em entrada externa | ou o validador do framework |
| **Cliente tipado end-to-end** | o tipo da resposta é redigitado no frontend e diverge em silêncio | `hono/client` (`Hono`), Eden Treaty ([Elysia](elysia.md)) — |
| **CORS** | preflight `OPTIONS` tratado à mão, header a header | § 7.1, abaixo — |
| **Mapeamento de erro de domínio para status** | `throw` vira 500 genérico no `error` handler | camada própria — |
| **Roteador aninhado / `basePath`** | prefixo repetido literalmente em cada chave de `routes` | `Hono` / [Elysia](elysia.md) |
| **`AbortSignal` do request propagado** | trabalho continua depois do cliente desistir | veja abaixo |

Sobre o último: a doc de `Bun.serve` não documenta um `req.signal`. O que **está** documentado é o cancelamento no lado do corpo da resposta — o `finally` de um gerador assíncrono e o `cancel` de um `ReadableStream` rodam quando o cliente desconecta. Para trabalho caro disparado por request, é ali que a limpeza tem lugar garantido. Conceito em.

### 7.1 CORS: a ausência que o leitor típico encontra primeiro

CORS merece saída concreta e não só uma linha de tabela, porque é o cenário **mais provável** de quem chega aqui: o caminho recomendado em [Bun - Bundler e Build](bun-bundler-e-build.md) § 10 mantém o Vite para o frontend, e Vite em `:5173` chamando `Bun.serve` em `:3000` são origens diferentes. Não é caso de borda; é o dia 1.

Há três saídas, e elas não se contradizem — resolvem em camadas diferentes:

1. **Não ter CORS.** Servir o frontend pelo mesmo `Bun.serve`, via import de HTML ([Bun - Bundler e Build](bun-bundler-e-build.md) § 7), coloca página e API na mesma origem e o problema deixa de existir. É a única saída que não tem custo permanente, e é para onde o caminho fullstack de Bun aponta. Custo: você troca o dev server do Vite pelo do Bun, com o trade-off da § 10 daquele satélite.
2. **Middleware de framework.** `Hono` e [Elysia](elysia.md) têm CORS pronto, com preflight e credenciais tratados. Se você já ia precisar de middleware para outra coisa, CORS não é o que decide — mas conta na soma. Ver `Backend no runtime Bun`.
3. **À mão, em `Bun.serve` cru.** É viável e cabe em uma função, desde que você aceite fazer o preflight você mesmo. Não existe nada em Bun que faça isso por você.

```ts
const ORIGENS = new Set(["http://localhost:5173", "https://app.exemplo.com"]);

function cors(req: Request): Record<string, string> {
 const origem = req.headers.get("origin");
 // eco de origem contra allowlist: "*" é incompatível com credentials
 if (!origem || !ORIGENS.has(origem)) return {};
 return {
 "Access-Control-Allow-Origin": origem,
 "Access-Control-Allow-Credentials": "true",
 "Vary": "Origin", // sem isto, um cache intermediário serve a origem errada
 };
}

Bun.serve({
 routes: {
 "/api/pedidos": (req) => {
 // o preflight é um request de método OPTIONS na mesma rota
 if (req.method === "OPTIONS") {
 return new Response(null, {
 status: 204,
 headers: {
...cors(req),
 "Access-Control-Allow-Methods": "GET, POST",
 "Access-Control-Allow-Headers": "Content-Type, Authorization",
 "Access-Control-Max-Age": "86400", // evita um preflight por request
 },
 });
 }

 if (req.method === "GET") {
 return Response.json(listarPedidos, { headers: cors(req) });
 }
 return new Response(null, { status: 405 });
 },
 },
});
```

Repare no que a terceira saída custa: **cada rota** precisa lembrar de chamar `cors(req)` nas duas pontas, e esquecer numa delas produz uma falha que só aparece no browser. É exatamente a classe de repetição que a primeira linha da tabela acima descreve — CORS é o exemplo canônico de por que middleware componível é a ausência que mais pesa. Conceito e riscos em.

> **Nota de escopo.** A tabela de rotas por método (`{ GET, POST }`) é documentada com `GET` e `POST` nos exemplos oficiais; **não foi verificado** se `OPTIONS` é aceito como chave de método. Por isso o exemplo acima usa uma rota em forma de função e ramifica em `req.method`, que é API padrão de `Request`.

### 7.2 Limite declarado: esta nota pressupõe que você escolheu `Bun.serve`

`BUN-HTTP-01`, `BUN-HTTP-04` e `BUN-SYS-11` ([Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)) são **inimplementáveis** em um app que já roda Express, Fastify ou qualquer coisa em cima de `node:http`: não há `routes`, não há `server.timeout`, não há `server.stop`. Isso é limite desta nota, não defeito do seu app — e vale dizer em voz alta porque a § 7 responde "o que escolher para um servidor novo", não "o que faço com o que já tenho".

O que a fonte diz sobre o app que já existe é curto e é bom: *"Express and other major Node.js HTTP libraries should work in Bun without changes. Bun implements the `node:http` and `node:https` modules that these libraries rely on."* Ou seja, rodar sob Bun é o passo barato; reescrever para `Bun.serve` é um passo separado e opcional. Esta doc **não documenta Express** — a matriz de compatibilidade de `node:http`/`node:https` e o equivalente de shutdown gracioso fora de `Bun.serve` estão em [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) (§ 5 e § 6), e a decisão de migrar ou não está em `Backend no runtime Bun`.

`Request` e `Response` são os objetos padrão da plataforma — o mesmo `Response` que você devolve aqui é o que `fetch` retorna. O corpo é um `ReadableStream` web, não um; a conversão entre os dois é assunto de [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md).

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| Rotear com `if (url.pathname ===...)` dentro de `fetch` | perde params tipados, precedência, otimização de rota estática e `req.cookies` | declarar em `routes` — `BUN-HTTP-01`, cuja única exceção é o `fetch` que só faz `server.upgrade` |
| SSE ou stream longo sem `server.timeout(req, 0)` | conexão fechada após 10 s de silêncio; o cliente vê reset e reconecta em loop | desligar o timeout por request — `BUN-HTTP-04` |
| Terminar o evento SSE em `\n` em vez de `\n\n` | a linha em branco é o que despacha o evento: o stream transfere bytes, não dá erro, e o cliente nunca dispara `onmessage` | `\n\n` ao fim de cada evento — `BUN-HTTP-04` |
| Culpar o `idleTimeout` por SSE que "só cai em prod" | o timeout do Bun dispara igual em dev; a diferença dev↔prod é buffering ou read timeout de proxy | heartbeat `: ping\n\n` + conferir o proxy — § 3 |
| Subir `idleTimeout` global para manter um stream vivo | remove a proteção de **todos** os requests, inclusive handlers travados que nunca escrevem byte | `server.timeout(req, 0)` no endpoint — `BUN-HTTP-04` |
| `development: { hmr: true }` em produção, achando que a regra só proíbe `true` | o objeto liga o mesmo modo: rebundle por request, sem minificação, sem `Cache-Control` | `development: false` — `BUN-HTTP-10` |
| `new Response(await Bun.file(p).bytes)` para servir uploads | arquivo inteiro na RAM na inicialização, sem `Range`, e arquivo ausente derruba o boot | `new Response(Bun.file(p))` — `BUN-HTTP-03` |
| `return new Response(...)` depois de `server.upgrade` bem-sucedido | o socket já mudou de protocolo; a resposta é inválida | retornar `undefined` — `BUN-HTTP-08` |
| Validar sessão dentro de `websocket.open` | o `101` já foi enviado; não há mais status HTTP para recusar | validar no `fetch`, antes do `upgrade` — `BUN-HTTP-07` |
| `ws.publish` esperando que o remetente receba de volta | `ws.publish` exclui o próprio socket (`publishToSelf` é `false`) | `server.publish` para incluir todos |
| `Map<ServerWebSocket, Estado>` global para dado de conexão | vaza quando um `close` não roda, e duplica o que `ws.data` já garante | `server.upgrade(req, { data })` — `BUN-HTTP-09` |
| Devolver `error.stack` no corpo do `error` handler | expõe caminhos, versões e lógica interna a qualquer cliente | corpo genérico + log estruturado — `BUN-HTTP-10` |
| Gatear `/static/admin/*` com uma rota antes de `{ dir: "./public" }` | roteamento é case-sensitive, o filesystem de macOS/Windows não é; `/static/Admin/...` fura o gate | manter o conteúdo protegido fora do `dir` — `BUN-HTTP-02` |
| Mudar uma resposta estática e esperar que o servidor perceba | `Response` literal é cacheado pela vida do objeto servidor | `server.reload({ routes })` |

---

## Checklist de revisão

- [ ] Todo caminho está em `routes`, e `fetch` só devolve o 404 de fallback? → `BUN-HTTP-01`
- [ ] Endpoint de stream/SSE chama `server.timeout(req, 0)` e termina todo evento em `\n\n`? → `BUN-HTTP-04`
- [ ] O SSE tem heartbeat (`: ping\n\n`) e, se emite `id:`, lê `Last-Event-ID` na reconexão? → § 3
- [ ] Arquivos de usuário são servidos por `Bun.file`, não bufferizados? → `BUN-HTTP-03`
- [ ] `httpOnly` e `secure` aparecem explicitamente em todo `cookies.set` de sessão? → `BUN-HTTP-05`
- [ ] O `delete` do cookie repete `path`/`domain` do `set`? → `BUN-HTTP-06`
- [ ] A autenticação do socket está no `fetch`, antes do `upgrade`? → `BUN-HTTP-07`
- [ ] Nenhum handler devolve `Response` após upgrade bem-sucedido? → `BUN-HTTP-08`
- [ ] Estado por conexão vive em `ws.data`? → `BUN-HTTP-09`
- [ ] `development` desligado em produção nas **duas** formas (booleano e objeto) e corpo de erro genérico? → `BUN-HTTP-10`, `BUN-HTTP-11`
- [ ] O retorno de `ws.send` é checado onde o volume justifica?

---

## Relacionados

- [Bun](bun.md) — hub
- `Backend no runtime Bun` — a decisão `Bun.serve` × `Hono` × [Elysia](elysia.md), com os eixos e o custo de saída
- [Bun - Runtime e APIs](bun-runtime-e-apis.md) · [Bun - Bundler e Build](bun-bundler-e-build.md) · [Bun - Dados e Persistência](bun-dados-e-persistencia.md) · [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) · [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) · [Bun - Testes](bun-testes.md)
- · · · ·
- · ·
- · · `RFC 6265 - Cookies HTTP`

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Server](https://bun.com/docs/runtime/http/server) · [Routing](https://bun.com/docs/runtime/http/routing) · [Error Handling](https://bun.com/docs/runtime/http/error-handling) · [Metrics](https://bun.com/docs/runtime/http/metrics)
- [Cookies (HTTP)](https://bun.com/docs/runtime/http/cookies) · [Cookies (runtime)](https://bun.com/docs/runtime/cookies)
- [WebSockets](https://bun.com/docs/runtime/http/websockets) · [TLS](https://bun.com/docs/runtime/http/tls)
- [Server-Sent Events](https://bun.com/docs/guides/http/sse) · [Cluster de servidores HTTP](https://bun.com/docs/guides/http/cluster)
- [Fullstack dev server](https://bun.com/docs/bundler/fullstack) — a opção `development` na forma de objeto (`{ hmr, console }`)
- [Express e Bun](https://bun.com/docs/guides/ecosystem/express) — o que a fonte diz sobre app existente em `node:http`
- Fora da doc do Bun, para o formato de fio do SSE: [HTML Standard — Server-sent events](https://html.spec.whatwg.org/multipage/server-sent-events.html) e [MDN — Using server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events)
- Fora da doc do Bun, para buffering de proxy: [nginx `ngx_http_proxy_module`](https://nginx.org/en/docs/http/ngx_http_proxy_module.html) (`X-Accel-Buffering`, `proxy_buffering`, `proxy_read_timeout`)
- Versão: `https://registry.npmjs.org/bun/latest` → **1.3.14**

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **O `idleTimeout` padrão é de 10 segundos e conta durante a resposta**, não só antes dela. É a causa real da maioria dos SSE que "caem sozinhos" em Bun. O de WebSocket é outro: **120 segundos**. A doc é explícita de que a conexão conta como ociosa mesmo com o handler rodando, enquanto ele não tiver escrito byte nenhum.
- **Todo `server.upgrade` documentado está dentro de `fetch`.** A página de WebSockets diz literalmente *"Inside `fetch`, `server.upgrade` attempts to upgrade…"*, e não há um único exemplo de upgrade dentro de um handler de `routes`. **Não verificado:** se `server.upgrade` funciona a partir de `routes`. O tipo aceita qualquer `Request`, mas tipo não é comportamento — por isso a exceção em `BUN-HTTP-01` é nomeada em vez de a nota sugerir o contrário.
- **`development` aceita um objeto, não só um booleano** (`{ hmr: true, console: true }`) — o que faz uma regra escrita contra o literal `true` ter um buraco. Ambas as formas ligam o modo de desenvolvimento.
- **Handlers de `routes` recebem `(req, server)`.** A doc mostra isso nos exemplos de SSE e de `server.timeout`, mas nunca declara a assinatura em prosa — é a informação que carrega a correção de SSE inteira.
- **O formato de fio do SSE não é do Bun.** A doc do Bun mostra só `data: …\n\n`; `event:`, `id:`, `retry:`, a linha de comentário e o `Last-Event-ID` vêm do HTML Standard. O `\n\n` como delimitador é a diferença entre um endpoint que funciona e um que transfere bytes sem nunca despachar evento.
- **Nada na doc do Bun trata de buffering de proxy reverso.** "Funciona em dev, cai em prod" não é explicado pelo `idleTimeout`, que dispara igual nos dois. `X-Accel-Buffering`, `proxy_buffering` e `proxy_read_timeout` foram verificados **na doc do nginx**, não na do Bun; ALB, Cloudflare e Cloud Run **não foram verificados**.
- **`routes` exige Bun v1.2.3+**, marcado como comentário no primeiro exemplo da doc de Server. Código para versões anteriores depende de `fetch`.
- **`req.cookies` só existe em `routes`.** O handler `fetch` recebe um `Request` comum — a aplicação automática do `Set-Cookie` também não acontece ali.
- **`ws.publish` não envia para o próprio socket**; `server.publish` envia. `publishToSelf` é `false` por default.
- **Resposta estática é cacheada pela vida do objeto servidor** — alterar o valor exige `server.reload`, não basta reatribuir.
- **`tls.ca` substitui** a lista de CAs bem conhecidas curada pela Mozilla, em vez de acrescentar a ela.
- **`reusePort` é ignorado em silêncio** fora do Linux, o que faz um cluster "funcionar" em dev no macOS sem balancear nada.
- **HTTP/3 (`http3: true`) está marcado como experimental** na própria doc de Server.
- **`server.closeIdleConnections` retorna o número de conexões fechadas**, divergindo do `node:http`, que não retorna nada.
- A doc não documenta um `AbortSignal` do request em `Bun.serve`; o cancelamento observável é o do corpo da resposta (`finally` do gerador, `cancel` do `ReadableStream`).
