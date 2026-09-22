# Exemplo trabalhado

Tarefa: *"endpoint para aprovar uma fatura"*.

**Passo 1 — o método.** Aprovar altera estado → não é safe. Repetir a aprovação produz o mesmo estado final (já aprovada continua aprovada) → **é idempotente**. Duas opções sobrevivem:

- `POST /faturas/42/aprovacao` — cria o recurso "aprovação";
- `PUT /faturas/42/aprovacao` — declara o estado.

Escolho **`PUT`**, porque a idempotência fica no contrato em vez de depender de chave (`HTTP-METH-04`). E `GET /faturas/42/aprovar` estaria fora de questão — ação destrutiva atrás de método safe (`HTTP-METH-01`).

**Passo 2 — o status:**

| Caso | Status | Obrigação |
| --- | --- | --- |
| aprovou agora | `200` com a fatura | `Content-Type` (`HTTP-CORE-03`) |
| já estava aprovada | `200` — mesmo estado final | idempotência visível |
| fatura não existe | `404` | — |
| sem permissão de aprovar | `403` | credencial válida, permissão insuficiente (`HTTP-STATUS-10`) |
| sem credencial | `401` | `WWW-Authenticate` (`HTTP-STATUS-10`) |
| corpo válido, mas valor acima do limite do aprovador | **`422`** | não `400` (`HTTP-STATUS-11`) |
| `Content-Type` errado no request | **`415`** | não `400` (`HTTP-NEG-07`) |
| o serviço de contabilidade caiu | **`502`** | somos gateway (`HTTP-STATUS-12`) |

**Passo 3 — retry.** `PUT` é idempotente, então retry do cliente é seguro sem chave de idempotência. **Se fosse `POST`**, `HTTP-METH-08` proibiria retry automático sem `HTTP-METH-09` cumprida.

**Passo 4 — erro.** `application/problem+json`, o formato único da API (`HTTP-SPEC-08`), citando **RFC 9457**.

**Passo 5 — o stack.** Em Hono, `methodNotAllowed` precisa estar montado, senão `PATCH /faturas/42/aprovacao` volta `404` em vez de `405` (`HTTP-METH-07`).

**O que as decisões evitaram:**

| Decisão | Alternativa comum | Regra |
| --- | --- | --- |
| `PUT` numa subrota de estado | `POST /faturas/42/aprovar`, sem idempotência declarada | `HTTP-METH-04` |
| `422` para limite de aprovador | `400`, que não distingue sintaxe de regra | `HTTP-STATUS-11` |
| `415` para `Content-Type` errado | `400` | `HTTP-NEG-07` |
| `502` quando o upstream cai | `500`, que culpa a nossa aplicação | `HTTP-STATUS-12` |
| `200` na reaprovação | `409`, que quebra a idempotência que o `PUT` prometeu | `HTTP-METH-04` |
| status carregando o resultado | `200 {ok: false}` | `HTTP-CORE-06` |

---

