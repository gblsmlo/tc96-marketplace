# Worked example

Task: *"approve an invoice on the detail screen, and the list has to reflect it"*.

**The tree that matters is "I wrote to the server. Now what?".** A write does not update the screen — invalidation does. No mutation leaves this skill without answering **what it made stale**.

**The inventory of what aged**, done before writing the mutation:

| Query | Aged? | Why |
| --- | --- | --- |
| `['invoices','detail',id]` | yes | the status changed |
| `['invoices','list']` | yes | the invoice leaves the "pending" filter |
| `['invoices','summary']` | yes | the pending total changed |
| `['customers',customerId]` | **no** | approving an invoice does not change the customer |
| `['users']` | no | unrelated |

```ts
const approve = useMutation({
 mutationFn: (id: string) => api.invoices.approve(id),

 // cache synchronization lives HERE, not in the mutate callbacks — TSQ-MUT-03
 onSuccess: async (_, id) => {
 // return the Promise: the mutation stays pending until the refetch finishes — TSQ-MUT-02
 await Promise.all([
 qc.invalidateQueries({ queryKey: ['invoices','detail',id] }),
 qc.invalidateQueries({ queryKey: ['invoices','list'] }),
 qc.invalidateQueries({ queryKey: ['invoices','summary'] }),
 ]);
 },
});

// navigating and notifying belong to mutate — they should not run if the component unmounts
approve.mutate(id, {
 onSuccess: => { toast.success('Invoice approved'); navigate({ to: '/invoices' }); },
});
```

**What each decision prevented:**

| Decision | The symptom it prevents | Rule |
| --- | --- | --- |
| `useMutation`, not `useQuery` | a POST fired by a render, and again on a refetch | `TSQ-MUT-01` |
| `await` / `return` on `invalidateQueries` | the button returning to "Approve" with a stale list, and the user clicking again | `TSQ-MUT-02` |
| invalidation in `useMutation` | closing the modal cancels the invalidation, and the cache stays dirty | `TSQ-MUT-03` |
| `toast` and `navigate` in `mutate` | a toast firing on a screen that is already gone | `TSQ-MUT-03` |
| `try/catch` if it were `mutateAsync` | an unhandled rejection | `TSQ-MUT-04` |
| no `retry` | approving a non-idempotent operation twice | `TSQ-MUT-05` |
| `['customers']` **left out** of the list | refetching data that did not change, on every approval | invariant 3 |

The last row is the one most often got wrong in the opposite direction: invalidating all of `['invoices']` for safety also redoes `['invoices','drafts']`, which nobody touched. Over-broad invalidation is the same defect as missing invalidation — only the symptom is slowness, not a stale screen.
