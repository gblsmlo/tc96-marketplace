# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-contract/scripts/conferir.sh https://api.local /orders/42 /orders
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | a safe method does not write state | `HTTP-CORE-02`, `HTTP-METH-01` |
| 2 | `PUT` replaces the whole representation | `HTTP-METH-03` |
| 3 | no body in `GET`/`HEAD`/`DELETE` | `HTTP-METH-02` |
| 4 | `HEAD` answers where `GET` answers | `HTTP-METH-06` |
| 5 | a failure is not `2xx` | `HTTP-CORE-06` |
| 6 | `201` has `Location`; `204` has no body | `HTTP-STATUS-03`, `HTTP-STATUS-04` |
| 7 | `405` has `Allow`; `401` has `WWW-Authenticate` | `HTTP-METH-07`, `HTTP-STATUS-10` |
| 8 | `429`/`503` have `Retry-After` | `HTTP-STATUS-09` |
| 9 | a redirect that needs the method is `307`/`308`; `POST`→page is `303` | `HTTP-STATUS-07`, `HTTP-STATUS-08` |
| 10 | `Content-Type` declared, with `charset` on `text/*` | `HTTP-CORE-03` |
| 11 | a response that varies by request header declares `Vary` | `HTTP-CORE-04` |
| 12 | a retryable `POST`/`PATCH` accepts an idempotency key | `HTTP-METH-09` |
| 13 | the error body is in the API's single format | `HTTP-SPEC-08` |
| 14 | nothing sensitive in the query string | `HTTP-CORE-07` |
| 15 | header reading is case-insensitive | `HTTP-CORE-08` |

**And the check worth more than the fifteen:** `curl -i` on the route and read the headers for real.

```bash
curl -i -X POST https://api.local/orders -H 'Content-Type: application/json' -d '{}'
curl -i -X HEAD https://api.local/orders/42
curl -i -X PATCH https://api.local/orders/42 # does the route only accept PUT?
```

The third one is what catches `HTTP-METH-07`: if it returns `404` instead of `405` with `Allow`, the middleware is missing.
