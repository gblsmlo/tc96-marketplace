# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Refletir o header `Origin` cegamente em `Allow-Origin` | `HTTP-CORS-01` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `Allow-Origin: *` com `Allow-Credentials: true` | `HTTP-CORS-02` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Origem dinâmica sem `Vary: Origin` | `HTTP-CORS-03` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Header necessário ao JS fora de `Expose-Headers` | `HTTP-CORS-04` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Preflight exigindo autenticação | `HTTP-CORS-05` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Header não-safelisted fora de `Allow-Headers` | `HTTP-CORS-06` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Método fora de `Allow-Methods` | `HTTP-CORS-07` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Tratar CORS como mecanismo de autorização | `HTTP-CORS-08` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Allowlist sem as origens de desenvolvimento | `HTTP-CORS-09` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `Expose-Headers: *` em rota com credenciais | `HTTP-CORS-10` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Atribuir regra de CORS a um RFC | `HTTP-SPEC-04` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| `400` onde o `Content-Type` foi recusado (era `415`) | `HTTP-NEG-07` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| `406` respondido a `Accept-Encoding` que aceita `identity` | `HTTP-NEG-06` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| `text/*` sem `charset` | `HTTP-NEG-02` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Resposta negociada sem `Vary` | `HTTP-NEG-01` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Rejeitar request por header desconhecido | `HTTP-CORE-05` | [HTTP](../../../../knowledge-base/docs/http.md) |

