# Worked example — an auth plugin that does not protect the consumer

### Example

```
`ELYSIA-LIFE-01` — packages/auth/src/plugin.ts:14
Symptom: the routes in apps/server pass without credentials; the test routes inside the
 plugin itself are rejected correctly.
Evidence: the Step 6 test on the consuming instance returned 200, not 401.
 The plugin declares `.onBeforeHandle(verify)` without a scope.
Cause: the default scope is `local` — the hook does not cross into the instance that uses
 the plugin. The test that existed ran inside the plugin, so it never caught it.
Fix: declare `.onBeforeHandle({ as: 'scoped' }, verify)`, and move the test to the
 consuming instance (ELYSIA-LIFE-08). If the hook must hold across the whole tree,
 the scope is `global` (ELYSIA-LIFE-09).
See Elysia - Lifecycle e Plugins.
```

Rules of the format: **ID checked against § 6**; **evidence is a test or the registration order**, not an impression; concrete fix; one satellite link.

---


---

## The path that led there

```
$ bash scripts/sondas.sh src

== S1. Hook registered AFTER the route
 (nothing) ← the most common hypothesis fell
== S2. Undeclared scope in a plugin
 packages/auth/src/plugin.ts:14.onBeforeHandle(verify)
 -- plugins with a declared `name`: NONE ← ELYSIA-LIFE-03 also open
```

S1 clean and S2 pointing at the plugin: the hypothesis is scope. **The probe does not prove it** — what proves it is
the test on the consuming instance (`prova-de-escopo.md`), which returned 200 where it should have returned 401.

## What this example demonstrates

| Decision | Where the rule is |
| --- | --- |
| order was checked **before** scope | `duas-causas.md` |
| the evidence is a test, not an impression | § *Finding format* |
| the test that existed ran inside the plugin, and that is why it never caught it | `prova-de-escopo.md` |
| the fix names `scoped` **and** says when it would be `global` | `ELYSIA-LIFE-09` |
