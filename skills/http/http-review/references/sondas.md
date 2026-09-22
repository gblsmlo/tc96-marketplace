# The eight probes

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-review/scripts/sondas.sh https://api.local /invoices/42 /invoices/42
```

An HTTP contract is **invisible in the code**: the handler looks right, the test passes, and the missing header only breaks behind a CDN or in another browser. Run these eight probes against the running service, **before** opening the code.

| Probe | How | What it reveals |
| --- | --- | --- |
| **S1. Headers of a read** | `curl -i <GET of a resource>` | `HTTP-CACHE-01`, `HTTP-CORE-03` — missing `Cache-Control`? `Content-Type` without `charset`? |
| **S2. Does `HEAD` answer?** | `curl -i -X HEAD <same URL>` | `HTTP-METH-06` — `HEAD` absent where `GET` answers |
| **S3. Unsupported method** | `curl -i -X PATCH <route that only accepts PUT>` | `HTTP-METH-07` — does it return `404` instead of `405` with `Allow`? |
| **S4. Conditional** | `curl -i -H 'If-None-Match: "x"' <GET>` and with the real `ETag` | `HTTP-CACHE-07` — does it emit an `ETag` and ignore `If-None-Match`? |
| **S5. Concurrent write** | `curl -i -X PUT -H 'If-Match: "stale"' <write route>` | `HTTP-CACHE-08` — does it apply the write instead of `412`? |
| **S6. Preflight** | `curl -i -X OPTIONS <route> -H 'Origin: …' -H 'Access-Control-Request-Method: POST'` | `HTTP-CORS-05`, `HTTP-CORS-06` |
| **S7. Refused origin** | `curl -isS <route> -H 'Origin: https://malicious.example' \| grep -i 'access-control\|vary'` | `HTTP-CORS-01`, `HTTP-CORS-03` — does it reflect blindly? is `Vary` missing? |
| **S8. Error body** | provoke `400`, `404`, `422` and `500` and compare the bodies | `HTTP-SPEC-08` — more than one format in the same API? |

**S5 is the gravest and the least run.** If the write is applied, the service has silent data loss under concurrency — that is not a style finding.

**S3 is the most likely to light up in this stack:** in Hono, without the `methodNotAllowed` middleware, an unsupported method returns `404` — confirm the middleware through Context7, `/websites/hono_dev`.

**If S8 shows two error formats, report before continuing** — that is an inconsistent public contract, and every new route widens the problem.

**If the service does not start**, declare which probes did not run (Step 6, item 6). "Not verified" is not "no findings".
