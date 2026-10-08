---
titulo: React Hook Form - Validation and Resolvers
Link: https://react-hook-form.com/docs/useform
tags:
  - react
  - forms
  - react-hook-form
  - zod
  - validation
  - agent-context
source: "Official React Hook Form documentation — useForm, setError, trigger, resolvers"
verificado-em: 2026-08-15
---

# React Hook Form — Validation and Resolvers

> `mode` · `resolver` · `zodResolver` · `setError` · `trigger` · server errors
>
> What is valid, when it is checked, and what happens to what the server rejects.

Entry: [React Hook Form](react-hook-form.md) · Concept:

---

## 1. Concept: three layers, one source

RHF offers three ways to say what is valid — and they **do not add up freely**.

| Layer | Where it lives | Coexists with a resolver? |
| --- | --- | --- |
| Per-field rules | `register('x', { required, min, … })` | No — the resolver takes over validation |
| External schema | `useForm({ resolver: zodResolver(schema) })` | it is the layer itself |
| Form-level validation | `useForm({ validate })` (v7.72.0) | **No — mutually exclusive** |

> **Verified in the source:** the `validate` option of `useForm` **does not run when a `resolver` is configured**. They are alternatives, not complements. Writing both does not raise an error — the second one is simply ignored, which is worse.

**This doc's recommendation is the resolver with a schema**, for a reason that is not convenience: the same schema validates on the client and on the server, and the form's type derives from it. Inline rules remain legitimate for a small form in a project that has no schema — they are not an antipattern, they are a choice with less reach.

The fourth layer is not optional and is not on this list: **the server**. Client validation is a UX boundary. `RHF-CORE-05`.

---

## 2. When to validate

### 2.1 `mode` and `reValidateMode`

`mode` applies **before** the first submit. `reValidateMode` applies **after**.

| `mode` | Fires | Typical use |
| --- | --- | --- |
| `'onSubmit'` *(default)* | on submit | the right default for most |
| `'onBlur'` | when leaving the field | long form, without punishing whoever is typing |
| `'onChange'` | on every keystroke | **the source warns about the performance impact** |
| `'onTouched'` | first blur, then on every change | the best UX balance in practice |
| `'all'` | blur and change | rarely justifiable |

`reValidateMode` accepts `'onChange'` (default), `'onBlur'`, `'onSubmit'`.

**The combination that solves most cases** is `mode: 'onTouched'`: the user sees no error while filling in for the first time, but gets immediate correction after having already made a mistake there. Plain `onChange` flags "invalid email" on the first character typed.

Since v7.56.0, `mode` and `reValidateMode` are **reactive** — changing them at runtime takes effect.

### 2.2 `criteriaMode` and `delayError`

`criteriaMode: 'all'` collects **all** the errors of each field instead of only the first, and exposes them in `errors.field.types`. It only makes sense when the UI actually displays the list (a password requirements checklist is the classic case).

`delayError: 500` delays the **display** of the error. Fixing the input clears the error instantly, without waiting for the delay — the delay punishes only the appearance, which is exactly what you want.

### 2.3 Rules — `RHF-VAL-*` (when)

| ID | Rule |
| --- | --- |
| `RHF-VAL-01` | `resolver` and `useForm`'s `validate` **NEVER** coexist — the source states that `validate` does not run with a resolver present. |
| `RHF-VAL-03` | `mode: 'onChange'` **MUST** have a recorded justification; the working default is `'onSubmit'` or `'onTouched'`. |

---

## 3. Resolver with Zod

```bash
npm install @hookform/resolvers zod
```

```tsx
import { useId } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const signUpSchema = z.object({
  name: z.string().min(2, 'Enter at least 2 characters.'),
  email: z.email('Invalid email.'),
  password: z.string().min(8, 'Minimum of 8 characters.'),
  confirmation: z.string(),
}).refine((d) => d.password === d.confirmation, {
  message: 'The passwords do not match.',
  path: ['confirmation'],          // ✅ without this the error becomes a root error
})

type SignUp = z.infer<typeof signUpSchema>   // ✅ derived type, not hand-written

export function SignUpForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<SignUp>({
    resolver: zodResolver(signUpSchema),
    mode: 'onTouched',
    defaultValues: { name: '', email: '', password: '', confirmation: '' },
  })

  const id = useId()

  return (
    <form onSubmit={handleSubmit(async (data) => { await createAccount(data) })}>
      <label htmlFor={`${id}-name`}>Name</label>
      <input
        {...register('name')}
        id={`${id}-name`}
        aria-invalid={errors.name ? true : undefined}
        aria-describedby={errors.name ? `${id}-name-error` : undefined}
      />
      {errors.name && (
        <p id={`${id}-name-error`} role="alert">{errors.name.message}</p>
      )}
      {/* the other fields follow the same label/aria-describedby pair.
          In production, extract this into a field component:
          [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) § 3.3 */}
      <button disabled={isSubmitting}>Create account</button>
    </form>
  )
}
```

Three decisions:

- **`path: ['confirmation']` in the `refine`** — without it, the comparison error belongs to no field and ends up in `errors.root`, where the field does not display it. It is the most common cause of "validation runs but nothing shows up".
- **`z.infer` instead of a hand-written `interface`** — `RHF-VAL-04`. Two declarations of the same shape diverge on the first field added.
- **Complete `defaultValues`** — `RHF-CORE-01`. The schema defines what is valid; `defaultValues` defines what exists.

### 3.1 The `.transform()` and `.default()` gotcha

If the schema transforms, the **input** type and the **output** type stop being the same. `z.infer` returns the output one — and the form works with the input one.

```tsx
const schema = z.object({
  age: z.string().transform(Number),          // string in, number out
  active: z.boolean().default(true),          // may not exist in the input
})

// ❌ a single generic: the types clash and handleSubmit gets the wrong type
useForm<z.infer<typeof schema>>({ resolver: zodResolver(schema) })

// ✅ the three generics: input, context, output
useForm<z.input<typeof schema>, unknown, z.output<typeof schema>>({
  resolver: zodResolver(schema),
})
```

The third generic is what makes `handleSubmit` deliver the data **already transformed**. It is one of the three rules in this structure that depend on types, along with `RHF-VAL-04` and `RHF-CTRL-07`.

### 3.2 What a resolver is, underneath

A function that receives the values and returns `{ values, errors }`. This matters at two moments: when writing a custom resolver, and when interpreting an error-mapping bug.

**The resolver's error structure is hierarchical, not flat** — the source is explicit:

```ts
// ✅
{ participants: [null, { name: { type: 'required', message: '…' } }] }

// ❌ does not work
{ 'participants.1.name': { … } }
```

Other verified points: the resolver function is **cached**; during interaction, revalidation happens **one field at a time**; and parent-level error checking is limited to the direct parent.

`context` (the `useForm` option) reaches the resolver as the second argument — it is the path to validate against something that changes at runtime without recreating the schema (user role, feature flag, etc.).

### 3.3 Async validation: where it lives depends on whether there is a resolver

This is the point in the doc where careless reading produces code that never runs. The `resolver` reference states that it **"cannot be used with built-in validators"** — and the `register` `rules`, **`validate` included**, are built-in validators.

> **With a `resolver` configured, the `register` `rules` do not run — neither `validate` nor `deps`.** The symptom is the worst possible: no error, no exception, the function is simply never called. Since this doc recommends a resolver (§ 1), this is the default case, not the exception.

**With a resolver**, a rule that requires I/O (email uniqueness, valid coupon) has two paths:

**Path 1 — async inside the schema.** Consistent with "the schema is the source". The adapter accepts `mode: 'async'`.

```tsx
const signUpSchema = z.object({
  email: z.email('Invalid email.').refine(
    async (email) => await isEmailAvailable(email),
    { message: 'This email is already in use.' },
  ),
})
```

**Path 2 — only on submission, via `setError`.** Often the best: one call per submit instead of one per interaction, and the server is the authority anyway. See § 4.3.

**Without a resolver**, the path is the `register`'s `validate`:

```tsx
<input {...register('email', {
  validate: async (email) =>
    (await isEmailAvailable(email)) || 'This email is already in use.',
})} />
```

While either of them runs, `isValidating` stays `true`, and `validatingFields` (v7.51.0) tells **which** fields are in flight — which allows a per-field spinner instead of blocking the form.

> **The cost the source does not mention and that bites in production.** `mode: 'onTouched'` has a default `reValidateMode` of `'onChange'`: after the first error, it is **one API call per keystroke**. Per-field async validation requires debounce and cancellation (`AbortController`), otherwise the old response arrives after the new one and overwrites the result. That is a `race condition`, the same problem described in [React.js](react-js.md) § 1. Neither is provided by RHF. If you are not going to implement them, use Path 2.

**Fields that depend on another field.** `deps` revalidates the neighbor along with it — but, being a `register` `rule`, it has the same restriction as above:

```tsx
// Without a resolver:
<input {...register('confirmation', { deps: ['password'] })} />

// With a resolver: the cross-field rule goes into the schema, with path (RHF-VAL-05),
// and revalidation of the neighbor is forced through trigger.
await trigger('confirmation')
```

`trigger` validates manually and returns `Promise<boolean>` — it is what a wizard uses to unlock the next step:

```tsx
const canProceed = await trigger(['name', 'email'])
```

> **Cost of `trigger`.** The source is specific: render isolation only holds when passing **a single name as a string**. Passing an array, or calling `trigger()` with no argument, re-renders the whole form state. In a wizard that is acceptable — it happens once per step. Inside an `onChange`, it is not.

### 3.4 Rules — `RHF-VAL-*` (schema)

| ID | Rule |
| --- | --- |
| `RHF-VAL-02` | A schema with `.transform()` or `.default()` **MUST** declare the three generics: `useForm<z.input<S>, unknown, z.output<S>>`. |
| `RHF-VAL-04` | The form's type **MUST** derive from the schema (`z.infer`/`z.input`); **NEVER** be written in parallel. |
| `RHF-VAL-05` | A rule that crosses fields **MUST** use `.refine()`/`.superRefine()` with `path`, **NEVER** a `validate` duplicated on both fields. |
| `RHF-VAL-06` | With a `resolver` active, `register` `rules` — `validate` and `deps` included — are **NEVER** used. A rule that requires I/O **MUST** go into the schema (async `.refine()`) or into submission (`setError`). |
| `RHF-VAL-10` | Per-field async validation **MUST** have debounce and cancellation, or be moved to submission. |
| `RHF-VAL-07` | `trigger` with an array or no argument **MUST** be restricted to step transitions; **NEVER** in a typing handler. |

---

## 4. Errors

### 4.1 The structure

```ts
errors.email                 // FieldError    → { type, message, types?, ref? }
errors.address?.city         // nested follows the form's shape
errors.items?.[0]?.name      // arrays by index
errors.items?.root           // error from the field array's own rules (v7.34.0)
errors.root?.serverError     // global error — belongs to no field
```

`errors.field.types` is only filled with `criteriaMode: 'all'`.

**`errors.root.*` has its own behavior, verified in the source: it does not persist across submissions.** That is convenient — the global error disappears by itself on the next attempt — and it is a trap if you were counting on it to display a persistent summary.

### 4.2 `setError` — and its two caveats

```tsx
setError('email', { type: 'server', message: 'Email already registered.' })
setError('root.serverError', { type: '503', message: 'Service unavailable.' })
setError('cpf', { type: 'server', message: '…' }, { shouldFocus: true })
```

Two things the source states that change the code's design:

**1. The error does not persist if the field passes the `register` rules.** A server error placed on a field **registered with validation** is erased on that field's next validation round. For "email already registered" that is even desirable (the user types another one, the error disappears). For an error that needs to survive, the place is `root.serverError`.

**2. `setError` forces `isValid` to `false` immediately** — but that value does not come from validation and will be overwritten on the next round. Do not use `isValid` as proof that the server accepted.

`shouldFocus` does not work on a disabled field.

### 4.3 Server errors: the complete flow

```tsx
const onSubmit = handleSubmit(async (data) => {
  try {
    await api.createAccount(data)
  } catch (e) {
    if (e instanceof ApiError && e.fieldErrors) {
      // 422 with per-field detail → each error on its field
      for (const [field, message] of Object.entries(e.fieldErrors)) {
        setError(field as FieldPath<SignUp>, { type: 'server', message })
      }
      return
    }
    // expected, but with no field: goes to the root
    setError('root.serverError', {
      type: String(e instanceof ApiError ? e.status : 'unknown'),
      message: 'Could not create the account. Try again.',
    })
  }
})
```

And in the UI:

```tsx
{errors.root?.serverError && (
  <p role="alert">{errors.root.serverError.message}</p>
)}
```

**Why `try/catch` and not let it throw:** the source says `handleSubmit` **does not swallow** exceptions from `onSubmit`. An exception that escapes bubbles up to the Error Boundary, removes the form from the screen along with everything the user typed, and leaves `isSubmitSuccessful` incorrect. An expected error is state. `REACT-ASYNC-09`.

**The exception to the exception:** a genuinely unexpected error — broken contract, bug — **must** bubble up. The distinction is: expected is what the UI knows how to present.

### 4.4 The `errors` option of `useForm`

Since v7.49.0, server errors can come in reactively, without `setError`:

```tsx
useForm({ errors: serverErrors })
```

Useful when the errors already live in external state (return of `useActionState`, mutation cache). **The source warns:** the object needs a **stable reference**, otherwise the form enters an infinite re-render. An inline object literal is precisely what breaks it.

### 4.5 `SubmitErrorHandler`

`handleSubmit` accepts a second callback, called when validation **fails**:

```tsx
handleSubmit(onValid, (errors) => {
  analytics.track('form_invalid', { fields: Object.keys(errors) })
})
```

It is the right place for form telemetry — and it avoids the `useEffect` observing `errors` that tends to show up in its place.

> **Scope of `RHF-ERR-04`, and the two time scales the source does not separate.** They are different things:
>
> | Where | Disappears when |
> | --- | --- |
> | `errors.<field>` set by `setError` | **that field** revalidates |
> | `errors.root.*` | there is a **new submission** |
>
> The source describes the first as "does not persist if the input passes the `register` rules". With a `resolver`, `register` has no rules (`RHF-VAL-06`) — but the field **is** validated, by the schema. What erases the error is the field's revalidation, whatever its source.
>
> **In practice:** "email already in use" on the field is the desired behavior (the user types another one, the error disappears). A 503 on the field would be erased by any typing — that is why it goes to `root`. And if you need a summary that **also** survives the new submission, neither works: that is your application's state, not the form's.

### 4.6 Rules — `RHF-ERR-*`

| ID | Rule |
| --- | --- |
| `RHF-ERR-01` | An expected error **MUST** be displayed by the form; **NEVER** by an uncaught exception. |
| `RHF-ERR-02` | A server error **MUST** come in through `setError`: a field error on the field, one with no field in `root.serverError`. |
| `RHF-ERR-03` | An expected error is **NEVER** thrown from inside `onSubmit` — `handleSubmit` does not swallow it and `isSubmitSuccessful` ends up wrong. Alias of `REACT-ASYNC-09`. |
| `RHF-ERR-04` | A server error that needs to survive revalidation **MUST** go to `root.*`. An error set on a field is erased when **that field** revalidates — and in a project with a `resolver` this holds for every field, since the schema validates all of them. See the scope note below. |
| `RHF-ERR-05` | `isValid` is **NEVER** used as proof of acceptance by the server. |
| `RHF-ERR-06` | The object passed to the `errors` option **MUST** have a stable reference — an inline literal causes infinite re-render. |
| `RHF-ERR-07` | Validation-failure telemetry **MUST** use `handleSubmit`'s second callback, **NEVER** a `useEffect` observing `errors`. |

---

## 5. Native browser validation

Two distinct options that are often confused — and that the source declares **independent**.

| Option | What it does |
| --- | --- |
| `shouldUseNativeValidation` (v7.9.0) | delegates display to the browser's Constraint Validation API; enables `:valid`/`:invalid` in CSS |
| `progressive` (v7.44.0) | **only** emits `required`, `min`, `max`, `minLength`, `maxLength` and `pattern` as HTML attributes in `register` |

`shouldUseNativeValidation` has verified restrictions: it only works with `mode` `onSubmit` or `onChange`, and each rule's message **must be a string**.

`progressive` is what serves progressive enhancement: the HTML leaves the server already carrying the attributes, and the form validates in the browser before hydration happens. It does not depend on `shouldUseNativeValidation`, nor the other way around.

| ID | Rule |
| --- | --- |
| `RHF-VAL-08` | `shouldUseNativeValidation` **MUST** come with `mode` `'onSubmit'` or `'onChange'` and string messages. |
| `RHF-VAL-09` | `progressive` is **NEVER** assumed to be equivalent to `shouldUseNativeValidation` — they are independent. |

---

## 6. Antipatterns

| Antipattern | Fix |
| --- | --- |
| `resolver` and `validate` in the same `useForm` | pick one · `RHF-VAL-01` |
| `interface FormData` written next to the schema | `z.infer` · `RHF-VAL-04` |
| `z.infer` with a schema that uses `.transform()` | three generics · `RHF-VAL-02` |
| `refine` without `path` | the error vanishes into the root · `RHF-VAL-05` |
| The same cross-field rule duplicated in two `validate`s | `.refine()` · `RHF-VAL-05` |
| `validate` in `register` with a resolver active — never runs | async `.refine()` or `setError` on submit · `RHF-VAL-06` |
| Async validation per keystroke, with no debounce or cancellation | debounce + `AbortController`, or move to submit · `RHF-VAL-10` |
| `trigger()` with no argument on every keystroke | single target, or only on the transition · `RHF-VAL-07` |
| `throw` of a validation error in `onSubmit` | `setError` · `RHF-ERR-03` |
| Server error in a `toast` and not in the form | `setError` · `RHF-ERR-02` |
| `setError` on a field with rules, expecting persistence | `root.serverError` · `RHF-ERR-04` |
| Inline `errors={{ … }}` literal in `useForm` | stable reference · `RHF-ERR-06` |
| `useEffect` observing `errors` for telemetry | `handleSubmit`'s 2nd callback · `RHF-ERR-07` |
| `mode: 'onChange'` as the project default | `'onTouched'` · `RHF-VAL-03` |
| Trusting client validation | revalidate on the server · `RHF-CORE-05` |

---

## Related

- [React Hook Form](react-hook-form.md) — entry, the tree in § 5.3 and § 5.5
- [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) · [React Hook Form - State and Performance](react-hook-form-state-and-performance.md)
- [React - Suspense and Async](react-suspense-and-async.md) — `REACT-ASYNC-09`, the canonical ID
- [React - Server Components and Directives](react-server-components-and-directives.md) § 3 — the same boundary, on the server side

## Sources consulted

Verified on 2026-08-15:

- [useForm](https://react-hook-form.com/docs/useform) — `mode`, `criteriaMode`, `delayError`, the resolver contract, `validate` × `resolver` exclusivity
- [setError](https://react-hook-form.com/docs/useform/seterror) — non-persistence on a field with rules, `root.serverError`, effect on `isValid`
- [trigger](https://react-hook-form.com/docs/useform/trigger) — render isolation only with a single name
- [handleSubmit](https://react-hook-form.com/docs/useform/handlesubmit) — exceptions are not swallowed; `SubmitErrorHandler`
- [formState](https://react-hook-form.com/docs/useform/formstate) — `isValidating`, `validatingFields`, `isValid` behavior
- [register](https://react-hook-form.com/docs/useform/register) — `validate`, `deps`
- [@hookform/resolvers](https://github.com/react-hook-form/resolvers) — `zodResolver`, typing of transformed values
- [TypeScript](https://react-hook-form.com/ts) — `Resolver`, `ValidateForm`, `useForm` generics
