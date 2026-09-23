---
nome: react-hook-form
descricao: Work with forms in React Hook Form — triaging whether RHF is the tool, connecting fields, validating with Zod, conditional fields and dynamic lists, submitting, and diagnosing re-renders and a field that does not submit, citing `RHF-*` IDs, with twelve executable probes — use when the task is building a new form, integrating a controlled UI component through Controller, mapping a server error onto a field, using useFieldArray, deciding who owns the submission state, or reviewing an existing form. Do not use for an isolated field with no validation, which is the native Actions through react-developer, for server state, which is tanstack-query, nor for state that belongs to the URL, which is tanstack-router.
tipo: skill
familia: react
idioma: en
fonte: "[React Hook Form](../../../knowledge-base/react-hook-form.md)"
docs:
  - /react-hook-form/documentation
  - /reactjs/react.dev
tags:
  - skill
  - react
  - react-hook-form
---

# react-hook-form

> **Source of this skill:** [React Hook Form](../../../knowledge-base/react-hook-form.md) and its three satellites in the knowledge base.
> A **task → note** router, not an API summary. It contains neither the text of the `RHF-*` rules, nor signatures, options, nor the behavior of the `formState` Proxy: that lives in the satellites, and that is where it is read and updated. Technical procedure written here becomes a copy that goes stale on its own.
> **API surface:** resolve it through Context7 — `/react-hook-form/documentation` · `/reactjs/react.dev`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [React Hook Form](../../../knowledge-base/react-hook-form.md) § 7. The invariants there hold in every task, without repetition per section.

---

## Step 0 — Triage: does this really need React Hook Form?

**Before installing, importing or writing anything.** Invariant 1 of the contract.

```
Does the form need at least ONE of these?
 · per-field validation while the user types
 · per-field errors (from the client or the server)
 · a dynamic array of fields — adding/removing rows
 · several steps (a wizard)
 · dependency between fields — one decides what the other accepts
├── NO → React 19's native Actions: useActionState + <form action>.
│ Fewer dependencies, less code, and it is the most common case.
│ → React - Formulários e Actions · skill react-developer. STOP HERE.
└── YES → RHF owns the CAPTURE. Continue.
```

Three notes converge on that cut — [React Hook Form](../../../knowledge-base/react-hook-form.md) § 5.4, [React - Formulários e Actions](../../../knowledge-base/react-formularios-e-actions.md) § 6 and [React - Patterns](../../../knowledge-base/react-patterns.md) § 4 —, so it is not a style preference. **Record the decision in one sentence:** if you cannot name which of the five triggers applies, RHF is a dependency with no counterpart.

---

## Minimum loading

Per [React Hook Form](../../../knowledge-base/react-hook-form.md) § 7:

```
ALWAYS: React Hook Form § 2 (mental model), § 5 (trees), § 6 + § 6.1 (rules)
FIRST: § 5.4 — Step 0 above

ON DEMAND, ONE satellite at a time:
 connecting a field........... React Hook Form - Registro e Controle
 validating / server errors... React Hook Form - Validação e Resolvers
 reading state, lists, re-renders React Hook Form - Estado e Performance

BASE: React.js § 6 — `REACT-PURE-*` and `REACT-HOOK-*` hold inside the form
NEVER: all three satellites at once
```

References in this skill — open only the one the task asks for:

| File | What for |
| --- | --- |
| `references/tarefas.md` | the five tasks, with the order of decisions and what to check in each |
| `references/dono-da-submissao.md` | `isSubmitting` × `isPending` — pick one and declare which |
| `references/diagnostico.md` | symptom → likely cause → satellite, and what is **not** this skill's |
| `references/mapa-de-ids.md` | where each `RHF-*` is declared, and the cross-doc citation rule |
| `references/exemplo-lancamento-de-fatura.md` | worked case, from Step 0 to the submit |
| `scripts/sondas.sh` | twelve executable probes for reviewing an existing form |
| `scripts/gerar-mapa-de-ids.sh` | regenerates `mapa-de-ids.md` from `knowledge-base/react-hook-form*` |

Below, the satellites appear by their short names: **Registro**, **Validação**, **Estado**; the **hub** is [React Hook Form](../../../knowledge-base/react-hook-form.md).

---

## Routing by task

| Task | Where | The rule that fails most |
| --- | --- | --- |
| Building a new form | `references/tarefas.md` § 1 | `RHF-VAL-04` — schema first, type derived |
| Integrating a controlled UI component | § 2 | `RHF-CORE-03` / `RHF-CTRL-01` |
| Validating with Zod, mapping a server error | § 3 | `RHF-VAL-01`, `RHF-ERR-02` |
| A conditional field, a dynamic list, a wizard | § 4 | `RHF-PERF-01`, `RHF-ARRAY-01`, `REACT-PAT-10` |
| Submitting (a mutation or a Server Function) | § 5 | `RHF-BRIDGE-01` — one owner only |
| Deciding who disables the button | `references/dono-da-submissao.md` | — |
| Diagnosing a re-render or a field that does not submit | `references/diagnostico.md` | `REACT-PERF-01` — did you measure? |

The order of the decisions is **not** the order of writing the JSX: schema → `defaultValues` → `mode` → field by field → the submit's owner. Writing the JSX first is what produces a `useState` per field.

---

## Reviewing a form that already exists

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-hook-form/scripts/sondas.sh src
```

Twelve probes, in the order that fails most: `watch` at the root, deprecated `watch(callback)`, `useForm` without `defaultValues`, `formState` coming from `useFormContext`, two owners of the submission, `reset` inside the `onSubmit`, an index `key` in `useFieldArray`, double registration, `useState` mirroring a field, optimism in the form, two waiting states, and an error without `aria-invalid`.

**Probes 3 and 9 have a high false-positive rate** — a `useForm` without `defaultValues` may be receiving `values`, and a `useState` in the file may have nothing to do with the form. Confirm by reading before reporting.

When reporting, use `react-review`'s format: canonical ID + `file:line` + concrete fix + satellite link.

---

## What is a boundary, and whose it is

| The question is about | Skill |
| --- | --- |
| whether this form should use RHF at all | Step 0 — if the answer is native Actions, `react-developer` |
| capture, field connection, validation, field errors, submission | **this one** |
| what the write made stale: key, freshness, invalidation, optimism | `tanstack-query` |
| where the wizard's step lives, route data in the form, a filter in the URL | `tanstack-router` |
| the component around it: purity, Hooks, boundaries | `react-review` · `react-developer` |
| where the form's file lives, who imports whom | `react-structure` |
| a story and an interaction test for the form | `storybook-story` · `storybook-test` |
| the form test's **level** (unit × integration × e2e) | `test-design` |
| a unit test · an e2e of the submission journey | `bun-test-build` · `playwright-build` |
| the endpoint receiving the submit: schema, status, errors | `elysia-schema` · `http-contract` |

Three boundary rules that decide the citation:

- **Optimism is never the form's** → `RHF-BRIDGE-04`, which is **canonical**, not an alias of `REACT-FORM-07` (hub § 6.2): that one is about `useOptimistic` not being the source of truth, and it does not replace this one.
- **Remote data in the form:** `values` + `keepDirtyValues` is this skill's (`RHF-BRIDGE-03`); which query supplies the data, and with what freshness, is `tanstack-query`'s.
- **A React rule beats an RHF rule:** `REACT-PURE-*` and `REACT-HOOK-*` take precedence (§ 7, invariant 4).

**Honesty:** an API that does not appear in hub § 4 has not been verified — this applies especially to `setValues`, `resetDefaultValues` and `createFormControl` (§ 4.3, with a caveat) and to `<Form>`, which is BETA. Declare the limitation, consult [react-hook-form.com](https://react-hook-form.com/docs) and propose updating the note; do not invent behavior or an ID (§ 7, invariant 2).

---

## Example

An invoice entry form: a currency amount, a due date, and a justification that only appears above R$ 10,000. Step 0 names two of the five triggers; the order of decisions eliminates the per-field `useState` before the first JSX; the cross-field rule goes to `.superRefine`, not to `validate`; and the conditional reads the value with `useWatch` in the smallest component, not with `watch` at the root.

Full case, with code and the table of what each decision prevented: `references/exemplo-lancamento-de-fatura.md`.

---

## Related

- [React Hook Form](../../../knowledge-base/react-hook-form.md) — hub, mental model, decision trees, skill contract (source)
- [React Hook Form - Registro e Controle](../../../knowledge-base/react-hook-form-registro-e-controle.md) · [React Hook Form - Validação e Resolvers](../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) · [React Hook Form - Estado e Performance](../../../knowledge-base/react-hook-form-estado-e-performance.md) — satellites, one at a time
- [React - Formulários e Actions](../../../knowledge-base/react-formularios-e-actions.md) — the native alternative, which Step 0 may point to
- `react-developer` · `react-review` · `react-structure` · `tanstack-query` · `tanstack-router` — neighboring skills
