# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Reflecting the `Origin` header blindly into `Allow-Origin` | `HTTP-CORS-01` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| `Allow-Origin: *` with `Allow-Credentials: true` | `HTTP-CORS-02` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| Dynamic origin without `Vary: Origin` | `HTTP-CORS-03` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| A header JS needs left out of `Expose-Headers` | `HTTP-CORS-04` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| Preflight requiring authentication | `HTTP-CORS-05` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| Non-safelisted header left out of `Allow-Headers` | `HTTP-CORS-06` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| Method left out of `Allow-Methods` | `HTTP-CORS-07` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| Treating CORS as an authorization mechanism | `HTTP-CORS-08` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| Allowlist without the development origins | `HTTP-CORS-09` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| `Expose-Headers: *` on a route with credentials | `HTTP-CORS-10` | [HTTP - CORS](../../../../knowledge-base/http-cors.md) |
| Attributing a CORS rule to an RFC | `HTTP-SPEC-04` | [HTTP - Specs e RFCs](../../../../knowledge-base/http-specs-e-rfcs.md) |
| `400` where the `Content-Type` was refused (it was `415`) | `HTTP-NEG-07` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/http-negociacao-de-conteudo-e-range.md) |
| `406` answered to an `Accept-Encoding` that accepts `identity` | `HTTP-NEG-06` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/http-negociacao-de-conteudo-e-range.md) |
| `text/*` without `charset` | `HTTP-NEG-02` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/http-negociacao-de-conteudo-e-range.md) |
| Negotiated response without `Vary` | `HTTP-NEG-01` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/http-negociacao-de-conteudo-e-range.md) |
| Rejecting a request over an unknown header | `HTTP-CORE-05` | [HTTP](../../../../knowledge-base/http.md) |

