---
titulo: Playwright - Rede e Mocking
Link: https://playwright.dev/docs/network
tags:
 - playwright
 - testing
 - network
 - mocking
 - api
 - agent-context
source: "Documentação oficial do Playwright — Network, Mock APIs, Mock browser APIs, API testing, Clock"
verificado-em: 2026-08-20
---

# Playwright — Rede e Mocking

> Satélite de [Playwright](playwright.md). Cobre tudo que fica entre o teste e o mundo externo: interceptar HTTP, chamar API direto, mockar API de browser, e controlar o relógio. A árvore de decisão está na § 5.4 do hub.
>
> **O critério que organiza a nota.** Existem duas perguntas distintas, e confundi-las produz suíte lenta e frágil ao mesmo tempo: *"quero substituir esta dependência?"* (interceptar) e *"quero preparar este estado?"* (chamar a API de verdade). Mockar o que deveria ser criado torna o teste menos fiel; criar pela UI o que deveria ser um `POST` torna o teste dez vezes mais lento.

---

## 1. Interceptar — `route`

```ts
await page.route('*/**/api/v1/frutas', async route => {
 await route.fulfill({ json: [{ id: 21, nome: 'Morango' }] });
});
await page.goto('/frutas');
await expect(page.getByText('Morango')).toBeVisible;
```

`page.route` vale para aquela página; `context.route` vale para todas as páginas do contexto **e para popups**. Registrar em `context` é o certo quando o fluxo abre janela.

As quatro operações de um `Route`:

| Operação | Efeito |
| --- | --- |
| `route.fulfill` | responde com dado inventado; a requisição não sai |
| `route.abort` | bloqueia; a requisição falha |
| `route.continue` | segue, opcionalmente com `headers`/`postData`/`url` alterados |
| `route.fetch` | executa a real e devolve a resposta, para modificar antes de responder |

Há também `route.fallback`, para passar a decisão ao próximo handler registrado.

### 1.1 Modificar a resposta real

O caso mais valioso, porque preserva o contrato e muda só o dado:

```ts
await page.route('*/**/api/v1/frutas', async route => {
 const resposta = await route.fetch;
 const json = await resposta.json;
 json.push({ id: 100, nome: 'Nêspera' });
 await route.fulfill({ response: resposta, json });
});
```

Passar `response` junto preserva status e headers originais — sem isso o mock inventa também o envelope, e o teste deixa de exercitar o tratamento de header (cache, `Content-Type`, paginação).

### 1.2 Modificar a requisição

```ts
await page.route('**/*', async route => {
 const headers = {...route.request.headers, 'x-tenant': 'acme' };
 await route.continue({ headers });
});
```

### 1.3 Bloquear

```ts
// cortar peso de terceiros e deixar o teste mais rápido e determinístico
await page.route(/(analytics|googletagmanager|hotjar)/, r => r.abort);
await page.route(/\.(png|jpg|woff2)$/, r => r.abort);
```

Bloquear imagem acelera, mas **quebra teste de screenshot** — e é uma das causas de screenshot que só difere em CI.

### 1.4 Ordem e remoção

Handlers registrados depois têm precedência: o **último** registrado é consultado primeiro, e `route.fallback` passa adiante. `page.unroute(url, handler)` remove um; `page.unrouteAll` remove todos.

Isso é o mecanismo para "o mock geral vale para a suíte, e esta story diverge": registre o geral numa fixture e o específico no teste.

---

## 2. HAR — congelar o tráfego real

```ts
// gravar
await page.routeFromHAR('./hars/frutas.har', {
 url: '*/**/api/v1/frutas',
 update: true,
});

// reproduzir
await page.routeFromHAR('./hars/frutas.har', {
 url: '*/**/api/v1/frutas',
 update: false,
});
```

Com `update: true` o Playwright grava o tráfego real; com `false` responde do arquivo. O corpo das respostas fica em arquivos `.txt` ao lado do HAR, editáveis antes do commit.

Quando HAR compensa: API de terceiro com resposta grande e estável, cuja forma ninguém quer redigitar. Quando não compensa: API própria em evolução — o HAR vira um contrato fossilizado que passa a esconder mudança de shape. Nesse caso, reusar o tipo do servidor é melhor (`PW-NET-04`).

---

## 3. WebSocket

```ts
// mock completo
await page.routeWebSocket('wss://exemplo.com/ws', ws => {
 ws.onMessage(msg => {
 if (msg === 'ping') ws.send('pong');
 });
});

// intermediar o servidor real
await page.routeWebSocket('wss://exemplo.com/ws', ws => {
 const servidor = ws.connectToServer;
 ws.onMessage(msg => servidor.send(msg === 'request' ? 'request2' : msg));
});
```

Observar sem interceptar:

```ts
page.on('websocket', ws => {
 ws.on('framesent', f => console.log('→', f.payload));
 ws.on('framereceived', f => console.log('←', f.payload));
});
```

---

## 4. Eventos e espera de rede

```ts
page.on('request', r => console.log('→', r.method, r.url));
page.on('response', r => console.log('←', r.status, r.url));

const respostaPromise = page.waitForResponse(r =>
 r.url.includes('/api/pedidos') && r.status === 201);
await page.getByRole('button', { name: 'Salvar' }).click;
const resposta = await respostaPromise;
await expect(resposta).toBeOK;
```

A espera é armada **antes** da ação, pela mesma razão de `PW-ACT-03`.

> **A causa mais comum de "os eventos de rede não aparecem", e a menos óbvia:** um **Service Worker** intercepta a requisição antes do Playwright. A fonte prescreve, textualmente, desligar:
>
> ```ts
> use: { serviceWorkers: 'block' }
> ```
>
> Verifique isto **antes** de qualquer outra hipótese (`PW-NET-03`). Num PWA — qualquer app que registre Service Worker — este é o default de config para a suíte E2E.

---

## 5. `APIRequestContext` — chamar API de verdade

Isto **não** é mock: é a forma de preparar e verificar estado sem passar pela UI.

```ts
// config
use: {
 baseURL: 'http://localhost:3333',
 extraHTTPHeaders: { Authorization: `Bearer ${process.env.API_TOKEN}` },
}
```

```ts
// teste só de API
test('cria pedido', async ({ request }) => {
 const r = await request.post('/pedidos', { data: { item: 'Café', qtd: 2 } });
 await expect(r).toBeOK;
 expect(await r.json).toMatchObject({ item: 'Café' });
});
```

### 5.1 Preparar estado antes da UI — o padrão que mais economiza tempo

```ts
test('pedido criado aparece na lista', async ({ page, request }) => {
 const r = await request.post('/pedidos', { data: { item: 'Café' } });
 const { id } = await r.json;

 await page.goto('/pedidos');
 await expect(page.getByRole('row', { name: new RegExp(String(id)) })).toBeVisible;
});
```

Doze cliques viram um `POST`. E o teste passa a falhar por **um** motivo — a listagem — em vez de falhar por qualquer defeito no formulário de criação, que tem teste próprio.

### 5.2 Verificar o servidor depois da UI

```ts
test('criar pelo formulário grava no servidor', async ({ page, request }) => {
 await page.goto('/pedidos/novo');
 await page.getByLabel('Item').fill('Café');
 await page.getByRole('button', { name: 'Salvar' }).click;
 await expect(page.getByText('Pedido criado')).toBeVisible;

 const id = new URL(page.url).pathname.split('/').pop;
 await expect(await request.get(`/pedidos/${id}`)).toBeOK;
});
```

Isto verifica que a UI não mentiu — que o "Pedido criado" corresponde a estado persistido.

### 5.3 `page.request` × `playwright.request` — a diferença que morde

| Forma | Cookies |
| --- | --- |
| `page.request` / `context.request` | **compartilha** os cookies do contexto do browser, e aplica `Set-Cookie` de volta nele |
| `playwright.request.newContext` | **isolado**; cookies próprios |

Consequência prática: uma chamada autenticada por cookie de sessão funciona com `page.request` e retorna 401 com `playwright.request` — e vice-versa, um teste que quer verificar "sem estar logado" precisa do segundo (`PW-NET-05`).

```ts
const ctx = await playwright.request.newContext({ baseURL: 'http://localhost:3333' });
// … usa …
await ctx.dispose;
```

`storageState` é **interoperável** entre `BrowserContext` e `APIRequestContext`: login por API serve para teste de UI, e vice-versa ([Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) § 4).

---

## 6. Mockar API de browser

```ts
test.beforeEach(async ({ page }) => {
 await page.addInitScript( => {
 const bateria = {
 level: 0.15,
 charging: false,
 chargingTime: Infinity,
 dischargingTime: 1800,
 addEventListener: => {},
 };
 // @ts-expect-error API não tipada no lib padrão
 window.navigator.getBattery = async => bateria;
 });
});
```

**`addInitScript` roda antes de qualquer script da página, a cada navegação.** Registrar depois do `goto` não tem efeito — a página já leu a API.

Propriedade somente-leitura:

```ts
await page.addInitScript( => {
 Object.defineProperty(Object.getPrototypeOf(navigator), 'cookieEnabled', { value: false });
});
```

Observar chamadas do lado da página:

```ts
await page.exposeFunction('registrar', (nome: string) => chamadas.push(nome));
```

---

## 7. Controlar o tempo — `page.clock`

```ts
// caso simples: data fixa, timers continuam correndo
await page.clock.setFixedTime(new Date('2026-02-02T10:00:00'));
await page.goto('/relatorio');
await expect(page.getByTestId('data')).toHaveText('02/02/2026');
```

```ts
// caso avançado: controlar timers
await page.clock.install({ time: new Date('2026-02-02T08:00:00') });
await page.goto('/sessao');
await page.clock.pauseAt(new Date('2026-02-02T10:00:00'));
await page.clock.fastForward('30:00'); // 30 min à frente
await expect(page.getByText('Sessão expirada')).toBeVisible;
```

```ts
// disparar timer com precisão
await page.clock.pauseAt(new Date('2026-02-02T10:00:00'));
await page.clock.runFor(2000); // avança 2 s de timers
```

| Método | Para quê |
| --- | --- |
| `setFixedTime` | **começar por aqui.** Congela `Date.now`/`new Date`, deixa timers rodando |
| `install` | assume o controle completo, para usar `pauseAt`/`fastForward`/`runFor` |
| `pauseAt` | para o tempo num instante |
| `fastForward` | avança disparando os timers do intervalo |
| `runFor` | avança uma duração exata |
| `resume` | volta a correr |
| `setSystemTime` | a fonte reserva para "casos avançados"; prefira `setFixedTime` |

Isto é o que permite testar expiração de sessão, debounce, polling e "faz 3 dias" **sem** `waitForTimeout` — é o antídoto direto de `PW-CORE-05` na classe de testes onde o tempo é o assunto.

---

## 8. Regras — `PW-NET-01` a `PW-NET-07`

| ID | Regra |
| --- | --- |
| `PW-NET-01` | Dependência de terceiro **MUST** ser interceptada com `route`. Teste que chama serviço externo de verdade **NEVER**. |
| `PW-NET-02` | `route` **MUST** ser registrado antes da navegação que dispara a requisição; `addInitScript` **MUST** ser registrado antes do `goto`. |
| `PW-NET-03` | Quando eventos de rede não aparecem, `serviceWorkers: 'block'` **MUST** ser a primeira hipótese verificada. |
| `PW-NET-04` | Mock que reproduz o shape da resposta **MUST** reusar o tipo exportado do servidor. Shape redigitado à mão **NEVER**. † |
| `PW-NET-05` | `page.request` e `playwright.request` **NEVER** são intercambiáveis: o primeiro compartilha cookies com o contexto do browser, o segundo é isolado. |
| `PW-NET-06` | Estado necessário ao teste **MUST** ser criado por API quando existir endpoint. Criar pela UI o que não está sob teste **NEVER**. † |
| `PW-NET-07` | Teste cujo assunto é tempo (expiração, debounce, polling) **MUST** usar `page.clock`. † |

---

## 9. Antipadrões

### 9.1 Chamar o terceiro de verdade

```ts
// ✗
await page.goto('/checkout'); // fala com o gateway de pagamento real
```

Teste que depende de rede alheia falha por motivo alheio, e o sinal deixa de significar algo (`PW-NET-01`).

### 9.2 `route` depois do `goto`

```ts
// ✗ a requisição já saiu
await page.goto('/frutas');
await page.route('**/api/frutas', r => r.fulfill({ json: [] }));
```

(`PW-NET-02`)

### 9.3 Mockar `fetch` na mão

```ts
// ✗
await page.addInitScript( => {
 window.fetch = async => new Response(JSON.stringify([]));
});
```

Reimplementa `route` pior: não pega XHR, não pega navegação, não pega recurso, e quebra tudo que a aplicação faz com `Response`.

### 9.4 Redigitar o shape da resposta

```ts
// ✗
await route.fulfill({ json: { id: 1, name: 'Café', qty: 2 } }); // o servidor manda "quantidade"
```

O mock passa, a aplicação real quebra. Reuse o tipo do servidor — [Hono - Validação e RPC](hono-validacao-e-rpc.md), [Elysia - Schema e Eden](elysia-schema-e-eden.md) (`PW-NET-04`).

### 9.5 Criar dado pela UI para testar outra coisa

```ts
// ✗ 14 ações para chegar ao assunto do teste
await criarClientePelaUI(page);
await criarPedidoPelaUI(page);
await test.step('finalmente, o que o teste verifica', async => { … });
```

Lento, e falha por qualquer defeito no caminho (`PW-NET-06`).

### 9.6 `waitForTimeout` onde o assunto é tempo

```ts
// ✗ 61 s de teste
await page.waitForTimeout(61_000);
await expect(page.getByText('Sessão expirada')).toBeVisible;
```

`page.clock` resolve em milissegundos reais (`PW-NET-07`).

### 9.7 Bloquear imagens numa suíte com screenshot

```ts
// ✗ conflita com toHaveScreenshot
await page.route(/\.(png|jpg)$/, r => r.abort);
```

Ver § 1.3 e [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) § 2.

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 5.4 é a árvore de "o que substituir"
- [Playwright - Ações e Auto-waiting](playwright-acoes-e-auto-waiting.md) — armar a espera antes da ação
- [Playwright - Assertions](playwright-assertions.md) — `toBeOK` e matchers assimétricos sobre payload
- [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) — `storageState` entre API e browser
- [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) — por que bloquear imagem quebra screenshot
- [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) · [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) · [HTTP - CORS](http-cors.md) — a semântica que o mock precisa preservar
- [Hono - Validação e RPC](hono-validacao-e-rpc.md) · [Elysia - Schema e Eden](elysia-schema-e-eden.md) — de onde vem o tipo da resposta
- [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) — por que a query não refaz o fetch que o teste esperava
- — o critério de quando mock não basta
- [Storybook - Mocking](storybook-mocking.md) — o mesmo problema, um nível abaixo, com MSW

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Network](https://playwright.dev/docs/network) — `route`, eventos, e o aviso sobre Service Workers
- [Mock APIs](https://playwright.dev/docs/mock) — `fulfill`, `fetch`, HAR, `routeWebSocket`
- [Mock browser APIs](https://playwright.dev/docs/mock-browser-apis) — `addInitScript`, `defineProperty`, `exposeFunction`
- [API testing](https://playwright.dev/docs/api-testing) — `APIRequestContext`, e a diferença de cookies
- [Clock](https://playwright.dev/docs/clock) — `setFixedTime` × `install`, e a recomendação da fonte
