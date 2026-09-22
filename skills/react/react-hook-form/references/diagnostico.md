# Diagnosis — symptom → likely cause → satellite

> A **likely** cause: the table shortens the search, it does not close the diagnosis. Confirm in the code
> before reporting, and cite `file:line`.

---

## "The form re-renders too much"

**Step zero, normative: did you measure?** The Profiler before changing anything — § 5.6, step 0,
and `REACT-PERF-01`. The order in § 5.6 is mandatory and **does not start with memoization**.

| Symptom | Likely cause | Where | Probe |
| --- | --- | --- | --- |
| The whole screen renders on every keystroke | `watch` with no argument at the root (`RHF-PERF-01`) | Estado | 1 |
| A render per character in a simple field | `useState` mirroring the field (`REACT-PAT-01`), or `Controller` where `register` would do (`RHF-CORE-03`) | hub § 2 · Registro | 9 |
| A component that only displays an error renders with the whole form | `formState` read at the top and passed as a prop (`RHF-STATE-01`) | Estado | 4 |
| Autosave, analytics or logging causing renders | `watch(callback)`, deprecated — use `subscribe` (`RHF-PERF-02`) | Estado | 2 |
| A slow list even with `memo` on the row | node volume, not computation (§ 5.6, step 5) | Estado | — |

---

## "My field does not validate / does not submit"

| Symptom | Likely cause | Where | Probe |
| --- | --- | --- | --- |
| `errors` does not update, but the initial value is right | `formState` accessed conditionally — the Proxy did not subscribe (`RHF-CORE-02`) | hub § 2 | — |
| In a child component, the state freezes after the first render | `formState` from `useFormContext` instead of `useFormState` (`RHF-STATE-01`) | hub § 5.2 | 4 |
| The field does not reach the submit | not registered, or a name with brackets (`RHF-REG-01`) | Registro | — |
| A controlled UI field submits empty, or loses `onBlur`/focus | `field` not spread (`RHF-CTRL-01`), or double registration (`RHF-CORE-04`) | Registro | 8 |
| An input switches from uncontrolled to controlled | a field outside `defaultValues` (`RHF-CORE-01`), or an `onChange` with `undefined` (`RHF-CORE-06`) | hub § 2 | 3 |
| A number arrives as a string on the server | missing coercion (`RHF-REG-03`) | Registro | — |
| `useForm`'s `validate` never runs | there is a `resolver` — they are exclusive (`RHF-VAL-01`) | Validação | — |
| It submits twice, or in an unpredictable order | two owners: `<form action>` with `onSubmit` (`RHF-BRIDGE-01`) | hub § 5.4 | 5 |
| A server error appears and disappears on the next keystroke | `setError` under revalidation — the caveats of `RHF-ERR-02` | Validação § 4.2 | — |
| `isSubmitSuccessful` is wrong, or the form does not reset | an expected error thrown in the `onSubmit` (`REACT-ASYNC-09`), or a `reset` outside the Effect (`RHF-STATE-02`) | Validação · Estado | 6 |
| `setValue` on mount does nothing | the subscription is not ready yet — see `isReady` (v7.56.0) | the hub's verification note | — |

---

## What is **not** this skill's diagnosis

| Symptom | Go to |
| --- | --- |
| the screen goes back to the old value after saving | the cache: `tanstack-query` |
| the wizard loses the step on refresh | the step belongs to the URL: `tanstack-router` (`REACT-PAT-10`) |
| the surrounding component violates purity or the Rules of Hooks | `react-review` — `REACT-PURE-*` and `REACT-HOOK-*` take precedence (hub § 7, invariant 4) |
| the form should not be using RHF at all | Step 0 of the skill; if the answer is native Actions, `react-developer` |

---

## Related

- `tarefas.md` — the task corresponding to each cause
- `mapa-de-ids.md` — where each `RHF-*` is declared, and what is an alias
- [React Hook Form - Estado e Performance](../../../../knowledge-base/docs/react-hook-form-estado-e-performance.md) — the satellite that closes most of these cases
