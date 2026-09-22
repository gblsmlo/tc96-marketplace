# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Refletir o header `Origin` cegamente em `Allow-Origin` | `HTTP-CORS-01` | [[HTTP - CORS]] |
| `Allow-Origin: *` com `Allow-Credentials: true` | `HTTP-CORS-02` | [[HTTP - CORS]] |
| Origem dinâmica sem `Vary: Origin` | `HTTP-CORS-03` | [[HTTP - CORS]] |
| Header necessário ao JS fora de `Expose-Headers` | `HTTP-CORS-04` | [[HTTP - CORS]] |
| Preflight exigindo autenticação | `HTTP-CORS-05` | [[HTTP - CORS]] |
| Header não-safelisted fora de `Allow-Headers` | `HTTP-CORS-06` | [[HTTP - CORS]] |
| Método fora de `Allow-Methods` | `HTTP-CORS-07` | [[HTTP - CORS]] |
| Tratar CORS como mecanismo de autorização | `HTTP-CORS-08` | [[HTTP - CORS]] |
| Allowlist sem as origens de desenvolvimento | `HTTP-CORS-09` | [[HTTP - CORS]] |
| `Expose-Headers: *` em rota com credenciais | `HTTP-CORS-10` | [[HTTP - CORS]] |
| Atribuir regra de CORS a um RFC | `HTTP-SPEC-04` | [[HTTP - Specs e RFCs]] |
| `400` onde o `Content-Type` foi recusado (era `415`) | `HTTP-NEG-07` | [[HTTP - Negociação de Conteúdo e Range]] |
| `406` respondido a `Accept-Encoding` que aceita `identity` | `HTTP-NEG-06` | [[HTTP - Negociação de Conteúdo e Range]] |
| `text/*` sem `charset` | `HTTP-NEG-02` | [[HTTP - Negociação de Conteúdo e Range]] |
| Resposta negociada sem `Vary` | `HTTP-NEG-01` | [[HTTP - Negociação de Conteúdo e Range]] |
| Rejeitar request por header desconhecido | `HTTP-CORE-05` | [[HTTP]] |

