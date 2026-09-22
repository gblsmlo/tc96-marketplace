# Antipadrões mais frequentes, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Falha em `2xx` com erro no corpo | `HTTP-CORE-06` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Escrita concorrente sem `If-Match` | `HTTP-CACHE-08` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `ETag` fraco em `If-Match` | `HTTP-CACHE-09` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `GET` sem `Cache-Control` | `HTTP-CACHE-01` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Resposta autenticada como `public` | `HTTP-CACHE-02` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `ETag` emitido e `If-None-Match` ignorado | `HTTP-CACHE-07` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Corpo que varia por header, sem `Vary` | `HTTP-CACHE-10` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `Vary: Cookie` para proteger dado | `HTTP-CACHE-11` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Destrutivo atrás de `GET` | `HTTP-METH-01` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `PUT` que ignora campos ausentes | `HTTP-METH-03` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| Idempotência quebrada em `PUT`/`DELETE` | `HTTP-METH-04` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| Retry automático em `POST` sem chave | `HTTP-METH-08`, `HTTP-METH-09` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `HEAD` ausente onde `GET` responde | `HTTP-METH-06` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `404` em vez de `405` com `Allow` | `HTTP-METH-07` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `POST`/`PATCH` com frescor sem `Content-Location` | `HTTP-METH-10` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `4xx` e `5xx` trocados | `HTTP-STATUS-02` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `201` sem `Location` · `204` com corpo | `HTTP-STATUS-03`, `HTTP-STATUS-04` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `202` sem como acompanhar | `HTTP-STATUS-05` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `3xx` sem `Location` | `HTTP-STATUS-06` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `302` onde o método precisa sobreviver | `HTTP-STATUS-07` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `POST`→página sem `303` | `HTTP-STATUS-08` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `429`/`503` sem `Retry-After` | `HTTP-STATUS-09` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `401` sem `WWW-Authenticate`, ou no lugar de `403` | `HTTP-STATUS-10` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `400` onde era `422` | `HTTP-STATUS-11` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| `500` onde era `502` | `HTTP-STATUS-12` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) |
| Origem refletida cegamente | `HTTP-CORS-01` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `*` com credenciais | `HTTP-CORS-02` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Origem dinâmica sem `Vary: Origin` | `HTTP-CORS-03` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Header necessário fora de `Expose-Headers` | `HTTP-CORS-04` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| Preflight exigindo auth | `HTTP-CORS-05` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| CORS tratado como autorização | `HTTP-CORS-08` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `Expose-Headers: *` com credenciais | `HTTP-CORS-10` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `text/*` sem `charset` | `HTTP-CORE-03`, `HTTP-NEG-02` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Comprimir formato já comprimido | `HTTP-NEG-04` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| `400` onde era `415` | `HTTP-NEG-07` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| `Range` fora dos limites sem `416` | `HTTP-NEG-11` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Sensível em query string | `HTTP-CORE-07` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Rejeitar request por header desconhecido | `HTTP-CORE-05` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Comparar nome de header case-sensitive | `HTTP-CORE-08` | [HTTP](../../../../knowledge-base/docs/http.md) |
| Dois formatos de corpo de erro | `HTTP-SPEC-08` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| Citar RFC obsoleto (7230–7235, 7807…) | `HTTP-SPEC-02` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| MDN como única fonte de afirmação `MUST` | `HTTP-SPEC-03` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| Atribuir CORS a um RFC | `HTTP-SPEC-04` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| Citar RFC 6265 para `SameSite` | `HTTP-SPEC-05` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |
| Status fora do registro do IANA | `HTTP-SPEC-06` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) |

