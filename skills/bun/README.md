# Bun skills

Five skills: two about testing, three about runtime, packages and migration.

| Skill | The question it answers | Source | Internal support |
| --- | --- | --- | --- |
| `bun-test-build` | how do I write this test, and how do I configure the suite? | [Bun - Testes](../../knowledge-base/docs/bun-testes.md) | 4 references + 1 script |
| `bun-test-review` | does this suite have defects? why is this test flaky? | [Bun - Testes](../../knowledge-base/docs/bun-testes.md) | 5 references + 2 scripts |
| `bun-runtime` | how do I write this with the runtime APIs? | [Bun - Runtime e APIs](../../knowledge-base/docs/bun-runtime-e-apis.md) | 6 references + 2 scripts |
| `bun-workspace` | dependency, lockfile, workspace, install | [Bun - Gerenciador de Pacotes](../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) | 5 references + 1 script |
| `bun-migrate` | it came from Node and does not run — is it an incompatibility? | [Bun - Shell, FFI e Compat Node](../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) | 4 references + 1 script |

## The three newer ones, and what each script does

| Script | What it does |
| --- | --- |
| `bun-workspace/scripts/sondas.sh` | reads `package.json` **as JSON** and says which packages from the default list `trustedDependencies` turned off |
| `bun-migrate/scripts/enumerar.sh` | enumerates `node:*` in the code **and in transitive dependencies** |
| `bun-runtime/scripts/autoverificar.sh` | binary invariants, `tsc --noEmit` in CI, password hashing, `--watch` × `--hot` |

**The `trustedDependencies` probe needed JSON, not grep.** The rule is that the list
**replaces** the default one rather than extending it (`BUN-PKG-04`), and the symptom shows up
at **runtime** — an uncompiled binary, far from the cause. A `grep` over a one-line
`package.json` answers "it is there" for the whole file; the correct check compares
`dependencies` against the declared list, item by item.

**Search 2 in `enumerar.sh` is the one that changes the plan.** A transitive dependency using
`async_hooks` — which in Bun is a **stub that does not throw** — decides the feasibility of the
migration, and does not appear in the project's own code. Without `node_modules` installed, the
script **says the enumeration is partial** rather than faking coverage.

## The two about testing

`bun-test-build` and `bun-test-review` split by **mode of work**, not by source: the whole
`BUN-TEST-*` family is declared in § 6 of the hub, and the body of each rule lives in the owning satellite.

| Skill | Gained | Gap it closed |
| --- | --- | --- |
| `bun-test-build` | **`scripts/autoverificar.sh`** | the 10-item checklist was reading; now it points at file and line |
| `bun-test-review` | **`scripts/sondas.sh`** (with `--rodar`) | S2, S3, S4 and S5 need the suite up — the script separates what runs without it |

`autoverificar.sh` explicitly marks the four **heuristic** items (assertion in `catch`,
timezone, `cleanup`, awaited `userEvent`): it points at the file, and confirmation is reading.
A probe that fakes certainty is worse than an absent probe.

## The ID maps — two of them, and the column only this family has

There are **two generators**, because the families do not mix:

| Generator | Family | IDs |
| --- | --- | --- |
| `bun-test-review/scripts/gerar-mapa-de-ids.sh` | `BUN-TEST-*` | **29** — the full `01`–`29` range, checked against invented IDs |
| `bun-runtime/scripts/gerar-mapa-de-ids.sh` | `BUN-CORE/RT/PKG/SYS-*` | **43** |

The second one **excludes** the `bun-testes*` notes on purpose: mixing the two families into a
single map would make the satellite column meaningless.

Because the **whole** family is declared in § 6 of the hub, a "declared in" column would be
uniform and useless. The generator adds **"body in satellite"** instead: for each ID, which of
the six satellites carries the reasoning, and in which section. That is the information the
skill needs in order to load **one** satellite instead of six.

```bash
bash plugins/twincam-backend/skills/bun-test-review/scripts/gerar-mapa-de-ids.sh
bash scripts/instalar.sh
```

<!-- tokens:inicio -->
## Context budget

Measured by `skill-validator` (tiktoken), on 2026-09-05. **The number that matters is the
`SKILL.md` column**: it is what enters the context before the skill decides what to open.
References load on demand, one at a time.

| Skill | `SKILL.md` | largest `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| `bun-migrate` | 1.036 | `mapa-de-ids.md` (1.772) | 5.365 | 5 |
| `bun-runtime` | 1.035 | `mapa-de-ids.md` (1.772) | 5.856 | 7 |
| `bun-test-build` | 1.718 | `por-tarefa.md` (1.938) | 7.344 | 5 |
| `bun-test-review` | 1.565 | `mapa-de-ids.md` (1.632) | 8.899 | 6 |
| `bun-workspace` | 973 | `mapa-de-ids.md` (1.772) | 5.436 | 6 |

Loading all 5 skills in this group at once would cost **6.327 tokens** in `SKILL.md` alone,
and **32.900** with every reference. That is why each skill declares what it must **never** load.

Regenerate: `bash scripts/medir.sh`
<!-- tokens:fim -->

## Related

- [Skills index](../README.md) · [Bun - Testes](../../knowledge-base/docs/bun-testes.md) § 7 — the contract
- `twincam-core: test family` — decides the level, before these
- `twincam-e2e: playwright family` — the E2E level
