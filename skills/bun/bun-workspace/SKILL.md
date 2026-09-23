---
nome: bun-workspace
descricao: Manage dependencies and the workspace with Bun's package manager — `bun install`, lockfile, `trustedDependencies`, linker, catalogs, `overrides`, `bun patch` — citing `BUN-PKG-*` IDs, with eight executable probes and a JSON check of `trustedDependencies` — use when the task is adding a dependency, configuring a CI install, allowing a package's install script, aligning a shared version in a monorepo, declaring a workspace, patching a package, or assembling a production image. Do not use to write application code, which is bun-runtime, to migrate Node code, which is bun-migrate, nor for bundling and builds, which is the Bundler e Build satellite.
tipo: skill
familia: bun
idioma: en
fonte: "[Bun - Gerenciador de Pacotes](../../../knowledge-base/bun-gerenciador-de-pacotes.md)"
docs:
  - /oven-sh/bun
tags:
  - skill
  - bun
  - backend
---

# bun-workspace

> **Source of this skill:** [Bun - Gerenciador de Pacotes](../../../knowledge-base/bun-gerenciador-de-pacotes.md), with the [Bun](../../../knowledge-base/bun.md) hub as the router.
> **API surface:** resolve it through Context7 — `/oven-sh/bun`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

---

## When to use

Dependency, lockfile, workspace, install.

| Situation | Go to |
| --- | --- |
| writing application code | `bun-runtime` |
| Node code that does not run | `bun-migrate` |
| test suite and CI gates | `bun-test-review` |
| bundling and builds | [Bun - Bundler e Build](../../../knowledge-base/bun-bundler-e-build.md) |

---

## Minimum loading

| Order | Load |
| --- | --- |
| 1 | [Bun](../../../knowledge-base/bun.md) § 6 — `BUN-PKG-*` |
| 2 | [Bun - Gerenciador de Pacotes](../../../knowledge-base/bun-gerenciador-de-pacotes.md) |

References in this skill:

| File | What for |
| --- | --- |
| `references/trusted-dependencies.md` | the rule that breaks the whole build |
| `references/lockfile-monorepo-linker.md` | lockfile and CI, monorepo, linker, patch and `bunx` |
| `references/autoverificacao.md` | the checklist |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 43 `BUN-CORE/RT/PKG/SYS-*` by satellite and section |
| `references/exemplo.md` | worked case |
| `scripts/sondas.sh` | eight probes, with a **JSON** check of `trustedDependencies` |

---

## Step 1 — The rule that breaks the whole build

> **`trustedDependencies` REPLACES the default list. It does not extend it.**

Declaring one package there **turns off the install scripts of everything else** — `sharp`, `esbuild`, `better-sqlite3`. The symptom **is not an install error**: it is a binary that was never compiled, and the failure shows up at **runtime**, far from the cause (`BUN-PKG-04`).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-workspace/scripts/sondas.sh.
```

Probe S1 reads `package.json` **as JSON** and says which known packages from the default list were left out — the check a `grep` does not do properly.

And `BUN-PKG-03`: a PR that adds an entry there **must** carry the output of `bun pm untrusted` in its body. Allowing an install script is a **security decision** — the script runs with the permissions of whoever installs.

---

## Step 2 — Lockfile and CI

`bun ci`, not `bun install` (`BUN-PKG-02`): `install` can update the lockfile in CI; `ci` fails if it diverges. And the Bun version **pinned**, so that local and CI resolve alike.

---

## Step 3 — Monorepo, linker, patch

`references/lockfile-monorepo-linker.md`: workspaces, catalogs for a shared version, `overrides` (Bun's key — `resolutions` is Yarn's), `isolated` × `hoisted` linker, and versioned `bun patch`.

---

## Step 4 — Self-check

`references/autoverificacao.md`, and the probes above.

---

## Step 5 — Closing

1. **If `trustedDependencies` exists**, confirm nothing from the default list was left out.
2. **If CI uses `bun install`**, swap it for `bun ci`.
3. **If `bunx` runs without `@version`**, what executes is whatever is published at that moment.
4. **Declare what you did not verify.**

---

## Example

A monorepo that added an internal package to `trustedDependencies` and started seeing `sharp` fail at runtime: the default list was replaced, and `sharp`'s install script never ran. The fix is to **re-include it in the same list**, with the output of `bun pm untrusted` in the PR body.

Full case: `references/exemplo.md`.

---

## Related

- [Bun - Gerenciador de Pacotes](../../../knowledge-base/bun-gerenciador-de-pacotes.md) — source of this skill
- `bun-runtime` · `bun-migrate` · `bun-test-build` · `bun-test-review` — the family
- [Bun - Bundler e Build](../../../knowledge-base/bun-bundler-e-build.md) — bundling, which stays outside this skill
