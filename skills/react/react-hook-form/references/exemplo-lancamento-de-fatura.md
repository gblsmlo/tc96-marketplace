# Worked example — entering an invoice

Task: *"an invoice entry form — a currency amount, a due date, and a justification field
that only appears when the amount goes above R$ 10,000"*.

---

## Step 0 — triage

Three fields, **validation between them**, a **conditional field** and a submit that
**invalidates the cache**. It crosses the "one field with no validation" boundary: it is RHF. Two of the five triggers
named — recording that in one sentence is what invariant 1 of the contract asks for.

## The order of decisions, which is not the order of the JSX

**1. Schema first** — the form's type derives from Zod, never the other way round (`RHF-VAL-04`).
The rule **between** fields lives in `.superRefine`, not in a per-field `validate`:

```ts
const schema = z.object({
 amount: z.coerce.number.positive, // the DOM returns a string — RHF-REG-03
 dueDate: z.coerce.date,
 justification: z.string.optional,
}).superRefine((v, ctx) => {
 if (v.amount > 10_000 && !v.justification?.trim)
 ctx.addIssue({ code: 'custom', path: ['justification'],
 message: 'Required above R$ 10,000' });
});
```

**2. `defaultValues` covering every field**, including the conditional one (`RHF-CORE-01`) —
`justification: ''`, not absent.

**3. `mode`** — here `onBlur`, because validating on every keystroke in a currency field fights the
mask. It is a declared decision, not a default by omission.

**4. Field by field through the § 5.1 tree.** `amount` and `dueDate` go through `register`; the
currency selector is a third-party controlled component → `Controller` (the exception, not the rule).

**5. Only then the submit's owner.** There is a cache to invalidate → a TanStack Query mutation
(`RHF-BRIDGE-01`):

```ts
const onSubmit = handleSubmit(async (data) => {
 try {
 await createInvoice.mutateAsync(data); // mutateAsync throws — TSQ-MUT-04
 } catch (e) {
 if (isValidationError(e))
 setError('amount', { message: e.field.amount }); // a field error — RHF-ERR-02
 else
 setError('root.serverError', { message: 'Failed to create' });
 }
});
```

And the conditional field reads the value in the **smallest component that needs it**:

```tsx
function Justification {
 const amount = useWatch({ name: 'amount' }); // not watch at the root — RHF-PERF-01
 if (amount <= 10_000) return null;
 return <TextField name="justification" />; // defaultValues already covers it — RHF-CORE-01
}
```

## What these decisions prevented

| Decision | Alternative that hurts later | Rule |
| --- | --- | --- |
| a type derived from the schema | a hand-written type, diverging from the Zod one | `RHF-VAL-04` |
| `z.coerce.number` | `amount` arrives as a string and `> 10_000` compares text | `RHF-REG-03` |
| `superRefine` for the cross-field rule | a `validate` on the justification, which cannot see the amount | Validação § 3 |
| `defaultValues` on the conditional field | the field goes from uncontrolled to controlled mid-flight | `RHF-CORE-01` |
| one owner of the submit | `<form action>` **and** `onSubmit` together — the order stops being yours | `RHF-BRIDGE-01` |
| `try/catch` around `mutateAsync` | an unhandled rejection, and the form stuck in `isSubmitting` | `TSQ-MUT-04` |
| an expected error through `setError` | throwing from the `onSubmit` to the Error Boundary | `REACT-ASYNC-09` |
| `useWatch` in the child | `watch` at the root: a re-render of the whole form on every keystroke | `RHF-PERF-01` |
| a single waiting state | `disabled={isSubmitting \|\| isPending}` | `dono-da-submissao.md` |

## What stays outside this skill

- What creating the invoice made stale in the cache is the **mutation's** decision —
 `tanstack-query`.
- **Optimism**, if any, belongs to the mutation with a snapshot and a rollback — `RHF-BRIDGE-04`,
 never to the form.
- Client validation here is UX; the server revalidates and authorizes — `REACT-RSC-06`.
