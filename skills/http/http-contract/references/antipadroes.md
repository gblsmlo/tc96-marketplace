# Antipadrões, com ID

> Confira em `mapa-de-ids.md` antes de citar.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Ação destrutiva atrás de `GET` | `HTTP-METH-01` | [[HTTP - Métodos e Semântica]] |
| Corpo em `GET` ou `DELETE` | `HTTP-METH-02` | [[HTTP - Métodos e Semântica]] |
| `PUT` que ignora campos ausentes | `HTTP-METH-03` | [[HTTP - Métodos e Semântica]] |
| `POST` retentável sem chave de idempotência | `HTTP-METH-09` | [[HTTP - Métodos e Semântica]] |
| Retry automático configurado para `POST` | `HTTP-METH-08` | [[HTTP - Métodos e Semântica]] |
| `HEAD` não respondido onde `GET` responde | `HTTP-METH-06` | [[HTTP - Métodos e Semântica]] |
| `404` onde devia ser `405` com `Allow` | `HTTP-METH-07` | [[HTTP - Métodos e Semântica]] |
| `201` sem `Location` | `HTTP-STATUS-03` | [[HTTP - Status e Redirecionamento]] |
| `204` com corpo | `HTTP-STATUS-04` | [[HTTP - Status e Redirecionamento]] |
| `202` sem como acompanhar | `HTTP-STATUS-05` | [[HTTP - Status e Redirecionamento]] |
| `302` num redirect de `POST` que precisa do corpo | `HTTP-STATUS-07` | [[HTTP - Status e Redirecionamento]] |
| `POST`→página de resultado com `302` em vez de `303` | `HTTP-STATUS-08` | [[HTTP - Status e Redirecionamento]] |
| `429`/`503` sem `Retry-After` | `HTTP-STATUS-09` | [[HTTP - Status e Redirecionamento]] |
| `401` sem `WWW-Authenticate`, ou `401` onde era `403` | `HTTP-STATUS-10` | [[HTTP - Status e Redirecionamento]] |
| `400` onde a regra de negócio reprovou (era `422`) | `HTTP-STATUS-11` | [[HTTP - Status e Redirecionamento]] |
| `500` quando o upstream caiu (era `502`) | `HTTP-STATUS-12` | [[HTTP - Status e Redirecionamento]] |
| `400` onde o `Content-Type` foi recusado (era `415`) | `HTTP-NEG-07` | [[HTTP - Negociação de Conteúdo e Range]] |
| Falha em `2xx` com erro no corpo | `HTTP-CORE-06` | [[HTTP]] |
| Resposta sem `Content-Type`, ou `text/*` sem `charset` | `HTTP-CORE-03` | [[HTTP]] |
| Token ou documento em query string | `HTTP-CORE-07` | [[HTTP]] |
| Rejeitar request por header desconhecido | `HTTP-CORE-05` | [[HTTP]] |
| Comparar nome de header com maiúsculas | `HTTP-CORE-08` | [[HTTP]] |
| Dois formatos de corpo de erro na mesma API | `HTTP-SPEC-08` | [[HTTP - Specs e RFCs]] |
| Citar RFC 7807 para `problem+json` (é 9457) | `HTTP-SPEC-02` | [[HTTP - Specs e RFCs]] |

