# Worked example

Task: *"add `sharp` to the images service, in a monorepo where `@scope/core` also uses `zod`"*.

**Step 1 — the install script.** `sharp` compiles a binary on install. It **is** on the default trust list, so there is nothing to declare:

```bash
bun add sharp --cwd apps/images
bun pm untrusted # confirms sharp did NOT end up blocked
```

**Had the project had `trustedDependencies`**, then yes: `sharp` would have to be re-included, because the declared list replaces the default one (`BUN-PKG-04`).

**Step 3 — the shared version.** `zod` is used by `apps/images` and by `@scope/core` → catalog:

```jsonc
// root package.json
{
 "private": true, // BUN-PKG-12
 "workspaces": {
 "packages": ["apps/*", "packages/*"],
 "catalog": { "zod": "^3.24.1" } // BUN-PKG-06
 }
}
```

```jsonc
// apps/images/package.json
{ "dependencies": { "sharp": "^0.34.1", "zod": "catalog:" } }
```

And `sharp` does **not** go in the catalog: only one package uses it.

**Step 2 — CI:**

```yaml
- run: bun ci # not `bun install` — BUN-PKG-02
- run: tsc --noEmit # the runtime does not type-check — BUN-CORE-02
```

**What these decisions prevented:**

| Decision | Alternative that hurts | Rule |
| --- | --- | --- |
| checking `bun pm untrusted` | assuming `sharp` compiled, and finding out at runtime | `BUN-PKG-03` |
| not declaring `trustedDependencies` without need | declaring it and turning off everything else's scripts | `BUN-PKG-04` |
| `zod` in a catalog | two versions diverging across packages | `BUN-PKG-06` |
| root `"private": true` without `zod` | a package working through hoisting, breaking when moved | `BUN-PKG-12` |
| `bun ci` in CI | `bun install`, which rewrites the lock and does not fail | `BUN-PKG-02` |
| `sharp` outside the catalog | a catalog with a single-consumer entry, which ages | `BUN-PKG-06` |
