# The boundary with TanStack Query

These are **two cache layers** and confusing them produces the wrong decision in both. § 8.3 of the hub covers the overlap; the summary:

| | HTTP cache | TanStack Query |
| --- | --- | --- |
| Where it lives | browser, CDN, proxy | the client's memory |
| Key | URL + `Vary` | `queryKey` |
| Who decides | **the server**, through headers | **the client**, through `staleTime` |
| Invalidation | deadline, `ETag`, CDN purge | `invalidateQueries` |

Practical consequences:

- **Query's `staleTime` does not replace `Cache-Control`.** Without the header, the browser and the CDN apply heuristics on their own (`HTTP-CACHE-01`).
- **`Cache-Control` does not replace `staleTime`.** Query may reuse from memory without even reaching the browser.
- **`invalidateQueries` does not clear a CDN cache.** For that it is `no-cache` + `ETag` (`HTTP-CACHE-12`) or a purge —.
- **A `304` is a success**, and Query sees it as a normal response — not as "nothing changed".

---


---

## Why the confusion is structural, and not carelessness

The two layers use the same vocabulary — "cache", "stale", "invalidate" — for things with
**different owners**:

| | HTTP cache | TanStack Query cache |
| --- | --- | --- |
| where it lives | browser, CDN, proxy | the client's memory |
| who decides | **the server**, through headers | **the client**, through `staleTime` |
| what the wrong skill does | raise `max-age` to "speed up the UI" | change `staleTime` to fix stale CDN data |

A high `staleTime` does **not** stop the browser from serving a response cached by
`Cache-Control`; and a `no-store` does **not** stop Query from returning what it already has in
memory. They are stacked layers, and each needs its own decision.

## Related

- `tanstack-query` — the owner of the other layer
- [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) — `staleTime` and invalidation
