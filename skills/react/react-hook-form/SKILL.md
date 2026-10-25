---
nome: react-hook-form
descricao: Build, review or debug a form in React Hook Form, citing `RHF-*` IDs — triage first on whether RHF is the right tool at all, then field connection, Zod validation, conditional fields and dynamic lists, submission ownership, and twelve executable probes for an existing form. Use when building a new form, wiring a controlled UI component through Controller, mapping a server error onto a field, using useFieldArray or a wizard, deciding who owns the submitting state, reviewing a form, or diagnosing re-renders per keystroke or a field that does not submit. Not for a single field without validation (native Actions via react-developer), server state (tanstack-query) or URL state (tanstack-router).
tipo: skill
familia: react
idioma: en
fonte: "[React Hook Form](../docs/react-hook-form.md)"
docs:
  - /react-hook-form/documentation
  - /reactjs/react.dev
tags:
  - skill
  - react
  - react-hook-form
---

# react-hook-form

> **Source:** [React Hook Form](../docs/react-hook-form.md) and its three satellites (§ 7 is the skill contract; its invariants hold in every task). A task → note router: rule text, signatures and `formState` behavior live only in the satellites.
> **API surface:** Context7 `/react-hook-form/documentation` · `/reactjs/react.dev`. The rule and its ID come from the family's docs.

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
│ → React - Forms and Actions · skill react-developer. STOP HERE.
└── YES → RHF owns the CAPTURE. Continue.
```

Three notes converge on that cut — [React Hook Form](../docs/react-hook-form.md) § 5.4, [React - Forms and Actions](../docs/react-forms-and-actions.md) § 6 and [React - Patterns](../docs/react-patterns.md) § 4 —, so it is not a style preference. **Record the decision in one sentence:** if you cannot name which of the five triggers applies, RHF is a dependency with no counterpart.

---

## Minimum loading

Per [React Hook Form](../docs/react-hook-form.md) § 7:

```
ALWAYS: React Hook Form § 2 (mental model), § 5 (trees), § 6 + § 6.1 (rules)
FIRST: § 5.4 — Step 0 above

ON DEMAND, ONE satellite at a time:
 connecting a field........... React Hook Form - Registration and Control
 validating / server errors... React Hook Form - Validation and Resolvers
 reading state, lists, re-renders React Hook Form - State and Performance

BASE: React.js § 6 — `REACT-PURE-*` and `REACT-HOOK-*` hold inside the form
NEVER: all three satellites at once
```

References in this skill — open only the one the task asks for:

| File | What for |
| --- | --- |
| `references/tasks.md` | the five tasks, with the order of decisions and what to check in each |
| `references/submission-owner.md` | `isSubmitting` × `isPending` — pick one and declare which |
| `references/diagnosis.md` | symptom → likely cause → satellite, and what is **not** this skill's |
| `references/id-map.md` | where each `RHF-*` is declared, and the cross-doc citation rule |
| `references/example-invoice-entry.md` | worked case, from Step 0 to the submit |
| `scripts/probes.sh` | twelve executable probes for reviewing an existing form |
| `scripts/generate-id-map.sh` | regenerates `id-map.md` from the family's `docs/react-hook-form*` |

Below, the satellites appear by their short names: **Registration**, **Validation**, **State**; the **hub** is [React Hook Form](../docs/react-hook-form.md).

---

## Routing by task

| Task | Where | The rule that fails most |
| --- | --- | --- |
| Building a new form | `references/tasks.md` § 1 | `RHF-VAL-04` — schema first, type derived |
| Integrating a controlled UI component | § 2 | `RHF-CORE-03` / `RHF-CTRL-01` |
| Validating with Zod, mapping a server error | § 3 | `RHF-VAL-01`, `RHF-ERR-02` |
| A conditional field, a dynamic list, a wizard | § 4 | `RHF-PERF-01`, `RHF-ARRAY-01`, `REACT-PAT-10` |
| Submitting (a mutation or a Server Function) | § 5 | `RHF-BRIDGE-01` — one owner only |
| Deciding who disables the button | `references/submission-owner.md` | — |
| Diagnosing a re-render or a field that does not submit | `references/diagnosis.md` | `REACT-PERF-01` — did you measure? |

The order of the decisions is **not** the order of writing the JSX: schema → `defaultValues` → `mode` → field by field → the submit's owner. Writing the JSX first is what produces a `useState` per field.

---

## Reviewing a form that already exists

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-hook-form/scripts/probes.sh src
```

Twelve probes, in the order that fails most: `watch` at the root, deprecated `watch(callback)`, `useForm` without `defaultValues`, `formState` coming from `useFormContext`, two owners of the submission, `reset` inside the `onSubmit`, an index `key` in `useFieldArray`, double registration, `useState` mirroring a field, optimism in the form, two waiting states, and an error without `aria-invalid`.

**Probes 3 and 9 have a high false-positive rate** — a `useForm` without `defaultValues` may be receiving `values`, and a `useState` in the file may have nothing to do with the form. Confirm by reading before reporting.

When reporting, use `react-review`'s format: canonical ID + `file:line` + concrete fix + satellite link.

---

## What is a boundary, and whose it is

| The question is about | Skill |
| --- | --- |
| whether this form should use RHF at all | Step 0; if native Actions, `react-developer` |
| capture, field connection, validation, field errors, submission | **this one** |
| what the write made stale: key, freshness, invalidation, optimism | `tanstack-query` |
| the wizard step in the URL, route data in the form | `tanstack-router` |
| the component around it · where its file lives | `react-review` / `react-developer` · `react-structure` |
| a story and interaction test · the test's level | `storybook-test` · `test-design` |
| the endpoint receiving the submit | `elysia-schema` · `http-contract` |

Three boundary rules that decide the citation:

- **Optimism is never the form's** → `RHF-BRIDGE-04`, which is **canonical**, not an alias of `REACT-FORM-07` (hub § 6.2): that one is about `useOptimistic` not being the source of truth, and it does not replace this one.
- **Remote data in the form:** `values` + `keepDirtyValues` is this skill's (`RHF-BRIDGE-03`); which query supplies the data, and with what freshness, is `tanstack-query`'s.
- **A React rule beats an RHF rule:** `REACT-PURE-*` and `REACT-HOOK-*` take precedence (§ 7, invariant 4).

**Honesty:** an API that does not appear in hub § 4 has not been verified — this applies especially to `setValues`, `resetDefaultValues` and `createFormControl` (§ 4.3, with a caveat) and to `<Form>`, which is BETA. Declare the limitation, resolve the API through Context7 (`/react-hook-form/documentation`) and propose updating the note; do not invent behavior or an ID (§ 7, invariant 2).

---

## Example

An invoice entry form: a currency amount, a due date, and a justification that only appears above R$ 10,000. Step 0 names two of the five triggers; the order of decisions eliminates the per-field `useState` before the first JSX; the cross-field rule goes to `.superRefine`, not to `validate`; and the conditional reads the value with `useWatch` in the smallest component, not with `watch` at the root.

Full case, with code and the table of what each decision prevented: `references/example-invoice-entry.md`.

---

## Related

- Satellites, one at a time: [Registration and Control](../docs/react-hook-form-registration-and-control.md) · [Validation and Resolvers](../docs/react-hook-form-validation-and-resolvers.md) · [State and Performance](../docs/react-hook-form-state-and-performance.md)
- [React - Forms and Actions](../docs/react-forms-and-actions.md) — the native alternative Step 0 may point to
