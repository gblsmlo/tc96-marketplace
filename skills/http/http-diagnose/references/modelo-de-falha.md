# É CORS mesmo? e o modelo de falha

**1. Não existe RFC de CORS.** O protocolo, o preflight e os forbidden headers são do **Fetch Standard (WHATWG)**, Living Standard, sem versão citável. Atribuir regra de CORS a um RFC é erro de citação (`HTTP-SPEC-04`), e procurar a resposta no RFC 9110 é perder tempo.

**2. CORS não é autorização.** Ele restringe o que um script de **outra origem** pode **ler** — e **não impede a requisição de chegar ao servidor**. Se a preocupação é impedir acesso, o mecanismo é o handler (`HTTP-CORS-08`). Um endpoint "protegido por CORS" está aberto para qualquer cliente que não seja browser.

---

## Passo 1 — É CORS mesmo?

A árvore completa é a § 5.4 do hub. Percorra **sem pular**:

```
O erro no console menciona "CORS policy"?
├── NÃO → não é CORS. É rede, TLS, DNS, ou o servidor caiu.
│ Confirme se a requisição saiu (aba Network / log do servidor).
└── SIM
 └── A requisição chegou ao servidor (aparece no log)?
 ├── NÃO → o preflight falhou ou não foi respondido
 │ ├── há OPTIONS no log? → o handler não devolve os Access-Control-Allow-*
 │ └── não há OPTIONS → a rota não trata OPTIONS
 │ (framework devolvendo 404/405 no preflight)
 └── SIM, 2xx, e ainda falhou
 ├── usa cookie/credencial? → Allow-Origin: * é INVÁLIDO com credenciais
 ├── o header vem undefined → falta Access-Control-Expose-Headers
 └── falha só para alguns, ou só antes de hard refresh
 → cache compartilhado sem Vary: Origin
```

**O primeiro nó é o que mais engana:** "CORS" no console frequentemente é o browser relatando que **não houve resposta** — servidor caído, TLS inválido, porta errada. A checagem é o log do servidor, não o console.

---

## Passo 2 — O modelo de falha, ramo a ramo

### 2.1 O preflight

Um `OPTIONS` automático que o browser envia **antes** da chamada real, quando ela não é "simples".

| Gatilho de preflight | Regra |
| --- | --- |
| método fora de `GET`/`HEAD`/`POST` | `HTTP-CORS-07` |
| header não-safelisted (`Authorization`, `Content-Type: application/json`, header custom) | `HTTP-CORS-06` |

> **`application/json` não é `Content-Type` de requisição simples.** É a causa da maioria dos preflights "inexplicáveis" numa SPA — praticamente toda chamada de API dispara preflight, e isso é normal.

**A resposta ao preflight precisa ser 2xx e não pode exigir autenticação** (`HTTP-CORS-05`) — o browser não manda credencial no `OPTIONS`. Middleware de auth montado antes do de CORS transforma todo preflight em `401`, e o sintoma é "CORS" no console.

### 2.2 Credenciais

```
A chamada usa cookie, Authorization, ou credentials: 'include'?
└── SIM → Access-Control-Allow-Origin: * é INVÁLIDO
 → ecoe a origem concreta + Access-Control-Allow-Credentials: true
 (HTTP-CORS-02)
 → e a origem concreta veio de uma ALLOWLIST, nunca do header Origin
 refletido cegamente (HTTP-CORS-01)
 → e a resposta declara Vary: Origin, inclusive quando RECUSA
 (HTTP-CORS-03)
```

**O default do Hono é `origin: '*'`**, que é inválido com `credentials: true` — `HONO-MW-08` em `Docs/Hono - Middleware e Ciclo de Vida.md`. É o caso concreto mais comum deste ramo no stack.

### 2.3 Header que chega `undefined`

Só **sete** headers de resposta são legíveis cross-origin por default. `ETag` e `Location` **não estão** entre eles.

Se o JavaScript precisa ler um header, ele vai em `Access-Control-Expose-Headers` (`HTTP-CORS-04`). E `*` ali **nunca** em rota que aceita credenciais (`HTTP-CORS-10`).

Isto interage com `http-cache`: uma API que emite `ETag` para o cliente usar em `If-None-Match` precisa expor `ETag`, senão o cliente nunca o vê.

### 2.4 Funciona para uns e não para outros

Cache compartilhado servindo a resposta de outra origem. A correção é `Vary: Origin` (`HTTP-CORS-03`) — e ela vale **inclusive quando a origem é recusada**, porque a resposta de recusa também é cacheável.

### 2.5 Funciona em produção e falha local

`HTTP-CORS-09`: a allowlist precisa incluir as origens de desenvolvimento. **Porta diferente é origem diferente** — `localhost:3000` e `localhost:5173` não são a mesma origem.

---

