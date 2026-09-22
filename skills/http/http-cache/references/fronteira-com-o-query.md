# A fronteira com o TanStack Query

São **duas camadas de cache** e confundi-las produz decisão errada nas duas. A § 8.3 do hub cobre a sobreposição; o resumo:

| | Cache HTTP | TanStack Query |
| --- | --- | --- |
| Onde vive | browser, CDN, proxy | memória do cliente |
| Chave | URL + `Vary` | `queryKey` |
| Quem decide | **o servidor**, por header | **o cliente**, por `staleTime` |
| Invalidação | prazo, `ETag`, purge de CDN | `invalidateQueries` |

Consequências práticas:

- **`staleTime` do Query não substitui `Cache-Control`.** Sem header, o browser e a CDN aplicam heurística por conta própria (`HTTP-CACHE-01`).
- **`Cache-Control` não substitui `staleTime`.** O Query pode reusar da memória sem nem chegar ao browser.
- **`invalidateQueries` não derruba cache de CDN.** Para isso é `no-cache` + `ETag` (`HTTP-CACHE-12`) ou purge — [[CDN e invalidação de cache]].
- **Um `304` é sucesso**, e o Query o vê como resposta normal — não como "não mudou nada".

---


---

## Por que a confusão é estrutural, e não descuido

As duas camadas usam o mesmo vocabulário — "cache", "stale", "invalidar" — para coisas com
**donos diferentes**:

| | Cache HTTP | Cache do TanStack Query |
| --- | --- | --- |
| onde vive | browser, CDN, proxy | memória do cliente |
| quem decide | **o servidor**, por header | **o cliente**, por `staleTime` |
| o que a skill errada faz | subir `max-age` para "acelerar a UI" | mexer em `staleTime` para resolver dado velho de CDN |

Um `staleTime` alto **não** impede o browser de servir uma resposta cacheada por
`Cache-Control`; e um `no-store` **não** impede o Query de devolver o que já tem em memória.
São camadas empilhadas, e cada uma precisa da sua decisão.

## Relacionados

- [[tanstack-query]] — o dono da outra camada
- [[TanStack Query - Cache e Frescor]] — `staleTime` e invalidação
