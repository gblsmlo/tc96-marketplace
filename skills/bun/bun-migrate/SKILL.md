---
nome: bun-migrate
descricao: Migrate Node code to Bun and diagnose what does not run — `node:*` compatibility matrix, crypto gaps, async hooks that are stubs, IPC across runtimes, container shutdown, Dockerfile — citing `BUN-SYS-*` and `BUN-CORE-*` IDs, with a script that enumerates the modules used by the code **and by transitive dependencies** — use when the task is planning the migration of a Node service, investigating a module that behaves differently, deciding whether a transitive dependency is supported, assembling a production image, or making the container shut down without dropping a request. Do not use to write new code with Bun APIs, which is bun-runtime, nor for lockfile and workspace, which is bun-workspace.
tipo: skill
familia: bun
idioma: en
fonte: "[Bun - Shell, FFI e Compat Node](../../../knowledge-base/bun-shell-ffi-e-compat-node.md)"
docs:
  - /oven-sh/bun
tags:
  - skill
  - bun
  - backend
---
# bun-migrate

> **Source of this skill:** [Bun - Shell, FFI e Compat Node](../../../knowledge-base/bun-shell-ffi-e-compat-node.md), with the [Bun](../../../knowledge-base/bun.md) hub as the router.
> **API surface:** resolve it through Context7 — `/oven-sh/bun`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

---

## When to use

Code that came from Node, or is about to.

| Situation | Go to |
| --- | --- |
| writing new code with Bun APIs | `bun-runtime` |
| dependency, lockfile, workspace | `bun-workspace` |
| a test that fails only under Bun | `bun-test-review` |

---

## Step 0 — The rule that governs the whole skill

> **A claim about Node.js compatibility MUST be checked against the official page.** "It works in Node" is **not** evidence that it works in Bun (`BUN-CORE-05`).

Compatibility is **partial and uneven**: some modules are complete, some have a specific gap, and some are **stubs that do not throw** — the worst case, because the code runs and the result is **silently wrong**.

---

## Minimum loading

| Order | Load |
| --- | --- |
| 1 | [Bun](../../../knowledge-base/bun.md) § 6 — `BUN-CORE-*` and `BUN-SYS-*` |
| 2 | [Bun - Shell, FFI e Compat Node](../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| 3 | the official compatibility page, for **every** enumerated module |

References in this skill:

| File | What for |
| --- | --- |
| `references/enumerar-e-lacunas.md` | the step you do not skip, and the four gaps that matter |
| `references/container.md` | image, shutdown and Dockerfile |
| `references/diagnostico-e-relatorio.md` | symptom → cause, finding format, and what is **not** an incompatibility |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 43 `BUN-CORE/RT/PKG/SYS-*` by satellite and section |
| `scripts/enumerar.sh` | enumerates `node:*` in the code **and** in transitive dependencies |

---

## Step 1 — Enumerate, before migrating

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-migrate/scripts/enumerar.sh src
```

`BUN-SYS-07` is the step that **cannot be skipped**. And **the second search is the one that changes the plan**: a dependency using `async_hooks` for tracing, or `crypto` for a specific cipher, decides the feasibility of the migration — and it **does not appear in the project's own code**.

Without `node_modules` installed, the enumeration is partial — the script says so rather than faking coverage.

---

## Step 2 — The four gaps that matter

| Module | State | Consequence |
| --- | --- | --- |
| `async_hooks` | **stub that does not throw** | the code runs and the result is silently wrong |
| `crypto` | complete in almost everything, with gaps per cipher | check **the cipher you use**, not the module |
| `worker_threads` | partial | |
| `vm` / `cluster` | partial or absent | |

Detail: `references/enumerar-e-lacunas.md`.

---

## Step 3 — Container

`references/container.md`: image, `--smol`, and **shutdown**. Without handling `SIGTERM`, the container exits **mid-request** — and the symptom shows up as an intermittent client error during deploy.

---

## Step 4 — Diagnose and report

`references/diagnostico-e-relatorio.md`: symptom → cause, the finding format, and **the cut** — what is not an incompatibility but a bug in the code itself.

---

## Step 5 — Closing

1. **Was every enumerated module checked against the official page?** If not, the plan rests on assumption (`BUN-CORE-05`).
2. **If any is a stub that does not throw**, it is blocking — it is not "works with caveats".
3. **If the container does not handle `SIGTERM`**, the deploy drops requests.
4. **Declare what was not verified** — especially the transitive ones, if `node_modules` was not installed.

---

## Related

- [Bun - Shell, FFI e Compat Node](../../../knowledge-base/bun-shell-ffi-e-compat-node.md) — source of this skill
- [Bun](../../../knowledge-base/bun.md) § 6
- `bun-runtime` · `bun-workspace` · `bun-test-build` · `bun-test-review` — the family
- Node.js — what is being left behind; its API surface resolves through Context7, `/nodejs/node`
