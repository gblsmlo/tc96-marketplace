# Lockfile, CI, monorepo, linker and patch

| Rule | What it requires |
| --- | --- |
| `BUN-PKG-01` | `bun.lock` **committed** |
| `BUN-PKG-02` | CI installs with `bun ci` or `bun install --frozen-lockfile` |

**A plain `bun install` in CI rewrites the lockfile and does not fail** — so a `package.json` diverging from the lock passes silently, and the build uses versions nobody reviewed. It is this family's violation with the greatest distance between cause and symptom.

```bash
bun ci # CI
bun install --frozen-lockfile # explicit equivalent
```

And `BUN-PKG-05`, which misleads by its name: **`--production` is not cleanup.** It does not remove `devDependencies` already present in `node_modules` — that is what `bun pm` is for. In a layered image, `--production` after a full install reduces nothing.

---

## Step 3 — Monorepo

| Rule | What it requires |
| --- | --- |
| `BUN-PKG-12` | the root `package.json` declares `"private": true`, and **never** lists a dependency that some package imports |
| `BUN-PKG-06` | a version shared by more than one package comes from a **catalog**, not repeated in each `package.json` |
| `BUN-PKG-08` | `overrides`/`resolutions` in the **root** `package.json` — Bun **ignores** those declared in a workspace |
| `BUN-PKG-07` | `catalog:` **never** reaches a published package — publish via `bun publish` or `bun pm pack` |

**`BUN-PKG-08` fails silently:** an `overrides` in a workspace package is simply ignored, and the version the author meant to pin keeps floating.

**`BUN-PKG-12` is about dependency direction:** a root dependency that a package imports makes the package work by accident — it resolves through hoisting and breaks when someone moves or publishes it. See `Monorepo com Bun - estrutura e tooling`.

**`BUN-PKG-07`** is the counterpart of `BUN-PKG-06`: a catalog resolves the version at workspace install time, and the `catalog:` protocol is not understood by whoever installs from the registry. `bun publish` rewrites it; a raw `npm publish` publishes the literal protocol.

---

## Step 4 — Linker

| Mode | Layout |
| --- | --- |
| `hoisted` | flat `node_modules`, like classic npm/yarn |
| `isolated` | per package, no hoisting |

`BUN-PKG-10`: a project whose **build depends on the `node_modules` layout** declares `linker` explicitly in `bunfig.toml`. The default can change, and a tool that resolves by path — a bundler with `resolve.alias`, a plugin doing `require.resolve` — breaks when it does.

If the build does not depend on the layout, do not declare it: that is configuration that ages without benefit.

---

## Step 5 — Patch and `bunx`

| Rule | What it requires |
| --- | --- |
| `BUN-PKG-09` | editing a package under `node_modules/` **requires** `bun patch <pkg>` first — a direct edit **corrupts the global cache** |
| `BUN-PKG-11` | `bunx` in CI or in a committed script pins the version, or the package is a devDependency |

**`BUN-PKG-09` has consequences outside the project:** the cache is global, so a direct edit contaminates other projects on the machine. And the symptom shows up in them, not in this one.

**`BUN-PKG-11`** is reproducibility: `bunx <pkg>` without a version resolves that day's `latest`, and tomorrow's CI runs something else.
