# Antipadrões, com ID

> Confira em `mapa-de-ids.md` antes de citar.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Ação destrutiva atrás de `GET` | `HTTP-METH-01` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| Corpo em `GET` ou `DELETE` | `HTTP-METH-02` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `PUT` que ignora campos ausentes | `HTTP-METH-03` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `POST` retentável sem chave de idempotência | `HTTP-METH-09` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| Retry automático configurado para `POST` | `HTTP-METH-08` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `HEAD` não respondido onde `GET` responde | `HTTP-METH-06` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `404` onde devia ser `405` com `Allow` | `HTTP-METH-07` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `201` sem `Location` | `HTTP-STATUS-03` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `204` com corpo | `HTTP-STATUS-04` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `202` sem como acompanhar | `HTTP-STATUS-05` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `302` num redirect de `POST` que precisa do corpo | `HTTP-STATUS-07` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `POST`→página de resultado com `302` em vez de `303` | `HTTP-STATUS-08` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `429`/`503` sem `Retry-After` | `HTTP-STATUS-09` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `401` sem `WWW-Authenticate`, ou `401` onde era `403` | `HTTP-STATUS-10` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `400` onde a regra de negócio reprovou (era `422`) | `HTTP-STATUS-11` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `500` quando o upstream caiu (era `502`) | `HTTP-STATUS-12` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `400` onde o `Content-Type` foi recusado (era `415`) | `HTTP-NEG-07` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Falha em `2xx` com erro no corpo | `HTTP-CORE-06` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Resposta sem `Content-Type`, ou `text/*` sem `charset` | `HTTP-CORE-03` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Token ou documento em query string | `HTTP-CORE-07` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Rejeitar request por header desconhecido | `HTTP-CORE-05` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Comparar nome de header com maiúsculas | `HTTP-CORE-08` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Dois formatos de corpo de erro na mesma API | `HTTP-SPEC-08` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| Citar RFC 7807 para `problem+json` (é 9457) | `HTTP-SPEC-02` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |

