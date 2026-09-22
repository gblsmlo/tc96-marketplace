# The tree, and what it eliminates

```
The hook does not run for this route.
├── was it registered BEFORE the route?
│ └── NO → that is it. ELYSIA-CORE-01
├── does it come from a plugin, and is the route on the CONSUMING instance?
│ └── YES, and the scope was not declared → that is it. ELYSIA-LIFE-01
├── is the plugin applied by more than one instance?
│ └── and it has no `name` → the lifecycle runs only once. ELYSIA-LIFE-03
├── does the hook need body/query/params/cookie?
│ └── and it is in onRequest → the PreContext does not have them. ELYSIA-LIFE-04
└── is the plugin a callback (app) => app?
 └── swap it for a `new Elysia` instance. ELYSIA-LIFE-07
```

**`ELYSIA-LIFE-03` produces the most bewildering bug:** without a `name`, a plugin applied twice has its lifecycle executed **once**. The symptom is the hook running for half the routes.

**`ELYSIA-LIFE-04`:** `onRequest` receives a `PreContext`, which has **no** `body`, `query`, `params` or `cookie`. Logic that needs them there reads `undefined` — and `undefined` often passes as "no filter".

---


---

## Step 3 — `derive` × `resolve`: the security rule

`ELYSIA-LIFE-02`: **an authentication or authorization decision never uses `derive`** — it uses `resolve` or `macro.resolve`, which run **after** validation.

`derive` runs **before** validation. An authorization decision there operates on unvalidated input — the classic case of checking a field that validation would later reject, or trusting a value coerced differently.

| You need… | Use |
| --- | --- |
| a derived value, with no security decision | `derive` |
| an **auth/authorization decision** | `resolve` or `macro.resolve` |
| **mutable** state | `state` |
| an injected immutable value | `decorate` |

---

## Step 4 — State that does not change, or changes too much

| Symptom | Cause | Rule |
| --- | --- | --- |
| the `store` value stays frozen | a primitive destructured in the handler's parameter — the reference is lost | `ELYSIA-LIFE-06` |
| a `decorate` value was mutated and behavior became unpredictable | `decorate` is immutable; mutable state is `state` | `ELYSIA-LIFE-05` |

```ts
// ✗ counter freezes at its value at registration time
.get('/x', ({ store: { counter } }) => counter)

// ✓ reads through the reference
.get('/x', ({ store }) => store.counter)
```

`ELYSIA-LIFE-06` is subtle and common: destructuring copies the primitive, and every later read returns the old value.
