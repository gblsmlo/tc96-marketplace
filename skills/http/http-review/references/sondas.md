# As oito sondas

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-review/scripts/sondas.sh https://api.local /faturas/42 /faturas/42
```

Contrato HTTP é **invisível no código**: o handler parece certo, o teste passa, e o header que falta só quebra atrás de uma CDN ou noutro browser. Rode estas oito sondas contra o serviço de pé, **antes** de abrir o código.

| Sonda | Como | O que revela |
| --- | --- | --- |
| **S1. Headers de uma leitura** | `curl -i <GET de recurso>` | `HTTP-CACHE-01`, `HTTP-CORE-03` — falta `Cache-Control`? `Content-Type` sem `charset`? |
| **S2. `HEAD` responde?** | `curl -i -X HEAD <mesma URL>` | `HTTP-METH-06` — `HEAD` ausente onde `GET` responde |
| **S3. Método não suportado** | `curl -i -X PATCH <rota que só aceita PUT>` | `HTTP-METH-07` — devolve `404` em vez de `405` com `Allow`? |
| **S4. Condicional** | `curl -i -H 'If-None-Match: "x"' <GET>` e com o `ETag` real | `HTTP-CACHE-07` — emite `ETag` e ignora `If-None-Match`? |
| **S5. Escrita concorrente** | `curl -i -X PUT -H 'If-Match: "obsoleto"' <rota de escrita>` | `HTTP-CACHE-08` — aplica a escrita em vez de `412`? |
| **S6. Preflight** | `curl -i -X OPTIONS <rota> -H 'Origin: …' -H 'Access-Control-Request-Method: POST'` | `HTTP-CORS-05`, `HTTP-CORS-06` |
| **S7. Origem recusada** | `curl -isS <rota> -H 'Origin: https://malicioso.example' \| grep -i 'access-control\|vary'` | `HTTP-CORS-01`, `HTTP-CORS-03` — reflete cegamente? falta `Vary`? |
| **S8. Corpo de erro** | provocar `400`, `404`, `422` e `500` e comparar os corpos | `HTTP-SPEC-08` — mais de um formato na mesma API? |

**S5 é a mais grave e a menos rodada.** Se a escrita é aplicada, o serviço tem perda silenciosa de dado sob concorrência — não é achado de estilo.

**S3 é a mais provável de acender no stack:** em Hono, sem o middleware `methodNotAllowed`, método não suportado devolve `404` (`Docs/Hono - Middleware e Ciclo de Vida.md` § 5).

**Se S8 mostrar dois formatos de erro, reporte antes de continuar** — é contrato público inconsistente, e cada rota nova amplia o problema.

**Se o serviço não sobe**, declare quais sondas não rodaram (Passo 6, item 6). "Não verificado" não é "sem achado".

---

