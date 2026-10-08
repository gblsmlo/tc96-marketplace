---
titulo: React - Forms and Actions
Link: https://react.dev/reference/react/useActionState
tags:
  - react
  - forms
  - actions
  - agent-context
source: "Official React documentation — useActionState, useOptimistic, useFormStatus"
verificado-em: 2026-08-14
---

# React — Forms and Actions

> `useActionState` · `useOptimistic` · `useFormStatus` · `<form action>`
>
> React's Actions model: submission, pending state, errors and optimistic feedback without managing four `useState`s per form.

Entry: [React.js](react-js.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. Concept: Action

An **Action** is a function (often `async`) passed to React to run an operation, with React managing pending state, errors and ordering. It runs inside a Transition — hence the natural integration with `isPending` and with Suspense.

It replaces the manual pattern:

```tsx
// BEFORE — four states coordinated by hand
const [isLoading, setIsLoading] = useState(false)
const [error, setError] = useState<string | null>(null)
const [data, setData] = useState<Result | null>(null)

async function handleSubmit(e: React.FormEvent) {
  e.preventDefault()
  setIsLoading(true)
  setError(null)
  try {
    setData(await submit(new FormData(e.currentTarget)))
  } catch (err) {
    setError((err as Error).message)
  } finally {
    setIsLoading(false)
  }
}
```

> **Verified at the source:** `useActionState` **works in plain React, with no framework**. Only the `permalink` parameter (progressive enhancement) requires a framework with Server Components. That makes Actions usable in a Vite SPA, not only in Next.js.
>
> **Version requirement:** the whole Actions model — `useActionState`, `useOptimistic`, `useFormStatus`, `<form action>` — arrived in **React 19**. None of it exists in React 18 (`useFormState`, the predecessor of `useActionState`, only existed in canary with a framework). Confirm the version before using it.

---

## 2. `<form action>`

```tsx
<form action={myAction}>
  <input name="title" />
  <button type="submit">Save</button>
</form>
```

The function receives the form's `FormData`. React:

- prevents the default behavior automatically — **no `e.preventDefault()`**;
- wraps the submission in a Transition, with no manual `startTransition`;
- resets the uncontrolled form after a successful Action.

`formAction` on `<button>` and `<input type="submit">` allows different actions in the same form.

| ID | Rule |
| --- | --- |
| `REACT-FORM-01` | With `<form action>`, **NEVER** call `e.preventDefault()` — React already prevents it. |
| `REACT-FORM-02` | Fields the Action reads **MUST** have a `name`; `FormData` is keyed by `name`, not by id or by state. |

---

## 3. `useActionState`

```tsx
const [state, formAction, isPending] = useActionState(action, initialState, permalink?)
```

| Return | What it is |
| --- | --- |
| `state` | `initialState` the first time; afterwards, the action's return value |
| `formAction` | the function to pass to the form's `action` (or to dispatch manually) |
| `isPending` | `true` while any dispatched action is pending |

The action receives `(previousState, payload)` — with `<form action>`, the payload is the `FormData`.

```tsx
import { useActionState, useId } from 'react'
import { z } from 'zod'

const topicSchema = z.object({
  title: z.string().min(5, 'The title must be at least 5 characters long.'),
})

type FormState = {
  ok: boolean
  message?: string                          // general error (network, 500)
  fieldErrors?: Record<string, string>      // per-field error
}

async function createTopic(_prev: FormState, formData: FormData): Promise<FormState> {
  // formData.get() returns string | File | null — coerce before validating
  const parsed = topicSchema.safeParse({ title: String(formData.get('title') ?? '') })

  if (!parsed.success) {
    // flatten() returns { fieldErrors: Record<string, string[]> } — we take the 1st message
    const { fieldErrors } = z.flattenError(parsed.error)
    return {
      ok: false,
      fieldErrors: Object.fromEntries(
        Object.entries(fieldErrors).map(([field, msgs]) => [field, msgs![0]]),
      ),
    }
  }

  try {
    await api.createTopic(parsed.data)
    return { ok: true }
  } catch {
    // an unexpected failure becomes a message, not an exception: throwing would take down the form
    return { ok: false, message: 'Could not save. Try again.' }
  }
}

function NewTopic() {
  const [state, formAction, isPending] = useActionState(createTopic, { ok: false })
  const id = useId()
  const error = state.fieldErrors?.title

  return (
    <form action={formAction}>
      <label htmlFor={`${id}-title`}>Title</label>
      <input
        id={`${id}-title`}
        name="title"
        aria-invalid={!!error}
        aria-describedby={error ? `${id}-title-error` : undefined}
      />
      {error && <p id={`${id}-title-error`} role="alert">{error}</p>}

      {state.message && <p role="alert">{state.message}</p>}
      {state.ok && <p role="status">Topic created.</p>}

      <button disabled={isPending}>{isPending ? 'Saving…' : 'Save'}</button>
    </form>
  )
}
```

Four decisions in the example that are not obvious:

- **`String(... ?? '')`** — `formData.get()` returns `string | File | null`. An empty field returns `''`, a missing field returns `null`; the schema needs to receive a string.
- **IDs via `useId`** — `aria-describedby` has to point to the error paragraph, and the ID has to be stable between server and client. See `REACT-UTIL-01` in [React - Utility Hooks](react-utility-hooks.md).
- **`role="alert"` for errors, `role="status"` for success** — the first interrupts the screen reader, the second waits for a pause. A submission error justifies the interruption; a confirmation does not.
- **A network failure becomes a `message`, not an exception** — throwing would trigger the Error Boundary and remove the form from the screen, along with what the user typed.

The key pattern: **an expected error is returned as state, not thrown.** Throwing sends the error to the Error Boundary and takes down the form's UI — the wrong behavior for "title is required". `REACT-ASYNC-09`.

### Verified caveats

| Caveat | Practical consequence |
| --- | --- |
| Dispatches are queued and run in sequence | rapid submissions don't compete |
| Outside `<form action>`, the dispatch **MUST** run in `startTransition` | a manual call requires the wrapper |
| `formAction` has a stable identity | safe to omit from Effect dependencies |
| If the action throws, React cancels the queue and triggers the Error Boundary | an expected error must be returned, not thrown |
| In `<StrictMode>` the action is **not** invoked twice | it may have side effects, unlike a reducer |
| With Server Functions, `initialState` and payload **MUST** be serializable | no classes or functions in the state |
| When setting state after an `await`, wrap it in a new `startTransition` | `REACT-PERF-06` |

| ID | Rule |
| --- | --- |
| `REACT-FORM-03` | Every **expected** error **MUST** be returned in the action's state, never thrown. This applies to validation, but also to conflict (409), not found (404), forbidden (403) and network failure — anything the form knows how to present. Only a genuinely unexpected error goes up to the boundary. Alias of `REACT-ASYNC-09`. |
| `REACT-FORM-04` | A dispatch outside `<form action>` **MUST** happen inside `startTransition`. |

---

## 4. `useFormStatus`

```tsx
import { useFormStatus } from 'react-dom'

const { pending, data, method, action } = useFormStatus()
```

Reads the status of the **ancestor** `<form>`. The only Hook exported by `react-dom`.

```tsx
function SubmitButton() {
  const { pending } = useFormStatus()
  return <button disabled={pending}>{pending ? 'Submitting…' : 'Submit'}</button>
}

// It must be INSIDE the form, in a separate component
<form action={myAction}>
  <input name="email" />
  <SubmitButton />
</form>
```

**The restriction that breaks naive use:** the Hook reads an ancestor form. Called in the same component that renders the `<form>`, it does not see that form and `pending` is always `false`. A child component is mandatory.

| ID | Rule |
| --- | --- |
| `REACT-FORM-05` | `useFormStatus` **MUST** be called in a component that is a descendant of the `<form>`, never in the component that renders it. |

**Which one to use, with a precedence rule:** if the component already has `isPending` from `useActionState` in scope, use it — it is one less dependency and does not depend on position in the tree. `useFormStatus` exists for the case where that information **cannot be passed as a prop**: a design-system `<SubmitButton>`, used in forms you don't control. If the button is reusable **and** you control the form, prefer passing `isPending` as a prop; explicit beats implicit.

---

## 5. `useOptimistic`

```tsx
const [optimisticState, setOptimistic] = useOptimistic(value, reducer?)
```

Shows the expected result **immediately**, while the Action is pending.

```tsx
function Messages({ messages, send }: Props) {
  const [optimistic, addOptimistic] = useOptimistic(
    messages,
    (state: Message[], newText: string) => [...state, { text: newText, pending: true }],
  )

  async function action(formData: FormData) {
    const text = String(formData.get('text'))
    addOptimistic(text)                // shows up right away
    await send(text)                   // on completion, converges to `messages`
  }

  return (
    <>
      {optimistic.map((m, i) => (
        <p key={i}>{m.text}{m.pending && ' (sending…)'}</p>
      ))}
      <form action={action}><input name="text" /></form>
    </>
  )
}
```

Verified caveats:

- the setter **must** be called inside a Transition or an Action, otherwise React warns and the optimistic state reverts immediately;
- the optimistic state only exists while the Action is pending;
- the setter **cannot** be called during render;
- there is no extra render to "clear" the optimistic state — optimistic and real converge in the same render.

Rollback is automatic: if the Action fails, the state goes back to `value`. This differs from an optimistic cache mutation, where snapshot and rollback are explicit.

| ID | Rule |
| --- | --- |
| `REACT-FORM-06` | The `useOptimistic` setter **MUST** be called inside an Action or Transition. |
| `REACT-FORM-07` | `useOptimistic` is **NEVER** a source of truth — the truth is `value`, which converges at the end of the Action. |

---

## 6. Bridge to the stack

| Scenario | Tool |
| --- | --- |
| Simple form, few fields, validation on submit | the native Actions in this note |
| Complex form: per-field validation, arrays, wizard | React Hook Form — [React Hook Form](react-hook-form.md) § 5.4 decides the boundary |
| Schema validation (client and server) | one Zod schema shared by both — § 3 of this note and [Feature-Based Architecture](feature-based-architecture.md) § 5.1 |
| Remote mutation with a cache to invalidate | TanStack Query mutation |
| Optimistic update over a remote cache | optimistic mutation, not `useOptimistic` |
| Server-side operation | a Server Function — [React - Server Components and Directives](react-server-components-and-directives.md) § 3 |

**No-stacking criterion:** `useOptimistic` and the Query's optimistic mutation solve the same problem in different layers. If the data lives in the Query cache, the optimism belongs to the mutation. Using both produces two diverging sources of truth.

| ID | Rule |
| --- | --- |
| `REACT-FORM-08` | Every server function invoked by an Action **MUST** revalidate and authorize at the boundary, regardless of client-side validation. |

---

## 7. Antipatterns

| Antipattern | Fix |
| --- | --- |
| `e.preventDefault()` with `<form action>` | remove · `REACT-FORM-01` |
| Fields without `name` read via `FormData` | add `name` · `REACT-FORM-02` |
| Throwing a validation error from the action | return it in the state · `REACT-FORM-03` |
| `useFormStatus` in the same component as the `<form>` | extract a child component · `REACT-FORM-05` |
| `setOptimistic` outside an Action/Transition | wrap it · `REACT-FORM-06` |
| `useState` mirroring the action's state | use `state` from `useActionState` |
| `useOptimistic` + optimistic mutation together | pick one layer |
| Trusting only client-side validation | validate on the server · `REACT-FORM-08` |

---

## Related

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Suspense and Async](react-suspense-and-async.md) · [React - Server Components and Directives](react-server-components-and-directives.md)
- [React Hook Form](react-hook-form.md) — the alternative for complex forms, with the selection criterion in § 5.4

## Sources consulted

Verified on 2026-08-14:

- [useActionState](https://react.dev/reference/react/useActionState) — caveats and framework independence confirmed
- [useOptimistic](https://react.dev/reference/react/useOptimistic) — confirmed stable
- [useFormStatus](https://react.dev/reference/react-dom/hooks/useFormStatus)
- [`<form>`](https://react.dev/reference/react-dom/components/form)
