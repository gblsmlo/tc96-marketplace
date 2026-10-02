---
titulo: React Hook Form - State and Performance
Link: https://react-hook-form.com/docs/useform/formstate
tags:
  - react
  - forms
  - react-hook-form
  - performance
  - agent-context
source: "Official documentation — https://react-hook-form.com/docs"
verificado-em: 2026-08-15
---

# React Hook Form — State and Performance

> **Covers:** `formState` and its Proxy · the five ways to read (`getValues`, `watch`, `useWatch`, `useFormState`, `subscribe`) · `setValue`, `reset`, `getFieldState` · `defaultValues` × `values` · `shouldUnregister` and `disabled` at the form level · `useFieldArray` · multi-step forms · the re-render investigation order.
>
> **Does not cover:** how a field enters the form (`register`, `Controller`, `useController`, `FormProvider`) — [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md). What is valid and what to do with an error (`mode`, `resolver`, `setError`, `trigger`) — [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md). Who owns the submission and the bridges to the stack — [React Hook Form](react-hook-form.md) § 5.4 and § 8.

Entry point: [React Hook Form](react-hook-form.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. Concept: the subscription is created by the read

RHF keeps values outside the render cycle. The consequence is that **nothing re-renders by default** — not while typing, not when an error appears. A component only re-renders if it subscribed to something.

And the subscription **is not declared: it is created by the read**. `formState` comes wrapped in a `Proxy` that records which properties were accessed **during render**, and only recomputes and notifies those. The source is literal:

> "Returned `formState` is wrapped with a Proxy to improve render performance and skip extra logic if a specific state is not subscribed to. Therefore, make sure you invoke or read it before a render in order to enable the state update."

```tsx
// ✅ the destructuring is the read — subscribes to isDirty and isValid
const { formState: { isDirty, isValid } } = useForm<Profile>()
return <button disabled={!isDirty || !isValid}>Save</button>

// ❌ isDirty is read and subscribed; isValid is NOT — the `||` short-circuits when
//    isDirty is true, so the Proxy never sees the read of isValid
const { formState } = useForm<Profile>()
return <button disabled={!formState.isDirty || !formState.isValid}>Save</button>
```

The two forms look identical, and the second is the most common cause of "the button does not enable". Note **exactly** where the defect is, because it is easy to learn the wrong lesson: the problem is **not** keeping the `formState` object — it is the **conditional access**. The source's own comment is precise: *"`formState.isValid` is accessed conditionally, so the Proxy does not subscribe to changes of that state."*

In other words, `const formState = useFormState({ control }); return <p>{formState.errors.name?.message}</p>` works: `errors` is read unconditionally. What breaks is the property that sits behind a `&&`, `||`, ternary or `if`. Destructuring at the top is the simplest way to never fall into this — not the only one.

This is not a bug: it is the mechanism avoiding computing `isValid` for whoever did not ask for it. `RHF-CORE-02`.

**Where the read happens defines where the re-render happens.** Everything else in this note is organized from that point: choosing between `watch` and `useWatch` is not choosing between two ways to read the same value — it is choosing **which component re-renders**.

> **Corollary for `useEffect`.** The source states that "`formState` is updated in batch. If you want to subscribe via `useEffect`, make sure that you place the entire `formState` in the optional array." The correct dependency is the whole object, not the property:
>
> ```tsx
> // ✅ the whole object
> useEffect(() => {
>   if (formState.errors.name) { /* … */ }
> }, [formState])
>
> // ❌ the property — does not fire, because the update comes in a batch
> useEffect(() => {
>   if (formState.errors.name) { /* … */ }
> }, [formState.errors])
> ```
>
> This applies to **non-destructured** `formState`. A property already extracted in the component body (`const { isSubmitSuccessful } = formState`) is an ordinary value and goes into the list normally — that is what `RHF-STATE-02` does.

---

## 2. `formState` — the inventory

| Property | Type | What it is | Since |
| --- | --- | --- | --- |
| `errors` | `object` | errors per field, in the shape of the form | — |
| `isDirty` | `boolean` | the user modified some input | — |
| `dirtyFields` | `object` | which fields the user modified | — |
| `touchedFields` | `object` | which fields the user has passed through | — |
| `defaultValues` | `object` | the current default — the one from `useForm` or the one updated via `reset` | v7.37.0 |
| `isSubmitted` | `boolean` | a submit happened; stays `true` until `reset` | — |
| `isSubmitting` | `boolean` | submission in progress | — |
| `isSubmitSuccessful` | `boolean` | the submission finished without a runtime error | — |
| `submitCount` | `number` | how many times the form was submitted | — |
| `isValid` | `boolean` | the form has no errors — see caveat | — |
| `isValidating` | `boolean` | validation in progress | — |
| `validatingFields` | `object` | **which** fields are under async validation | v7.51.0 |
| `isLoading` | `boolean` | loading **async** `defaultValues` | v7.41.0 |
| `disabled` | `boolean` | the form is disabled via the `disabled` prop | v7.48.0 |
| `isReady` | `boolean` | the `formState` subscription has finished being set up | v7.56.0 |

### 2.1 `isDirty` × `dirtyFields`

They are not the same information at different granularity — they are two questions.

| | Question | Shape |
| --- | --- | --- |
| `isDirty` | "did anything in this form change?" | aggregate `boolean` |
| `dirtyFields` | "what exactly changed?" | object with the modified fields |

Enabling a Save button is `isDirty`. Sending a `PATCH` with only what changed is `dirtyFields`. Using `isDirty` for the second question sends the whole object; using `dirtyFields` for the first forces you to count keys on every render.

Three verified restrictions:

- **The comparison is always against `defaultValues`.** Without `defaultValues` covering the field, it is compared against `undefined` and the result means nothing. `RHF-CORE-01`.
- **`File`, classes and custom objects are not supported** in that comparison. The source says file inputs "will need to be managed at the app level due to the ability to cancel file selection". Objects with methods on the prototype (Moment, Luxon) should be avoided in `defaultValues`.
- **`setValue`'s `shouldDirty` only guarantees the immediate marking of the target field.** Since `isDirty` always recompares against `defaultValues`, a later change to any field may recompute `dirtyFields`.

### 2.2 `isValid` is weaker than it looks

`setError` forces `isValid` to `false` **immediately**, and the source records that this value "is not derived from validation and will be overwritten the next time validation runs".

`isValid` answers "there is no error registered right now". It does not answer "the form is correct", much less "the server accepted it" — that is what `isSubmitSuccessful` is for. `RHF-ERR-05`.

### 2.3 `isSubmitSuccessful`

"Indicates that the form was successfully submitted without any runtime error." The important reading is in *runtime error*: it says the `onSubmit` **did not throw**, not that the business operation succeeded. Since an expected error should not be thrown from inside `onSubmit` (`RHF-ERR-03`), a `400` handled with `setError` leaves `isSubmitSuccessful` at `true`.

This is consistent, not contradictory: the form submission happened; the business outcome is another matter. If you reset the form upon seeing `isSubmitSuccessful`, reset only after the call has actually succeeded — see § 4.3.

### 2.4 `isReady` fixes an ordering bug

> "Renders children before the parent completes setup. Use an `isReady` flag to ensure the form is initialized before updating state from the child."

A child component that calls `setValue` on mount may do so before the subscription exists — and the call is lost, silently.

```tsx
// In the component that called useForm: the subscription already exists
useEffect(() => { setValue('coupon', couponFromUrl) }, [])

// In a child component: it has to wait
const { isReady } = useFormState({ control })
useEffect(() => {
  if (isReady) setValue('coupon', couponFromUrl)
}, [isReady])
```

It is the same ordering problem that bites `useWatch` (§ 3.4).

---

## 3. The five ways to read

This table is the center of the satellite. The axis is not "what it returns", it is **where the re-render happens**.

| API | Subscribes? | Who re-renders | Where to call | Use when |
| --- | --- | --- | --- | --- |
| `getValues()` | no | nobody | anywhere | one-off read inside a handler |
| `watch(name?)` | yes | the component that called it — usually the **root** | next to `useForm` | you really need the whole form at the root |
| `useWatch({ control, name })` | yes | **only** the component that called it | any component | render that depends on a value |
| `useFormState({ control })` | yes | **only** the component that called it | any component | render that depends on error, dirty, submitting |
| `subscribe({ … })` | yes | **nobody** | inside `useEffect` | side effect with no UI |

### 3.1 `getValues` — a read at no cost

```tsx
const onApplyCoupon = () => {
  const coupon = getValues('coupon')     // does not subscribe, does not re-render
  if (coupon) validateCoupon(coupon)
}
```

The symmetric mistake also exists: using `getValues` to **render**. Since it does not subscribe, the screen does not update, and the displayed value stays frozen at whatever the last render, triggered for some other reason, produced.

### 3.2 `watch` — and why it is almost always the wrong choice

Four verified overloads:

```ts
watch(name: string, defaultValue?: unknown): unknown
watch(names: string[], defaultValue?: { [k: string]: unknown }): unknown[]
watch(): { [k: string]: unknown }
watch(callback, defaultValues?): { unsubscribe: () => void }   // Deprecated — see § 3.6
```

```tsx
const type = watch('type')     // re-renders THIS component on every change
```

Called next to `useForm`, "this component" is the whole form. The source:

> "This API will trigger a re-render at the root of your application or form. Consider using a callback or the useWatch API if you experience performance issues."

Two initial-value caveats:

- Without `defaultValue`, the first render returns `undefined`, "because it is called before `register`".
- When `defaultValue` and `defaultValues` coexist, **the one from `useForm` wins**; the inline one only serves as a fallback when there is no value at all for the field.

### 3.3 `useWatch` — the default

```tsx
function TotalSummary({ control }: { control: Control<Order> }) {
  // defaultValue covers the first render: without it, `items` may come as undefined
  // and the reduce throws. See the initial-value caveats in § 3.2.
  const items = useWatch({ control, name: 'items', defaultValue: [] })
  const total = items.reduce((s, i) => s + i.price * i.quantity, 0)
  return <strong>{formatCurrency(total)}</strong>
}
```

Only `TotalSummary` re-renders. The rest of the form does not know anything changed — the hook "isolates re-rendering at the custom hook level".

Verified props:

| Prop | Default | Note |
| --- | --- | --- |
| `name` | — | reactive: changing the prop updates the subscription |
| `control` | — | optional under `FormProvider` |
| `defaultValue` | — | fallback before mount, only when there is no value yet |
| `disabled` | `false` | turns the subscription off · v7.13.0 |
| `exact` | `false` | v7.20.0. With `false`, fires when the subscribed name is a prefix of the changed field, or vice versa |
| `compute` | — | v7.61.0 |

`compute` subscribes to a **derived** value and avoids the re-render when the result of the computation does not change:

```tsx
const aboveLimit = useWatch({
  control,
  compute: (form) => form.total > LIMIT,   // only notifies when the boolean flips
})
```

It is the difference between re-rendering on every cent typed and re-rendering twice in the life of the form.

> **Watch out for the `exact` default.** It is `false` here and in `useFormState`, but `true` in `Controller`/`useController`. The inconsistency is real and is in the source.

### 3.4 The two `useWatch` traps

**Order.** "If you update a form value before the subscription is in place, then the updated value will be ignored." A `setValue` called before the `useWatch` exists is discarded. Same problem that `isReady` solves (§ 2.4).

**`useEffect`.** The source is explicit:

> "useWatch's result is optimized for the render phase instead of useEffect dependencies. To detect value updates, you may want to use an external custom hook for value comparison."

The same goes for `watch`. To react to changes **outside render**, the API is `subscribe`.

### 3.5 `useFormState` — the same isolation, for state

```tsx
function SaveButton({ control }: { control: Control<Profile> }) {
  const { isDirty, isSubmitting } = useFormState({ control })
  return <button disabled={!isDirty || isSubmitting}>Save</button>
}
```

The Proxy applies here too, and the source repeats the requirement: `const { isDirty } = useFormState()` ✅ versus `const formState = useFormState()` ❌.

`name` (v7.4.0) restricts the subscription to specific fields; `disabled` (v7.13.0) turns the subscription off; `exact` (v7.20.0) defaults to `false`.

**This is the API to use inside `FormProvider`** — never destructuring `formState` from `useFormContext`, because the read would happen in the wrong component. `RHF-STATE-01`, and the alias `RHF-CTX-01` in [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) § 4.1.

### 3.6 `subscribe` — reacting without rendering

Available since **v7.55.0**. The source describes the purpose in one line:

> "This function is dedicated to subscribing to form state without **render**"

```tsx
useEffect(() => {
  const unsubscribe = subscribe({
    formState: { values: true },
    callback: ({ values }) => saveDraft(values),
  })
  return unsubscribe        // RHF-STATE-05
}, [subscribe])
```

| Prop | Type | Role |
| --- | --- | --- |
| `name` | `undefined \| string \| string[]` | whole form, one field or several |
| `formState` | `Partial<ReadFormState>` | which parts to monitor |
| `callback` | `Function` | receives the subscription payload |
| `exact` | `boolean` | exact name matching |

Keys accepted in `formState`: `values`, `isDirty`, `dirtyFields`, `touchedFields`, `isValid`, `errors`, `validatingFields`, `isValidating`.

It returns the cancellation function, which **must** be returned from the Effect. It shares the same functionality as `createFormControl.subscribe`, which initializes outside React components.

It is the right API for autosave, analytics and logging. None of those needs a render, and using `watch` for them pays a re-render of the whole root for an invisible effect.

### 3.7 Rules — reading

| ID | Rule |
| --- | --- |
| `RHF-PERF-01` | `watch()` with no argument **NEVER** in a large component — it re-renders the root. Use `useWatch` in the smallest component that needs the value. |
| `RHF-PERF-02` | A reaction with no UI (autosave, analytics, logging) **MUST** use `subscribe`. The `watch(callback)` overload is marked **Deprecated** in the source, with `subscribe` as the replacement. |
| `RHF-PERF-03` | The return of `watch`/`useWatch` **NEVER** goes into a `useEffect` dependency array — it is optimized for the render phase. |
| `RHF-PERF-04` | A read that does not affect the UI **MUST** use `getValues`, **NEVER** `watch`. |
| `RHF-STATE-01` | In a nested component or under `FormProvider`, form state **MUST** come from `useFormState({ control })`, **NEVER** from destructuring `useFormContext`. |
| `RHF-STATE-03` | A child component that calls `setValue` on mount **MUST** wait for `isReady`. |
| `RHF-STATE-04` | When reading **non-destructured** `formState` inside a `useEffect`, the dependency **MUST** be the whole `formState` object — `[formState.errors]` does not fire, because the update is batched. A property **already destructured in the component body** (`const { isSubmitSuccessful } = formState`) is an ordinary value and goes into the list normally, as in `RHF-STATE-02`. |
| `RHF-STATE-05` | The return of `subscribe` **MUST** be returned as the Effect's cleanup. |

---

## 4. Writing, resetting and feeding from outside

### 4.1 `setValue`

```tsx
setValue('address.city', 'Recife', { shouldValidate: true, shouldDirty: true })
```

| Option | Effect | Since |
| --- | --- | --- |
| `shouldValidate` | validates the field and recomputes the form's validity | — |
| `shouldDirty` | compares against `defaultValues` and marks it in `dirtyFields` | — |
| `shouldTouch` | marks the input as *touched* | v7.8.0 |
| `delayError` | delays showing the resulting error, using the configured delay | v7.82.0 |

Verified points:

- **Target the leaf field, not the parent object.** The source calls `setValue('details', { name: v })` "less performant" compared to `setValue('details.name', v)`, and recommends avoiding setting whole objects over registered nested fields.
- **Register first.** "It's recommended to register the input's name before invoking `setValue`" — and, with a field array, make sure `useFieldArray` ran first.
- **To replace a whole array**, the source says to prefer `useFieldArray`'s `replace`, "the more explicit, purpose-built API".
- A field under `Controller` updates through `field.onChange`, not through `setValue` — `RHF-CTRL-04`.

### 4.2 `defaultValues` × `values`

Two `useForm` options that look like alternatives and are not: one defines the **shape**, the other the **content**.

| | `defaultValues` | `values` |
| --- | --- | --- |
| Nature | static, cached | **reactive** (v7.41.0) |
| When it changes | only via `reset` | whenever the prop changes |
| Role | the form's contract: what exists, and the base for `isDirty` | content coming from outside (server, store) |

Verified: `defaultValues` "are cached. To reset them, use the reset API", are included in the submission result by default, and must **not** receive `undefined`, "as it conflicts with the default state of a controlled component". It accepts an async function:

```tsx
useForm({ defaultValues: async () => fetch('/api/profile').then((r) => r.json()) })
```

`values` overrides `defaultValues` unless `resetOptions: { keepDefaultValues: true }`; when it changes, the internal `reset` is invoked according to `resetOptions`.

The right pair for remote data is `defaultValues` for the shape and `values` for the content:

```tsx
const { data } = useQuery({ queryKey: ['profile'], queryFn: fetchProfile })

useForm({
  defaultValues: { name: '', email: '' },   // shape — every field exists from the start
  values: data,                             // content — reactive
  resetOptions: { keepDirtyValues: true },  // does not wipe an edit in progress
})
```

Without `keepDirtyValues`, a background refetch overwrites what the user is typing. The bridge rule is `RHF-BRIDGE-03`, in [React Hook Form](react-hook-form.md) § 8 — I do not redefine it here.

### 4.3 `reset` — and the order that matters

`reset(values, options)`. The point that surprises most:

> "Calling `reset` with `values` updates the form's `defaultValues` unless `options.keepDefaultValues` is set. If `reset` is later called without `values` or with `{}`, the form resets to the last `values` provided instead of the initial `defaultValues`."

In other words: `reset(x)` **redefines the contract**, and every later `isDirty` compares against `x`.

Verified options: `keepErrors`, `keepDirty`, `keepDirtyValues` (v7.31.0), `keepValues`, `keepDefaultValues`, `keepIsSubmitted`, `keepIsSubmitSuccessful` (v7.47.0), `keepTouched`, `keepIsValidating` (v7.51.0), `keepIsValid`, `keepSubmitCount`, `keepFieldsRef` (v7.60.0).

`keepFieldsRef` preserves the internal references of registered inputs — "useful when you want to reset form values without causing inputs to unmount and remount".

Since **v7.36.0**, `values` also accepts a callback that receives the current values:

```tsx
reset((current) => ({ ...current, coupon: '' }))
```

**Clearing after a successful submission** is the most common case, and the correct place is **not** `onSubmit`. The source recommends `useEffect` because "execution order matters": resetting inside `onSubmit` competes with the update of `isSubmitSuccessful` itself and produces inconsistent state.

But the Effect's condition **cannot be `isSubmitSuccessful` alone**:

```tsx
// WRONG — also resets when the server refused
useEffect(() => {
  if (isSubmitSuccessful) reset()
}, [isSubmitSuccessful, reset])
```

Per § 2.3, `isSubmitSuccessful` means "the `onSubmit` did not throw". And since `RHF-ERR-03` forbids throwing an expected error from inside `onSubmit`, a `422` handled with `setError` leaves the flag at `true` — the Effect fires and **wipes the fields and the errors you just displayed**, together.

```tsx
// RIGHT — the success signal is yours, not RHF's
const [saved, setSaved] = useState(false)

const onSubmit = handleSubmit(async (data) => {
  try {
    await mutateAsync(data)
    setSaved(true)
  } catch (e) {
    setError('root.serverError', { message: messageFrom(e) })
  }
})

useEffect(() => {
  if (saved) { reset(); setSaved(false) }
}, [saved, reset])
```

`RHF-STATE-02`. Details of the trap in [React Hook Form](react-hook-form.md) § 6.1.

The source also recommends to "always provide `defaultValues` when resetting a form to ensure all inputs, especially controlled components, are restored correctly".

### 4.4 `shouldUnregister` and `disabled` at the form level

**`shouldUnregister`** (default `false`) decides what happens to the value of an **unmounted** field.

| Value | Behavior |
| --- | --- |
| `false` *(default)* | the unmounted field's value **persists** in the form |
| `true` | unmounting removes the value — the form starts behaving like a native HTML form |

Three verified notes: it is "a global configuration that overrides child-level configurations"; with the default `false`, unmounted fields **are not validated** by built-in validation; and detecting unmounted inputs requires notification via `useEffect`.

**It also exists at the field level** — the sentence above already said so when it spoke of "child-level configurations", and the source completes it: *"To have individual behavior, set the configuration at the component or hook level, not at `useForm`."* It is an option of `RegisterOptions`, a prop of `Controller`, a prop of `useController` and a prop of `useFieldArray`.

And there is a difference the table above does not cover. At the field level, the `Controller`/`useController` doc says:

> "Input will be unregistered after unmount **and defaultValues will be removed as well**."

In other words: `shouldUnregister: true` on a field removes the **default** along with the value — which collides head-on with `RHF-CORE-01`. If the field mounts again, it does not go back to the default; it goes back to having no default at all.

| ID | Rule |
| --- | --- |
| `RHF-STATE-12` | `shouldUnregister: true` at the field level **MUST** come with the awareness that the `defaultValue` also disappears on unmount — if the field can remount and needs the default, use an explicit `unregister` instead of the option. |

The default is the right one for a multi-step form or one with conditional fields, where disappearing from the screen should not mean losing what was typed. And it is **incompatible with `useFieldArray`** — § 6.

**`disabled`** (v7.48.0) disables the whole form and all associated inputs, preventing interaction. It works with `register`, `<select>` and `Controller`, and the source cites its usefulness for "preventing user interaction during asynchronous tasks". The state is readable in `formState.disabled`.

```tsx
const { formState: { isSubmitting } } = useForm({ /* … */ })
useForm({ disabled: isSubmitting })   // freezes the form during submission
```

> **Not verified:** whether form-level `disabled` excludes the values from the submission, as **field**-level `disabled` does (`RHF-REG-05`, in [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md)). The `useForm` page only describes the interaction lock, without stating the effect on the submitted values. Confirm in the source before relying on it.

### 4.5 `getFieldState`

```tsx
const { isDirty, isTouched, invalid, isValidating, error } = getFieldState('email')
```

Available since v7.25.0. Two verified requirements:

**It needs a subscription.** "getFieldState works by subscribing to form state updates." Without `formState` read via `useForm`, `useFormContext` or `useFormState` — or without passing `formState` as the second argument — the return comes back incomplete. And it is **per property**: `isDirty` requires a `dirtyFields` subscription, `invalid` and `error` require `errors`, and so on.

**It needs a registered field.** "The prop must match a registered field name." An unknown name returns default/`false` state, not an error — which lets a typo go unnoticed.

### 4.6 Rules — writing

| ID | Rule |
| --- | --- |
| `RHF-STATE-02` | A post-submission `reset` **MUST** run in `useEffect`, **NEVER** inside `onSubmit`. And it **MUST** be conditioned on a **real** success signal, not just on `isSubmitSuccessful` — which stays `true` even when `onSubmit` caught a server error with `setError`. See `RHF-STATE-09` in [React Hook Form](react-hook-form.md) § 6.1: resetting there wipes the errors and what the user typed. |
| `RHF-STATE-06` | `setValue` **MUST** target the leaf field; **NEVER** replace the parent object when one field is enough. |
| `RHF-STATE-07` | Replacing a whole array **MUST** use `useFieldArray`'s `replace`, **NEVER** `setValue`. |
| `RHF-STATE-08` | `getFieldState` **MUST** have `formState` subscribed — or receive it as the second argument —, otherwise it returns uninitialized state. |

### 4.7 Conditional field: `unregister` and `resetField`

The case that breaks dynamic forms the most: a field that only appears under a condition (checking "special order" reveals "note"). The user checks it, types, unchecks it — and the typed value **stays in the form state**, because the `shouldUnregister` default is `false`. It travels in the submit without anything on screen showing it.

Two APIs solve it, and they do different things:

```tsx
unregister(names?: string | string[], options?: UnregisterOptions): void
resetField(name: string, options?: ResetFieldOptions): void
```

| | `unregister` | `resetField` |
| --- | --- | --- |
| Does the field stay registered? | **no** — it disappears from the form state | **yes** |
| Effect | removes reference, value and built-in validation rules | goes back to the `defaultValue`, re-evaluates `isDirty`/`isValid` |
| Options | `keepValue`, `keepError`, `keepDirty`, `keepTouched`, `keepIsValid`, `keepDefaultValue`, `keepIsValidating` | `keepError`, `keepDirty`, `keepTouched`, `defaultValue` |
| Use when | the field has logically ceased to exist | the field exists and you want to clear it |

Two warnings quoted from the source, and the second is the one that misleads:

> "This method will remove input reference and its value, which means built-in validation rules will be removed as well."

> "By unregister an input, it will not affect the schema validation."

**`unregister` does not turn off the resolver.** If the schema requires `note`, it keeps requiring it after the field disappears from the screen — and the form stays invalid because of a field the user can neither see nor fill in. Taking the field out of the UI is half the job; the other half is the schema no longer requiring it.

```tsx
// The condition lives in the schema, not only in the JSX
const orderSchema = z.discriminatedUnion('specialOrder', [
  z.object({ specialOrder: z.literal(false), items: itemsSchema }),
  z.object({
    specialOrder: z.literal(true),
    note: z.string().min(1, 'Describe what makes the order special.'),
    items: itemsSchema,
  }),
])

function Note() {
  const { control, register, unregister } = useFormContext<Order>()
  const special = useWatch({ control, name: 'specialOrder' })

  useEffect(() => {
    if (!special) unregister('note')   // leaves the payload together with the UI
  }, [special, unregister])

  if (!special) return null
  return <textarea {...register('note')} />
}
```

A discriminated union is preferable to `.optional()` + `.refine()` because the output type stops **admitting** the impossible combination (`specialOrder: false` with `note` filled in), instead of only rejecting it at runtime.

> **Why an explicit `unregister` and not `shouldUnregister` on the field.** The option exists at the field level (§ 4.4), but there it **also removes the `defaultValue`** (`RHF-STATE-12`), and the global version is incompatible with `useFieldArray` (`RHF-ARRAY-03`). In a form with a dynamic list — which is the case of this section — the explicit `unregister` is the path that has neither side effect.

And the third RULE on the `unregister` page, which makes the pattern above fail silently if forgotten:

> "Make sure you unmount that input which has register callback or else the input will get registered again."

The example's `return null` is not a rendering detail: without it, `register` runs again on the next render and the field re-registers right after the `unregister`.

| ID | Rule |
| --- | --- |
| `RHF-STATE-10` | A field removed from the UI by a condition **MUST** be removed from the form state by `unregister` (or cleared by `resetField`) — otherwise the orphan value travels in the submit. |
| `RHF-STATE-11` | The conditionality **MUST** also exist in the schema: `unregister` **NEVER** affects resolver validation. Prefer a discriminated union to an optional field. |

---

## 5. Re-render investigation order

The order announced in [React Hook Form](react-hook-form.md) § 5.7, from cheapest to most expensive. It is **normative**: skipping a step to reach `memo` is the mistake this section exists to prevent.

**0. Measure.** React DevTools Profiler, with *Highlight updates* on. A healthy RHF form **does not flash** while typing. If it flashes, someone subscribed to something too high up. Without a measurement, stop here — `REACT-PERF-01`, in [React - Performance and Concurrency](react-performance-and-concurrency.md).

**1. Remove `useState` mirroring a field.** The value is already in the form; the parallel `useState` reintroduces exactly the render the library eliminated, and creates a second source of truth that diverges. It is applied to forms.

**2. Push the value read down.** `watch` at the root becomes `useWatch` in the leaf component. **This step solves most cases** — and is often the only one needed. If the value only feeds a boolean computation, `compute` (§ 3.3) cuts the rest.

**3. Push the `formState` read down.** Instead of reading `errors` at the top and passing it by prop, each consumer subscribes to what it needs with `useFormState`. A `<SaveButton>` that subscribes to `isDirty` and `isSubmitting` does not re-render when a field error appears three sections above. `RHF-STATE-01`.

**4. Review each `Controller`.** It reintroduces controlled rendering on that field. Where the component forwards `ref`, `register` is cheaper — `RHF-CORE-03`, and the tree in [React Hook Form](react-hook-form.md) § 5.1.

**5. Volume, not computation.** A long list with `useFieldArray` costs **DOM nodes**, not processing. Memoizing the row does not solve it; the way out is to paginate or virtualize — § 6.4.

**6. Only then `memo`.** On the row or the field, with stable props. And only with the measurement from step 0 in hand.

> **The most expensive conceptual mistake** is treating RHF as if it were React state and then trying to memoize the result. The library already eliminated the render; memoization only becomes necessary again when someone brought it back. **Look for what over-subscribed before looking for what to memoize** — steps 2 and 3 are free and remove the cause, while step 6 only masks the symptom and charges a comparison on every render.

---

## 6. `useFieldArray`

```tsx
const { fields, append, remove, move } = useFieldArray({ control, name: 'items' })

{fields.map((field, index) => (
  <div key={field.id}>                              {/* ✅ never the index */}
    <input {...register(`items.${index}.name`)} />
    <button type="button" onClick={() => remove(index)}>Remove</button>
  </div>
))}
<button type="button" onClick={() => append({ name: '', quantity: 1 })}>
  Add
</button>
```

### 6.1 Verified surface

| Method | Signature |
| --- | --- |
| `fields` | `(object & { id: string })[]` |
| `append` | `(obj: object \| object[], focusOptions) => void` |
| `prepend` | `(obj: object \| object[], focusOptions) => void` |
| `insert` | `(index: number, value: object \| object[], focusOptions) => void` |
| `swap` | `(from: number, to: number) => void` |
| `move` | `(from: number, to: number) => void` |
| `update` | `(index: number, obj: object) => void` · v7.11.0 |
| `replace` | `(obj: object[]) => void` · v7.15.0 |
| `remove` | `(index?: number \| number[]) => void` |

Props: `name` (required, **dynamic names are not supported**), `control`, `shouldUnregister`, `keyName` (default `"id"`), `rules` (v7.34.0, same validation API as `register`) and `disabled` (v7.79.0).

`rules` validates the array as a whole, and the error goes to `errors.<name>.root` — not to an entry. `disabled` disables the whole array; the source records that the flag on each `fields` object only mirrors the hook's `disabled`, is **not** read from what you pass to `append`/`prepend`/`insert` and is **not** forwarded automatically to the registered input.

### 6.2 The six restrictions, and why they exist

| Restriction | Consequence of violating it |
| --- | --- |
| `key` **must** be `field.id`, never the index | values shuffled on remove — § 6.3 |
| Each entry **must be an object**; flat arrays are not supported | `{ tags: ['a','b'] }` ❌ · `{ tags: [{ value: 'a' }] }` ✅ |
| `shouldUnregister: true` **is not supported** | newly added fields are unregistered on re-render and **lose their value** |
| `append`/`prepend`/`insert`/`update` **do not accept `{}`** | `append()` ❌ · `append({})` ❌ · `append({ name: 'bill' })` ✅ |
| Do not stack actions in the same handler | queue them via `useEffect` — the second action runs on the next render |
| One `useFieldArray` per `name` | "Each useFieldArray is unique and has its own state update" — two instances diverge |

The source is literal about `shouldUnregister`: "Field array relies on inputs being mounted and unmounted to manage its internal state". The array **uses** the mount cycle as a mechanism; turning off persistence of the unmounted value pulls the ground out from under it.

And on stacking actions, the official example:

```tsx
// ❌ the two actions compete in the same tick
onClick={() => { append({ test: 'test' }); remove(0) }}

// ✅ the remove happens after the second render
useEffect(() => { remove(0) }, [remove])
onClick={() => { append({ test: 'test' }) }}
```

### 6.3 Index × identity

The `key={index}` mistake deserves detail because the symptom does not point to the cause.

With an index `key`, removing item 0 makes React reuse the DOM node at that position for what was item 1. Since the field is **uncontrolled**, the value that was in the DOM node stays there — and the list starts showing swapped data, even though `getValues()` returns the correct array. The divergence between what is seen and what is submitted is what makes this bug expensive: it does not break, it lies.

`field.id` is generated by the library exactly for this, and the source points to React's lists page for the why. The key name is configurable through `keyName`, but there is no reason to change it — and in the v8 beta it ceases to exist (§ Verification notes).

### 6.4 Long lists

`useFieldArray` does not virtualize. With hundreds of rows the cost is **volume of DOM nodes**, and memoizing the row does not solve it — it is step 5 of § 5.

Virtualizing, however, has a side effect the source describes:

> "A common practice is to only render the items in the viewport; however, this causes issues as items are removed from the DOM when they are out of view and then re-added. This will cause items to reset to their default values when they re-enter the viewport."

Two official ways out: `FormProvider` + `useFormContext` in the virtualized rows, or `Controller` restoring the value via `getValues()` when rendering each item.

> And before optimizing `FormProvider`: "Using React Hook Form's DevTools alongside FormProvider can cause performance issues in some situations. Before diving deep in performance optimizations, consider this bottleneck first."

### 6.5 Rules — `RHF-ARRAY-*`

| ID | Rule |
| --- | --- |
| `RHF-ARRAY-01` | The row's `key` **MUST** be `field.id`, **NEVER** the index. |
| `RHF-ARRAY-02` | Each array entry **MUST** be an object; an array of primitives **NEVER**. |
| `RHF-ARRAY-03` | `shouldUnregister: true` **NEVER** with `useFieldArray` — added fields lose their value on re-render. |
| `RHF-ARRAY-04` | `append`/`prepend`/`insert`/`update` **MUST** receive all of the entry's `defaultValues`; `{}` or no argument **NEVER**. |
| `RHF-ARRAY-05` | A `name` **MUST** have at most one `useFieldArray`, and the `name` is **NEVER** dynamic. |
| `RHF-ARRAY-06` | Two array actions are **NEVER** stacked in the same handler — the second goes into a `useEffect`. |

> `RHF-CTRL-06`, in [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md), states the same principle as `RHF-ARRAY-03` from the field's side. **`RHF-ARRAY-03` is the canonical one**; cite it in review.

---

## 7. Multi-step form

A wizard forces a decision that no single-screen form requires: **one `useForm` for everything, or one per step?** The answer changes the schema, the validation, persistence when going back and the "Next" button.

### 7.1 What the source does not answer

`trigger(['customer.name', 'customer.email'])` returns `Promise<boolean>` and is the obvious way to unlock the next step. The problem appears when there is a `resolver`: **the whole schema runs**, so an `items: z.array().min(1)` produces an error already on step 1's `trigger`, when the user has not even gotten there.

The source **does not say** whether `formState.errors` holds the errors of all steps or only of the named fields — I checked the `trigger` page and it only deals with re-rendering. See [Verification notes](#verification-notes).

This matters because it is the difference between step 1 showing errors for fields that are not on screen and not showing them. **The recommendation below avoids depending on that answer.**

### 7.2 The decision: one form per step

```
Do the steps share cross-validation
(a rule that only makes sense when looking at data from two steps)?
├── NO  (the common case)
│   → ONE FORM PER STEP, with an accumulator in the wizard.
│     Each step has its own schema, its own isValid, its own lifecycle.
└── YES, and the rule must warn BEFORE the last step
    → a single form, with trigger per step.
      Accept the uncertainty of § 7.1 and test the behavior.

In both: the COMPLETE schema validates the accumulated object before sending.
It is the one the server uses too.
```

One form per step solves, at once, the four problems the wizard creates:

| Problem | How it goes away |
| --- | --- |
| `isValid` is global and the "Next" button never enables | each step has its own `isValid`, which is only its own |
| Errors from future steps leaking into the current step | the step's schema does not know about the other fields |
| Going back without losing data | the accumulator is the memory, not RHF |
| `shouldUnregister` and unmounted field | irrelevant: the whole form unmounts, and nothing depended on it remembering |

### 7.3 Composed schemas

One schema per step, and the complete one is the sum — not two declarations of the same shape (`RHF-VAL-04`).

```tsx
const step1Schema = z.object({
  customer: z.object({
    name: z.string().min(2, 'Enter at least 2 characters.'),
    email: z.email('Invalid email.'),
  }),
})

const step2Schema = z.object({
  items: z.array(z.object({
    description: z.string().min(1, 'Describe the item.'),
    quantityCents: z.number().int().positive(),
  })).min(1, 'Add at least one item.'),
})

const step3Schema = z.object({
  notes: z.string().max(500).optional(),
})

// The complete one is the composition, not a third declaration
const quoteSchema = z.object({
  ...step1Schema.shape,
  ...step2Schema.shape,
  ...step3Schema.shape,
})

type Quote = z.infer<typeof quoteSchema>
type Step1 = z.infer<typeof step1Schema>
```

The `.shape` spread works the same in Zod 3 and 4, and makes explicit that the complete one **is** the sum of the parts. A cross-step rule goes in a `.refine()` on `quoteSchema`, not on the partials.

### 7.4 The accumulator

```tsx
export function QuoteWizard() {
  const [step, setStep] = useState(1)
  const [data, setData] = useState<Partial<Quote>>({})

  const advance = (partial: Partial<Quote>) => {
    setData((d) => ({ ...d, ...partial }))
    setStep((s) => s + 1)
  }

  return (
    <>
      {step === 1 && <Step1 data={data} onNext={advance} />}
      {step === 2 && (
        <Step2 data={data} onNext={advance} onBack={() => setStep(1)} />
      )}
      {step === 3 && (
        <Step3 data={data} onBack={() => setStep(2)} onSend={send} />
      )}
    </>
  )
}

function Step1({ data, onNext }: StepProps) {
  const { register, handleSubmit, formState: { errors, isValid } } = useForm<Step1>({
    resolver: zodResolver(step1Schema),
    mode: 'onTouched',
    defaultValues: { customer: { name: '', email: '' } },
    values: data as Step1,        // comes back filled in — RHF-BRIDGE-03
  })

  // handleSubmit is the "Next": validates this step and only then moves on
  return (
    <form onSubmit={handleSubmit(onNext)}>
      {/* fields */}
      <button disabled={!isValid}>Next</button>
    </form>
  )
}
```

Four decisions:

- **`handleSubmit` is the "Next" button.** It is not a hack: submitting the step **is** validating it and handing over its data. The `trigger` with an array goes away, and with it the re-render cost that `RHF-VAL-07` warns about.
- **`isValid` works again.** It is this step's `isValid`, with this schema. That is what the single form made impossible.
- **`values: data`** feeds the step when going back. Same mechanism as remote data (`RHF-BRIDGE-03`) — the accumulator is "from outside" just as much as a server is.
- **One `<form>` per step**, each with a single submission owner (`RHF-BRIDGE-01`). There is no nested `<form>` nor a button fighting over a handler.

### 7.5 The validation that matters happens at the end

The accumulator is `Partial<Quote>` — TypeScript does not guarantee it is complete, and the user may have gotten there by a path you did not foresee. Before sending, validate the whole object against the complete schema:

```tsx
const send = async (lastStep: Partial<Quote>) => {
  const complete = { ...data, ...lastStep }
  const parsed = quoteSchema.safeParse(complete)

  if (!parsed.success) {
    // incomplete step: take the user back instead of sending garbage
    setStep(firstStepWithError(parsed.error))
    return
  }
  await api.createQuote(parsed.data)
}
```

This is not redundant with per-step validation: the steps validate **fragments**, and only the complete schema validates the **cross rules** and completeness. And it is the same schema the server uses — `RHF-CORE-05`.

### 7.6 When the single form is the right choice

Two short steps, no dynamic list, with a rule that needs to see both at the same time. Then the cost of coordinating two forms outweighs that of the uncertainty of § 7.1.

In that case: `trigger(['a','b'])` to advance, `isValid` does **not** work for the button (it is global), and the "Next" button validates on click instead of reacting. Display on the current step only the `errors` of its own fields — do not trust `formState.errors` to be clean of the others.

### 7.7 Rules — `RHF-STEP-*`

| ID | Rule |
| --- | --- |
| `RHF-STEP-01` | A wizard **MUST** have one `useForm` per step, with its own schema, unless there is a cross rule that must warn before the last step. |
| `RHF-STEP-02` | The complete schema **MUST** be the composition of the step schemas, **NEVER** a parallel declaration. Alias of `RHF-VAL-04`. |
| `RHF-STEP-03` | Persistence between steps **MUST** live in an accumulator outside RHF, fed back through `values`; **NEVER** depend on the form remembering an unmounted field. |
| `RHF-STEP-04` | Before sending, the accumulated object **MUST** be validated against the complete schema — the steps validated fragments. |
| `RHF-STEP-05` | With a single form, `formState.errors` is **NEVER** assumed to be restricted to the visible step; filter by the step's fields. |

---

## 8. Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| `const { formState } = useForm()` without destructuring what it uses | the Proxy subscribes by read during render; nothing was read | destructure at the top · `RHF-CORE-02` |
| `useEffect(…, [formState.errors])` | `formState` updates in a batch; the property does not fire | `[formState]` · `RHF-STATE-04` |
| `watch()` at the root to display one field | re-renders the whole form on every keystroke | `useWatch` in the leaf · `RHF-PERF-01` |
| `watch(callback)` for autosave | overload marked Deprecated; forces the render path | `subscribe` · `RHF-PERF-02` |
| `useEffect(…, [watch('x')])` | the return is optimized for render, not for dependencies | `subscribe` · `RHF-PERF-03` |
| `getValues()` to render | does not subscribe; the screen freezes at the last render | `useWatch` |
| `watch` for a check inside a handler | pays a re-render for an invisible read | `getValues` · `RHF-PERF-04` |
| `errors` read from `useFormContext()` | the read happens in the wrong component; only the 1st render gets it right | `useFormState({ control })` · `RHF-STATE-01` |
| `setValue` on a child component's mount | runs before the subscription exists; the call is lost | wait for `isReady` · `RHF-STATE-03` |
| `subscribe` without returning the unsubscribe | the subscription leaks on every remount | `return unsubscribe` · `RHF-STATE-05` |
| `reset()` inside `onSubmit` | competes with the update of `isSubmitSuccessful` | `useEffect` with your own success signal · `RHF-STATE-02` |
| `useEffect(() => { if (isSubmitSuccessful) reset() })` | a server error handled with `setError` does not throw, so the flag stays `true` and the reset wipes fields and errors | condition on a real success signal · `RHF-STATE-02` |
| `setValue('obj', {…})` for one field | the source marks it as less performant | target the leaf field · `RHF-STATE-06` |
| `setValue` to swap the whole array | bypasses the dedicated API and throws the array's state out of sync | `replace` · `RHF-STATE-07` |
| `getFieldState` without `formState` subscribed | returns uninitialized state, with no error | subscribe first · `RHF-STATE-08` |
| Server data in static `defaultValues` | not reactive; the refetch never reaches the form | `values` + `keepDirtyValues` · `RHF-BRIDGE-03` |
| `key={index}` in a field array | the DOM node is reused and shows another row's value | `key={field.id}` · `RHF-ARRAY-01` |
| `{ tags: ['a', 'b'] }` in a field array | flat arrays are not supported | `[{ value: 'a' }]` · `RHF-ARRAY-02` |
| `shouldUnregister: true` with `useFieldArray` | the array depends on mount/unmount for its state | remove the option · `RHF-ARRAY-03` |
| `append({})` | the entry is born without the registered fields | pass the defaults · `RHF-ARRAY-04` |
| `append(...)` and `remove(0)` in the same handler | the actions compete in the same tick | second action in `useEffect` · `RHF-ARRAY-06` |
| `isValid` as confirmation of success | `setError` forces it to `false` outside validation | `isSubmitSuccessful` · `RHF-ERR-05` |
| `memo` before pushing the subscription down | masks the symptom and charges a comparison per render | follow the order of § 5 |
| Wizard with a single `useForm` and the complete schema | the whole schema runs; errors from future steps leak | one form per step · `RHF-STEP-01` |
| `disabled={!isValid}` on "Next" with a single form | `isValid` belongs to the whole form, not the step | validate on click · `RHF-STEP-05` |
| Steps counting on RHF remembering an unmounted field | a fragile promise, and an unnecessary one | accumulator + `values` · `RHF-STEP-03` |
| Sending the accumulated data without validating the whole object | the steps validated fragments, not completeness | `safeParse` before sending · `RHF-STEP-04` |

---

## 9. Review checklist

- [ ] Is every `formState` used destructured before render? → `RHF-CORE-02`
- [ ] Does any `useEffect` depend on a `formState` property instead of the object? → `RHF-STATE-04`
- [ ] Is there a `watch()` with no argument, or `watch` in a large component? → `RHF-PERF-01`
- [ ] Do autosave, analytics or logging use `subscribe`, and not `watch(callback)`? → `RHF-PERF-02`
- [ ] Does the return of `watch`/`useWatch` appear in a dependency array? → `RHF-PERF-03`
- [ ] Does a read that does not affect the UI use `getValues`? → `RHF-PERF-04`
- [ ] Under `FormProvider`, does state come from `useFormState`? → `RHF-STATE-01`
- [ ] Does a child component call `setValue` on mount without waiting for `isReady`? → `RHF-STATE-03`
- [ ] Does every `subscribe` return the unsubscribe as cleanup? → `RHF-STATE-05`
- [ ] Is the post-submission `reset` in a `useEffect` conditioned on a **real** success signal — not on `isSubmitSuccessful` alone? → `RHF-STATE-02`
- [ ] Does any `setValue` replace a parent object where a leaf field would do? → `RHF-STATE-06`
- [ ] Does swapping a whole array use `replace`? → `RHF-STATE-07`
- [ ] Does every `getFieldState` have `formState` subscribed? → `RHF-STATE-08`
- [ ] Does remote data come in through `values` with `resetOptions`, not through static `defaultValues`? → `RHF-BRIDGE-03`
- [ ] Do `defaultValues` cover every field of the form? → `RHF-CORE-01`
- [ ] Does every field array row use `key={field.id}`? → `RHF-ARRAY-01`
- [ ] Is every field array entry an object? → `RHF-ARRAY-02`
- [ ] Is there `shouldUnregister: true` in any form with a field array? → `RHF-ARRAY-03`
- [ ] Do `append`/`insert`/`update` receive all of the entry's defaults? → `RHF-ARRAY-04`
- [ ] Does each array `name` have a single `useFieldArray`, and is it non-dynamic? → `RHF-ARRAY-05`
- [ ] Are there two array actions in the same handler? → `RHF-ARRAY-06`
- [ ] Did the re-render investigation follow the order of § 5 before reaching `memo`? → `REACT-PERF-01`

---

## Related

- [React Hook Form](react-hook-form.md) — entry point, tree of § 5.2, order announced in § 5.7, bridges of § 8
- [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) — how the field enters; `RHF-CTX-01`, `RHF-CTRL-04`, `RHF-REG-05`
- [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) — `isValid`, `setError` and `RHF-ERR-05`
- [React - Performance and Concurrency](react-performance-and-concurrency.md) — `REACT-PERF-01`, measure before memoizing
- [React - Rules of React](react-rules-of-react.md) — normative base; the Proxy does not suspend any purity rule
- [React - State and Reactivity](react-state-and-reactivity.md) · — step 1 of § 5
- [React - Hooks](react-hooks.md) — `useEffect` and dependencies
- `TanStack Query - Mutations e Invalidação` — the other side of the submission, and the origin of the `values` data

## Sources consulted

Verified on 2026-08-15:

- [formState](https://react-hook-form.com/docs/useform/formstate) — Proxy and read before render, batched update, `isDirty`/`isValid` caveats, `isReady`
- [watch](https://react-hook-form.com/docs/useform/watch) — the four overloads, re-render at the root, `defaultValues` precedence
- [useWatch](https://react-hook-form.com/docs/usewatch) — render isolation, `compute` (v7.61.0), ordering with `setValue`, not for use in dependencies
- [useFormState](https://react-hook-form.com/docs/useformstate) — `name` (v7.4.0), `disabled` (v7.13.0), `exact` default `false`
- [subscribe](https://react-hook-form.com/docs/useform/subscribe) — v7.55.0, subscription without render, `formState` keys
- [setValue](https://react-hook-form.com/docs/useform/setvalue) — leaf field, `replace` for arrays, `shouldDirty` caveat, `delayError` (v7.82.0)
- [reset](https://react-hook-form.com/docs/useform/reset) — `keep*`, redefinition of `defaultValues`, reset in `useEffect`, callback (v7.36.0)
- [useForm](https://react-hook-form.com/docs/useform) — `defaultValues` × `values`, `resetOptions`, `shouldUnregister`, `disabled`
- [getFieldState](https://react-hook-form.com/docs/useform/getfieldstate) — per-property subscription requirement
- [useFieldArray](https://react-hook-form.com/docs/usefieldarray) — methods, full *Rules* section, `disabled` (v7.79.0)
- [Advanced Usage](https://react-hook-form.com/advanced-usage) — virtualized lists, DevTools with `FormProvider`
- [Migrate V7 to V8 (BETA)](https://react-hook-form.com/migrate-v7-to-v8) — consulted for the status of `watch(callback)` and `keyName`

### Verification notes

Points where the source contradicts what is assumed by habit — or what this doc used to state:

- **The deprecation of `watch(callback)` is not from v7.0.0.** The `watch` page shows, next to the callback overload, the warning *"Deprecated: consider use or migrate to subscribe"* **and** the `Since v7.0.0` badge. The badge marks **when the overload was introduced**, as it does throughout the doc (`update` *Since v7.11.0*, `replace` *Since v7.15.0*). It is not the date of the deprecation: `subscribe` only exists since **v7.55.0**, and a deprecation cannot point to a replacement that did not exist yet. **The source does not state in which version the deprecation happened.** See the divergence recorded below.
- **In v8 (BETA), `watch(callback)` was not removed.** The migration page says what left the public API was the exported **type** `WatchObserver`; the callback "still works at runtime". The recommendation to migrate to `subscribe` remains, as it is "the supported, fully-typed API for this pattern".
- **In v8 (BETA), `useFieldArray` renames `id` to `key` and removes `keyName`.** `RHF-ARRAY-01` still holds in v7 with `field.id`; whoever migrates needs to rewrite the `key`.
- **`isSubmitSuccessful` does not mean "it worked".** It means the `onSubmit` did not throw. A business error handled with `setError` keeps the flag at `true` — which is coherent, but breaks the "I reset because it saved" pattern.
- **`isValid` does not always come from validation.** `setError` forces it to `false`, and the source says that value "is not derived from validation and will be overwritten the next time validation runs".
- **`exact` has different defaults in the same library:** `false` in `useWatch` and `useFormState`, `true` in `Controller`/`useController`.
- **`shouldUnregister: false` (the default) does not validate unmounted fields.** The values persist, but stay outside built-in validation — which is easy to confuse with "the field passed".
- **`shouldUnregister` is a global configuration** and overrides the field-level configuration, rather than merely coexisting with it.
- **`reset(x)` redefines `defaultValues`.** A later `reset()` with no argument goes back to `x`, not to the original `useForm` values.
- **`getFieldState` requires a per-property subscription**, not a generic one: `isDirty` needs `dirtyFields` subscribed, `error` needs `errors`, and so on.
- **An unknown name in `getFieldState` does not raise an error** — it returns default state, which lets a typo pass as a valid, clean field.

### Verification note — `trigger` with a resolver and a subset of fields

The `trigger` page was consulted specifically to find out whether, with a `resolver` configured, calling `trigger(['a','b'])` populates `formState.errors` with the errors of **all** fields in the schema or only of the named ones. **It does not answer** — it only deals with re-rendering ("Render-optimization isolation only applies when you target a single field").

Since the whole schema runs by definition of the resolver, the safe behavior to assume is the pessimistic one: errors from the other steps **may** be in `errors`. § 7.2 recommends the architecture that does not depend on this; `RHF-STEP-05` covers whoever picks the other one.

### Verification note — the version of the `watch(callback)` deprecation

The `Since v7.0.0` badge on the callback overload marks its **introduction**, not its deprecation. Since the replacement indicated by the source itself (`subscribe`) only exists since v7.55.0, "deprecated since v7.0.0" is untenable.

The fact remains: the overload is marked **Deprecated**, with `subscribe` as the replacement, and `RHF-PERF-02` holds. Only the version cannot be asserted — and that is why neither this note nor the hub states it.
