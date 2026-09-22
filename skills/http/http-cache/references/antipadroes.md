# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| `GET` sem `Cache-Control` (entra o frescor heurístico) | `HTTP-CACHE-01` | [[HTTP - Cache e Requisições Condicionais]] |
| Resposta autenticada como `public` | `HTTP-CACHE-02` | [[HTTP - Cache e Requisições Condicionais]] |
| `no-store` querendo "sempre revalidar" | `HTTP-CACHE-03` | [[HTTP - Cache e Requisições Condicionais]] |
| `max-age` longo em URL sem versão | `HTTP-CACHE-04` | [[HTTP - Cache e Requisições Condicionais]] |
| Emitir `ETag` e não tratar `If-None-Match` | `HTTP-CACHE-07` | [[HTTP - Cache e Requisições Condicionais]] |
| `304` com corpo, ou sem repetir `ETag`/`Vary` | `HTTP-CACHE-06` | [[HTTP - Cache e Requisições Condicionais]] |
| Escrita concorrente sem `If-Match` (last-write-wins) | `HTTP-CACHE-08` | [[HTTP - Cache e Requisições Condicionais]] |
| `W/` num `ETag` usado em `If-Match` | `HTTP-CACHE-09` | [[HTTP - Cache e Requisições Condicionais]] |
| Corpo que varia por header, sem `Vary` | `HTTP-CACHE-10` | [[HTTP - Cache e Requisições Condicionais]] |
| `Vary: Cookie` para proteger dado personalizado | `HTTP-CACHE-11` | [[HTTP - Cache e Requisições Condicionais]] |
| `max-age` fixo em recurso que precisa ser derrubado | `HTTP-CACHE-12` | [[HTTP - Cache e Requisições Condicionais]] |
| Resposta comprimida sem `Vary: Accept-Encoding` | `HTTP-NEG-01` | [[HTTP - Negociação de Conteúdo e Range]] |
| Origem dinâmica sem `Vary: Origin` | `HTTP-CORS-03` | [[HTTP - CORS]] |
| `POST`/`PATCH` declarando frescor sem `Content-Location` | `HTTP-METH-10` | [[HTTP - Métodos e Semântica]] |
| `staleTime` do Query tratado como política de cache do recurso | § 8.3 do hub | [[TanStack Query - Cache e Frescor]] |
| `invalidateQueries` esperando derrubar cache de CDN | § 8.3 do hub | [[CDN e invalidação de cache]] |

