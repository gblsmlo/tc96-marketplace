# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| `GET` sem `Cache-Control` (entra o frescor heurístico) | `HTTP-CACHE-01` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Resposta autenticada como `public` | `HTTP-CACHE-02` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `no-store` querendo "sempre revalidar" | `HTTP-CACHE-03` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `max-age` longo em URL sem versão | `HTTP-CACHE-04` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Emitir `ETag` e não tratar `If-None-Match` | `HTTP-CACHE-07` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `304` com corpo, ou sem repetir `ETag`/`Vary` | `HTTP-CACHE-06` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Escrita concorrente sem `If-Match` (last-write-wins) | `HTTP-CACHE-08` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `W/` num `ETag` usado em `If-Match` | `HTTP-CACHE-09` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Corpo que varia por header, sem `Vary` | `HTTP-CACHE-10` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `Vary: Cookie` para proteger dado personalizado | `HTTP-CACHE-11` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| `max-age` fixo em recurso que precisa ser derrubado | `HTTP-CACHE-12` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) |
| Resposta comprimida sem `Vary: Accept-Encoding` | `HTTP-NEG-01` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) |
| Origem dinâmica sem `Vary: Origin` | `HTTP-CORS-03` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) |
| `POST`/`PATCH` declarando frescor sem `Content-Location` | `HTTP-METH-10` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) |
| `staleTime` do Query tratado como política de cache do recurso | § 8.3 do hub | `Docs/TanStack Query - Cache e Frescor.md` |
| `invalidateQueries` esperando derrubar cache de CDN | § 8.3 do hub | |

