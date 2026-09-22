# Autoverificação antes de entregar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-contract/scripts/conferir.sh https://api.local /pedidos/42 /pedidos
```

| # | Confira | Regra |
| --- | --- | --- |
| 1 | método safe não escreve estado | `HTTP-CORE-02`, `HTTP-METH-01` |
| 2 | `PUT` substitui a representação inteira | `HTTP-METH-03` |
| 3 | sem corpo em `GET`/`HEAD`/`DELETE` | `HTTP-METH-02` |
| 4 | `HEAD` responde onde `GET` responde | `HTTP-METH-06` |
| 5 | falha não é `2xx` | `HTTP-CORE-06` |
| 6 | `201` tem `Location`; `204` não tem corpo | `HTTP-STATUS-03`, `HTTP-STATUS-04` |
| 7 | `405` tem `Allow`; `401` tem `WWW-Authenticate` | `HTTP-METH-07`, `HTTP-STATUS-10` |
| 8 | `429`/`503` têm `Retry-After` | `HTTP-STATUS-09` |
| 9 | redirect que precisa do método é `307`/`308`; `POST`→página é `303` | `HTTP-STATUS-07`, `HTTP-STATUS-08` |
| 10 | `Content-Type` declarado, com `charset` em `text/*` | `HTTP-CORE-03` |
| 11 | resposta que varia por header de request declara `Vary` | `HTTP-CORE-04` |
| 12 | `POST`/`PATCH` retentável aceita chave de idempotência | `HTTP-METH-09` |
| 13 | corpo de erro no formato único da API | `HTTP-SPEC-08` |
| 14 | nada sensível em query string | `HTTP-CORE-07` |
| 15 | leitura de header é case-insensitive | `HTTP-CORE-08` |

**E a verificação que vale mais que as quinze:** `curl -i` na rota e leia os headers de verdade.

```bash
curl -i -X POST https://api.local/pedidos -H 'Content-Type: application/json' -d '{}'
curl -i -X HEAD https://api.local/pedidos/42
curl -i -X PATCH https://api.local/pedidos/42 # a rota só aceita PUT?
```

O terceiro é o que pega `HTTP-METH-07`: se voltar `404` em vez de `405` com `Allow`, é o middleware faltando.

---

