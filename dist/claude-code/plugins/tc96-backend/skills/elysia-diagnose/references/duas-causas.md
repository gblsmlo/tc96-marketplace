# The two causes that account for almost everything

### 1.1 Registered after the route

`ELYSIA-CORE-01`: hooks, plugins and `onError` **only apply to routes registered after them**.

```ts
// ✗ the hook does not affect /invoices
new Elysia
.get('/invoices', h)
.onBeforeHandle(auth)

// ✓
new Elysia
.onBeforeHandle(auth)
.get('/invoices', h)
```

**It is the first hypothesis, always.** No error, no warning — the route simply does not pass through the hook.

### 1.2 Undeclared scope

`ELYSIA-LIFE-01`: a plugin hook that has to hold **for whoever consumes it** declares a scope — `{ as: 'scoped' }`, `guard({ as })` or `.as(...)`.

The default is **`local`**: the hook stays inside the plugin and **does not cross** into the consuming instance. An authentication plugin without a declared scope protects its own routes and **none** of the consumer's.

```
local → only the plugin's own instance
scoped → the direct consumer
global → the whole tree
```

`ELYSIA-LIFE-09`: a cross-cutting hook that must hold across the whole tree — tracing, logging, CORS — uses **`global`**, not a chain of `scoped`.

> **The proof `ELYSIA-LIFE-08` requires:** an authentication plugin **has to prove in a test that a route of the consuming instance is rejected without credentials.** Testing inside the plugin proves nothing — it is exactly the case that passes with `local` scope and fails in production.
