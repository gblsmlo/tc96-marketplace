# Who owns the submission state

With TanStack Query in the flow there are **two** states saying "it is saving":
`formState.isSubmitting` (RHF) and `isPending` (the mutation). Pick one and use the **same** one
across the whole screen — button, text, `disabled`, spinner.

| Situation | Owner | Why |
| --- | --- | --- |
| `handleSubmit` does `await mutateAsync(...)` and is the only write path | `isSubmitting` | it covers the entire `await`, including the refetch if the callback returns the Promise (`TSQ-MUT-02`) |
| The same mutation fires from elsewhere (retry, another screen, optimism) | `isPending` | the state belongs to the mutation; the form is just one of the triggers |
| A Server Function with `useActionState` | `useActionState`'s `isPending` | `isSubmitting` is not read |

**Do not write `disabled={isSubmitting || isPending}`.** It looks defensive and it is the symptom that
nobody decided: the two diverge between the end of the `await` and the end of the invalidation, and the button
flickers or unlocks early.

The precedent is `REACT-FORM-07` — when two layers describe the same state, one is the
truth and the other is noise. It is the same mistake `RHF-BRIDGE-04` forbids for **optimism**,
applied to the **waiting** state; they are distinct rules and citable separately (hub § 6.2).

**Leave the choice recorded next to the handler**, in one line. Probe 11 in `sondas.sh`
looks for exactly the `||` that appears when it was not made.

---

## Related

- [React Hook Form](../../../../knowledge-base/react-hook-form.md) § 5.4 and § 8 — the submission trees and the bridges
- `tanstack-query` — what the write made stale in the cache
- `tarefas.md` § 5 — submitting
