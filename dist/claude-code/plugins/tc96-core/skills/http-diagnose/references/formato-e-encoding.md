# Format, language and encoding

The full tree is § 5.5 of the hub:

| Symptom | Cause | Rule |
| --- | --- | --- |
| **`415`** | the server does not process the `Content-Type` **you sent** — an error in the request | `HTTP-NEG-07` |
| **`406`** | the server has no representation that satisfies your `Accept` — frequently the client's `Accept` is too restrictive | `HTTP-NEG-06` |
| `200`, wrong format, always | the server ignores `Accept` — a server failure | `HTTP-NEG-01` |
| `200`, wrong format, intermittently | the cache served another client's representation — missing `Vary` | `HTTP-CACHE-10` |
| **broken accents** | charset | `HTTP-CORE-03`, `HTTP-NEG-02` |

**Charset is the most direct one:** `application/json` is UTF-8 **by the media type's definition**; `text/*` **is not** — it needs an explicit `; charset=utf-8` (`HTTP-NEG-02`). A broken accent in a `text/plain` or `text/csv` is almost always this.

**And `406` is genuinely rare:** the server should **not** answer `406` to an `Accept-Encoding` that does not explicitly forbid `identity` (`HTTP-NEG-06`). A received `406` deserves suspicion of a server bug before any client adjustment.
