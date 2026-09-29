# Finding format, and the cut

```
`RULE-ID` — <where>
Symptom: <how the failure presents, and to whom>
Evidence: <the probe's output — paste the headers>
Cause: <one sentence>
Fix: <concrete change>
See the corresponding satellite.
```

### Example

```
`HTTP-CORS-05` — apps/server/src/app.ts:22 (middleware order)
Symptom: every SPA call fails with "CORS policy" in the console; direct curl works.
Evidence: probe 2 returned `401 Unauthorized` on the OPTIONS, with no
 Access-Control-Allow-* at all. The server log has the OPTIONS, and the auth middleware
 recorded "missing bearer token".
Cause: the authentication middleware is mounted before the CORS one, and the browser
 does not send credentials on the preflight — so the OPTIONS is rejected before CORS answers.
Fix: mount the CORS middleware before the auth one, or exempt OPTIONS from auth.
See HTTP - CORS, and Hono - Middleware e Ciclo de Vida for the onion model's order.
```

Rules of the format: **ID checked against § 6**; **evidence is the probe's output**, not "looks like CORS"; a concrete fix; one satellite link.

---

## Step 6 — The cut: what is not CORS

Four failures that present as CORS and are not. Confusing them costs hours.

| Symptom | It is not CORS — it is |
| --- | --- |
| the console says CORS, and the server has no log of the request | server down, TLS, DNS, port |
| the request arrives, `401` on the **real** call | authorization — `OWASP - Sessão e Autorização` |
| the cookie is not sent cross-site | `SameSite` — `RFC 6265 - Cookies HTTP` |
| works in curl, fails in the browser, with no mention of CORS | mixed content, CSP, or a service worker |

**And the inverse, which is the most dangerous:** "I fixed the CORS by allowing `*`" on a route that accepts credentials did not fix it — it is invalid, and the browser keeps refusing (`HTTP-CORS-02`). Whoever "fixes" it by switching CORS off has generally moved the bug to production.
