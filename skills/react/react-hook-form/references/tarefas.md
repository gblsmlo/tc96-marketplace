# The five tasks

> A task → note router. It contains no signatures, no options and no `formState` Proxy
> behavior: that lives in the satellites, and that is where it is read and updated.
> Short names: **Registro**, **Validação**, **Estado**; the **hub** is [React Hook Form](../../../../knowledge-base/docs/react-hook-form.md).

---

## 1. Building a new form

The order of **decisions** — not the order of writing the JSX:

1. **Schema first.** The form's type derives from Zod, never the other way round → `RHF-VAL-04`.
2. **`defaultValues` covering every field** → `RHF-CORE-01`, including the conditional ones.
3. **`mode` / `reValidateMode`** — a UX decision (hub § 5.3, Validação § 2.1). Staying on the default is legitimate **when it is a declared choice**.
4. **Field by field through the § 5.1 tree** — `register` is the default route, `Controller` is the exception (task 2).
5. **Only then the submit's owner** — § 5.4 and task 5.

**Check:**

- `formState` destructured before the render that depends on it → `RHF-CORE-02` (the subscription is created by **reading** — hub § 2)
- A name in dot notation → `RHF-REG-01`; with no reserved name and not starting with a number
- `number` and `date` with explicit coercion — the DOM returns strings → `RHF-REG-03`
- `.transform`/`.default` require all three generics → `RHF-VAL-02`
- An error with `aria-invalid` and `aria-describedby` → `RHF-A11Y-01`; a message with `role="alert"` → `RHF-A11Y-02`
- No `useState` per field, and no read just to submit: `handleSubmit` already delivers the validated object (§ 5.2)

**Do not:** `watch` at the root "to follow the form" → `RHF-PERF-01`. That is exactly the cost the library removes.

---

## 2. Integrating a controlled UI component

**Load:** Registro § 3 (`Controller`, `useController`, the `field` object, the traps); § 3.3 if it becomes a reusable field component.

**The criterion is technical, not about the library:** does the component forward `ref` and emit a native `onChange`? Check **the component**, not the package. shadcn's `<Input>` is an `<input>` with classes — `register` is enough. `Select`, `Checkbox`, `RadioGroup`, `Switch` or a date picker over Radix expose `value`/`onValueChange` and do not forward a ref — `Controller`.

**Check:**

- `Controller` only where `register` does not serve → `RHF-CORE-03`; and with no double registration → `RHF-CORE-04`
- `field` spread **before** overriding `onChange`/`value` → `RHF-CTRL-01`
- `field.onChange` never receives `undefined` → `RHF-CORE-06`; it escapes through the "clear selection" adapter
- Inline and one-off → `<Controller>`; reusable → `useController` (§ 5.1)
- A nested field takes **methods** from `useFormContext`, but **state** from `useFormState` → `RHF-STATE-01`
- `exact` has a different default between `useController` and `useWatch`/`useFormState` — check the hub's verification note, not your memory

---

## 3. Validating with Zod and mapping errors onto fields

**Load:** Validação § 3 (resolver) and § 4 (errors); before that, the hub's § 5.3 and § 5.5 trees.

The schema is the single source, from client to server —.

**Check:**

- A rule **between** fields lives in `.refine`/`.superRefine`, not in a per-field `validate`
- `useForm`'s `resolver` and `validate` do not coexist → `RHF-VAL-01`
- A rule with I/O is an async `validate`, with `deps` if it depends on another field (Validação § 3.3)
- A server field error comes in through `setError`; a global error in `root.serverError` → `RHF-ERR-02` — read the caveats in Validação § 4.2 before assuming it survives revalidation
- An **expected** error is state, never an exception thrown from the `onSubmit` → `REACT-ASYNC-09`; an **unexpected** one rises to the feature's Error Boundary → `REACT-PAT-06`
- Client validation is UX, not a guarantee: the server revalidates and authorizes → `REACT-RSC-06`

The last two are the **canonical** ones (hub § 6.2). `RHF-ERR-03` and `RHF-CORE-05` are aliases and do not appear in a review that crosses docs.

---

## 4. Conditional fields and dynamic lists

**Load:** Estado; before that, the hub's § 5.2 tree to choose **how** to read the value that decides the condition.

**Conditional.** The value governing the condition is read with `useWatch` in the smallest component that needs it, never with `watch` at the root → `RHF-PERF-01`. For a field that unmounts, `shouldUnregister` is a conscious decision (does the value disappear or stay?), and `defaultValues` still has to cover it → `RHF-CORE-01`.

**List.** `useFieldArray` with `key={field.id}` → `RHF-ARRAY-01`. An index as the `key` is the antipattern in [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) § 8 **with a local aggravating factor**: the names are already indexed (`items.0.name`, `RHF-REG-01`), so the index in the `key` and the index in the name blur together in the bug. If the list is long, the cost is node volume (§ 5.6, step 5): virtualize or paginate.

**Wizard.** The step belongs to the URL → `REACT-PAT-10` and `tanstack-router`. The form holds values; the route holds **where the user is**.

---

## 5. Submitting

A single owner → `RHF-BRIDGE-01`. `<form action={...} onSubmit={handleSubmit(...)}>` is the bug where the order of execution stops being yours.

**a) A TanStack Query mutation** (there is a cache to invalidate) — hub § 8.2:

- `handleSubmit` validates and calls `mutateAsync` **inside it**; `mutateAsync` throws, so a `try/catch` is required (`TSQ-MUT-04`) and the expected failure comes back through `setError`
- The mutation owns the send, the cache and the **optimism** → `RHF-BRIDGE-04`, which is canonical and is **not** an alias of `REACT-FORM-07`: that one is about `useOptimistic` not being the source of truth, and it does not replace this one (hub § 6.2). Optimism in the form, never
- What the write made stale is the mutation's decision → `tanstack-query`
- Filling in with remote data is not a static `defaultValues`: it is `values` + `resetOptions.keepDirtyValues` → `RHF-BRIDGE-03` (an alias of `REACT-PAT-03`)

**b) A Server Function / Server Action** — hub § 8.1:

- The dispatch leaves from inside the `handleSubmit`; no `<form action>`, no bridge through a `useEffect` → `RHF-BRIDGE-02`
- `useActionState`'s `state` and `isPending` are read directly in the JSX; copying them into the form creates a second state that diverges
- Only the **field** error comes back to the form, through `setError` → `RHF-ERR-02`
- The server function is a public endpoint: it authenticates, validates and authorizes → `REACT-RSC-06`

**After the submit:** `reset` in a `useEffect` observing `isSubmitSuccessful`, not inside the `onSubmit` → `RHF-STATE-02`.

---

## Related

- [React Hook Form](../../../../knowledge-base/docs/react-hook-form.md) — the hub: mental model, § 5 trees, § 6 rules
- [React Hook Form - Registro e Controle](../../../../knowledge-base/docs/react-hook-form-registro-e-controle.md) · [React Hook Form - Validação e Resolvers](../../../../knowledge-base/docs/react-hook-form-validacao-e-resolvers.md) · [React Hook Form - Estado e Performance](../../../../knowledge-base/docs/react-hook-form-estado-e-performance.md) — one at a time
- `dono-da-submissao.md` — who disables the button
- `diagnostico.md` — symptom → cause → satellite
