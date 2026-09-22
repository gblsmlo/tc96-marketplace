---
nome: test-design
descricao: Decide which level a test belongs at and derive the cases before writing a line, citing `TS-*` IDs from the vault docs — use when the task is answering "what test do I write for this?", choosing between unit/integration/component/contract/E2E, setting the suite proportion for a module, deriving cases from an input (range, boundary, combination, state), or deciding what to replace with a double. Do not use to write the test itself — once the level is decided, the source becomes playwright-build or bun-test-build. Do not use to audit an existing suite, which is test-review, nor for an unstable suite, which is test-diagnose.
tipo: skill
familia: test
idioma: en
fonte: "[Teste de Software - Níveis e Escopo](../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md)"
tags:
  - skill
  - testing
  - software-quality
  - test-design
---

# test-design

> **Source of this skill:** [Teste de Software - Níveis e Escopo](../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) and [Teste de Software - Técnicas de Design de Caso](../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md), with the [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) hub as the router. The 64 rules of the `TS-*` family live in § 6 of the hub.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and whom to hand it to afterwards.

Contract this skill implements: [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 7 ("Contrato de skill").

> **Design note.** This is the **concept layer**: it decides *what* and *at which level*. It **does not write tests** — that is `playwright-build` or `bun-test-build`, and the handoff is in Step 7. Running both layers as if they were one wastes context; skipping this one and going straight to the tool produces **E2E by default**, the most expensive antipattern in this stack.

---

## When to use

There is a feature, a bug, a rule, a journey — and the question is *what test covers this, and where does it live?*

| Situation | Go to |
| --- | --- |
| the level is already decided, I want to write | `playwright-build` (E2E) · `bun-test-build` (unit/integration) · `storybook-test` (component) |
| auditing the strategy of an existing suite | `test-review` |
| a suite nobody trusts | `test-diagnose` |
| one concrete test failing | `playwright-diagnose` · `bun-test-review` |
| acceptance criteria for a non-functional requirement | [Teste de Software - Processo e Artefatos](../../../knowledge-base/docs/teste-de-software-processo-e-artefatos.md) |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 2 | a test buys information at a price; the cheapest layer that still catches the defect |
| 2 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 4.1 | the level tree — the core of this skill |
| 3 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 6 | the 8 `TS-CORE-*` and the critical ones in § 6.1 |
| 4 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 4.3 | the technique tree, when there is input to exercise |
| 5 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 4.2 | the replacement tree, when there is a dependency |

**Never load all six satellites.** And do not load the tool note yet — it comes in at Step 7.

References in this skill:

| File | What for |
| --- | --- |
| `references/arvore-de-nivel.md` | the sentence, the level, the per-module proportion (Steps 1–3) |
| `references/tecnicas-de-caso.md` | technique by input shape, non-numeric boundaries, the five states (Step 4) |
| `references/substituicao.md` | the single question about doubles and the vocabulary (Step 5) |
| `references/antipadroes.md` | the check grid, 24 antipatterns with IDs |
| `references/mapa-de-ids.md` | the 64 `TS-*` by satellite and section, and the three **aliases** |
| `references/exemplo-desconto-por-volume.md` | worked case, from the sentence to the handoff |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map across the three test skills |

---

## Step 1 — The sentence, before anything else

> **What exactly can go wrong here?**

If you cannot write it, **the test should not be written yet** (`TS-CORE-01`). A good sentence names **a subject and a wrong behavior** — and it is the sentence that decides the level, not intuition. Examples of vague × actionable sentences: `references/arvore-de-nivel.md`.

---

## Step 2 — Choose the level

`references/arvore-de-nivel.md`, or § 4.1 of the hub. Three cuts settle most cases:

- **a business rule is never E2E** (`TS-NIV-02`);
- it needs routing, login or more than one screen → **E2E**; it varies props → **component**;
- the defect is in the **joint** between pieces → integration.

**E2E is the smallest slice of the suite** (`TS-CORE-02`).

---

## Step 3 — Choose the module's proportion

Per **module**, not per repository (`TS-NIV-08`). Complexity inside functions → pyramid; between pieces → trophy. The same repository has both. Count the static layer (`TS-TIPO-08`).

---

## Step 4 — Derive the cases

`references/tecnicas-de-caso.md`. If you are going to apply **one** technique, make it **boundary value** (`TS-TEC-01`). Do not forget the non-numeric boundaries — an **empty** collection is the one that breaks UI most — nor the five states of the flow (`TS-TIPO-02`).

---

## Step 5 — Decide what to replace

`references/substituicao.md`. The single question: **if the real dependency diverged from the double, should this test break?** If yes, do not replace it (`TS-CORE-03`). Clock and randomness: always replace them (`TS-DUB-05`).

---

## Step 6 — Self-check before the handoff

| # | Check | Rule |
| --- | --- | --- |
| 1 | the sentence exists and is specific | `TS-CORE-01` |
| 2 | the level is the cheapest one that still catches the defect | `TS-CORE-02` |
| 3 | no business rule was sent to E2E | `TS-NIV-02` |
| 4 | the input's boundaries have cases | `TS-TEC-01`, `TS-TEC-03` |
| 5 | the **invalid** classes/transitions have cases | `TS-TEC-02`, `TS-TEC-04` |
| 6 | the five states are decided (even if "not covering") | `TS-TIPO-02` |
| 7 | nothing the test came to prove is being replaced | `TS-CORE-03` |
| 8 | clock and randomness are controlled | `TS-DUB-05` |
| 9 | the double is called by the right name | `TS-DUB-01` |
| 10 | a non-functional requirement has a number and a percentile | `TS-TIPO-05`, `TS-TIPO-06` |

Then go through `references/antipadroes.md` line by line.

---

## Step 7 — Hand off

| Level | Continue in |
| --- | --- |
| E2E | `playwright-build` |
| unit, integration | `bun-test-build` |
| component | `storybook-story` · `storybook-test` |
| contract | `elysia-schema` · `Docs/Hono - Validação e RPC.md` |
| static | `Docs/TypeScript.md` · `Docs/Zod - Validação de Ambiente.md` |

**Hand the decision over with it:** level, derived cases, and what will be replaced. The tool skill implements — it does not reopen those questions.

---

## Step 8 — Closing

1. **Declare what you decided not to cover.** A recorded decision is not a gap; an implicit one is.
2. **If the sentence fell into no level**, the requirement is ambiguous — the finding is about the requirement (`TS-PROC-01`).
3. **If the defect came from production**, the test goes at the cheapest level that catches it (`TS-CORE-06`) — it is the test with the strongest proof of value there is.
4. **If the decision was "do not test"**, write down why.

---

## Example

*"Cover the volume discount at checkout."* The sentence — "a discount above 50% can be applied without approval" — sends it to **unit**, not to the whole checkout. Boundary value generates 5 cases, state transition 2 more, and E2E gets **one**: the screen displays the calculated value. The intuitive alternative (8 E2E runs) buys less information for far more execution time.

Full case: `references/exemplo-desconto-por-volume.md`.

---

## Related

- [Teste de Software - Níveis e Escopo](../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) — source of this skill
- [Teste de Software - Técnicas de Design de Caso](../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) — the second source, from Step 4
- [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) — the hub: § 2, § 4.1, § 4.2, § 4.3, § 6, § 7
- `test-review` · `test-diagnose` — the sibling skills
- `playwright-build` · `bun-test-build` · `storybook-test` — where the handoff goes
