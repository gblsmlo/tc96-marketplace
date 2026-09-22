# A ordem da varredura, e a severidade

A ordem é por consequência, não por família.

1. **Falha mascarada como sucesso** — `HTTP-CORE-06`. Primeiro porque envenena todo cliente: o `hc` do Hono e o Eden Treaty **não lançam** em status de erro, então um `200 {ok:false}` deixa a query em `success` com o erro dentro de `data`.
2. **Escrita sem proteção de concorrência** — `HTTP-CACHE-08`, `HTTP-CACHE-09`. Perda silenciosa de dado.
3. **Método com semântica errada** — `HTTP-METH-01` (destrutivo em safe), `HTTP-METH-03` (`PUT` parcial), `HTTP-METH-04` (idempotência quebrada), `HTTP-METH-02`.
4. **Retry inseguro** — `HTTP-METH-08`, `HTTP-METH-09`. Frequentemente é configuração do cliente, não código do servidor.
5. **Status que perde informação** — `HTTP-STATUS-02` (4xx × 5xx), `HTTP-STATUS-11` (`422`), `HTTP-STATUS-12` (`502`), `HTTP-STATUS-10` (`401` × `403`), `HTTP-NEG-07` (`415`).
6. **Obrigações que acompanham status** — `HTTP-STATUS-03` (`Location`), `HTTP-STATUS-04` (`204` sem corpo), `HTTP-STATUS-05`, `HTTP-STATUS-09` (`Retry-After`), `HTTP-METH-07` (`Allow`).
7. **Redirecionamento** — `HTTP-STATUS-06`, `HTTP-STATUS-07`, `HTTP-STATUS-08`.
8. **CORS desenhado ou improvisado** — `HTTP-CORS-01`, `HTTP-CORS-02`, `HTTP-CORS-08`, `HTTP-CORS-10`. E `HTTP-CORS-08` é conceitual: CORS tratado como autorização é achado de segurança.
9. **Cache e `Vary`** — `HTTP-CACHE-01`, `HTTP-CACHE-02`, `HTTP-CACHE-10`, `HTTP-CACHE-11`, `HTTP-CORS-03`.
10. **Negociação e charset** — `HTTP-CORE-03`, `HTTP-NEG-02`, `HTTP-NEG-04`, `HTTP-NEG-09` a `HTTP-NEG-11`.
11. **Higiene de request** — `HTTP-CORE-05`, `HTTP-CORE-07`, `HTTP-CORE-08`.
12. **Citação de spec** — `HTTP-SPEC-*`. Por último, e só onde há ADR, comentário de PR ou doc afirmando norma.

Se um passo produz achado que invalida o seguinte — a API sinaliza falha em `2xx`, então discutir qual `4xx` é acadêmico — **pare de auditar o interior** e reporte a mudança de contrato.

---

## Passo 3 — Classificar severidade

| Severidade | O que entra |
| --- | --- |
| **Bloqueante** | falha em `2xx` (`HTTP-CORE-06`); escrita concorrente sem `If-Match` (`HTTP-CACHE-08`); destrutivo atrás de método safe (`HTTP-METH-01`); dado sensível em query string (`HTTP-CORE-07`); CORS usado como autorização (`HTTP-CORS-08`); `Allow-Origin: *` com credenciais (`HTTP-CORS-02`) |
| **Alta** | `PUT` parcial (`HTTP-METH-03`); idempotência quebrada (`HTTP-METH-04`); retry sem chave (`HTTP-METH-08`/`09`); `5xx` onde era `4xx` e vice-versa (`HTTP-STATUS-02`); `500` onde era `502` (`HTTP-STATUS-12`); resposta autenticada como `public` (`HTTP-CACHE-02`); falta de `Vary` (`HTTP-CACHE-10`, `HTTP-CORS-03`) |
| **Média** | `201` sem `Location`; `204` com corpo; `405` sem `Allow`; `429` sem `Retry-After`; `400` onde era `422` ou `415`; `HEAD` ausente; `ETag` sem tratar `If-None-Match`; `charset` faltando; dois formatos de erro |
| **Baixa** | citação de spec desatualizada (`HTTP-SPEC-02`), nome de header fora do registro (`HTTP-SPEC-07`) |

O critério entre Bloqueante e Alta: **o defeito faz o cliente acreditar em algo falso, ou perde dado?** Falha em `2xx` e last-write-wins fazem as duas coisas — são de outra categoria que "status impreciso".

**E o critério que separa achado de contexto:** se o framework não faz aquilo sozinho (§ 8 do hub), o achado continua válido, mas a correção muda — é montar o built-in, não escrever o header à mão.

---

