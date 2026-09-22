# Choosing the framework, and the platform

The decision everything afterwards presupposes. The full tree is § 5.1 of the hub:

```
Will any story import @tanstack/react-router —
directly or transitively (a <Link> inside a component counts)?
├── NO, and it never will → @storybook/react-vite
│ floor: React ≥ 16.8 · Vite ≥ 5
└── YES, or probably
 ├── is the project on React ≥ 18 AND Vite ≥ 7?
 │ ├── YES → @storybook/tanstack-react
 │ └── NO → @storybook/react-vite + a hand-rolled router (transition)
```

| | `@storybook/tanstack-react` | `@storybook/react-vite` |
| --- | --- | --- |
| React | ≥ **18** | ≥ 16.8 |
| Vite | ≥ **7** | ≥ 5 |
| rule family | `SB-TS-*` | `SB-RV-*` |
| note | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) | [Storybook - React Vite](../../../../knowledge-base/docs/storybook-react-vite.md) |

Three facts that change the decision and are not obvious:

- **`tanstack-react` demands the highest floor in the whole structure: Vite ≥ 7.** Adopting it in an app on Vite 5 or 6 is scheduling a **Vite migration before any story** — that is not a configuration detail.
- **TanStack Start is not a requirement.** The source declares SPA support using only `@tanstack/react-router`. In an SPA with a separate BFF, the server-function stubs sit inert, and that is expected, not a symptom.
- **The redirection of `@tanstack/react-router` to the mock layer is global**, not opt-in — it also applies to stories in `packages/ui` that never touch routing. That is a cost, and it goes into the ledger.

**In a monorepo, the question is not about `packages/ui`** — it is about the most demanding package the Storybook will cover. A Storybook that also shows `apps/web`, where every page imports `Link`, needs the framework that wraps routing.

> **The choice is practically irreversible.** The `react-vite-to-tanstack-react` automigration is one-way, and `routeOverrides` has no direct replacement on the Vite side. Deciding by inertia here costs a migration later.

Record the choice: it determines which path note to load for the rest of the project's life, and citing the wrong path's family is an invalid finding ([Storybook](../../../../knowledge-base/docs/storybook.md) § 6.2).

---

## Step 2 — Check the platform

Two line-10 constraints that break a project coming from 8 or 9:

| Constraint | Rule |
| --- | --- |
| **ESM-only** — `main.ts` and presets have to be valid ESM; `require`/`module.exports` do not start | `SB-CORE-03` |
| **Node ≥ 20.19 or ≥ 22.12** | `SB-CORE-04` |

> **Watch the Node floor when Playwright is in the project:** `Docs/Playwright.md` requires Node **≥ 22** (22.x, 24.x or 26.x). A project on Node 20.19 runs Storybook and does **not** run Playwright 1.62 — and addon-vitest uses Playwright. In practice, the monorepo's effective floor is 22.12.
