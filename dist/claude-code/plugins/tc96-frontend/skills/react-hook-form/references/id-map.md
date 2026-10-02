---
generated-by: skills/react/react-hook-form/scripts/generate-id-map.sh
generated-at: 2026-10-02
---

# ID map `RHF-*`

> An index, not a copy: it says **where** the rule is declared, never what it says.
> Regenerate with `bash skills/react/react-hook-form/scripts/generate-id-map.sh`.

## Citing across docs

Inside a form review, the `RHF-*` ID is enough. **When citing across docs**
— a React review that touches a form, or the other way round — use the canonical one,
or whoever fixes it will not find the text. The tables below come from § 6.2 of the hub.


**Citation rule:** inside a review restricted to forms, the `RHF-*` ID is enough and is what the satellites' tables use. **When citing across docs** — a React review that touches a form, or vice versa — use the canonical one, otherwise the reviewer cannot find the text.

| Principle | Canonical | Aliases |
| --- | --- | --- |
| An expected error is state, not an exception for a boundary | `REACT-ASYNC-09` ([React - Suspense and Async](../../../docs/react/react-suspense-and-async.md)) | `RHF-ERR-03`, `REACT-FORM-03`, `REACT-PAT-07` |
| The server revalidates and authorizes at the boundary | `REACT-RSC-06` ([React - Server Components and Directives](../../../docs/react/react-server-components-and-directives.md)) | `RHF-CORE-05`, `REACT-FORM-08`, `REACT-PAT-09` |

**`RHF-BRIDGE-04` is canonical**, with no equivalent in the React corpus: "optimism over a remote cache belongs to the mutation" is a boundary rule between RHF and TanStack Query. `REACT-FORM-07` deals with something else — that `useOptimistic` is not a source of truth — and must not be cited in its place.

Two more React principles that RHF does **not** redefine — cite the React ID:

| Principle | Canonical | Where RHF mentions it |
| --- | --- | --- |
| Remote data never becomes a local snapshot as the source of truth | `REACT-PAT-03` | `RHF-BRIDGE-03` is an alias — static `defaultValues` is exactly that |
| A stale request needs cancellation | `REACT-EFFECT-06` | `RHF-VAL-10` is an alias — async validation has the same race condition |
| A derivable value never becomes its own state | `REACT-PAT-01` | it is **step 1** of the re-render investigation order ("is there a `useState` mirroring a field?"), which appears in three notes without an ID. Cite `REACT-PAT-01` |

And RHF's own internal pairs, where the same norm appears in more than one place:

| Principle | Canonical | Alias |
| --- | --- | --- |
| `field.onChange` never receives `undefined` | `RHF-CORE-06` | `RHF-CTRL-02` |
| Under `FormProvider`, state comes from `useFormState` | `RHF-STATE-01` | `RHF-CTX-01` |
| Global `shouldUnregister` is incompatible with `useFieldArray` | `RHF-ARRAY-03` | `RHF-CTRL-06` |
| An expected error does not bubble up as an exception from `onSubmit` | `RHF-ERR-03` | `RHF-ERR-01` — same norm, same table, two IDs |
| A post-submission `reset` requires a real success signal | `RHF-STATE-02` | `RHF-STATE-09` — the predicate is already in `-02` |
| The form's type derives from the schema | `RHF-VAL-04` | `RHF-STEP-02` |
| Does the component forward `ref`? decides `register` × `Controller` | `RHF-CORE-03` | `RHF-CTRL-08` is the other half of the same predicate |


## Full index

| ID | Satellite | Section |
| --- | --- | --- |
| `RHF-A11Y-01` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 5. Accessibility |
| `RHF-A11Y-02` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 5. Accessibility |
| `RHF-A11Y-03` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 5. Accessibility |
| `RHF-A11Y-04` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 5. Accessibility |
| `RHF-ARRAY-01` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-02` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-03` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-04` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-05` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-06` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 6. `useFieldArray` |
| `RHF-BRIDGE-01` | [React Hook Form](../../../docs/react/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-BRIDGE-02` | [React Hook Form](../../../docs/react/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-BRIDGE-03` | [React Hook Form](../../../docs/react/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-BRIDGE-04` | [React Hook Form](../../../docs/react/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-BRIDGE-05` | [React Hook Form](../../../docs/react/react-hook-form.md) | 8. Bridges to the stack |
| `RHF-CORE-01` | [React Hook Form](../../../docs/react/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-02` | [React Hook Form](../../../docs/react/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-03` | [React Hook Form](../../../docs/react/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-04` | [React Hook Form](../../../docs/react/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-05` | [React Hook Form](../../../docs/react/react-hook-form.md) | 6. Normative rules |
| `RHF-CORE-06` | [React Hook Form](../../../docs/react/react-hook-form.md) | 6. Normative rules |
| `RHF-CTRL-01` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-02` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-03` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3.5 Rules — `RHF-CTRL-*` |
| `RHF-CTRL-04` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-05` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-06` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-07` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-08` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-09` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-10` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-11` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-12` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTRL-13` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 3. `Controller` and `useController` |
| `RHF-CTX-01` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 4. `FormProvider` and `useFormContext` |
| `RHF-CTX-02` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 4. `FormProvider` and `useFormContext` |
| `RHF-CTX-03` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 4. `FormProvider` and `useFormContext` |
| `RHF-CTX-04` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 4. `FormProvider` and `useFormContext` |
| `RHF-ERR-01` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-02` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-03` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-04` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-05` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-06` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-ERR-07` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 4. Errors |
| `RHF-PERF-01` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-PERF-02` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-PERF-03` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-PERF-04` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-REG-01` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-REG-02` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-REG-03` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-REG-04` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-REG-05` | [React Hook Form - Registration and Control](../../../docs/react/react-hook-form-registration-and-control.md) | 2. `register` |
| `RHF-STATE-01` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-STATE-02` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-03` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-STATE-04` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-STATE-05` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 3. The five ways to read |
| `RHF-STATE-06` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-07` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-08` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-09` | [React Hook Form](../../../docs/react/react-hook-form.md) | 6. Normative rules |
| `RHF-STATE-10` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-11` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STATE-12` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 4. Writing, resetting and feeding from outside |
| `RHF-STEP-01` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-STEP-02` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-STEP-03` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-STEP-04` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-STEP-05` | [React Hook Form - State and Performance](../../../docs/react/react-hook-form-state-and-performance.md) | 7. Multi-step form |
| `RHF-VAL-01` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 2. When to validate |
| `RHF-VAL-02` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-03` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 2. When to validate |
| `RHF-VAL-04` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-05` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-06` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-07` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
| `RHF-VAL-08` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 5. Native browser validation |
| `RHF-VAL-09` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 5. Native browser validation |
| `RHF-VAL-10` | [React Hook Form - Validation and Resolvers](../../../docs/react/react-hook-form-validation-and-resolvers.md) | 3. Resolver with Zod |
