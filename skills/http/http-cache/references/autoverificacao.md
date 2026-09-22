# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-cache/scripts/sondas-cache.sh https://api.local/invoices/42
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | every `GET` response declares `Cache-Control` | `HTTP-CACHE-01` |
| 2 | an authenticated user's response is `private` or `no-store` | `HTTP-CACHE-02` |
| 3 | `no-store` was not used meaning "always revalidate" | `HTTP-CACHE-03` |
| 4 | `max-age` > 24 h only on a versioned URL | `HTTP-CACHE-04` |
| 5 | a revalidatable response has an `ETag` | `HTTP-CACHE-05` |
| 6 | the route **handles** `If-None-Match` and returns `304` | `HTTP-CACHE-07` |
| 7 | `304` with no body, repeating the required headers | `HTTP-CACHE-06` |
| 8 | a concurrent write accepts `If-Match` and returns `412` | `HTTP-CACHE-08` |
| 9 | the `If-Match` `ETag` is strong, without `W/` | `HTTP-CACHE-09` |
| 10 | `Vary` lists the headers that change the body | `HTTP-CACHE-10` |
| 11 | `Vary` does not use `Cookie`/`User-Agent` to protect data | `HTTP-CACHE-11` |
| 12 | a resource that must be invalidated early uses `no-cache` | `HTTP-CACHE-12` |

**The probes that prove it:**

```bash
curl -i https://api.local/invoices/42 # does it have Cache-Control? ETag? Vary?
curl -i -H 'If-None-Match: "v7"' https://api.local/invoices/42 # does it return 304 with no body?
curl -i -X PUT -H 'If-Match: "stale"' https://api.local/invoices/42 # does it return 412?
```

The second and third are the ones that fail most, and neither errors when unimplemented — the second returns `200` with the whole body, the third applies the write and erases someone else's work.
