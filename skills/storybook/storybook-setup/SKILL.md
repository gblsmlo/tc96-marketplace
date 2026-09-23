---
nome: storybook-setup
descricao: Configure Storybook in a project or monorepo — choosing between the two frameworks by their version floors, `main.ts`, `preview.tsx`, where the Vite config is inherited from, CSS and theming — citing `SB-CFG-*` and `SB-CORE-*` IDs, with a script that discovers the path and checks the floors — use when the task is installing Storybook from scratch, migrating from line 8 or 9, choosing the framework, fixing an empty sidebar, aligning package versions, or carving out `apps/storybook` in a monorepo. Do not use to write a story, which is storybook-story, for the test inside it, which is storybook-test, nor for coverage and CI, which is the Cobertura e CI satellite.
tipo: skill
familia: storybook
idioma: en
fonte: "[Storybook - Configuração e Builder](../../../knowledge-base/storybook-configuracao-e-builder.md)"
docs:
  - /storybookjs/storybook
tags:
  - skill
  - storybook
  - frontend
---

# storybook-setup

> **Source of this skill:** [Storybook - Configuração e Builder](../../../knowledge-base/storybook-configuracao-e-builder.md), with the [Storybook](../../../knowledge-base/storybook.md) hub as the router.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and what to check.
> **API surface:** resolve it through Context7 — `/storybookjs/storybook`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Storybook](../../../knowledge-base/storybook.md) § 7.

---

## When to use

Installing, migrating or reconfiguring Storybook.

| Situation | Go to |
| --- | --- |
| writing a story | `storybook-story` |
| an interaction test inside the story | `storybook-test` |
| coverage and the CI job | [Storybook - Cobertura e CI](../../../knowledge-base/storybook-cobertura-e-ci.md) |
| a journey test | `playwright-build` · a unit test | `bun-test-build` |

---

## Step 1 — Choose the framework

**The decision everything afterwards presupposes**, and it is **practically irreversible**: the `react-vite-to-tanstack-react` automigration is one-way.

```
Will any story import @tanstack/react-router —
directly or transitively (a <Link> inside a component counts)?
├── NO, and it never will → @storybook/react-vite (React ≥ 16.8 · Vite ≥ 5)
└── YES, or probably
 ├── is the project on React ≥ 18 AND Vite ≥ 7?
 │ ├── YES → @storybook/tanstack-react
 │ └── NO → @storybook/react-vite + a hand-rolled router (transition)
```

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-setup/scripts/descobrir-caminho.sh
```

The script reads the `framework` field, checks the floors, and **looks for the path contradiction in the code** — which is the finding that fails silently.

Three facts that change the decision: `tanstack-react` demands **Vite ≥ 7** (adopting it on Vite 5/6 is scheduling a Vite migration before any story); **TanStack Start is not a requirement**; and the redirection to the mock layer is **global**, not opt-in.

**In a monorepo, the question is not about `packages/ui`** — it is about the most demanding package the Storybook will cover.

Detail: `references/escolher-o-framework.md`.

---

## Minimum loading

| Order | Load |
| --- | --- |
| 1 | [Storybook](../../../knowledge-base/storybook.md) § 5.1 (the framework tree) and § 6.2 (the mutually exclusive families) |
| 2 | [Storybook - Configuração e Builder](../../../knowledge-base/storybook-configuracao-e-builder.md) |
| 3 | the note for the **chosen path**: [Storybook - TanStack React](../../../knowledge-base/storybook-tanstack-react.md) or [Storybook - React Vite](../../../knowledge-base/storybook-react-vite.md) |

References in this skill:

| File | What for |
| --- | --- |
| `references/escolher-o-framework.md` | the tree, the floors, and the three non-obvious facts |
| `references/sequencia-e-vite.md` | the seven-step sequence, and where the Vite config is inherited from |
| `references/autoverificacao.md` | the checklist, and the type-augmentation trap |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 75 `SB-*` by satellite and section |
| `references/exemplo.md` | worked case |
| `scripts/descobrir-caminho.sh` | reads the `framework`, checks floors and finds contradictions |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map across the three skills |

---

## Step 2 — The sequence

`references/sequencia-e-vite.md`: the seven-step order the official docs never give, and **where the Vite config is inherited from** — which is the cause of most "works in the app and breaks in Storybook".

---

## Step 3 — Self-check

`references/autoverificacao.md`, plus the **type-augmentation** trap.

**Start it and look at the sidebar.** A glob that does not match **raises no error** — it gives an empty sidebar (`SB-CFG-02`).

---

## Step 4 — Closing, and handing off

1. **Record the framework choice.** It determines which note to load for the rest of the project's life.
2. **Citing the wrong path's family is an invalid finding** (`SB-TS-*` × `SB-RV-*`).
3. A story → `storybook-story`; the test inside it → `storybook-test`; coverage and CI → [Storybook - Cobertura e CI](../../../knowledge-base/storybook-cobertura-e-ci.md).

---

## Example

A monorepo with `packages/ui` and `apps/web`: the question is not about `ui`, it is about `web`, where every page imports `Link`. The project is on Vite 6 — so `tanstack-react` requires **a Vite migration before the first story**, and the transitional way out is `react-vite` with a hand-rolled router.

Full case: `references/exemplo.md`.

---

## Related

- [Storybook - Configuração e Builder](../../../knowledge-base/storybook-configuracao-e-builder.md) — source of this skill
- [Storybook](../../../knowledge-base/storybook.md) § 5.1, § 6.2, § 7
- `storybook-story` · `storybook-test` — the sibling skills
- [Storybook - TanStack React](../../../knowledge-base/storybook-tanstack-react.md) · [Storybook - React Vite](../../../knowledge-base/storybook-react-vite.md) — the two path notes
