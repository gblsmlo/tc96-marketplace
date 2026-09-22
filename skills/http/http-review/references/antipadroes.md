# Most frequent antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Failure as `2xx` with the error in the body | `HTTP-CORE-06` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Concurrent write without `If-Match` | `HTTP-CACHE-08` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Weak `ETag` in `If-Match` | `HTTP-CACHE-09` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `GET` without `Cache-Control` | `HTTP-CACHE-01` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Authenticated response marked `public` | `HTTP-CACHE-02` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `ETag` emitted and `If-None-Match` ignored | `HTTP-CACHE-07` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| A body that varies by header, without `Vary` | `HTTP-CACHE-10` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `Vary: Cookie` to protect data | `HTTP-CACHE-11` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Destructive behind `GET` | `HTTP-METH-01` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `PUT` that ignores absent fields | `HTTP-METH-03` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| Broken idempotency in `PUT`/`DELETE` | `HTTP-METH-04` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| Automatic retry on `POST` without a key | `HTTP-METH-08`, `HTTP-METH-09` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `HEAD` absent where `GET` answers | `HTTP-METH-06` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `404` instead of `405` with `Allow` | `HTTP-METH-07` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `POST`/`PATCH` with freshness but no `Content-Location` | `HTTP-METH-10` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `4xx` and `5xx` swapped | `HTTP-STATUS-02` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `201` without `Location` · `204` with a body | `HTTP-STATUS-03`, `HTTP-STATUS-04` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `202` with no way to track | `HTTP-STATUS-05` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `3xx` without `Location` | `HTTP-STATUS-06` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `302` where the method has to survive | `HTTP-STATUS-07` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `POST`→page without `303` | `HTTP-STATUS-08` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `429`/`503` without `Retry-After` | `HTTP-STATUS-09` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `401` without `WWW-Authenticate`, or in place of `403` | `HTTP-STATUS-10` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `400` where it was `422` | `HTTP-STATUS-11` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `500` where it was `502` | `HTTP-STATUS-12` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| Origin reflected blindly | `HTTP-CORS-01` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `*` with credentials | `HTTP-CORS-02` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Dynamic origin without `Vary: Origin` | `HTTP-CORS-03` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| A needed header left out of `Expose-Headers` | `HTTP-CORS-04` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Preflight requiring auth | `HTTP-CORS-05` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| CORS treated as authorization | `HTTP-CORS-08` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `Expose-Headers: *` with credentials | `HTTP-CORS-10` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `text/*` without `charset` | `HTTP-CORE-03`, `HTTP-NEG-02` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Compressing an already compressed format | `HTTP-NEG-04` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| `400` where it was `415` | `HTTP-NEG-07` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Out-of-bounds `Range` without `416` | `HTTP-NEG-11` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Sensitive data in the query string | `HTTP-CORE-07` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Rejecting a request over an unknown header | `HTTP-CORE-05` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Comparing a header name case-sensitively | `HTTP-CORE-08` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Two error body formats | `HTTP-SPEC-08` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| Citing an obsolete RFC (7230–7235, 7807…) | `HTTP-SPEC-02` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| MDN as the sole source for a `MUST` claim | `HTTP-SPEC-03` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| Attributing CORS to an RFC | `HTTP-SPEC-04` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| Citing RFC 6265 for `SameSite` | `HTTP-SPEC-05` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| Status outside the IANA registry | `HTTP-SPEC-06` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |

