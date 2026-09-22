# Exemplo trabalhado

Tarefa: *"a listagem de faturas está lenta, e duas pessoas editando a mesma fatura se sobrescrevem"*.

São dois problemas e duas partes da árvore.

**Parte 1 — frescor da listagem.** É dado de usuário autenticado, muda a cada escrita, e servir velho não é aceitável (dinheiro na tela):

```http
GET /faturas
200 OK
Cache-Control: private, max-age=0, must-revalidate
ETag: "lista-v41"
Vary: Accept, Accept-Encoding
Content-Type: application/json; charset=utf-8
```

E a rota passa a tratar `If-None-Match`, devolvendo `304` quando `"lista-v41"` bate (`HTTP-CACHE-07`). A economia vem do `304`, não do `max-age` — o cliente pergunta sempre, e a resposta é pequena.

**Parte 2 — a escrita concorrente:**

```http
PUT /faturas/42
If-Match: "v7"

→ 412 Precondition Failed (o ETag atual é "v9")
```

**O que as decisões evitaram:**

| Decisão | Alternativa comum | Regra |
| --- | --- | --- |
| `private` | `public`, e a CDN serve a fatura de uma pessoa para outra | `HTTP-CACHE-02` |
| `max-age=0, must-revalidate` + `ETag` | `no-store`, que perde o `304` e mantém a lentidão | `HTTP-CACHE-03` |
| tratar `If-None-Match` | só emitir `ETag`, e o cliente receber o corpo sempre | `HTTP-CACHE-07` |
| `Vary: Accept, Accept-Encoding` | sem `Vary`, e o cache serve gzip a cliente que não aceita | `HTTP-CACHE-10`, `HTTP-NEG-01` |
| `If-Match` + `412` | last-write-wins, perda silenciosa de dado | `HTTP-CACHE-08` |
| `ETag` forte | `W/"v7"`, que não decide identidade | `HTTP-CACHE-09` |
| `charset=utf-8` explícito | acentos quebrados | `HTTP-CORE-03` |

E o que **não** foi feito, deliberadamente: nada de `staleTime` como resposta ao problema de lentidão. Ele economizaria requisição do cliente e não resolveria a segunda visita nem outro dispositivo — camada diferente (§ 5).

---

