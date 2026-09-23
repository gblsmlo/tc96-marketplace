# Macro, tracing and CORS

| Rule | What it requires |
| --- | --- |
| `ELYSIA-LIFE-10` | a macro signals failure with `return status(...)` — **`throw` becomes a 500** and loses inference for Eden and OpenAPI |
| `ELYSIA-LIFE-11` | a hook in an app instrumented with OpenTelemetry is a **named function** — an anonymous arrow produces an `anonymous` span |
| `ELYSIA-LIFE-12` | `cors` in an authenticated API **never** keeps the default `origin` (`*`) |

**`ELYSIA-LIFE-11` makes tracing useless without breaking anything:** every span is called `anonymous`, and the instrumentation exists without informing.

**`ELYSIA-LIFE-12` is the same finding as `HTTP-CORS-02`** by another path: `origin: '*'` with `credentials: true` is invalid, and the browser refuses. See `http-diagnose` § 2.2 — the plugin's permissive default is the most common concrete cause in this stack.

---


---

## All three fail without breaking anything

| Rule | What is lost | How the symptom appears |
| --- | --- | --- |
| `ELYSIA-LIFE-10` | inference for Eden and OpenAPI | the `throw` inside the macro becomes a **500**, and the expected status disappears from the type |
| `ELYSIA-LIFE-11` | the whole of tracing | every span is called `anonymous`; the instrumentation exists without informing |
| `ELYSIA-LIFE-12` | origin protection | `origin: '*'` with `credentials: true` is **invalid**, and the browser refuses |

`ELYSIA-LIFE-12` is the same finding as `HTTP-CORS-02` by another path — the plugin's permissive
default is the most common concrete cause in this stack. See `http-diagnose`.

## Related

- [Elysia - Lifecycle e Plugins](../../../../knowledge-base/elysia-lifecycle-e-plugins.md) — the source
- `http-diagnose` — when the symptom is the browser blocking
