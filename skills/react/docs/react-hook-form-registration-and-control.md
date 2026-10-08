---
titulo: React Hook Form - Registration and Control
Link: https://react-hook-form.com/docs/useform/register
tags:
  - react
  - forms
  - react-hook-form
  - a11y
  - agent-context
source: "Official React Hook Form documentation — register, Controller, useController, useFormContext"
verificado-em: 2026-08-15
---

# React Hook Form — Registration and Control

> `register` · coercion · transform/parse (currency, percentage, mask) · `Controller` · `useController` · `FormProvider` / `useFormContext` · accessibility
>
> How a field enters the form. It is the decision that defines whether the form will be fast, accessible and typed — or none of the three.

Entry: [React Hook Form](react-hook-form.md) · React normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. Concept: why there are two paths

RHF is **uncontrolled by default**: the value lives in the DOM node, and the form talks to it through `ref`. Typing re-renders nothing. That is where the library's performance comes from — and it is what `Controller` partially gives up.

```tsx
// register: the form connects the input via ref. Zero renders per keystroke.
<input {...register('email')} />
```

`register` returns exactly the four things a native input needs:

| Property | Role |
| --- | --- |
| `name` | the field's identity in the form |
| `ref` | how RHF reads the value, and how it focuses the field on error |
| `onChange` | notifies a change |
| `onBlur` | notifies interaction (feeds `touchedFields`) |

When `progressive: true` is on in `useForm`, the return also carries `required`, `min`, `max`, `minLength`, `maxLength` and `pattern` as native HTML attributes. And it carries `disabled` when the option is set.

**The problem:** many UI components accept neither a `ref` nor emit `onChange` with the native event. A `<Select>` that only understands `value` and `onChange={(value) => …}` has nowhere to attach a `ref`. For those, `Controller` does the translation — and reintroduces controlled rendering **in that field only**, not in the whole form.

> **The criterion is technical, not aesthetic.** The question is "does this component forward `ref` and emit a native event?". If yes, `register`. If not, `Controller`. Using `Controller` where `register` would do costs renders with no gain; using `register` where it cannot work costs a field that simply does not work. See the tree in [React Hook Form](react-hook-form.md) § 5.1.

---

## 2. `register`

```tsx
register(name: string, options?: RegisterOptions): UseFormRegisterReturn
```

### 2.1 Naming rules

The name is a **path** inside the values object, not a label.

```tsx
register('email')                  // { email: … }
register('address.city')           // { address: { city: … } }
register('items.0.quantity')       // { items: [{ quantity: … }] }
```

| Rule from the source | Consequence |
| --- | --- |
| The name is required and unique — except native radio and checkbox, which share a name on purpose | two fields with the same name silently overwrite each other |
| **Dot notation only**; `items[0].name` is not supported | the path does not resolve and the value does not show up on submit |
| A name **segment** cannot start with a number when it is an object key | `register('2fa')` and `register('profile.2fa')` break path resolution. **An array index is the exception and is the correct form**: in `items.0.name`, the `0` is a position, not a key — it is exactly what `RHF-REG-01` says to write |
| Reserved by RHF: `ref` and `_f` | collision with the library's internals |
| Reserved by errors: `type`, `root`, `ref`, `types`, `message`, `form` | they collide with the `FieldError` structure — the field's error becomes inaccessible |

### 2.2 Inline validation rules

Accepted in the short form or with a message:

```tsx
<input {...register('title', { required: true })} />

<input {...register('title', {
  required: { value: true, message: 'Title is required.' },
  minLength: { value: 5, message: 'Minimum of 5 characters.' },
})} />
```

Available: `required`, `min`, `max`, `minLength`, `maxLength`, `pattern`, `validate`.

`validate` accepts a function or an object of named functions, and the function receives **the form values as its second argument** — that is how you validate one field against another:

```tsx
register('product', {
  validate: {
    available: async (product, { category }) => {
      if (!category) return 'Choose a category first.'
      return (await hasStock(category, product)) || 'Product unavailable.'
    },
  },
})
```

**When a `resolver` exists, these rules are not used** — the source says the resolver "cannot be used with built-in validators". This holds for all of them, `validate` and `deps` included, and the symptom is silent: the function is never called. See `RHF-VAL-06` and § 3.3 of [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md).

### 2.3 The re-registration gotcha

Calling `register` again on the same name **merges** the options with the previous ones; it does not replace them.

```tsx
register('age', { required: true, min: 18 })
register('age', { min: 21 })         // result: { required: true, min: 21 }
register('age', { required: undefined })  // ❌ removes NOTHING
register('age', { required: false })      // ✅ removes
```

This bites in components that re-register conditionally. To turn a rule off, pass an explicit `false`.

### 2.4 Coercion: the DOM always returns a string

`<input type="number">` produces `"42"`. `<input type="date">` produces `"2026-08-15"`. Without explicit coercion, the schema receives a string where it expects a number, and validation fails for a reason that is not the real one.

| Option | Use | Watch out |
| --- | --- | --- |
| `valueAsNumber: true` | plain numeric | an empty field becomes `NaN`, not `undefined` |
| `valueAsDate: true` | date | invalid input becomes `Invalid Date` |
| `setValueAs: (v) => T` | **one-way** conversion: trim, normalize, parse | it also runs with an empty value — handle that case. **It does NOT work for currency or masks** — see § 3.4 · `RHF-CTRL-09` |

```tsx
// ✅ empty becomes undefined instead of NaN — the schema decides whether it is required
<input type="number" {...register('quantity', {
  setValueAs: (v) => (v === '' ? undefined : Number(v)),
})} />
```

> **Which of the three to use — and the criterion that separates them.**
>
> | Situation | Mechanism |
> | --- | --- |
> | Only change the type, and the project already has a schema | `z.coerce.number()` — keeps the conversion next to the rule, and the server inherits the same coercion |
> | Only change the type, no schema | `valueAsNumber` / `setValueAs` |
> | **Display formatted and store another value** | neither: `Controller` with `input`/`output` — § 3.4 · `RHF-CTRL-09` |
>
> `setValueAs` transforms only what **comes in**. There is no `displayValueAs`. The moment what is seen stops being what is stored, the field is controlled by definition, and the mechanism changes.

### 2.5 A disabled field erases the value

`disabled: true` makes the field's value `undefined` on submission. This is native HTML behavior, and it is often the opposite of what you want ("show but do not allow editing").

```tsx
<input {...register('cpf', { disabled: true })} />   // gone from submit
<input {...register('cpf')} readOnly />              // ✅ goes in submit
```

To freeze an entire block while keeping the values, use `<fieldset disabled>` with `readOnly` on the fields, or the `disabled` option of `useForm` when the intent **really is** to exclude everything from submission.

### 2.6 Rules — `RHF-REG-*`

| ID | Rule |
| --- | --- |
| `RHF-REG-01` | A field name **MUST** use dot notation (`items.0.name`); brackets **NEVER**. |
| `RHF-REG-02` | A name **NEVER** starts with a number, and **NEVER** uses `type`, `root`, `ref`, `types`, `message`, `form` or `_f`. |
| `RHF-REG-03` | A numeric or date field value **MUST** have explicit coercion — `valueAsNumber`, `valueAsDate`, `setValueAs` or `z.coerce.*`. |
| `RHF-REG-04` | To remove a rule on re-registration, the value **MUST** be `false`; `undefined` **NEVER** removes. |
| `RHF-REG-05` | `disabled: true` **MUST** be used only when the intent is to exclude the field from submission; otherwise, `readOnly`. |

---

## 3. `Controller` and `useController`

They are the same thing: `Controller` is the component, `useController` is the hook that drives it. The choice is one of form, not of behavior.

| Use | When |
| --- | --- |
| `<Controller>` | one-off use, written inline in the form's JSX |
| `useController` | you are packaging a **reusable field component** |

```tsx
<Controller
  name="birthDate"
  control={control}
  render={({ field, fieldState }) => (
    // spread field: name and disabled are part of it too. RHF-CTRL-01
    <DatePicker {...field} aria-invalid={fieldState.invalid || undefined} />
  )}
/>
```

> **`aria-invalid` convention in this doc:** `fieldState.invalid || undefined` (or `error ? true : undefined`), never `!!error`. The `!!` form emits `aria-invalid="false"` on **every** valid field, which is noise for the screen reader; `undefined` omits the attribute.

### 3.1 The `field` object

| Property | Role | If you forget it |
| --- | --- | --- |
| `value` | current value | the component shows nothing |
| `onChange` | returns the value to the form | the value never reaches submit |
| `onBlur` | reports interaction | `touchedFields` and `mode: 'onBlur'` stop working |
| `ref` | lets RHF focus the field with an error | `shouldFocusError` and `setFocus` become a no-op on that field |
| `name` | identity | — |
| `disabled` | disabled state (v7.46.0) | — |

And `fieldState` carries `invalid`, `isTouched`, `isDirty` and `error` **for that field**, without subscribing to the whole form.

### 3.2 The three traps

**`onChange(undefined)` is invalid.** The source is explicit. Clearing a controlled field with `undefined` makes React treat the input as uncontrolled again, and it starts warning in the console.

```tsx
onChange={(v) => field.onChange(v ?? null)}   // ✅ null or '' — never undefined
```

**Spread `field` before overriding.** It is the most common mistake when transforming values: overriding `onChange` without spreading the rest drops `onBlur`, `name` and `ref` with it — and the field loses autofocus and *touched* state without giving any signal.

```tsx
// ❌ loses onBlur, name and ref
<input onChange={(e) => field.onChange(Number(e.target.value))} value={field.value} />

// ✅
<input {...field} onChange={(e) => field.onChange(Number(e.target.value))} />
```

**Do not use `setValue` to update a controlled field.** The path is `field.onChange`. `setValue` works, but it bypasses the `Controller` path and throws off `isDirty`/`isTouched`.

### 3.3 Reusable field component

The pattern `useController` exists to serve. The gain is not aesthetic: it is having correct `aria-*`, `id` and error message **once**, instead of in every field.

```tsx
import { useId } from 'react'
import {
  useController,
  type Control,
  type FieldValues,
  type FieldPath,
} from 'react-hook-form'

type TextFieldProps<T extends FieldValues> = {
  control: Control<T>
  name: FieldPath<T>          // ✅ autocompletes and validates against the form's shape
  label: string
  type?: 'text' | 'email' | 'password'
}

export function TextField<T extends FieldValues>({
  control, name, label, type = 'text',
}: TextFieldProps<T>) {
  const { field, fieldState } = useController({ control, name })
  const id = useId()
  const errorId = `${id}-error`

  return (
    <div>
      <label htmlFor={id}>{label}</label>
      <input
        {...field}
        id={id}
        type={type}
        value={field.value ?? ''}                        // never undefined
        aria-invalid={fieldState.invalid || undefined}
        aria-describedby={fieldState.error ? errorId : undefined}
      />
      {fieldState.error && (
        <p id={errorId} role="alert">{fieldState.error.message}</p>
      )}
    </div>
  )
}
```

Four decisions that are not obvious:

- **`FieldPath<T>` instead of `string`** — `name` starts to autocomplete and to fail at compile time if the field does not exist in the form. Without it, a typo only shows up at runtime, as a field that never validates.
- **`useId` for the `label`/`input`/error trio** — the id needs to be stable between server and client. See `REACT-UTIL-01` in [React - Utility Hooks](react-utility-hooks.md).
- **`value={field.value ?? ''}`** — guards against the input starting out uncontrolled when `defaultValues` does not cover the field. It is a safety net, not a substitute for `RHF-CORE-01`.
- **One `useController` call per component** — the source explicitly recommends it. Each call creates its own subscription, and several in the same component multiply re-renders with no gain.

### 3.4 Transform and parse: when what is displayed differs from what is stored

So far, `register` + coercion (§ 2.4) has handled type conversion. It does not handle **formatting**, and the difference between the two is what decides the mechanism.

| | The user sees | The form stores | Mechanism |
| --- | --- | --- | --- |
| **One-way** | what they typed | another **type** of the same value | `register` + `valueAsNumber` / `setValueAs` |
| **Two-way** | a **formatted** value | another value | `Controller` with `input`/`output` |

Currency, percentage, masked phone, date in local format — all are two-way: `R$ 1.234,56` on screen and `123456` on submit are not the same text. Two-way is **inherently controlled**, and that is why `setValueAs` cannot handle it: it only transforms what comes in, and there is no counterpart for what goes out.

This is the official answer from the documentation (*Advanced Usage*, "Transform and Parse"), and the reason it gives for not stopping at `valueAsNumber`: those options leave `NaN` and `null` unhandled.

#### The pattern

Two pure functions, one for each direction, applied inside `render`:

```tsx
import { useId } from 'react'
import { Controller, type Control, type FieldPath, type FieldValues } from 'react-hook-form'

// input — from what we store to what is seen. Cents → formatted text.
const toDisplay = (cents: number | null | undefined) =>
  new Intl.NumberFormat('pt-BR', {
    style: 'currency', currency: 'BRL',
  }).format((cents ?? 0) / 100)

// output — from what was typed to what we store. Digits only: never touches a float.
const toCents = (text: string) => Number(text.replace(/\D/g, '') || 0)

export function CurrencyField<T extends FieldValues>({
  control, name, label,
}: { control: Control<T>; name: FieldPath<T>; label: string }) {
  const id = useId()

  return (
    <Controller
      control={control}
      name={name}
      render={({ field, fieldState }) => (
        <>
          <label htmlFor={id}>{label}</label>
          <input
            {...field}                                   // RHF-CTRL-01
            id={id}
            type="text"                                  // NOT type="number"
            inputMode="numeric"
            value={toDisplay(field.value as number)}     // input:  stored → seen
            onChange={(e) => field.onChange(toCents(e.target.value))}  // output
            aria-invalid={fieldState.invalid || undefined}
            aria-describedby={fieldState.error ? `${id}-error` : undefined}
          />
          {fieldState.error && (
            <p id={`${id}-error`} role="alert">{fieldState.error.message}</p>
          )}
        </>
      )}
    />
  )
}
```

#### The six decisions

**1. Store cents as an integer, never reais as a float.** `19.99 * 100` is `1998.9999999999998` in JavaScript. Any money arithmetic in floating point accumulates error, and the form is where the value is born. `toCents` strips everything that is not a digit and treats the result **already as cents** — there is no multiplication, so there is no float anywhere.

**2. `type="text"` with `inputMode="numeric"`, not `type="number"`.** An `<input type="number">` rejects `R$ 1.234,56` as a value — the field simply stays empty. On top of that it brings spinners and allows `e`, `+`, `-`. `inputMode="numeric"` brings up the numeric keyboard on mobile without any of those costs.

**3. `{...field}` before overriding.** `RHF-CTRL-01`. Here `value` and `onChange` are replaced, but `onBlur`, `name` and `ref` need to keep flowing, otherwise the field loses `isTouched` and autofocus on error.

**4. The typing model is "by cents".** The user types `1`, `2`, `3`, `4` and sees `R$ 0,01` → `R$ 0,12` → `R$ 1,23` → `R$ 12,34`. It sounds odd when described and it is what every banking app does, for a practical reason: **the cursor always stays at the end**, and the problem of repositioning the cursor in the middle of a mask ceases to exist. The alternative — free typing with formatting on `blur` — requires managing `selectionStart` manually on every render, which is outside RHF's scope and is the origin of most masked-field bugs.

**5. `defaultValues` gets `0`, not `''`.** The stored type is `number`. `RHF-CORE-01` still applies, and `toDisplay` already handles `null`/`undefined` with `?? 0` as a safety net.

**6. The schema validates the domain, not the presentation.** Since `output` has already converted, the schema receives a number:

```tsx
const orderSchema = z.object({
  amount: z.number().int().positive('Enter an amount.'),
})
```

No `z.coerce`, no `.transform()` — and therefore **no requirement for the three generics of `RHF-VAL-02`**. Moving the conversion into the `Controller` instead of the schema is what keeps `z.input` and `z.output` equal.

#### Closing the loop with server data

This is the point where the `RHF-BRIDGE-03` bridge and formatting meet. The server returns cents; `values` injects them; `input` formats them. Nothing else is needed — and neither end needs to know about the other.

```tsx
const { data } = useQuery({ queryKey: ['order', id], queryFn: fetchOrder })

useForm({
  defaultValues: { amount: 0 },
  values: data,                             // { amount: 123456 } in cents
  resetOptions: { keepDirtyValues: true },
})
```

If instead the backend sent `"R$ 1.234,56"`, formatting would be an API contract — and then the conversion belongs to the fetch layer, not to the form.

#### Beyond currency: the three questions that generalize

Currency is the complete case. Percentage, phone and local date use the same skeleton, but **the six decisions above do not transfer whole** — three questions decide which ones apply.

**1. What to store?** The type the consumer expects. If it is numeric with **fixed decimal places** (money, rate, weight), store the integer in the smallest unit — for the reason in decision 1. If it is an identifier (phone, CPF, CEP), store the string of digits: it is not a number, it is not summed, and a leading zero is significant.

**2. Does the unit live inside or outside the `value`?** This is the question the currency section did not need to ask, and it is the one that breaks percentage.

| | Example | Can it live inside the `value`? |
| --- | --- | --- |
| **Prefix** | `R$ ` | **Yes** — typing appends at the end, away from it |
| **Suffix** | ` %`, ` kg` | **No** — the cursor would have to stop before it, and you are back to managing the caret |
| **Internal separator** | `(81) 99999-9999` | Yes — it grows at the end, and the separators are rewritten on every keystroke |

A suffix goes **outside the input**, as adjacent text. This is not an aesthetic detail: it is what preserves the property that makes the whole pattern work.

**3. Does growth happen at the end?** If yes, pure `input`/`output` are enough and the cursor sorts itself out. If not — editing in the middle of a mask, a date field with per-segment navigation — you need `selectionStart` management, which is outside the scope of RHF and of this doc.

#### Percentage

The backend wants `0.15`; the user sees `15%`. Two traps, and the first is the same as currency's seen from another angle.

```tsx
// We store basis points: 1500 = 15.00%. Integer, as decision 1 requires.
const toDisplay = (basisPoints: number | null | undefined) =>
  ((basisPoints ?? 0) / 100).toLocaleString('pt-BR', { minimumFractionDigits: 2 })

const toBasisPoints = (text: string) => Number(text.replace(/\D/g, '') || 0)

// The suffix stays OUTSIDE the input — question 2
<div className="flex items-baseline gap-1">
  <input
    {...field}
    id={id}
    type="text"
    inputMode="numeric"
    value={toDisplay(field.value as number)}
    onChange={(e) => field.onChange(toBasisPoints(e.target.value))}
  />
  <span aria-hidden="true">%</span>
</div>
```

**The float trap is the same, and so is the way out.** `0.15 * 100` is `15.000000000000002`. Storing basis points, no multiplication happens while typing — only a division, and only on display.

**The conversion to `0.15` happens at the boundary, once.** The same criterion as the previous section on `"R$ 1.234,56"` coming from the backend: if the API contract is `0.15`, that is the shape of the **payload**, not the shape of the **form**. Convert where the payload is built:

```tsx
const quoteSchema = z.object({
  discountBasisPoints: z.number().int().min(0).max(10000),
})

const onSubmit = handleSubmit(async (data) => {
  await api.save({ discount: data.discountBasisPoints / 10000 })  // single division
})
```

If the conversion really needs to live in the form, use `.transform()` in the schema — and then `RHF-VAL-02` applies again: three generics.

> **`aria-hidden` on the `%`.** The symbol outside the input is visual decoration: the screen reader should hear it through the `<label>` ("Discount in percent"), not loose after the value. If the label does not make the unit clear, the place to say it is the `<label>` or an `aria-describedby` — not an orphan `<span>`.

#### Variable-length mask — phone

The case the currency section does not cover: **the format depends on how many digits there are**.

```tsx
const toDigits = (text: string) => text.replace(/\D/g, '').slice(0, 11)

const toMask = (digits: string) => {
  const d = digits ?? ''
  const areaCode = d.slice(0, 2)
  const rest = d.slice(2)

  if (d.length <= 2) return areaCode                    // "8", "81" — no parentheses yet
  if (d.length <= 6) return `(${areaCode}) ${rest}`     // "(81) 9999"
  if (d.length <= 10) return `(${areaCode}) ${rest.slice(0, 4)}-${rest.slice(4)}`   // landline
  return `(${areaCode}) ${rest.slice(0, 5)}-${rest.slice(5)}`                        // mobile
}

<input
  {...field}
  id={id}
  type="text"
  inputMode="tel"                                  // phone keyboard, not numeric
  value={toMask(field.value as string)}
  onChange={(e) => field.onChange(toDigits(e.target.value))}
/>
```

Four decisions currency did not require:

- **We store a string, not a number.** `"081..."` would lose the zero as a number, and a phone is not a quantity.
- **`slice(0, 11)` in the `output`, not in the `input`.** Truncation belongs to what is stored. Pasting 15 digits stores 11 and displays 11 — no inconsistent state between what is seen and what is stored.
- **Partial states do not invent punctuation.** With 1 or 2 digits the return is `"8"`/`"81"`, with no `(`. Opening a parenthesis the user did not type makes the field look stuck when they delete everything.
- **10 × 11 digits** decides where the hyphen falls. Landline groups 4-4; mobile, 5-4. One `if` in the `input`, because it is presentation — the `output` stays digits only.

**Validation stays in the schema**, not in the mask: `z.string().length(11, 'Incomplete phone number.')`. The mask formats; it does not decide what is valid.

#### When this is overkill

If the field accepts the **raw** value and only needs to change type (`"42"` → `42`), stay with `register` + `valueAsNumber`. `Controller` reintroduces controlled rendering in that field (§ 1), and paying that for a one-way conversion is what `RHF-CTRL-08` forbids.

### 3.5 Rules — `RHF-CTRL-*`

| ID | Rule |
| --- | --- |
| `RHF-CTRL-01` | When overriding `onChange` or `value`, `field` **MUST** be spread first — `onBlur`, `name` and `ref` need to keep arriving. |
| `RHF-CTRL-02` | `field.onChange` **NEVER** receives `undefined`. Use `null` or `''`. Alias of `RHF-CORE-06`. |
| `RHF-CTRL-03` | `useController` **SHOULD** be called at most once per component — each call creates its own subscription and pays a re-render. It is a performance recommendation from the source, not a correctness rule: two `useController` calls in one component work. |
| `RHF-CTRL-04` | A controlled field **MUST** be updated through `field.onChange`, **NEVER** through `setValue`. |
| `RHF-CTRL-05` | `field.ref` **MUST** reach the focusable element, otherwise `shouldFocusError` and `setFocus` do not work on that field. |
| `RHF-CTRL-06` | `shouldUnregister` is **NEVER** used on a field inside `useFieldArray` — remount and reordering break the state. |
| `RHF-CTRL-07` | The `name` of a reusable field component **MUST** be typed as `FieldPath<T>`, **NEVER** as `string`. |
| `RHF-CTRL-08` | `Controller`/`useController` on a native field **MUST** have a stated reason — encapsulating accessibility in a reusable component counts; convenience does not. Without a reason, use `register`. |
| `RHF-CTRL-09` | A **two-way** transformation (displayed ≠ stored) **MUST** use `Controller` with `input`/`output` functions; `setValueAs` **NEVER** handles it, because it only transforms the input. |
| `RHF-CTRL-10` | A numeric value with **fixed decimal places** (money, rate, weight) **MUST** be stored as an integer in the smallest unit — cents, basis points. `float` **NEVER**. A formatted identifier (phone, CPF, CEP) **MUST** be stored as a string of digits: a leading zero is significant. |
| `RHF-CTRL-11` | A field with a mask or formatting **MUST** use `type="text"` with an appropriate `inputMode` (`numeric` for quantity, `tel` for phone, `decimal` for a value with a decimal comma), **NEVER** `type="number"` — which rejects the formatted value. |
| `RHF-CTRL-12` | A unit **suffix** (`%`, `kg`) **MUST** stay outside the `value`, as adjacent text with `aria-hidden`; inside the `value` it forces you to manage the cursor. A prefix (`R$`) may stay inside. |
| `RHF-CTRL-13` | Length truncation **MUST** happen in the `output` (what is stored), **NEVER** only in the `input` — otherwise what is displayed and what is stored diverge. |

> **The caveat the § 3.3 example requires.** `TextField` uses `useController` on a **native** `<input>`, which by the tree in § 5.1 would be a `register` case. The reason is `RHF-CTRL-08`: `fieldState.error` is local to the field and does not force the component to receive `errors` by prop nor to subscribe to the whole form — which is the point of a reusable field component.
>
> **The price, which needs to be known:** `valueAsNumber`, `valueAsDate` and `setValueAs` are `register` options and **do not exist** in `useController`. A field component built this way loses that coercion path.
>
> Three remain, and the choice is the one in the § 2.4 table:
>
> 1. **`register` with the coercion options** — if the component needs neither `fieldState` nor `Controller`.
> 2. **Coerce in the schema** (`z.coerce.*`) — the natural path when a resolver already exists.
> 3. **Convert in the `Controller` itself**, with `input`/`output` — that is § 3.4, and it is mandatory when the transformation is two-way.
>
> All three satisfy `RHF-REG-03`, which requires **explicit** coercion, not a specific mechanism.

---

## 4. `FormProvider` and `useFormContext`

For large forms, with fields in deep components, `FormProvider` avoids passing `control` through levels that do not use it.

```tsx
const methods = useForm<Profile>({ defaultValues })

<FormProvider {...methods}>
  <form onSubmit={methods.handleSubmit(onSubmit)}>
    <PersonalData />   {/* useFormContext<Profile>() inside — § 4.2 */}
    <Address />
  </form>
</FormProvider>
```

### 4.1 The rule the source highlights

**Do not read `formState` from `useFormContext`.** The official doc says to use `useFormState`. The reason is the Proxy: the subscription is created when the property is **read during the render of the component that will re-render**. Taking `formState` from the context hands you the object, but the read happens in the wrong place.

```tsx
// ❌ the initial value comes out right — and then never updates
const { formState: { errors } } = useFormContext()

// ✅
const { control } = useFormContext()
const { errors } = useFormState({ control })
```

The symptom is misleading precisely because the first render works. The Proxy mechanism is in § 1 of [React Hook Form - State and Performance](react-hook-form-state-and-performance.md).

### 4.2 `control` by prop or by context?

The apparent contradiction: § 4 justifies `FormProvider` as "avoids passing `control`", and the field components in § 3.3 and § 3.4 receive `control` as a **required** prop. It looks like one pattern undoes the other.

It does not, because these are **two kinds of consumer with opposite needs**.

| Consumer | How it gets the form | Why |
| --- | --- | --- |
| **Section of this form** — `<PersonalData />`, `<Address />` | `useFormContext<Profile>()` | It exists for *this* form. It knows `Profile`, and can declare it in the generic |
| **Reusable field** — `<TextField />`, `<CurrencyField />` | `control: Control<T>` by prop | It is used in **different** forms. It cannot know the type — `T` comes from whoever renders it |
| **Inline `Controller`** in the form's own JSX | neither: `control` is already in scope | — |

**What decides is where the type comes from.** `useFormContext()` without a generic returns `Control<FieldValues>`, and `FieldValues` is `Record<string, any>` — with it, `FieldPath<T>` accepts any string and `RHF-CTRL-07` stops applying in practice. The component compiles, autocomplete disappears, and a typo in `name` is a runtime bug again.

```tsx
// ✅ Section: knows the form, declares the type, receives no prop
function PersonalData() {
  const { control } = useFormContext<Profile>()      // ← the generic is the point
  return (
    <>
      <TextField control={control} name="name" label="Name" />
      <TextField control={control} name="email" label="Email" />
    </>
  )
}

// ✅ Reusable field: T is inferred from the control that arrives
function TextField<T extends FieldValues>({ control, name }: {
  control: Control<T>
  name: FieldPath<T>      // autocompletes with Profile's fields at the call site above
}) { /* … */ }
```

**This is not prop drilling.** Drilling is crossing levels that do not use the value. Here `control` travels **one level**, from the section that got it from the context to the field it renders. What `FormProvider` eliminated was the path `<Form>` → `<Step>` → `<Group>` → `<PersonalData>`, which is where the cost was.

**What if the reusable field took it from the context?** It is possible — `Controller` and `useController` accept omitting `control` under `FormProvider`, and the source confirms the prop is optional in that case. The cost is exactly the one described above: without the generic, the component loses the `name` check. An optional `control` with a fallback (`control ?? context`) has the same problem, because the fallback's type is still `FieldValues`.

**Rule of thumb:** the prop exists to carry the **type**, not the value. Where the type is known, use the context with a generic. Where it is not, pass the prop.

### 4.3 Cost and mitigation

`FormProvider` is Context: whoever consumes it re-renders when the context changes. The doc records two points:

- using the **RHF DevTools together with `FormProvider`** can cause performance problems;
- the mitigation is `memo` on the section components **combined with** reading `formState` via `useFormState` in the smallest possible component.

Before reaching for `memo`, apply the order in [React Hook Form](react-hook-form.md) § 5.7 — usually the problem is `formState` read too high, not a lack of memoization.

### 4.4 `ConnectForm` for very deep components

A pattern from the documentation itself (*Advanced Usage*), useful when a nested component needs several methods:

```tsx
export const ConnectForm = ({ children }: { children: (m: UseFormReturn) => ReactNode }) =>
  children(useFormContext())

// usage
<ConnectForm>{({ register }) => <input {...register('zipCode')} />}</ConnectForm>
```

### 4.5 Rules — `RHF-CTX-*`

| ID | Rule |
| --- | --- |
| `RHF-CTX-01` | Inside `FormProvider`, `formState` **MUST** come from `useFormState`, **NEVER** from destructuring `useFormContext`. Alias of `RHF-STATE-01`. |
| `RHF-CTX-02` | The return of `useFormContext`/`useForm` **NEVER** goes whole into a `useEffect` dependency array — destructure the specific method. |
| `RHF-CTX-03` | `useFormContext` **MUST** be called with the form's generic (`useFormContext<Profile>()`) whenever the component knows the type. Without it the return is `Control<FieldValues>` and `RHF-CTRL-07` has no effect. |
| `RHF-CTX-04` | A field component **reusable across forms** **MUST** receive `control` by prop, **NEVER** read it from the context — it is the prop that carries the type `T`. A **section** component does the opposite: reads from the context with a generic. |

> `RHF-CTX-02` comes from an explicit warning in the source: the object returned by `useForm` will become memoized, and depending on it whole is fragile. `useEffect(() => reset(x), [reset])`, not `[methods]`.

---

## 5. Accessibility

The official doc devotes the opening of *Advanced Usage* to this, and it is the part generated code omits most. The target is for the screen reader to announce `"Name, edit, invalid entry, This field is required"` — which requires three things tied together.

```tsx
const id = useId()
const error = errors.name

<label htmlFor={id}>Name</label>
<input
  id={id}
  {...register('name', { required: 'This field is required.' })}
  aria-invalid={error ? true : undefined}
  aria-describedby={error ? `${id}-error` : undefined}
/>
{error && <p id={`${id}-error`} role="alert">{error.message}</p>}
```

| Piece | Why |
| --- | --- |
| `htmlFor` ↔ `id` | without it the field has no accessible name |
| `aria-invalid` | announces the error state |
| `aria-describedby` → the paragraph's `id` | ties the **message** to the field; without it the error is read loose, or not read at all |
| `role="alert"` | interrupts the reader to announce the error as soon as it appears |

**`role="alert"` only for errors.** A success confirmation uses `role="status"`, which waits for the pause instead of interrupting. Same criterion as [React - Forms and Actions](react-forms-and-actions.md) § 3.

**Focus.** `shouldFocusError` (default `true`) moves focus to the first field with an error on submit — but it only works if the `ref` reached a DOM element, and the **order is registration order**, not visual order. In a column layout, this can focus a field that is far from the top. `setFocus(name)` solves it case by case.

### 5.1 Rules — `RHF-A11Y-*`

| ID | Rule |
| --- | --- |
| `RHF-A11Y-01` | A field with an error **MUST** have `aria-invalid` and the message tied by `aria-describedby`. |
| `RHF-A11Y-02` | An error message **MUST** use `role="alert"`; a success confirmation, `role="status"`. |
| `RHF-A11Y-03` | Every field **MUST** have a `<label htmlFor>` associated by a stable `id` (`useId`), **NEVER** only a `placeholder`. |
| `RHF-A11Y-04` | In a form with a multi-column layout, registration order **MUST** be checked against visual order, or error focus jumps. |

---

## 6. Antipatterns

| Antipattern | Fix |
| --- | --- |
| `useState` per field, synced with the form | remove it; the value is already in RHF |
| `Controller` on a native `<input>` **without a reason** | `register` · `RHF-CTRL-08` |
| `register` spread on a component that does not forward `ref` | `Controller` · `RHF-CORE-03` |
| `{...register('x')}` **and** `<Controller name="x">` on the same field | pick one · `RHF-CORE-04` |
| `onChange` overridden without spreading `field` | spread first · `RHF-CTRL-01` |
| `field.onChange(undefined)` to clear | `null` or `''` · `RHF-CTRL-02` |
| `setValue` to edit a field under `Controller` | `field.onChange` · `RHF-CTRL-04` |
| `errors` read from `useFormContext()` | `useFormState({ control })` · `RHF-CTX-01` |
| `useFormContext()` without a generic in a component that knows the form | `useFormContext<Profile>()` · `RHF-CTX-03` |
| Reusable field reading `control` from the context | receive it by prop; the prop carries the type · `RHF-CTX-04` |
| `register('items[0].name')` | dot notation · `RHF-REG-01` |
| `<input type="number">` without coercion | `valueAsNumber` / `z.coerce.number()` · `RHF-REG-03` |
| `setValueAs` trying to display a formatted value | it is two-way: `Controller` with `input`/`output` · `RHF-CTRL-09` |
| Currency or rate stored as `float` | integer in the smallest unit · `RHF-CTRL-10` |
| Phone/CPF stored as a number | string of digits · `RHF-CTRL-10` |
| `type="number"` on a masked field | `type="text"` + `inputMode` · `RHF-CTRL-11` |
| `%` or `kg` inside the input's `value` | outside, as adjacent text · `RHF-CTRL-12` |
| Mask truncating only on display | truncate in the `output` · `RHF-CTRL-13` |
| Mask deciding what is valid | validation belongs to the schema; the mask only formats |
| `z.coerce`/`.transform()` on a field that already has a `Controller` with `output` | duplicated conversion; keep it only in the `output` |
| `disabled` to "show without editing" | `readOnly` · `RHF-REG-05` |
| `placeholder` instead of `<label>` | `label` + `htmlFor` · `RHF-A11Y-03` |
| Error message without `aria-describedby` | tie it by `id` · `RHF-A11Y-01` |
| `name: string` in a reusable field component | `FieldPath<T>` · `RHF-CTRL-07` |

---

## Related

- [React Hook Form](react-hook-form.md) — entry, decision trees, skill contract
- [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) · [React Hook Form - State and Performance](react-hook-form-state-and-performance.md)
- [React - Refs and DOM](react-refs-and-dom.md) — `ref` as a prop in React 19
- [React - Utility Hooks](react-utility-hooks.md) — `useId` and `REACT-UTIL-01`
- [React - Forms and Actions](react-forms-and-actions.md) — the same `role="alert"` / `role="status"` criterion

## Sources consulted

Verified on 2026-08-15:

- [register](https://react-hook-form.com/docs/useform/register) — merge on re-registration, reserved names and name restrictions confirmed
- [Controller](https://react-hook-form.com/docs/usecontroller/controller) — `exact` defaults to `true` since v7.68.0; warning about `onChange(undefined)`
- [useController](https://react-hook-form.com/docs/usecontroller) — recommendation of one call per component
- [useFormContext](https://react-hook-form.com/docs/useformcontext) — explicit guidance to use `useFormState` for `formState`
- [Advanced Usage](https://react-hook-form.com/advanced-usage) — accessibility, `ConnectForm`, `FormProvider` performance, and the *Transform and Parse* section that grounds § 3.4: the `input`/`output` pattern in `Controller` and the rationale that `valueAsNumber`/`valueAsDate` leave `NaN` and `null` unhandled
- [TypeScript](https://react-hook-form.com/ts) — `FieldPath`, `Control`, `ControllerRenderProps`
