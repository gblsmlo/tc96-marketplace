# Método e status

> Passos 1 e 2. As árvores completas são a § 5.1 e § 5.2 de [HTTP](../../../../knowledge-base/docs/http.md).

A árvore completa é a § 5.1 do hub. As invariantes que ela protege:

| Propriedade | Significa | Regra |
| --- | --- | --- |
| **safe** | não altera estado de domínio — `GET`, `HEAD`, `OPTIONS` | `HTTP-CORE-02`, `HTTP-METH-01` |
| **idempotente** | repetir produz o mesmo estado final — `PUT`, `DELETE` | `HTTP-METH-04` |
| **cacheável** | a resposta pode ser reusada | `HTTP-METH-10` |

Três decisões que a árvore resolve e que se erram por hábito:

- **`PUT` substitui a representação inteira.** Endpoint que aceita `PUT` e ignora os campos ausentes não é `PUT` — é `PATCH` mal nomeado (`HTTP-METH-03`).
- **Nada de corpo em `GET`, `HEAD` ou `DELETE`** — nem do cliente, nem definido pelo servidor (`HTTP-METH-02`).
- **Toda rota que responde `GET` responde `HEAD`** na mesma URL, com os mesmos headers e sem corpo (`HTTP-METH-06`).

E a que não é sobre estilo: **ação destrutiva nunca fica atrás de método safe** (`HTTP-METH-01`). Um `GET /pedidos/42/cancelar` é disparado por prefetch de browser, por crawler e por qualquer cache.

---

## Passo 2 — Qual status

A árvore completa é a § 5.2 do hub. As obrigações que acompanham cada escolha:

| Status | Obrigação | Regra |
| --- | --- | --- |
| `201` | `Location` apontando para o recurso criado | `HTTP-STATUS-03`, `HTTP-METH-05` |
| `204` | **sem corpo** | `HTTP-STATUS-04` |
| `202` | no corpo, o identificador ou URL de acompanhamento | `HTTP-STATUS-05` |
| `401` | `WWW-Authenticate` | `HTTP-STATUS-10` |
| `405` | `Allow` com os métodos suportados | `HTTP-METH-07` |
| `415` | quando o `Content-Type` **do request** é recusado — não `400` | `HTTP-NEG-07` |
| `422` | corpo válido reprovado por regra de negócio | `HTTP-STATUS-11` |
| `429` / `503` | `Retry-After` | `HTTP-STATUS-09` |
| `502` | quando o serviço é gateway e o upstream falhou | `HTTP-STATUS-12` |

**A regra que domina o passo:** falha nunca é `2xx` com erro no corpo. O status carrega o resultado (`HTTP-CORE-06` — canônico; `HTTP-STATUS-01` é apelido e não deve ser citado).

> **A ponte que evita o bug mais comum do stack:** nem o `hc` do Hono nem o Eden Treaty do Elysia **lançam** em status de erro. Uma `queryFn` ingênua fica em `success` com o erro dentro de `data` — ver `Docs/Hono - Validação e RPC.md` e `Docs/Elysia - Schema e Eden.md`. Ou seja: cumprir `HTTP-CORE-06` no servidor **não basta** se o cliente tipado não checa `res.ok`.

### 2.1 Redirecionamento

| Preciso… | Use | Regra |
| --- | --- | --- |
| preservar método e corpo | `307` (temporário) ou `308` (permanente) | `HTTP-STATUS-07` |
| mandar um `POST` para uma página de resultado | **`303`** | `HTTP-STATUS-08` |
| mover permanentemente uma URL de `GET` | `301` | — |

E todo `3xx` de redirecionamento leva `Location` (`HTTP-STATUS-06`).

> **`301` e `302` permitem a troca de método pela própria spec** — não é tolerância a bug de browser. É por isso que "temporário" não é o critério: o critério é se o método precisa sobreviver.

---

