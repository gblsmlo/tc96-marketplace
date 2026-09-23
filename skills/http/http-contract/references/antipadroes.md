# Antipatterns, with IDs

> Check `mapa-de-ids.md` before citing.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Destructive action behind `GET` | `HTTP-METH-01` | [HTTP - Métodos e Semântica](../../../../knowledge-base/http-metodos-e-semantica.md) |
| Body in `GET` or `DELETE` | `HTTP-METH-02` | [HTTP - Métodos e Semântica](../../../../knowledge-base/http-metodos-e-semantica.md) |
| `PUT` that ignores absent fields | `HTTP-METH-03` | [HTTP - Métodos e Semântica](../../../../knowledge-base/http-metodos-e-semantica.md) |
| Retryable `POST` without an idempotency key | `HTTP-METH-09` | [HTTP - Métodos e Semântica](../../../../knowledge-base/http-metodos-e-semantica.md) |
| Automatic retry configured for `POST` | `HTTP-METH-08` | [HTTP - Métodos e Semântica](../../../../knowledge-base/http-metodos-e-semantica.md) |
| `HEAD` not answered where `GET` answers | `HTTP-METH-06` | [HTTP - Métodos e Semântica](../../../../knowledge-base/http-metodos-e-semantica.md) |
| `404` where it should be `405` with `Allow` | `HTTP-METH-07` | [HTTP - Métodos e Semântica](../../../../knowledge-base/http-metodos-e-semantica.md) |
| `201` without `Location` | `HTTP-STATUS-03` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/http-status-e-redirecionamento.md) |
| `204` with a body | `HTTP-STATUS-04` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/http-status-e-redirecionamento.md) |
| `202` with no way to track | `HTTP-STATUS-05` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/http-status-e-redirecionamento.md) |
| `302` on a `POST` redirect that needs the body | `HTTP-STATUS-07` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/http-status-e-redirecionamento.md) |
| `POST`→result page with `302` instead of `303` | `HTTP-STATUS-08` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/http-status-e-redirecionamento.md) |
| `429`/`503` without `Retry-After` | `HTTP-STATUS-09` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/http-status-e-redirecionamento.md) |
| `401` without `WWW-Authenticate`, or `401` where it was `403` | `HTTP-STATUS-10` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/http-status-e-redirecionamento.md) |
| `400` where the business rule rejected (it was `422`) | `HTTP-STATUS-11` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/http-status-e-redirecionamento.md) |
| `500` when the upstream fell (it was `502`) | `HTTP-STATUS-12` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/http-status-e-redirecionamento.md) |
| `400` where the `Content-Type` was refused (it was `415`) | `HTTP-NEG-07` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/http-negociacao-de-conteudo-e-range.md) |
| Failure as `2xx` with the error in the body | `HTTP-CORE-06` | [HTTP](../../../../knowledge-base/http.md) |
| Response without `Content-Type`, or `text/*` without `charset` | `HTTP-CORE-03` | [HTTP](../../../../knowledge-base/http.md) |
| Token or document in the query string | `HTTP-CORE-07` | [HTTP](../../../../knowledge-base/http.md) |
| Rejecting a request over an unknown header | `HTTP-CORE-05` | [HTTP](../../../../knowledge-base/http.md) |
| Comparing a header name case-sensitively | `HTTP-CORE-08` | [HTTP](../../../../knowledge-base/http.md) |
| Two error body formats in the same API | `HTTP-SPEC-08` | [HTTP - Specs e RFCs](../../../../knowledge-base/http-specs-e-rfcs.md) |
| Citing RFC 7807 for `problem+json` (it is 9457) | `HTTP-SPEC-02` | [HTTP - Specs e RFCs](../../../../knowledge-base/http-specs-e-rfcs.md) |

