# Worked example — the robust variant: a server boundary

The same feature as the previous example, now with a **write**: approving an invoice.
What changes is not React — it is that there is a trust boundary in the middle.

> It applies to Server Functions (`'use server'`). In a Vite SPA without RSC, the boundary
> is the HTTP endpoint and the same three obligations hold there — see [React.js](../../../../knowledge-base/react-js.md) § 8.

---

## The rule that decides everything

`REACT-RSC-06` — a Server Function **MUST** authenticate, validate and authorize **in the function
itself**. It is a public endpoint: any client can call it with any argument.
Validation in the form is ergonomics, not security.

## The code

```tsx
// approve-invoice.ts
'use server';

const Input = z.object({ invoiceId: z.string.uuid }); // boundary validation

export async function approveInvoice(_state: ApprovalState, data: FormData) {
 const session = await readSession;
 if (!session) return { error: 'Session expired. Sign in again.' }; // 1. authenticate

 const parsed = Input.safeParse({ invoiceId: data.get('invoiceId') }); // 2. validate
 if (!parsed.success) return { error: 'Invalid invoice.' };

 const invoice = await repo.find(parsed.data.invoiceId);
 if (!invoice || invoice.orgId !== session.orgId) { // 3. authorize
 return { error: 'Invoice not found.' }; // the same message for both cases:
 } // do not reveal existence to someone who cannot see it

 if (invoice.status !== 'pending') {
 return { error: 'This invoice has already been processed.' }; // a conflict is expected → state
 }

 await repo.approve(invoice.id, session.userId);
 return { ok: true };
}
```

```tsx
// ApproveButton.tsx — a Client Component, as low as possible
'use client';

export function ApproveButton({ invoiceId }: { invoiceId: string }) {
 const [state, action] = useActionState(approveInvoice, {});

 return (
 <form action={action}> {/* no e.preventDefault */}
 <input type="hidden" name="invoiceId" value={invoiceId} /> {/* name, not state */}
 <Submit />
 {state.error && <p role="alert">{state.error}</p>} {/* an expected error is UI */}
 </form>
 );
}

function Submit {
 const { pending } = useFormStatus; // a descendant of the <form>, never the parent
 return <button disabled={pending}>{pending ? 'Approving…' : 'Approve'}</button>;
}
```

## Why each line is like this

| Decision | Rule |
| --- | --- |
| `'use server'` validates even with client-side validation | `REACT-RSC-06` |
| serializable arguments and return (`FormData`, a plain object) | `REACT-RSC-07` |
| session errors, conflicts and "not found" **return**, they do not throw | `REACT-FORM-03` / `REACT-ASYNC-09` |
| `'use client'` on the button, not on the page | `REACT-RSC-03` |
| no `e.preventDefault` with `<form action>` | `REACT-FORM-01` |
| `name` on the field the Action reads | `REACT-FORM-02` |
| `useFormStatus` in `<Submit>`, a descendant of the `<form>` | `REACT-FORM-05` |

## The question that decides the submission's owner

If the approval **invalidates** [TanStack Query](../../../../knowledge-base/tanstack-query.md) cache, the owner is Query's mutation, and the
form becomes an ordinary `<form>` with a handler. `useActionState` alone is enough when the
submission is isolated. Stacking the two — and adding `useOptimistic` over data that lives in the
cache — produces two sources of truth diverging (`REACT-FORM-07`). Criterion in
[React.js](../../../../knowledge-base/react-js.md) § 8.

## What an agent would write out of habit, and why it would fail

```tsx
// WRONG
export async function approveInvoice(id: string) {
 'use server';
 await repo.approve(id); // no session, no validation, no ownership check
} // REACT-RSC-06 — any id approves any invoice

// WRONG
if (invoice.status !== 'pending') throw new Error('already processed');
// REACT-ASYNC-09 — an expected error rising to the boundary: the whole screen falls
```
