# Commands — named entry points

A command is what **the person invokes**: `/scaffold-projeto`, `/configurar-antigravity`.
It is not a fourth layer of the chain — role → procedure → rule is still the chain, and a
command routes to the same skills and the same rules.

The difference from an agent: an agent receives a task in its own context and decides what
to load; a command is a fixed script, with numbered phases and gates.

## TanStack Start project scaffold

The orchestrator, which calls the phases: [`scaffold-projeto`](scaffold-projeto.md) —
orchestrates the full scaffold of a TanStack Start project, phase by phase.

The 10 phases, each runnable on its own:

| Phase | What it does |
| --- | --- |
| [`scaffold-01-tanstack-start`](scaffold-01-tanstack-start.md) | Phase 1 — TanStack Start base with TypeScript, Tailwind and Vite |
| [`scaffold-02-biome`](scaffold-02-biome.md) | Phase 2 — Biome as linter and formatter |
| [`scaffold-03-bun-test`](scaffold-03-bun-test.md) | Phase 3 — `bun test`, happy-dom and Testing Library |
| [`scaffold-04-git-hooks`](scaffold-04-git-hooks.md) | Phase 4 — git hooks and commit gates |
| [`scaffold-05-fba`](scaffold-05-fba.md) | Phase 5 — Feature-Based Architecture directory structure |
| [`scaffold-06-shadcn`](scaffold-06-shadcn.md) | Phase 6 — shadcn/ui and design tokens |
| [`scaffold-07-workos-authkit`](scaffold-07-workos-authkit.md) | Phase 7 — authentication with WorkOS AuthKit |
| [`scaffold-08-scripts`](scaffold-08-scripts.md) | Phase 8 — package scripts and project tasks |
| [`scaffold-09-feature-exemplo`](scaffold-09-feature-exemplo.md) | Phase 9 — end-to-end example feature |
| [`scaffold-10-verificacao`](scaffold-10-verificacao.md) | Phase 10 — final scaffold verification |

## FBA variant

Five phases with the same cut, in more detail, with the boundary test of
[Feature-Based Architecture](../knowledge-base/feature-based-architecture.md) written out
in full:

| Phase | What it does |
| --- | --- |
| [`scaffold-fba-01-start`](scaffold-fba-01-start.md) | FBA variant — phase 1, project base |
| [`scaffold-fba-02-biome`](scaffold-fba-02-biome.md) | FBA variant — phase 2, Biome |
| [`scaffold-fba-03-bun-test`](scaffold-fba-03-bun-test.md) | FBA variant — phase 3, `bun test` and Testing Library |
| [`scaffold-fba-04-git-hooks`](scaffold-fba-04-git-hooks.md) | FBA variant — phase 4, git hooks |
| [`scaffold-fba-05-fba`](scaffold-fba-05-fba.md) | FBA variant — phase 5, directory structure |

## Specification

[`spec`](spec.md) — searches, plans and stops: runs `workflow-search` to triage the request,
then `workflow-plan` to write or amend `.specs/PRD.md`, the ADRs and each feature's bundle in
`.specs/features/` (`spec.md`, `plan.md`, `contract.md`), and stops before any code.

[`scaffold-sdd-scripts`](scaffold-sdd-scripts.md) — writes the six harness scripts of the
delivery flow (`init.sh` and `scripts/`) and `sdd.config.sh` at the project root.

## Environment

[`configurar-antigravity`](configurar-antigravity.md) — configures the Antigravity agent with
this house's rules.

## Anatomy

| Field | What it is for |
| --- | --- |
| `nome:` | same as the file; it is what becomes `/nome` at runtime |
| `descricao:` | the line the person reads in the command list |
| `tipo: comando` | what makes the adapter emit this file |
| `idioma:` | `en` — the body came that way from the previous build and was not translated |
| `tags:` | when the original command carried them |

Who emits them: `build/claude-code.sh` writes `commands/<nome>.md` with `description:` for the
commands declared in `PLUGINS`; `build/agents-md.sh` writes the **Commands** table in
`AGENTS.md` and copies the body without frontmatter.

## Bun, since 2026-09-22

The package manager and runner are **Bun**, not pnpm. What the migration fixed, by rule:

| Rule | What came in |
| --- | --- |
| `BUN-CORE-06` | a `package.json` script is called in the long form `bun run <script>` |
| `BUN-CORE-02` | `typecheck: tsc --noEmit` in the scripts, and `bunx tsc --noEmit` in the phase 10 gate — the runtime transpiles **without** type-checking |
| `BUN-PKG-01/02` | the final checklist requires a committed `bun.lock`, and `bun ci` in CI |

Equivalents used: `pnpm add -D` → `bun add -d` · `pnpm dlx`/`pnpm exec`/`npx` → `bunx`
· `node -e` → `bun -e` with `Bun.file`/`Bun.write` · `pnpm-lock.yaml` → `bun.lock`.

**Phase 3 runs on `bun test`**, not Vitest — `scaffold-03-bun-test` and
`scaffold-fba-03-bun-test`. `vitest.config.ts` went with it: `bun test` reads
`compilerOptions.paths` from `tsconfig.json` (verified on bun 1.3.14), and the duplicated alias
map — whose drift from `tsconfig` was the phase's documented failure mode — no longer exists.
What is lost is `test:ui`, which `bun test` does not have.

`bunx @tanstack/create-start@latest` instead of `bun create @tanstack/start@latest`:
`bun create <t>` runs `bunx create-<t>`, and that rule does not resolve a scoped package. The
real package is [`@tanstack/create-start`](https://www.npmjs.com/package/@tanstack/create-start).

**One step disappeared.** The `scaffold-fba-02-biome` phase carried a `node -e` loop to check
whether each package was a dependency before removing it — a workaround for `pnpm`, which exits
1 on a missing name. `bun remove` accepts several names, removes what exists and exits 0
(verified on bun 1.3.14), so the loop became one line.

## What is declared, and not checked

These 17 files came from the previous build **without a content review**. What the Bun
migration touched, and did not resolve:

- **`vinxi` in the `dev`/`build`/`start` scripts.** It is TanStack Start's old driver; current
  versions run on Vite directly.
- **`biome.json` with the 1.9.4 `$schema`**, in the v1 format (`organizeImports` at the root).
  `bun add -d @biomejs/biome` installs **2.5.14** today, where that key moved. And the
  `$schema` value is written as a markdown link, not a URL.
- `scaffold-01…10` and `scaffold-fba-01…05` cover the same ground with different detail, and
  nothing declares which of the two is the current path.
