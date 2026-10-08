---
titulo: React Hook Form
Link: https://react-hook-form.com/get-started
tags:
  - react
  - forms
  - react-hook-form
  - frontend
  - reference
  - agent-context
source: "Official React Hook Form documentation — react-hook-form.com"
verificado-em: 2026-08-15
---

# React Hook Form — guided reference

> **What this note is.** The single entry point for React Hook Form in this vault: for me when looking things up, and for coding agents when generating or reviewing forms. It is not a linear summary of Get Started — it is a **router**. It decides what to load, offers the mental model that makes the rest make sense, and exposes citable rules that a skill or a code review can reference by ID.
>
> **What it is not.** It does not replace the source. When they diverge, [react-hook-form.com](https://react-hook-form.com/docs) wins, and this note must be corrected.
>
> **A self-contained family.** These notes live inside the `react` skill family, not in the tc96 knowledge base, so the family can move without it. Names in code spans — `TanStack Query`, `TanStack Router`, `Storybook`, `Monorepo com Bun - estrutura e tooling` — and IDs from other families (`TSQ-*`, `TSR-*`, `SB-*`, `PW-*`) belong to the tc96 knowledge base: useful context when it is installed, never required to apply a `REACT-*`, `RHF-*` or `REACT-ARCH-*` rule.

Surface verified directly on react-hook-form.com on **2026-08-15**, on the **v7** line (version references go up to v7.85.0).
See [Sources consulted](#sources-consulted).

This doc assumes [React.js](react-js.md). RHF does not replace any React rule — it adds a layer. `REACT-PURE-*` and `REACT-HOOK-*` still apply inside every form component.

---

## 1. How to use this doc

### For a human

Read section 2 once — it is short and explains why the API has the shape it has. Then use section 5 when you are torn between two APIs, and section 4 as an index. The satellites are on-demand reading.

### For a coding agent

Load in this order, stopping as soon as you have enough:

| Step | Load | When |
| --- | --- | --- |
| 1 | This note (§ 2, § 5, § 6) | Whenever the task involves a form in React |
| 2 | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) | When **connecting fields** — `register`, library component, reusable component, formatted field (currency, mask) |
| 3 | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) | When defining **what is valid** or handling an error coming from the server |
| 4 | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) | When **reading** form state, reacting to values, dynamic lists, or investigating re-renders |
| 5 | [React - Forms and Actions](react-forms-and-actions.md) | When the decision in § 5.4 points to native Actions |

**Context economy rule:** load one satellite at a time, guided by § 5.

> **The exception the rule has to admit:** a realistic CRUD form — controlled UI component + schema validation + dynamic list — triggers all three conditions at once. In that case load all three; the rule exists to prevent preventive "just in case" loading, not to prevent covering what the task actually touches. The sign that you are violating the spirit of the rule is opening a satellite **before** you know you need it.

### Conventions and vocabulary

**All examples are TypeScript**, and assume `react-hook-form` v7 with `@hookform/resolvers` + (the top-level `z.email()` form is Zod 4; in Zod 3 it is `z.string().email()`).

Three rules depend on types and make no sense in JS: `RHF-VAL-02`, `RHF-VAL-04` and `RHF-CTRL-07`. Apart from those, in JS just ignore the annotations.

Terms used without redefinition in the satellites:

| Term | Meaning in this doc |
| --- | --- |
| **uncontrolled field** | the value lives in the DOM node; React does not re-render it on every keystroke. It is RHF's default mode |
| **controlled field** | the value lives in someone's state and comes back as a prop on every render. It is what `Controller` takes over managing |
| **register** | introducing a field to the form, giving it a name and rules — via `register`, `Controller` or `useController` |
| **subscription** | the link that makes a component re-render when something in the form changes. In RHF it is **created by reading**, not declared |
| **`formState`** | the form's state object (errors, dirty, submitting…), delivered behind a Proxy |
| **resolver** | adapter that delegates validation to an external schema and returns `{ values, errors }` |
| **dirty** | differs from `defaultValues`. Not the same as *touched*, which is "the user passed through here" |
| **root error** | error that belongs to no field, stored in `errors.root.*` |
| **coercion** | converting what the DOM returns (always a string) into the type the domain expects |
| **`control`** | the object returned by `useForm` that carries the connection to the form. It is what you pass to `useController`, `useWatch`, `useFormState` and `Controller` so that a component **outside** `useForm` connects to it. Under `FormProvider`, it is optional |
| **`rules`** | the validation rules declared in `register`/`Controller` (`required`, `min`, `validate`, `deps`…). **They do not run when there is a `resolver`** — `RHF-VAL-06` |
| **`deps`** | `register` rule that tells other fields to revalidate together with this one |

---

## 2. Mental model

Five statements. Almost every RHF mistake an agent makes violates one of them.

**1. The form does not live in React state.** RHF keeps values outside the render cycle — in the DOM node itself, via `ref`, and in an internal store. Typing re-renders nothing. This is the inversion that explains the rest of the API: if you reintroduce `useState` per field, or scatter `watch()` across the root, you pay back exactly the cost the library eliminated.

**2. `register` is the default path; `Controller` is the bridge.** The criterion is not aesthetic preference: it is whether the component **forwards `ref` and emits native events**. A DOM `<input>` forwards — `register` is enough. A design-system `<Select>` that only accepts `value`/`onChange` does not forward — it needs `Controller`, which reintroduces controlled rendering *for that field only*.

**3. `formState` is a subscription Proxy, not an object.** You only receive updates for the properties you **read unconditionally during render**. A property accessed behind `&&`, `||`, a ternary or an `if` may never be read — the Proxy does not subscribe to it, and it simply does not update. This is not a bug: it is the mechanism that avoids computing `isValid` for whoever did not ask for it.

**4. `defaultValues` is the form's contract.** `isDirty` and `dirtyFields` compare against it. `reset()` goes back to it. A controlled component depends on it so it does not start uncontrolled. A field missing from `defaultValues` compares against `undefined`, and React complains about an input changing from uncontrolled to controlled on the first character.

**5. Client validation is a UX boundary, not a guarantee.** The resolver turns untrusted input into typed data **in the browser** — which improves the experience and protects nothing. The server always revalidates, and whatever it rejects comes back through the form's error path, not through an exception..

> **The most surprising consequence.** Because the value is not in React state, reading a field **is a choice with a cost**, not a free access. That is why there are five ways to read (`getValues`, `watch`, `useWatch`, `useFormState`, `subscribe`) instead of one: each pays a different render price. The tree in § 5.2 is the part of this doc that prevents the most bad code.

---

## 3. Package boundaries

| Package | Contains | Note |
| --- | --- | --- |
| `react-hook-form` | `useForm`, `useController`/`Controller`, `useFormContext`/`FormProvider`, `useWatch`, `useFormState`, `useFieldArray`, `<Form>`, `createFormControl` | the core; no validator dependency |
| `@hookform/resolvers` | `zodResolver` and adapters for ~19 libraries (Yup, Joi, Valibot, ArkType, Vest, Ajv, TypeBox, standard-schema…) | install together with the chosen validator |
| `@hookform/error-message` | `<ErrorMessage>` | optional; display convenience |
| `@hookform/lenses` | `useLens` | **separate package.** It appears in the official doc's index, which leads you to treat it as core — it is not |
| `@hookform/devtools` | inspection panel | development only. The doc warns that using it together with `FormProvider` can cause performance problems |

```bash
npm install react-hook-form @hookform/resolvers zod
```

---

## 4. API map

Verified surface. The **Satellite** column says what to load.

**Deliberately outside this map:** third-party integrations, validator adapters other than Zod, and the React Native documentation. If the task requires one of them, consult the source: absence here means "not verified in this doc", not "does not exist".

### Hooks

| Hook | What it is for | Satellite |
| --- | --- | --- |
| `useForm` | Creates and owns the form; returns all the methods | this note § 4.3 |
| `useController` | Connects a controlled component; it is the engine of `Controller` | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `useFormContext` | Reads the form's methods in a nested component | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `useWatch` | Subscribes to values **isolating the re-render** in the calling component | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `useFormState` | Subscribes to `formState` isolating the re-render | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `useFieldArray` | Lists of fields: append, remove, move, replace | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |

### Components

| Component | What it is for | Satellite |
| --- | --- | --- |
| `<Controller>` | Wraps a controlled component, inline in the JSX | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `<FormProvider>` | Distributes the form context to the subtree | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `<Form>` | Managed submission with built-in HTTP sending — **BETA** since v7.44.0 | this note § 5.4 |

### 4.3 `useForm` methods

Grouped by intent, because that is how the choice happens.

| Intent | Methods |
| --- | --- |
| **Connect fields** | `register`, `unregister`, `control` |
| **Submit** | `handleSubmit` |
| **Read values** | `getValues`, `watch` (+ the hooks `useWatch`, `useFormState`) — the **five ways to read** from § 2 are these plus `subscribe` |
| **Read a field's state** | `getFieldState` — requires a `formState` subscription; see `RHF-STATE-08` |
| **Observe without render** | `subscribe` |
| **Write** | `setValue`, `setValues`, `reset`, `resetField`, `resetDefaultValues` |
| **Errors and manual validation** | `setError`, `clearErrors`, `trigger` |
| **Focus** | `setFocus` |

> **Correction of an earlier verification.** A previous version of this note marked `setValues`, `resetDefaultValues` and `createFormControl` as "not verified" because of a 404. The 404 was a **URL** problem: the page is `/docs/createFormControl`, in camelCase. All three exist and are verified:
>
> | API | Page | Since | What it does |
> | --- | --- | --- | --- |
> | `setValues` | `/docs/useform/setvalues` | v7.74.0 | writes several fields **in a single re-render**, instead of N `setValue` calls. Accepts `shouldValidate`/`shouldDirty`/`shouldTouch`/`delayError` |
> | `resetDefaultValues` | `/docs/useform/resetdefaultvalues` | v7.77.0 | swaps the `defaultValues` **baseline** and recomputes `isDirty`/`dirtyFields` against it, **without** changing the form's current values |
> | `createFormControl` | `/docs/createFormControl` | v7.55.0 | creates the form subscription **outside a component**; returns `formControl` for `useForm`, `control` for the hooks, and `subscribe` to observe without re-render. It is the alternative to Context |
>
> `resetDefaultValues` is what was missing for the "I loaded remote data and want `isDirty` to start comparing against it" case — before it, `reset` with `keepDirtyValues` was the only way out (`RHF-BRIDGE-03`).

### 4.4 `useForm` options

| Option | Default | What it does | Satellite |
| --- | --- | --- | --- |
| `mode` | `'onSubmit'` | When to validate **before** the first submit | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `reValidateMode` | `'onChange'` | When to revalidate **after** the first submit | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `defaultValues` | — | Initial values; accepts an `async` function | this note § 2 |
| `values` | — | **Reactive** values coming from outside (server, store). v7.41.0 | § 8.2 and `RHF-BRIDGE-03` |
| `errors` | — | Reactive errors coming from the server. v7.49.0 | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `resetOptions` | — | What to preserve when `values` changes (`keepDirtyValues`, `keepErrors`) | § 8 |
| `resolver` | — | Delegates validation to an external schema | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `context` | — | Mutable object passed to the resolver | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `validate` | — | Form-level validation. v7.72.0 — **exclusive with `resolver`** | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `criteriaMode` | `'firstError'` | One error per field or all of them | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `delayError` | — | Delays the error's **display** by ms | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `shouldFocusError` | `true` | Focuses the first field with an error on submit | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `shouldUnregister` | `false` | Whether an unmounted field loses its value | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `shouldUseNativeValidation` | `false` | Uses the browser's Constraint Validation API | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `progressive` | `false` | Emits `required`/`min`/`pattern` as HTML attributes. v7.44.0 | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `disabled` | `false` | Disables the whole form. v7.48.0 | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `formControl` | — | Receives a control created outside React | § 4.3 (caveat) |

---

## 5. Decision trees

The goal is to map **symptom → correct API**, because that choice is where generated form code usually goes wrong.

### 5.1 How do I connect this field?

```
Is the field a native element (input, select, textarea)?
├── YES
│   └── Is what the user SEES what the form STORES?
│       ├── YES, only the TYPE changes ("42" → 42, "2026-08-15" → Date)
│       │   → register + explicit coercion: valueAsNumber, valueAsDate,
│       │     setValueAs, or z.coerce.* in the schema.
│       │     The DOM ALWAYS returns a string.        RHF-REG-03
│       └── NO — displays formatted and stores something else
│           (currency, percentage, phone, mask)
│           → two-way. setValueAs does NOT solve it: it only transforms
│             the input. Use Controller with input/output.
│             → [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) § 3.4
│                                                      RHF-CTRL-09
└── NO — it is a library or design-system component
    └── Does it forward `ref` and emit onChange with the native event?
        ├── YES → register works; spread its return onto it
        └── NO — only accepts value/onChange
            │   (common case: Select, DatePicker, Combobox, rich editor,
            │    wrappers that only expose value/onChange)
            ├── One-off use, written inline in the form's JSX → <Controller>
            └── Will become a reusable component → useController

Never both together: a field under Controller is not registered
again with register.  RHF-CORE-04
```

> **Do not decide by library name.** The branch's question is about the **component**, not about the package it comes from. Large libraries are mixed: several Radix primitives forward `ref` and render a hidden native input precisely to work with forms, and wrapper components in the same library do not forward. The test is empirical and takes seconds — spread `register` and see whether the value arrives on submit. If it does, `Controller` there is controlled rendering you paid for without needing it (`RHF-CTRL-08`).

### 5.2 I need to read a value. How?

The right question is not "how do I read", it is **what for**. This is where most render cost is created or avoided.

```
What are you going to use the value for?
├── Only on submit
│   → DO NOT READ. handleSubmit already delivers the whole object, validated.
│     Reading in order to submit is the most common waste.
│
├── For a one-off check inside a handler, without affecting the UI
│   → getValues() — subscribes to nothing, does not re-render
│
├── To RENDER something that depends on the value
│   ├── In a small, isolated component (the normal case)
│   │   → useWatch({ control, name }) — the re-render stays in the component
│   └── Needs the whole form in the root component AND the root is small
│       → watch(). In a large form this is forbidden, not
│         a trade-off: push the read down.             RHF-PERF-01
│
├── To trigger a side effect without UI (autosave, analytics, log)
│   → subscribe({ name, formState, callback })
│     watch(callback) does this and is DEPRECATED           RHF-PERF-02
│
└── To read the form's STATE (errors, isDirty, isSubmitting…)
    ├── In the same component that called useForm
    │   → destructure formState, BEFORE render         RHF-CORE-02
    └── In a nested component, or inside FormProvider
        → useFormState({ control })  RHF-STATE-01
```

> **Why not `useFormContext()` to read `formState`.** The official `useFormContext` doc is explicit: use `useFormState`. The subscription Proxy only registers what was read **during that component's render**; when you take `formState` from context you get the object, but the read happens in the wrong component. The result is state that does not update — and the symptom is misleading, because the *initial* value is correct.

### 5.3 Where do I validate?

```
Is the rule expressible in a schema?
├── YES → resolver (zodResolver). Single source, reusable on the server.
│   └── Does the rule cross fields (password × confirmation, start × end date)?
│       → .refine() / .superRefine() in the schema, not per-field validate
└── NO
    ├── Trivial single-field rule (required, min) and the project has no schema
    │   → register rules
    ├── Rule that requires I/O (email already exists, coupon is valid)
    │   ├── IS there a resolver in the project? Then register rules do NOT
    │   │   run — neither validate nor deps.           RHF-VAL-06
    │   │   → async .refine() in the schema, OR only on submit
    │   │     via setError. Prefer submit if you are not going
    │   │     to implement debounce and cancellation.  RHF-VAL-10
    │   └── NO resolver → async validate in register
    │       Depends on another field? → deps, to revalidate together
    └── Whole-form rule, no resolver in the project
        → validate in useForm (v7.72.0)
          NEVER together with resolver — they are exclusive.  RHF-VAL-01

Whatever the answer: the server revalidates.  RHF-CORE-05
```

### 5.4 Who owns the submission?

This is the boundary with [React - Forms and Actions](react-forms-and-actions.md). Getting it wrong produces forms with two owners, in which the execution order is no longer yours.

```
Do you need per-field validation, per-field errors, a dynamic array
of fields, or a multi-step form?
├── NO → React 19's native Actions are enough.
│         useActionState + <form action>. Fewer dependencies, less code.
│         → [React - Forms and Actions](react-forms-and-actions.md). Stop here.
└── YES → React Hook Form owns the CAPTURE.
    └── Where does the mutation happen?
        ├── Server Function / Server Action (Next.js, TanStack Start)
        │   → handleSubmit validates and, INSIDE it, you call the action.
        │     No <form action>. No bridge via useEffect.    RHF-BRIDGE-02
        ├── TanStack Query mutation (there is cache to invalidate)
        │   → handleSubmit calls mutateAsync.
        │     The mutation owns the optimism and the invalidation.  RHF-BRIDGE-04
        └── Isolated call, no cache and no RSC
            → handleSubmit calls the function and handles the return

NEVER both owners at the same time:
  <form action={serverAction} onSubmit={handleSubmit(...)}>   ❌
Pick one.  RHF-BRIDGE-01
```

> **What about RHF's own `<Form>`?** It exists, sends the HTTP request by itself and supports progressive enhancement — but it has been marked **BETA** since v7.44.0. While that holds, it is not this doc's default: use `<form onSubmit={handleSubmit(...)}>`. The legitimate exception is real progressive enhancement (the form needs to work before hydration), and then the cost of the beta is a conscious decision, recorded in the code.

### 5.5 Where does the error live?

```
Does the error belong to a specific field?
├── YES
│   ├── It came from client validation
│   │   → the resolver or the rules already fill errors[field]. Nothing to do.
│   └── It came from the server (409 email in use, 422 invalid field)
│       → setError('email', { type: 'server', message })   RHF-ERR-02
│         WARNING: an error set on a field that has validation is erased
│         on the next round. If it needs to survive → root.  RHF-ERR-04
└── NO — it belongs to the whole form
    ├── Expected (invalid credentials, insufficient balance, unavailable)
    │   → setError('root.serverError', { type: String(status), message })
    └── Unexpected (bug, broken contract, unforeseen exception)
        → let it bubble up to the Error Boundary. Do not catch it to display it.
        →

In no case is the expected error thrown from inside onSubmit:
handleSubmit does not swallow exceptions, and isSubmitSuccessful ends up wrong.
RHF-ERR-03
```

### 5.6 The form has several steps. One `useForm` or several?

The question looks like one of organization and is one of architecture: it decides the schema, the "Next" button and what happens when going back.

```
Do the steps have a CROSS rule that must warn before the last one?
(e.g.: "business customer requires an invoice", with the type in step 1
 and the invoice in step 3)
├── NO — the common case
│   → ONE FORM PER STEP, with an accumulator in the wizard.
│     Each step: its own schema, its own isValid, handleSubmit
│     as "Next".                                   RHF-STEP-01
│     Going back filled in = values fed by the accumulator.
│                                                  RHF-STEP-03
└── YES
    → a single useForm, with trigger(['fields','of','the','step']).
      Cost: isValid is global and useless for the button, and the
      source does NOT say whether errors stays restricted to the step.
      Filter by field.                             RHF-STEP-05

In both cases, before sending: safeParse the accumulated object
against the FULL schema. The steps validated fragments.
                                                   RHF-STEP-04
```

> **Why the recommendation inverts the instinct.** One form per step looks like "more state to coordinate". It is the opposite: the accumulator is an ordinary `useState`, and in exchange four problems disappear at once — `isValid` becomes useful again, errors from future steps do not leak, going back without losing data stops depending on RHF remembering an unmounted field, and `shouldUnregister` stops mattering. Detail and code in [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) § 7.

### 5.7 The form is slow or re-rendering too much

Order from cheapest to most expensive. It is normative and detailed in the "Re-render investigation order" section of [React Hook Form - State and Performance](react-hook-form-state-and-performance.md).

```
0. DID YOU MEASURE? React DevTools Profiler. Without a measurement, stop here.
   (the same REACT-PERF-01 from [React.js](react-js.md) applies here)

1. Is there a useState mirroring a field?
   → remove it. The value is already in the form.

2. Is there a watch() without an argument, or watch in a large component?
   → replace with useWatch in the smallest component that needs the value
     RHF-PERF-01

3. Is formState being read at the top and passed down as a prop?
   → each consumer subscribes to what it needs with useFormState  RHF-STATE-01

4. Is there a Controller where register would do?
   → Controller reintroduces controlled rendering. Only use it when the
     component does not forward ref.  RHF-CORE-03

5. Is it a long list with useFieldArray?
   → the cost is node volume, not computation. Virtualize or paginate;
     memoizing the row does not solve it on its own.

6. Only then: memo on the row/field, with stable props.
```

---

## 6. Normative rules

Rules citable by ID. A skill, a review prompt or a PR comment can reference `RHF-CORE-01` without repeating the text. The full body of each family lives in the corresponding satellite; the inviolable ones stay here.

**Convention:** `MUST` / `NEVER` are normative. A violation is a bug, not a matter of style.

### `RHF-CORE-*` — the core

| ID | Rule |
| --- | --- |
| `RHF-CORE-01` | `defaultValues` **MUST** cover every field in the form. `isDirty`, `dirtyFields`, `reset()` and controlled components depend on it; a missing field compares against `undefined`. |
| `RHF-CORE-02` | Every `formState` property the render depends on **MUST** be read unconditionally during render. The Proxy subscribes to what was **read**: access behind `&&`/`||`/a ternary or inside an `if` does not subscribe, and that property never updates. Destructuring at the top is the simplest way to guarantee this — but the defect is the conditional access, not the fact of keeping the object. |
| `RHF-CORE-03` | A component that does not forward `ref` **MUST** be connected through `Controller`/`useController`, never through spread `register`. |
| `RHF-CORE-04` | A field under `Controller`/`useController` is **NEVER** registered again with `register`. Double registration. |
| `RHF-CORE-05` | Client validation is **NEVER** a guarantee. Every mutation **MUST** revalidate and authorize on the server. Alias of `REACT-RSC-06`. |
| `RHF-CORE-06` | `field.onChange` **NEVER** receives `undefined`. Use `null` or `''` — `undefined` makes the input go back to being uncontrolled. |

### 6.1 Critical rules from the satellites

The full families live in the satellites, but **these need to travel with the minimal path** — they are the ones that show up most in generated code and cannot depend on the agent having opened the right satellite.

| ID | Rule | Satellite |
| --- | --- | --- |
| `RHF-REG-01` | A field name **MUST** use dot notation (`items.0.name`), never brackets. | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `RHF-REG-03` | The value of `<input type="number">` or `date` **MUST** have explicit coercion — the DOM returns a string. | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `RHF-CTRL-01` | When overriding `onChange`/`value` on a `Controller`, `field` **MUST** be spread first — otherwise `onBlur`, `name` and `ref` are lost. | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `RHF-CTRL-09` | A two-way transformation (displayed ≠ stored: currency, mask) **MUST** use `Controller` with `input`/`output`; `setValueAs` only transforms the input. | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `RHF-A11Y-01` | A field with an error **MUST** have `aria-invalid` and the message linked through `aria-describedby`. | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `RHF-A11Y-02` | An error message **MUST** use `role="alert"`; a success confirmation, `role="status"`. | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `RHF-A11Y-03` | Every field **MUST** have a `<label htmlFor>` with a stable `id`; `placeholder` **NEVER** replaces a label. | [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) |
| `RHF-VAL-06` | With an active `resolver`, `register` `rules` — `validate` and `deps` included — **NEVER** run. | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `RHF-ERR-04` | A server error that needs to survive the field's revalidation **MUST** go to `root.*`. | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `RHF-VAL-01` | `resolver` and `useForm`'s `validate` **NEVER** coexist — they are mutually exclusive. | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `RHF-VAL-02` | A schema with `.transform()`/`.default()` **MUST** declare all three generics: `useForm<z.input<S>, unknown, z.output<S>>`. | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `RHF-VAL-04` | The form's type is **NEVER** written by hand in parallel to the schema — it derives from it. | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `RHF-ERR-02` | An error coming from the server **MUST** enter through `setError`: a field error on the field, a global one in `root.serverError`. | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `RHF-ERR-03` | An expected error is **NEVER** thrown from inside `onSubmit`. Alias of `REACT-ASYNC-09`. | [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) |
| `RHF-STATE-01` | Inside `FormProvider`, form state **MUST** come from `useFormState`, not from destructuring `useFormContext`. | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `RHF-STATE-02` | A post-submission `reset` **MUST** run in a `useEffect` observing `isSubmitSuccessful` **and** a real success signal — see the trap below. | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `RHF-PERF-01` | `watch()` without an argument **NEVER** in a large component — it re-renders the root. Use `useWatch`. | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `RHF-PERF-02` | A reaction without UI **MUST** use `subscribe`; `watch(callback)` is marked as deprecated in the source (no version declared). | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `RHF-PERF-03` | The return of `watch`/`useWatch` **NEVER** goes into a `useEffect` dependency array — it is optimized for the render phase. To react outside render, `subscribe`. Writing back to the form from there is the standard path to a render loop. | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `RHF-ARRAY-01` | The `useFieldArray` `key` **MUST** be `field.id`, never the index. | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `RHF-STEP-01` | A wizard **MUST** have one `useForm` per step, with its own schema — unless a cross rule needs to warn before the last step. | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `RHF-STEP-04` | Before sending, the accumulated object **MUST** be validated against the full schema; the steps validated fragments. | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `RHF-ARRAY-02` | `useFieldArray` entries **MUST** be objects, never primitives. | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |
| `RHF-ARRAY-04` | `append` **MUST** receive the complete entry with all defaults; `append({})` leaves fields out of the form state. | [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) |

### The reset trap: three correct rules, one bug

These three, followed to the letter, wipe out the user's work:

1. `RHF-ERR-03` — an expected error is **not** thrown from `onSubmit`; it becomes `setError`.
2. `isSubmitSuccessful` means "the submission finished **without throwing**" — not "the server accepted".
3. `RHF-STATE-02` — reset in a `useEffect` observing `isSubmitSuccessful`.

Chained: the API returns 422, you catch it, call `setError`, do not throw → `isSubmitSuccessful` becomes `true` → the Effect resets → **the fields and the errors you just displayed disappear together.**

```tsx
// WRONG — also resets when the server rejected
useEffect(() => {
  if (isSubmitSuccessful) reset()
}, [isSubmitSuccessful, reset])

// RIGHT — the success signal is yours, not RHF's
const onSubmit = handleSubmit(async (data) => {
  try {
    await mutateAsync(data)
    setSavedSuccessfully(true)
  } catch (e) {
    setError('root.serverError', { message: messageFrom(e) })
  }
})

useEffect(() => {
  if (savedSuccessfully) { reset(); setSavedSuccessfully(false) }
}, [savedSuccessfully, reset])
```

| ID | Rule |
| --- | --- |
| `RHF-STATE-09` | `isSubmitSuccessful` is **NEVER** used alone as the `reset` condition when `onSubmit` catches a server error — it indicates the absence of an exception, not acceptance by the server. |

> The `RHF-BRIDGE-*` rules are defined in § 8.3, together with the context that justifies them.

### 6.2 Canonical IDs

Two principles already exist in the React corpus under another ID, because each doc needs to stand on its own.

**Citation rule:** inside a review restricted to forms, the `RHF-*` ID is enough and is what the satellites' tables use. **When citing across docs** — a React review that touches a form, or vice versa — use the canonical one, otherwise the reviewer cannot find the text.

| Principle | Canonical | Aliases |
| --- | --- | --- |
| An expected error is state, not an exception for a boundary | `REACT-ASYNC-09` ([React - Suspense and Async](react-suspense-and-async.md)) | `RHF-ERR-03`, `REACT-FORM-03`, `REACT-PAT-07` |
| The server revalidates and authorizes at the boundary | `REACT-RSC-06` ([React - Server Components and Directives](react-server-components-and-directives.md)) | `RHF-CORE-05`, `REACT-FORM-08`, `REACT-PAT-09` |

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

### Full families in the satellites

`RHF-REG-*` · `RHF-CTRL-*` · `RHF-CTX-*` · `RHF-A11Y-*` — [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md)
`RHF-VAL-*` · `RHF-ERR-*` — [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md)
`RHF-STATE-*` · `RHF-PERF-*` · `RHF-ARRAY-*` · `RHF-STEP-*` — [React Hook Form - State and Performance](react-hook-form-state-and-performance.md)
`RHF-BRIDGE-*` — this note, § 8.3

RHF's own internal aliases are in the table in § 6.2.

**Two rules live outside the satellite their family suggests**, because the context that justifies them is here: `RHF-STATE-09` (§ 6.1, the reset trap) and `RHF-BRIDGE-05` (§ 8).

---

## 7. Skill contract

How a forms skill should consume this doc.

### What to load

```
ALWAYS:   react-hook-form.md § 2 (mental model)
                             § 5 (decision trees)
                             § 6 + § 6.1 (rules)
                             § 8.3 (bridge rules)   ← do not omit
          react-js.md § 6 (REACT-PURE-*, REACT-HOOK-*)

BEFORE deciding to use RHF:
          § 5.4 — native Actions may be enough
          react-forms-and-actions.md, if the tree points there

WHEN CONNECTING FIELDS, with a formatted field (currency, mask),
or when labeling/associating an error for a screen reader:
          react-hook-form-registration-and-control.md

WHEN DEFINING VALIDATION or HANDLING A SERVER ERROR:
          react-hook-form-validation-and-resolvers.md

WHEN READING STATE, REACTING TO VALUES, LISTS, MULTI-STEP FORM,
or INVESTIGATING RE-RENDER:
          react-hook-form-state-and-performance.md

NEVER:    open a satellite BEFORE you know you need it
```

**On loading more than one satellite.** The rule is about sequence, not a ceiling. A **narrow** task — "why does this button not enable?" — touches one satellite and stops there. A **broad** task — reviewing a whole form, writing a CRUD from scratch — touches all three, because connecting fields, validating and reading state are three things every form does.

The waste the rule fights is preventive loading: opening everything "just in case" before running § 5. The sign of a violation is opening a satellite without being able to say which branch of § 5 sent you there.

> **Why § 8.3 is in ALWAYS.** The `RHF-BRIDGE-*` rules decide who owns the submission, where the remote data comes from and who owns the sending state. They apply **before** any satellite and are cited by all of them — `RHF-BRIDGE-03` in particular is the root cause of the most common mistake in an edit form (static `defaultValues` receiving data from `useQuery`).

### How to cite

Review findings cite the rule's ID and the satellite; they do not paraphrase:

> `RHF-PERF-01` — `watch()` without an argument in the root component re-renders the whole form on every keystroke. Use `useWatch` in the component that needs the value.
> See [React Hook Form - State and Performance](react-hook-form-state-and-performance.md).

### Invariants the skill must enforce

1. **Decide before installing.** § 5.4 comes before any code. RHF is the right answer for a complex form, not for every form.
2. **Verify before asserting.** If an API is not in § 4, it was not verified in this doc. Consult the source and update the note — do not invent behavior. 
3. **The source wins.** A divergence between this note and react-hook-form.com is a bug in this note.
4. **React rule before RHF rule.** A violation of `REACT-PURE-*` or `REACT-HOOK-*` takes precedence: RHF suspends none of them.
5. **One owner per submission.** `RHF-BRIDGE-01` is the rule that saves the most debugging.
6. **Do not optimize without measuring.** The order in § 5.7 is mandatory, and it starts with "did you measure?".

### When creating a new skill

Derive it from a satellite, not from this whole note: a form accessibility skill loads [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) + § 2 + § 6, and nothing more. Record at the start of the skill which satellite is its source, so that updates to the doc propagate.

---

## 8. Bridges to the stack

The body of this doc is pure RHF, faithful to the source. In my stack (`TanStack Router`, `TanStack Query`, TanStack Start, `Tailwind CSS`, `TypeScript`) several raw practices change owner.

| Problem | Raw practice | What to use in the stack |
| --- | --- | --- |
| Filling the form with remote data | static `defaultValues` after fetch | `values` + `resetOptions: { keepDirtyValues: true }` · `RHF-BRIDGE-03` |
| Sending the mutation | `fetch` inside `onSubmit` | TanStack Query's `mutateAsync` inside `handleSubmit` |
| Invalidating cache after saving | manual | `invalidateQueries` in the mutation — |
| Optimistic update | `useOptimistic` | Query's optimistic mutation — |
| Wizard state across routes | global store | the Router's typed search params — `TanStack Router - Search Params` |
| Boundary validation | manual `if` | the same Zod schema on client and server — |
| Server error in the UI | loose `alert`/toast | `setError` on the field or in `root.serverError` · `RHF-ERR-02` |

### Who disables the button: `isSubmitting` or `isPending`?

Both exist when `handleSubmit` calls `mutateAsync`, and **they have different durations**:

| Signal | Whose | Ends when |
| --- | --- | --- |
| `formState.isSubmitting` | RHF | the `onSubmit` Promise resolves |
| the mutation's `isPending` | TanStack Query | the mutation resolves **and**, if the callbacks return the invalidation Promise (`TSQ-MUT-02`), after the refetch |

Choosing `isSubmitting` re-enables the button while the list still shows stale data — which is exactly the double click `TSQ-MUT-02` exists to prevent.

**Rule:** when there is a mutation with invalidation, **the owner is `isPending`**. `isSubmitting` is only enough in a form with no cache to invalidate. Never combine the two in an `||` — that is not defensive redundancy, it is two owners for the same state. (The pattern is analogous to `REACT-FORM-07`'s, but that rule is about optimism; do not cite it for submission state — see § 6.2.)

| ID | Rule |
| --- | --- |
| `RHF-BRIDGE-05` | With a mutation that invalidates cache, the submission state in the UI **MUST** come from the mutation's `isPending`, not from `formState.isSubmitting`. |

### 8.1 RHF × Server Actions

The pattern is the one from the official documentation itself (*Advanced Usage* section), and the non-obvious point is the **absence** of a bridge: no `useEffect` observing the action's state to touch the form.

```tsx
'use client'

import { useActionState, useId } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { createTopic } from './actions'   // 'use server'
import { topicSchema } from './schema'

export function NewTopic() {
  const [state, dispatch, isPending] = useActionState(createTopic, null)
  const id = useId()
  const { register, handleSubmit, setError, formState: { errors } } = useForm({
    resolver: zodResolver(topicSchema),
    defaultValues: { title: '' },
  })

  // RHF validates; only then is the action dispatched. A single owner. RHF-BRIDGE-01
  // startTransition is mandatory: the dispatch comes from outside <form action>. REACT-FORM-04
  return (
    <form onSubmit={handleSubmit((data) => startTransition(() => dispatch(data)))}>
      <label htmlFor={`${id}-title`}>Title</label>
      <input
        {...register('title')}
        id={`${id}-title`}
        aria-invalid={errors.title ? true : undefined}
        aria-describedby={errors.title ? `${id}-title-error` : undefined}
      />
      {errors.title && (
        <p id={`${id}-title-error`} role="alert">{errors.title.message}</p>
      )}

      {/* state and isPending are read directly in the JSX — no useEffect */}
      {state?.error && <p role="alert">{state.error}</p>}
      <button disabled={isPending}>{isPending ? 'Saving…' : 'Save'}</button>
    </form>
  )
}
```

Three decisions in the example:

- **`handleSubmit` wraps `dispatch`**, not the other way around. The action only runs after client validation passes — that is what makes having RHF there meaningful.
- **`state` and `isPending` are consumed directly in the JSX.** Copying them into the form via `useEffect` creates a second state that diverges; the official doc says explicitly that this bridge is not needed.
- **A field error coming from the server is the only thing that goes back to RHF**, via `setError` — and that is legitimate synchronization with an external system, not state derivation.

The Server Function is still a public endpoint: it always validates and authorizes. `REACT-RSC-06`, and.

### 8.2 RHF × TanStack Query

```tsx
const { mutateAsync, isPending } = useMutation({
  mutationFn: saveProfile,
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['profile'] }),
})

const onSubmit = handleSubmit(async (data) => {
  try {
    await mutateAsync(data)
  } catch (e) {
    // the expected error goes back to the form; it is not thrown.  RHF-ERR-03
    setError('root.serverError', { message: messageFrom(e) })
  }
})
```

**Who owns what:** the form owns capture and validation; the mutation owns sending, cache and optimism. Stacking optimism in the form and in the mutation produces two sources of truth diverging — `RHF-BRIDGE-04`, and.

**Filling with server data** is not `defaultValues`: remote data changes without you knowing. Use `values`, which is reactive, with `keepDirtyValues` so you do not wipe what the user already typed while the refetch was arriving.

```tsx
const { data } = useQuery({ queryKey: ['profile'], queryFn: fetchProfile })

useForm({
  defaultValues: { name: '', email: '' },   // the form's shape
  values: data,                             // content coming from the server
  resetOptions: { keepDirtyValues: true },  // does not overwrite an edit in progress
})
```

### 8.3 Bridge rules

| ID | Rule |
| --- | --- |
| `RHF-BRIDGE-01` | The submission **MUST** have a single owner: `handleSubmit` **or** `<form action>`, never both on the same `<form>`. |
| `RHF-BRIDGE-02` | With a Server Action, the dispatch **MUST** be called from inside `handleSubmit`; the action's state is **NEVER** copied into the form via `useEffect`. |
| `RHF-BRIDGE-03` | Remote data **NEVER** becomes static `defaultValues` — use `values` with `resetOptions.keepDirtyValues`. |
| `RHF-BRIDGE-04` | An optimistic update over a remote cache **NEVER** belongs to the form — it belongs to the mutation. **Canonical** — see § 6.2; `REACT-FORM-07` deals with something else and does not replace it. |

---

## Related

- [React Hook Form - Registration and Control](react-hook-form-registration-and-control.md) — connecting fields
- [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) — what is valid, and what to do with an error
- [React Hook Form - State and Performance](react-hook-form-state-and-performance.md) — reading state, lists, re-render
- [React.js](react-js.md) — React entry point; `REACT-PURE-*` and `REACT-HOOK-*` apply here
- [React - Forms and Actions](react-forms-and-actions.md) — the native alternative; see § 5.4 before choosing
- `TanStack Query - Mutations e Invalidação` · `Frontend roadmap`

## Sources consulted

Verified directly on **2026-08-15**:

- [Get Started](https://react-hook-form.com/get-started) · [API index](https://react-hook-form.com/docs)
- [useForm](https://react-hook-form.com/docs/useform) · [register](https://react-hook-form.com/docs/useform/register) · [formState](https://react-hook-form.com/docs/useform/formstate) · [handleSubmit](https://react-hook-form.com/docs/useform/handlesubmit)
- [watch](https://react-hook-form.com/docs/useform/watch) · [subscribe](https://react-hook-form.com/docs/useform/subscribe) · [setValue](https://react-hook-form.com/docs/useform/setvalue) · [reset](https://react-hook-form.com/docs/useform/reset) · [setError](https://react-hook-form.com/docs/useform/seterror) · [trigger](https://react-hook-form.com/docs/useform/trigger) · [getFieldState](https://react-hook-form.com/docs/useform/getfieldstate)
- [Controller](https://react-hook-form.com/docs/usecontroller/controller) · [useController](https://react-hook-form.com/docs/usecontroller) · [useFormContext](https://react-hook-form.com/docs/useformcontext) · [useFormState](https://react-hook-form.com/docs/useformstate) · [useWatch](https://react-hook-form.com/docs/usewatch) · [useFieldArray](https://react-hook-form.com/docs/usefieldarray)
- [`<Form>`](https://react-hook-form.com/docs/useform/form) · [useLens](https://react-hook-form.com/docs/uselens)
- [Advanced Usage](https://react-hook-form.com/advanced-usage) · [TypeScript](https://react-hook-form.com/ts) · [FAQs](https://react-hook-form.com/faqs)
- [@hookform/resolvers](https://github.com/react-hook-form/resolvers)

### Verification notes

Points where the source contradicts what is assumed out of habit:

- **`watch(callback)` is marked as deprecated, but the source does not declare in which version.** The page carries the warning *"Deprecated: consider use or migrate to subscribe"* and, next to it, the badge `Since v7.0.0`. The two do not say the same thing: in this documentation `Since vX` marks **when the API was introduced** (`update` carries *Since v7.11.0*, `replace` carries *Since v7.15.0*). And the deprecation could not be from v7.0.0, because the indicated replacement, `subscribe`, only arrived in **v7.55.0** — 55 minor versions later. Treat it as "deprecated, unknown version" and prefer `subscribe` in new code.
- **`useLens` is not core.** It comes from `@hookform/lenses`, a separate package. It appears in the official doc's API index next to the core hooks, which is misleading.
- **`useForm`-level `validate` exists** since v7.72.0 and is **mutually exclusive with `resolver`** — the source says it does not run when a resolver is configured.
- **`isReady` (v7.56.0)** signals that the `formState` subscription is ready. A child component that calls `setValue` on mount needs to wait for it; without it the call is silently lost.
- **`<Form>` is BETA** since v7.44.0. The doc does not present it as the default, and neither does this note.
- **`Controller`/`useController` have `exact` defaulting to `true`** (v7.68.0), while `useWatch` and `useFormState` have `exact` defaulting to `false`. The inconsistency is real and is in the source.
- **Calling `register` again on the same name merges options, it does not replace them.** Removing a rule requires passing it as an explicit `false`; `undefined` or `{}` do not remove it.
- **`handleSubmit` does not swallow exceptions** from `onSubmit`, and the returned promise resolves with `onValid`'s return since v7.84.0.
- **The official doc has a Server Actions section** in *Advanced Usage*, and its pattern does away with `useEffect` as a bridge.
- **Reserved field names:** `type`, `root`, `ref`, `types`, `message`, `form` collide with `FieldError`'s internal structure. Names also cannot start with a number.
- **React's `<Activity />` is supported since v7.85.0** — RHF resynchronizes the internal subscriptions on remount.
- **A 404 that was a URL mistake, not a missing page.** `createFormControl` lives at `/docs/createFormControl` (camelCase); `setValues` and `resetDefaultValues` have their own pages. All three are verified in § 4.3. `/docs/useform/resolver`, on the other hand, really does not exist — the resolver contract is at `/useform#resolver`, which is the real source of what [React Hook Form - Validation and Resolvers](react-hook-form-validation-and-resolvers.md) § 3.2 asserts.
- **`register` `rules` × `resolver`:** the exclusivity is stated on the `useForm` page ("Cannot be used with built-in validators") and is the basis of `RHF-VAL-06`. The consequence for `validate` and `deps` is a direct deduction from that sentence — the source does not name them one by one. The recommended alternative (async `.refine()` with the resolver's `mode: 'async'`) has declared support in the `@hookform/resolvers` README, but **the Zod async refine + zodResolver chain was not tested end-to-end in this verification**.

**On review.** This structure went through a reading test with four agents with no context (choosing between RHF and Actions, performance and re-render, server errors with Zod, reusable field component) and an audit of ID and reference consistency, on 2026-08-15. The corrections applied included: reversing the async validation guidance in § 3.3 of the Validation satellite (it was telling you to use `register`'s `validate` in a setup with a resolver, where it does not run), rewriting `RHF-STATE-04`, which contradicted `RHF-STATE-02`, fixing `RHF-PERF-01` cited as permission for what it forbids, disambiguating "number as an isolated key" against `items.0.name`, and fixing the examples that violated `RHF-A11Y-01`/`-03`. When editing this doc, repeating the test is cheaper than trusting a reread.
