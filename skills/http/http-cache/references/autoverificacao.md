# Autoverificação antes de entregar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-cache/scripts/sondas-cache.sh https://api.local/faturas/42
```

| # | Confira | Regra |
| --- | --- | --- |
| 1 | toda resposta `GET` declara `Cache-Control` | `HTTP-CACHE-01` |
| 2 | resposta de usuário autenticado é `private` ou `no-store` | `HTTP-CACHE-02` |
| 3 | `no-store` não foi usado querendo "revalidar sempre" | `HTTP-CACHE-03` |
| 4 | `max-age` > 24 h só em URL versionada | `HTTP-CACHE-04` |
| 5 | resposta revalidável tem `ETag` | `HTTP-CACHE-05` |
| 6 | a rota **trata** `If-None-Match` e devolve `304` | `HTTP-CACHE-07` |
| 7 | `304` sem corpo, repetindo os headers exigidos | `HTTP-CACHE-06` |
| 8 | escrita concorrente aceita `If-Match` e devolve `412` | `HTTP-CACHE-08` |
| 9 | `ETag` de `If-Match` é forte, sem `W/` | `HTTP-CACHE-09` |
| 10 | `Vary` lista os headers que mudam o corpo | `HTTP-CACHE-10` |
| 11 | `Vary` não usa `Cookie`/`User-Agent` para proteger dado | `HTTP-CACHE-11` |
| 12 | recurso que precisa ser derrubado antes do prazo usa `no-cache` | `HTTP-CACHE-12` |

**As sondas que provam:**

```bash
curl -i https://api.local/faturas/42 # tem Cache-Control? ETag? Vary?
curl -i -H 'If-None-Match: "v7"' https://api.local/faturas/42 # devolve 304 sem corpo?
curl -i -X PUT -H 'If-Match: "obsoleto"' https://api.local/faturas/42 # devolve 412?
```

A segunda e a terceira são as que mais falham, e nenhuma das duas dá erro quando não implementada — a segunda devolve `200` com o corpo inteiro, a terceira aplica a escrita e apaga o trabalho de outra pessoa.

---

