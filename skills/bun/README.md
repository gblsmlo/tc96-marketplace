# Bun skills — runtime, workspace, migrate, test-build, test-review

Five skills, one directory each, with their own `references/`, `scripts/` and `evals/`. The common
anatomy described in [Skills index](../README.md) holds; the supporting material lives in its own
files instead of bloating the `SKILL.md`.

| Skill | The question it answers | Source | Internal support |
| --- | --- | --- | --- |
| `bun-test-build` | how do I write this test, and how do I configure the suite? | [Bun - Tests](docs/bun-tests.md) | 5 references + 1 script |
| `bun-test-review` | does this suite have defects? why is this test flaky? | [Bun - Tests](docs/bun-tests.md) | 6 references + 2 scripts |
| `bun-runtime` | how do I write this with the runtime APIs? | [Bun - Runtime and APIs](docs/bun-runtime-and-apis.md) | 7 references + 2 scripts |
| `bun-workspace` | dependency, lockfile, workspace, install | [Bun - Package Manager](docs/bun-package-manager.md) | 6 references + 1 script |
| `bun-migrate` | it came from Node and does not run — is it an incompatibility? | [Bun - Shell, FFI and Node Compat](docs/bun-shell-ffi-and-node-compat.md) | 5 references + 1 script |

## The docs travel with the family

The normative notes — the `Bun` hub with its four satellites, and the `Bun - Tests` hub with its
six, 83 IDs in all (`BUN-CORE-*`, `BUN-RT-*`, `BUN-PKG-*`, `BUN-SYS-*`, `BUN-BUILD-*`, `BUN-TEST-*`)
— live in [`docs/`](docs/bun.md), not in the tc96 `knowledge-base/`. That is what lets each skill
work in a project that has nothing else from tc96:

| Layout | Where the docs are |
| --- | --- |
| this repository | `skills/bun/docs/` — the skills link to `../docs/`, the references to `../../docs/` |
| the built plugin (`tc96-backend`) | `docs/bun/` at the plugin root — the build rewrites the links |
| a single `.skill` package | `docs/` inside the skill — only the notes it cites, and the notes those cite |

Two Bun notes stay outside the family on purpose: `Bun - HTTP e Servidor` belongs to the Elysia and
HTTP skills, `Bun - Dados e Persistência` to Drizzle. The docs and the skills cite them — and every
other tc96 note (`Monorepo com Bun - estrutura e tooling`, `Storybook - Testes e Interações`,
`Teste de Software - Técnicas de Design de Caso`…) — **by name in a code span**, never by link:
context when tc96 is installed, never a dependency.

The docs are English twins of the Portuguese notes in `knowledge-base/`, translated section by
section with the same headings, tables, code and ID positions. When a rule changes, change it in the
family doc; the knowledge-base note is the historical source, not the one the skills read.

`bash build/skill-packages.sh` produces one `dist/skills/<skill>.skill` per skill, each with its docs
closure and the sibling scripts it calls. `bash build/verificar.sh` then opens every package in
isolation and fails on any link, script or path that reaches outside it.

## What each package contains

```
bun-runtime/
├── SKILL.md
├── references/
│   ├── binary-invariants.md     the five invariants that hold in any task
│   ├── file-env-process.md      file, .env, process and shell — the Bun API × node:* decision
│   ├── hash-and-watch.md        Bun.password × Bun.hash, and --watch × --hot
│   ├── self-check.md            the 13-item checklist
│   ├── antipatterns.md          the grid, with IDs
│   ├── id-map.md                generated: the 43 BUN-CORE/RT/PKG/SYS-* → satellite → section
│   └── example.md               a job that reads a directory, validates, calls a binary
└── scripts/
    ├── self-check.sh            binary invariants, tsc --noEmit in CI, password hashing, --watch × --hot
    └── generate-id-map.sh       regenerates id-map.md for runtime, workspace and migrate

bun-workspace/
├── SKILL.md
├── references/
│   ├── trusted-dependencies.md  the rule that breaks the whole build
│   ├── lockfile-monorepo-linker.md  lockfile and CI, monorepo, linker, patch and bunx
│   ├── self-check.md            the 12-item checklist and the four probes
│   ├── antipatterns.md · id-map.md · example.md
└── scripts/
    └── probes.sh                eight probes, with a JSON check of trustedDependencies

bun-migrate/
├── SKILL.md
├── references/
│   ├── enumerate-and-gaps.md    the step you do not skip, and the four gaps that matter
│   ├── container.md             image, shutdown and Dockerfile
│   ├── diagnosis-and-report.md  symptom → cause, finding format, what is not an incompatibility
│   ├── antipatterns.md · id-map.md
└── scripts/
    └── enumerate.sh             node:* in the code AND in transitive dependencies

bun-test-build/
├── SKILL.md
├── references/
│   ├── by-task.md               task → satellite map, and the six cuts
│   ├── runner-traps.md          the three things you do not assume from Jest/Vitest memory
│   ├── self-check.md            the checklist and the three commands that require execution
│   ├── id-map.md                generated: the 29 BUN-TEST-* — declared in, body in which satellite
│   └── example-session-expiry.md
└── scripts/
    └── self-check.sh            runs the checklist over the file you just wrote

bun-test-review/
├── SKILL.md
├── references/
│   ├── probes.md                the seven probes, the stops, and what they do not catch
│   ├── scan-order.md            the nine steps, and the symptom → cause table for flakiness
│   ├── severity-and-report.md   classification, finding format, the finding × opinion cut
│   ├── antipatterns.md · id-map.md · example-review.md
└── scripts/
    ├── probes.sh                runs the mechanical ones; with --run, also the ones needing the suite up
    └── generate-id-map.sh       regenerates id-map.md for build and review
```

## What each script does, and why it is a script

| Script | What it does |
| --- | --- |
| `bun-workspace/scripts/probes.sh` | reads **every** workspace `package.json` as JSON: which packages on Bun's own default trust list `trustedDependencies` turned off, and which `overrides`/`resolutions` Bun ignores outside the root |
| `bun-migrate/scripts/enumerate.sh` | enumerates `node:*` in the code **and in transitive dependencies**, names the package that brings each one, and flags a shell-form `CMD`, an unpinned image and a missing `SIGTERM` listener |
| `bun-runtime/scripts/self-check.sh` | type checking in CI (direct or through a script), `*Sync` in a request path, a shell command built from a string, an unescaped `$` in `.env`, env validation, password hashing, `--watch` × `--hot` |
| `bun-test-build/scripts/self-check.sh` | the 10-item checklist over one file; marks the four heuristic items as such |
| `bun-test-review/scripts/probes.sh` | S1, S5, S6, S7 without the suite; `--run` adds the S0 baseline, S2 over eight seeds, S3, S4 and the real S5, and marks the probes a red baseline makes inconclusive |

**The `trustedDependencies` probe needed JSON, not grep.** The rule is that the list **replaces**
the default one rather than extending it (`BUN-PKG-04`), and the symptom shows up at **runtime** —
an uncompiled binary, far from the cause. A `grep` over a one-line `package.json` answers "it is
there" for the whole file; the correct check compares `dependencies` against the declared list,
item by item.

**Search 2 in `enumerate.sh` is the one that changes the plan.** It uses ripgrep when installed and falls back to grep, because a search that silently prints a tool's help is worse than none. A transitive dependency using
`async_hooks` — which in Bun is a **stub that does not throw** — decides the feasibility of the
migration, and does not appear in the project's own code. Without `node_modules` installed, the
script **says the enumeration is partial** rather than faking coverage.

`bun-test-build/scripts/self-check.sh` explicitly marks the four **heuristic** items (assertion in
`catch`, timezone, `cleanup`, awaited `userEvent`): it points at the file, and confirmation is
reading. A probe that fakes certainty is worse than an absent probe.

## The ID maps — two of them, and the column only this family has

| Generator | Family | IDs |
| --- | --- | --- |
| `bun-test-review/scripts/generate-id-map.sh` | `BUN-TEST-*` | **29** — the full `01`–`29` range, checked against invented IDs |
| `bun-runtime/scripts/generate-id-map.sh` | `BUN-CORE/RT/PKG/SYS-*` | **43** |

Both read `docs/`. The second one **excludes** the `bun-tests*` notes on purpose: mixing the two
families into a single map would make the satellite column meaningless.

Because the **whole** test family is declared in § 6 of the hub, a "declared in" column alone would
be uniform and useless. The generator adds **"body in satellite"**: for each ID, which of the six
satellites carries the reasoning, and in which section. That is the information the skill needs in
order to load **one** satellite instead of six.

```bash
bash skills/bun/bun-runtime/scripts/generate-id-map.sh
bash skills/bun/bun-test-review/scripts/generate-id-map.sh
```

## Evals

Each skill carries two test cases under `evals/<case>/` in the layout `claude plugin eval` reads —
a prompt as a user would type it, a fixture project in `files/`, and one grader per verifiable
statement. The fixtures are real: the suites run under `bun test`, and the order-dependent file passes alone
and fails together. In the "green CI" fixture the coverage gate never closes because `bunfig.toml`
sets `coverage = false`, which turns `--coverage` into a no-op on Bun 1.4.3. The `.only` and
lcov-only threshold behaviours described by `BUN-TEST-08` and `BUN-TEST-27` did not reproduce on
that version, so verify them before relying on them. Run them with `claude plugin eval skills/bun/<skill> --scaffold`,
or through the skill-creator loop.

<!-- tokens:inicio -->
## Context budget

Measured with tiktoken (`cl100k_base`) on 2026-10-24. **The number that matters is the `SKILL.md`
column**: it is what enters the context before the skill decides what to open. The "minimum loading"
column is what the skill tells the model to open before step 1 — a hub plus one satellite — and it
is where the cost lives: the `Bun` hub alone is ~16k tokens, and three skills ask for two of its
sections.

| Skill | `SKILL.md` | largest `references/` | all references | minimum loading (docs) |
| --- | ---: | --- | ---: | ---: |
| `bun-runtime` | 1.311 | `id-map.md` (2.096) | 5.225 | 26.793 |
| `bun-migrate` | 1.315 | `id-map.md` (2.096) | 4.713 | 26.094 |
| `bun-workspace` | 1.240 | `id-map.md` (2.096) | 4.800 | 26.838 |
| `bun-test-build` | 1.954 | `by-task.md` (1.975) | 5.862 | 18.348 |
| `bun-test-review` | 1.700 | `id-map.md` (1.923) | 7.560 | 12.500 |

The twelve docs total **98.694** tokens (the Portuguese originals were 112.475 — English is about
12% denser for the same content). Loading all 5 `SKILL.md` at once costs **7.520** tokens; that is
why each skill declares what it must **never** load.
<!-- tokens:fim -->

## Related

- [Skills index](../README.md) · [Bun - Tests](docs/bun-tests.md) § 7 — the contract
- `tc96-core: test family` — decides the level, before these
- `tc96-e2e: playwright family` — the E2E level
