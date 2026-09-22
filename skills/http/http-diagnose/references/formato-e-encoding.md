# Formato, idioma e encoding

A árvore completa é a § 5.5 do hub:

| Sintoma | Causa | Regra |
| --- | --- | --- |
| **`415`** | o servidor não processa o `Content-Type` que **você enviou** — erro no request | `HTTP-NEG-07` |
| **`406`** | o servidor não tem representação que satisfaça seu `Accept` — frequentemente o `Accept` do cliente é restritivo demais | `HTTP-NEG-06` |
| `200`, formato errado, sempre | o servidor ignora `Accept` — falha do servidor | `HTTP-NEG-01` |
| `200`, formato errado, intermitente | cache serviu a representação de outro cliente — falta `Vary` | `HTTP-CACHE-10` |
| **acentos quebrados** | charset | `HTTP-CORE-03`, `HTTP-NEG-02` |

**O charset é o mais direto:** `application/json` é UTF-8 **por definição do media type**; `text/*` **não é** — precisa de `; charset=utf-8` explícito (`HTTP-NEG-02`). Acento quebrado num `text/plain` ou `text/csv` é quase sempre isso.

**E `406` é raro de verdade:** o servidor **não** deve responder `406` a um `Accept-Encoding` que não proíbe `identity` explicitamente (`HTTP-NEG-06`). Um `406` recebido merece suspeita de bug do servidor antes de ajuste no cliente.

---

