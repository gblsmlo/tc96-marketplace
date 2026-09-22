# Formato do achado, e o corte

```
`ID-DA-REGRA` — <onde>
Sintoma: <como a falha se apresenta, e para quem>
Evidência: <a saída da sonda — cole os headers>
Causa: <uma frase>
Correção: <mudança concreta>
Ver [[Satélite correspondente]].
```

### Exemplo

```
`HTTP-CORS-05` — apps/server/src/app.ts:22 (ordem dos middlewares)
Sintoma: toda chamada do SPA falha com "CORS policy" no console; curl direto funciona.
Evidência: sonda 2 devolveu `401 Unauthorized` no OPTIONS, sem nenhum
  Access-Control-Allow-*. No log do servidor há o OPTIONS, e o middleware de auth
  registrou "missing bearer token".
Causa: o middleware de autenticação está montado antes do de CORS, e o browser
  não envia credencial no preflight — então o OPTIONS é rejeitado antes de o CORS responder.
Correção: montar o middleware de CORS antes do de auth, ou isentar OPTIONS da auth.
Ver [[HTTP - CORS]], e [[Hono - Middleware e Ciclo de Vida]] para a ordem do onion model.
```

Regras do formato: **ID conferido na § 6**; **evidência é a saída da sonda**, não "parece CORS"; correção concreta; um link de satélite.

---

## Passo 6 — O corte: o que não é CORS

Quatro falhas que se apresentam como CORS e não são. Confundi-las custa horas.

| Sintoma | Não é CORS — é |
| --- | --- |
| console diz CORS, e o servidor não tem log do request | servidor caído, TLS, DNS, porta |
| requisição chega, `401` na chamada **real** | autorização — [[OWASP - Sessão e Autorização]] |
| cookie não é enviado cross-site | `SameSite` — [[RFC 6265 - Cookies HTTP]] |
| funciona no curl, falha no browser, sem menção a CORS | mixed content, CSP, ou service worker |

**E o inverso, que é o mais perigoso:** "resolvi o CORS liberando `*`" numa rota que aceita credenciais não resolveu — é inválido, e o browser continua recusando (`HTTP-CORS-02`). Quem "resolve" desligando o CORS geralmente moveu o bug para produção.

---

