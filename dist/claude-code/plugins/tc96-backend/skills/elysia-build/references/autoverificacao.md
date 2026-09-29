# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-build/scripts/autoverificar.sh src
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | continuous method chaining, not broken into statements | `ELYSIA-APP-01` |
| 2 | no `error` from the context — it is `status` | `ELYSIA-APP-02` |
| 3 | the handler destructures the context inline | `ELYSIA-CORE-02` |
| 4 | `strict: true` and TS ≥ 5.0 on both sides | `ELYSIA-APP-04` |
| 5 | `export type App = typeof app` at the end of the chain | `ELYSIA-APP-05` |
| 6 | an expected error is `return status(...)` | `ELYSIA-CORE-03` |
| 7 | `status(code, value)` where there is a `response` schema | `ELYSIA-CORE-04` |
| 8 | `onError` does not leak `error.message` from `UNKNOWN` | `ELYSIA-CORE-07` |
| 9 | a recurring domain error in `.error({...})` | `ELYSIA-CORE-08` |
| 10 | session cookie signed and `httpOnly` | `ELYSIA-CORE-05` |
| 11 | `set.headers` is not changed after the first `yield` | `ELYSIA-CORE-06` |
| 12 | the test uses `app.handle`, with `await app.modules` | `ELYSIA-CORE-09`, `ELYSIA-CORE-10` |
| 13 | `process.env` is not read directly | `ELYSIA-APP-09` |
| 14 | no `@elysiajs/swagger` | `ELYSIA-APP-07` |
| 15 | hooks and plugins registered **before** the routes they affect | `ELYSIA-CORE-01` |

The items the script does **not** decide, and why:

| Item | Why it requires reading |
| --- | --- |
| `ELYSIA-APP-01` — continuous chaining | it is expression structure; grep cannot see where the chain breaks |
| `ELYSIA-CORE-03` — expected error with `return status` | telling expected from unexpected is domain semantics |
| `ELYSIA-CORE-08` — domain error with its own `code` | same |
| `ELYSIA-CORE-06` — `set.headers` after the `yield` | it requires order inside the generator |
| `ELYSIA-CORE-01` — registration order | probe S1 of `elysia-diagnose` measures that by line number |

**Run**, always:

```bash
tsc --noEmit # Bun transpiles without type-checking — BUN-CORE-02
bun test # through app.handle, with await app.modules
```

## Related

- `antipadroes.md` — the grid, with IDs
- `elysia-diagnose` — when the hook does not affect the route
