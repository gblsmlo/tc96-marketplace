# Is it really CORS? and the failure model

**1. There is no CORS RFC.** The protocol, the preflight and the forbidden headers belong to the **Fetch Standard (WHATWG)**, a Living Standard with no citable version. Attributing a CORS rule to an RFC is a citation error (`HTTP-SPEC-04`), and looking for the answer in RFC 9110 is wasted time.

**2. CORS is not authorization.** It restricts what a script from **another origin** may **read** — and it **does not stop the request from reaching the server**. If the concern is preventing access, the mechanism is the handler (`HTTP-CORS-08`). An endpoint "protected by CORS" is open to any client that is not a browser.

---

## Step 1 — Is it really CORS?

The full tree is § 5.4 of the hub. Walk it **without skipping**:

```
Does the console error mention "CORS policy"?
├── NO → it is not CORS. It is the network, TLS, DNS, or the server is down.
│ Confirm whether the request left at all (Network tab / server log).
└── YES
 └── Did the request reach the server (does it appear in the log)?
 ├── NO → the preflight failed or was not answered
 │ ├── is there an OPTIONS in the log? → the handler does not return the Access-Control-Allow-*
 │ └── no OPTIONS → the route does not handle OPTIONS
 │ (framework returning 404/405 on the preflight)
 └── YES, 2xx, and it still failed
 ├── does it use a cookie/credential? → Allow-Origin: * is INVALID with credentials
 ├── the header comes back undefined → missing Access-Control-Expose-Headers
 └── it fails only for some, or only before a hard refresh
 → shared cache without Vary: Origin
```

**The first node is the most misleading:** "CORS" in the console is frequently the browser reporting that **there was no response** — server down, invalid TLS, wrong port. The check is the server log, not the console.

---

## Step 2 — The failure model, branch by branch

### 2.1 The preflight

An automatic `OPTIONS` the browser sends **before** the real call, when that call is not "simple".

| Preflight trigger | Rule |
| --- | --- |
| a method other than `GET`/`HEAD`/`POST` | `HTTP-CORS-07` |
| a non-safelisted header (`Authorization`, `Content-Type: application/json`, a custom header) | `HTTP-CORS-06` |

> **`application/json` is not a simple-request `Content-Type`.** It is the cause of most "inexplicable" preflights in an SPA — practically every API call triggers a preflight, and that is normal.

**The preflight response has to be 2xx and cannot require authentication** (`HTTP-CORS-05`) — the browser does not send credentials on the `OPTIONS`. Auth middleware mounted before the CORS one turns every preflight into a `401`, and the symptom is "CORS" in the console.

### 2.2 Credentials

```
Does the call use a cookie, Authorization, or credentials: 'include'?
└── YES → Access-Control-Allow-Origin: * is INVALID
 → echo the concrete origin + Access-Control-Allow-Credentials: true
 (HTTP-CORS-02)
 → and the concrete origin came from an ALLOWLIST, never from the Origin
 header reflected blindly (HTTP-CORS-01)
 → and the response declares Vary: Origin, including when it REFUSES
 (HTTP-CORS-03)
```

**Hono's default is `origin: '*'`**, which is invalid with `credentials: true` — `HONO-MW-08` in [Hono - Middleware e Ciclo de Vida](../../../../knowledge-base/hono-middleware-e-ciclo-de-vida.md). It is the most common concrete case of this branch in this stack.

### 2.3 A header that arrives `undefined`

Only **seven** response headers are readable cross-origin by default. `ETag` and `Location` are **not** among them.

If JavaScript needs to read a header, it goes in `Access-Control-Expose-Headers` (`HTTP-CORS-04`). And `*` there **never** on a route that accepts credentials (`HTTP-CORS-10`).

This interacts with `http-cache`: an API that emits an `ETag` for the client to use in `If-None-Match` has to expose `ETag`, otherwise the client never sees it.

### 2.4 It works for some and not for others

A shared cache serving another origin's response. The fix is `Vary: Origin` (`HTTP-CORS-03`) — and it holds **including when the origin is refused**, because the refusal response is cacheable too.

### 2.5 It works in production and fails locally

`HTTP-CORS-09`: the allowlist has to include the development origins. **A different port is a different origin** — `localhost:3000` and `localhost:5173` are not the same origin.
