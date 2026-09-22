---
nome: bun-test-build
descricao: Write a new test under `bun test` and configure a project's suite, following the decision trees and the `BUN-TEST-*` rules from the vault docs, with an executable self-check — use when the task is writing a unit test, replacing a dependency with a mock or double, controlling date and time, testing a React component, configuring `bunfig.toml` and preloads, or assembling the CI command. Do not use to review an existing suite or diagnose flakiness, which is bun-test-review, and do not use to decide *what* to test and at which level, which is test-design.
tipo: skill
familia: bun
idioma: en
fonte: "[Bun - Testes](../../../knowledge-base/docs/bun-testes.md)"
docs:
  - /oven-sh/bun
tags:
  - skill
  - bun
  - testing
---

# bun-test-build

> **Source of this skill:** [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) — the normative § 6 (`BUN-TEST-01` to `BUN-TEST-29`), with the body of each rule in the owning satellite.
> This skill **does not contain** the text of the rules nor the API surface — it says what to load, in what order to decide, and what to run before delivering.
> **API surface:** resolve it through Context7 — `/oven-sh/bun`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 7 ("Contrato de skill").

---

## When to use

Writing a test that **will exist**, or configuring a project's suite under `bun test`.

| Situation | Go to |
| --- | --- |
| reviewing an existing suite, diagnosing flakiness | `bun-test-review` |
| deciding **what** to test and **at which level** | `test-design` — comes before this one |
| E2E test | `playwright-build` |
| story and interaction test in a real browser | `storybook-test` |
| reviewing the component, not its test | `react-review` · `react-developer` |

---

## Minimum loading

The order comes from the contract ([Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 7). The first two are **not optional**:

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 2 | the default is **one global shared by every file** — whoever writes a test without knowing that produces a suite that passes by accident |
| 2 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 6.1 | the seven silent-violation rules, which travel with any task |
| 3 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 3 | import boundaries: what comes from `bun:test`, and what Bun **does not** read (`vite.config.ts`, `jest.config.js`) |
| 4 | **one** satellite, via the map in `references/por-tarefa.md` | the surface the task touches |
| 5 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 5 | the decision tree, when in doubt between two APIs |

**Never load all six satellites.** Writing a unit test needs 1 + 2 + [Bun - Testes - Escrita e Asserções](../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) and nothing else.

References in this skill:

| File | What for |
| --- | --- |
| `references/por-tarefa.md` | the task → satellite map, and the six cuts (write, replace, time, component, suite, CI) |
| `references/armadilhas-do-runner.md` | the three things you do not assume from memory, coming from Jest/Vitest |
| `references/autoverificacao.md` | the checklist and the three commands that require execution |
| `references/mapa-de-ids.md` | the 29 `BUN-TEST-*`: where declared, and **in which satellite the body lives** |
| `references/exemplo-sessao-expira.md` | worked case, with what was run and what was not verified |
| `scripts/autoverificar.sh` | runs the checklist over the file you just wrote |

**Never invent an ID** — the family runs from `BUN-TEST-01` to `BUN-TEST-29`.

---

## Step 1 — Pick the cut

`references/por-tarefa.md`: write a new test · replace a dependency · control date and time · test a React component · configure the suite · assemble the CI command.

Each cut names **the satellite that is missing** — not its content.

---

## Step 2 — Do not trust Jest/Vitest memory

`references/armadilhas-do-runner.md`. The three that produce a test that is **green and unverified**:

1. **Without a flag, every file shares one `globalThis`.** "Leaked" does not mean "affected the next test": it means "affected the rest of the suite".
2. **`mock.restore` does not undo `mock.module`** (`BUN-TEST-03`). The three cleanups do different things.
3. **Concurrency inside a file isolates nothing** — mutable state requires `test.serial` (`BUN-TEST-23`), and `onTestFinished` does not work in a concurrent test (`BUN-TEST-22`).

And the fourth, about time: **`useFakeTimers` does not swap the `Date` constructor** — freezing a date is `setSystemTime` (`BUN-TEST-20`).

---

## Step 3 — Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-test-build/scripts/autoverificar.sh test/session.test.ts
```

Then, **the three that require execution**:

```bash
bun test./path/to-the-new.test.ts # passes in isolation
bun test --randomize # the suite still passes in random order
tsc --noEmit # the runner does not type-check — BUN-TEST-18
```

**Actually run all three.** If `--randomize` broke after your test, you have just introduced order dependence (`BUN-TEST-09`) — and no flag replaces moving the setup into the file itself. The full diagnosis is `bun-test-review`.

---

## Step 4 — What to deliver

Three parts, and the third is the one that usually goes missing:

1. **The code**, in the pattern the suite already uses. If the repository has the right pattern in another file, **extend that pattern** rather than introducing a new one.
2. **What was run**, with the result — paste the output when the output is the argument.
3. **What was not verified**, named. **"Should pass" is not a result**: declaring the gap is what separates a verified delivery from a plausible one.

---

## Example

*"The session expires 30 minutes after the last access."* The task is about **time**, so the first decision is not how to write the test — it is which API to use: `setSystemTime`, not `useFakeTimers` (`BUN-TEST-20`). The instants are 29/30/31 min (boundary value), the clock is given back in `afterEach`, and the spy is restored explicitly.

Full case, with what was run and what was left unverified: `references/exemplo-sessao-expira.md`.

---

## Boundary with the other skills

| If the task becomes… | Go to |
| --- | --- |
| reviewing the whole suite, diagnosing flakiness, classifying severity | `bun-test-review` |
| the **shape** of the suite across levels | `test-review` |
| reviewing the persistence the test exercises | `drizzle-review` |
| writing or reviewing the component, not its test | `react-developer` · `react-review` |
| deciding the cache and invalidation the test observes | `tanstack-query` |

When the boundary is crossed, **declare the handoff** instead of opining outside your source.

---

## Related

- [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) — source of this skill: § 2, § 5, § 6, § 7
- [Bun - Testes - Escrita e Asserções](../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) · [Bun - Testes - Mocks e Tempo](../../../knowledge-base/docs/bun-testes-mocks-e-tempo.md) · [Bun - Testes - DOM e Componentes](../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) · [Bun - Testes - Ciclo de Vida e Isolamento](../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md) · [Bun - Testes - Execução e Configuração](../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) · [Bun - Testes - Cobertura e CI](../../../knowledge-base/docs/bun-testes-cobertura-e-ci.md)
- `bun-test-review` — the sibling skill
- `test-design` — decides the level, before this skill starts
