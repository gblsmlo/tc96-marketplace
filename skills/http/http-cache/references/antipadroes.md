# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| `GET` without `Cache-Control` (heuristic freshness kicks in) | `HTTP-CACHE-01` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Authenticated response marked `public` | `HTTP-CACHE-02` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `no-store` meaning "always revalidate" | `HTTP-CACHE-03` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Long `max-age` on an unversioned URL | `HTTP-CACHE-04` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Emitting an `ETag` and not handling `If-None-Match` | `HTTP-CACHE-07` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `304` with a body, or without repeating `ETag`/`Vary` | `HTTP-CACHE-06` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Concurrent write without `If-Match` (last-write-wins) | `HTTP-CACHE-08` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `W/` on an `ETag` used in `If-Match` | `HTTP-CACHE-09` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| A body that varies by header, without `Vary` | `HTTP-CACHE-10` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `Vary: Cookie` to protect personalized data | `HTTP-CACHE-11` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `max-age` fixo em recurso que precisa ser derrubado | `HTTP-CACHE-12` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Resposta comprimida sem `Vary: Accept-Encoding` | `HTTP-NEG-01` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Origem dinâmica sem `Vary: Origin` | `HTTP-CORS-03` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `POST`/`PATCH` declarando frescor sem `Content-Location` | `HTTP-METH-10` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `staleTime` do Query tratado como política de cache do recurso | § 8.3 do hub | [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) |
| `invalidateQueries` esperando derrubar cache de CDN | § 8.3 do hub | |

