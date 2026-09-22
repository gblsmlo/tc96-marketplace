# Antipadrões mais frequentes, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Falha em `2xx` com erro no corpo | `HTTP-CORE-06` | [[HTTP]] |
| Escrita concorrente sem `If-Match` | `HTTP-CACHE-08` | [[HTTP - Cache e Requisições Condicionais]] |
| `ETag` fraco em `If-Match` | `HTTP-CACHE-09` | [[HTTP - Cache e Requisições Condicionais]] |
| `GET` sem `Cache-Control` | `HTTP-CACHE-01` | [[HTTP - Cache e Requisições Condicionais]] |
| Resposta autenticada como `public` | `HTTP-CACHE-02` | [[HTTP - Cache e Requisições Condicionais]] |
| `ETag` emitido e `If-None-Match` ignorado | `HTTP-CACHE-07` | [[HTTP - Cache e Requisições Condicionais]] |
| Corpo que varia por header, sem `Vary` | `HTTP-CACHE-10` | [[HTTP - Cache e Requisições Condicionais]] |
| `Vary: Cookie` para proteger dado | `HTTP-CACHE-11` | [[HTTP - Cache e Requisições Condicionais]] |
| Destrutivo atrás de `GET` | `HTTP-METH-01` | [[HTTP - Métodos e Semântica]] |
| `PUT` que ignora campos ausentes | `HTTP-METH-03` | [[HTTP - Métodos e Semântica]] |
| Idempotência quebrada em `PUT`/`DELETE` | `HTTP-METH-04` | [[HTTP - Métodos e Semântica]] |
| Retry automático em `POST` sem chave | `HTTP-METH-08`, `HTTP-METH-09` | [[HTTP - Métodos e Semântica]] |
| `HEAD` ausente onde `GET` responde | `HTTP-METH-06` | [[HTTP - Métodos e Semântica]] |
| `404` em vez de `405` com `Allow` | `HTTP-METH-07` | [[HTTP - Métodos e Semântica]] |
| `POST`/`PATCH` com frescor sem `Content-Location` | `HTTP-METH-10` | [[HTTP - Métodos e Semântica]] |
| `4xx` e `5xx` trocados | `HTTP-STATUS-02` | [[HTTP - Status e Redirecionamento]] |
| `201` sem `Location` · `204` com corpo | `HTTP-STATUS-03`, `HTTP-STATUS-04` | [[HTTP - Status e Redirecionamento]] |
| `202` sem como acompanhar | `HTTP-STATUS-05` | [[HTTP - Status e Redirecionamento]] |
| `3xx` sem `Location` | `HTTP-STATUS-06` | [[HTTP - Status e Redirecionamento]] |
| `302` onde o método precisa sobreviver | `HTTP-STATUS-07` | [[HTTP - Status e Redirecionamento]] |
| `POST`→página sem `303` | `HTTP-STATUS-08` | [[HTTP - Status e Redirecionamento]] |
| `429`/`503` sem `Retry-After` | `HTTP-STATUS-09` | [[HTTP - Status e Redirecionamento]] |
| `401` sem `WWW-Authenticate`, ou no lugar de `403` | `HTTP-STATUS-10` | [[HTTP - Status e Redirecionamento]] |
| `400` onde era `422` | `HTTP-STATUS-11` | [[HTTP - Status e Redirecionamento]] |
| `500` onde era `502` | `HTTP-STATUS-12` | [[HTTP - Status e Redirecionamento]] |
| Origem refletida cegamente | `HTTP-CORS-01` | [[HTTP - CORS]] |
| `*` com credenciais | `HTTP-CORS-02` | [[HTTP - CORS]] |
| Origem dinâmica sem `Vary: Origin` | `HTTP-CORS-03` | [[HTTP - CORS]] |
| Header necessário fora de `Expose-Headers` | `HTTP-CORS-04` | [[HTTP - CORS]] |
| Preflight exigindo auth | `HTTP-CORS-05` | [[HTTP - CORS]] |
| CORS tratado como autorização | `HTTP-CORS-08` | [[HTTP - CORS]] |
| `Expose-Headers: *` com credenciais | `HTTP-CORS-10` | [[HTTP - CORS]] |
| `text/*` sem `charset` | `HTTP-CORE-03`, `HTTP-NEG-02` | [[HTTP - Negociação de Conteúdo e Range]] |
| Comprimir formato já comprimido | `HTTP-NEG-04` | [[HTTP - Negociação de Conteúdo e Range]] |
| `400` onde era `415` | `HTTP-NEG-07` | [[HTTP - Negociação de Conteúdo e Range]] |
| `Range` fora dos limites sem `416` | `HTTP-NEG-11` | [[HTTP - Negociação de Conteúdo e Range]] |
| Sensível em query string | `HTTP-CORE-07` | [[HTTP]] |
| Rejeitar request por header desconhecido | `HTTP-CORE-05` | [[HTTP]] |
| Comparar nome de header case-sensitive | `HTTP-CORE-08` | [[HTTP]] |
| Dois formatos de corpo de erro | `HTTP-SPEC-08` | [[HTTP - Specs e RFCs]] |
| Citar RFC obsoleto (7230–7235, 7807…) | `HTTP-SPEC-02` | [[HTTP - Specs e RFCs]] |
| MDN como única fonte de afirmação `MUST` | `HTTP-SPEC-03` | [[HTTP - Specs e RFCs]] |
| Atribuir CORS a um RFC | `HTTP-SPEC-04` | [[HTTP - Specs e RFCs]] |
| Citar RFC 6265 para `SameSite` | `HTTP-SPEC-05` | [[HTTP - Specs e RFCs]] |
| Status fora do registro do IANA | `HTTP-SPEC-06` | [[HTTP - Specs e RFCs]] |

