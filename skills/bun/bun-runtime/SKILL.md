---
nome: bun-runtime
descricao: Write code that uses the Bun runtime APIs — file, `.env`, process, shell, hashing, watch — citing `BUN-RT-*` and `BUN-CORE-*` IDs, with an executable self-check — use when the task is reading or writing a file, loading and validating an environment variable, running a subprocess or external command, hashing a password, choosing between `--watch` and `--hot`, or deciding between a Bun API and a `node:*` module. Do not use to install a package or touch the workspace, which is bun-workspace, to migrate Node code that does not run, which is bun-migrate, nor to write tests, which is bun-test-build.
tipo: skill
familia: bun
idioma: en
fonte: "[Bun - Runtime e APIs](../../../knowledge-base/bun-runtime-e-apis.md)"
docs:
  - /oven-sh/bun
tags:
  - skill
  - bun
  - backend
---

# bun-runtime

> **Source of this skill:** [Bun - Runtime e APIs](../../../knowledge-base/bun-runtime-e-apis.md), with the [Bun](../../../knowledge-base/bun.md) hub as the router.
> This skill **does not contain** the text of the rules nor the API surface — it says what to decide and what to check.
> **API surface:** resolve it through Context7 — `/oven-sh/bun`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

---

## When to use

Writing application code that uses the runtime.

| Situation | Go to |
| --- | --- |
| dependency, lockfile, workspace, `trustedDependencies` | `bun-workspace` |
| code that came from Node and does not run | `bun-migrate` |
| writing a test | `bun-test-build` · reviewing a suite | `bun-test-review` |
| HTTP route | `elysia-build` · persistence | `drizzle-review` |

---

## Minimum loading

| Order | Load |
| --- | --- |
| 1 | [Bun](../../../knowledge-base/bun.md) § 2 (the binary is runtime, package manager, bundler and runner) |
| 2 | [Bun](../../../knowledge-base/bun.md) § 6 — `BUN-CORE-*` |
| 3 | [Bun - Runtime e APIs](../../../knowledge-base/bun-runtime-e-apis.md) |

References in this skill:

| File | What for |
| --- | --- |
| `references/invariantes-do-binario.md` | the five invariants that hold in any task |
| `references/arquivo-ambiente-processo.md` | file, `.env`, process and shell |
| `references/hash-e-watch.md` | hashing and passwords, and `--watch` × `--hot` |
| `references/autoverificacao.md` | the checklist |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 43 `BUN-CORE/RT/PKG/SYS-*` by satellite and section |
| `references/exemplo.md` | worked case |
| `scripts/autoverificar.sh` | runs the mechanical items |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map across the three runtime/package/migration skills |

---

## Step 1 — The invariants of the binary

**`BUN-CORE-02` is the one that costs most:** Bun transpiles TypeScript and **does not type-check**. Without `tsc --noEmit` in CI, the project has **decorative types** — the error only shows up when the wrong value arrives at runtime.

And `BUN-CORE-03`: adding `jest`, `ts-node`, `nodemon` or `dotenv` requires **justifying** why the built-in equivalent does not do the job.

---

## Step 2 — File, environment, process and shell

`references/arquivo-ambiente-processo.md`. The recurring decision is **Bun API × `node:*` module** — and it flips when the code has to run outside the `bun` process (`BUN-CORE-01`).

---

## Step 3 — Hashing and passwords

**A password is `Bun.password`** (argon2id by default), never `createHash` — using a generic hash for a password is a **security** finding, not a style one.

---

## Step 4 — `--watch` × `--hot`

`--hot` **keeps process state**; `--watch` restarts. A server with global state behaves differently between the two, and the symptom shows up as "only reproduces in dev".

---

## Step 5 — Self-check

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-runtime/scripts/autoverificar.sh src
tsc --noEmit
```

---

## Step 6 — Closing

1. **Does `tsc --noEmit` run in CI?** If not, that is the first finding.
2. **If the code uses the `Bun` global**, it only runs under the `bun` process — declare that if the library is published.
3. **If it came from Node and does not run**, that is `bun-migrate` — and "it works in Node" is not evidence (`BUN-CORE-05`).
4. **Declare what you did not verify.**

---

## Example

A service that reads `.env`, writes a file and hashes a password: `Bun.file`/`Bun.write` instead of `fs`, env validation at startup, `Bun.password` for the password, and `--watch` rather than `--hot` because the server has global state.

Full case: `references/exemplo.md`.

---

## Related

- [Bun - Runtime e APIs](../../../knowledge-base/bun-runtime-e-apis.md) — source of this skill
- [Bun](../../../knowledge-base/bun.md) § 2, § 6
- `bun-workspace` · `bun-migrate` · `bun-test-build` · `bun-test-review` — the family
