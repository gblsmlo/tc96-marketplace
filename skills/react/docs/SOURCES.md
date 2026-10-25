# Sources of the React family docs

Provenance for maintainers re-verifying a doc against upstream. No doc links here, so the build
and the `.skill` packages leave this file out and no run loads it.

## React - Effects and Synchronization

Doc: [react-effects-and-synchronization.md](react-effects-and-synchronization.md)

Verified on 2026-08-14:

- [useEffect](https://react.dev/reference/react/useEffect) · [useLayoutEffect](https://react.dev/reference/react/useLayoutEffect) · [useInsertionEffect](https://react.dev/reference/react/useInsertionEffect)
- [useEffectEvent](https://react.dev/reference/react/useEffectEvent) — confirmed as stable, with no experimental marking
- [Rules of React](https://react.dev/reference/rules)

## React - Forms and Actions

Doc: [react-forms-and-actions.md](react-forms-and-actions.md)

Verified on 2026-08-14:

- [useActionState](https://react.dev/reference/react/useActionState) — caveats and framework independence confirmed
- [useOptimistic](https://react.dev/reference/react/useOptimistic) — confirmed stable
- [useFormStatus](https://react.dev/reference/react-dom/hooks/useFormStatus)
- [`<form>`](https://react.dev/reference/react-dom/components/form)

## React Hook Form - Registration and Control

Doc: [react-hook-form-registration-and-control.md](react-hook-form-registration-and-control.md)

Verified on 2026-08-15:

- [register](https://react-hook-form.com/docs/useform/register) — merge on re-registration, reserved names and name restrictions confirmed
- [Controller](https://react-hook-form.com/docs/usecontroller/controller) — `exact` defaults to `true` since v7.68.0; warning about `onChange(undefined)`
- [useController](https://react-hook-form.com/docs/usecontroller) — recommendation of one call per component
- [useFormContext](https://react-hook-form.com/docs/useformcontext) — explicit guidance to use `useFormState` for `formState`
- [Advanced Usage](https://react-hook-form.com/advanced-usage) — accessibility, `ConnectForm`, `FormProvider` performance, and the *Transform and Parse* section that grounds § 3.4: the `input`/`output` pattern in `Controller` and the rationale that `valueAsNumber`/`valueAsDate` leave `NaN` and `null` unhandled
- [TypeScript](https://react-hook-form.com/ts) — `FieldPath`, `Control`, `ControllerRenderProps`

## React Hook Form - State and Performance

Doc: [react-hook-form-state-and-performance.md](react-hook-form-state-and-performance.md)

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

## React Hook Form - Validation and Resolvers

Doc: [react-hook-form-validation-and-resolvers.md](react-hook-form-validation-and-resolvers.md)

Verified on 2026-08-15:

- [useForm](https://react-hook-form.com/docs/useform) — `mode`, `criteriaMode`, `delayError`, the resolver contract, `validate` × `resolver` exclusivity
- [setError](https://react-hook-form.com/docs/useform/seterror) — non-persistence on a field with rules, `root.serverError`, effect on `isValid`
- [trigger](https://react-hook-form.com/docs/useform/trigger) — render isolation only with a single name
- [handleSubmit](https://react-hook-form.com/docs/useform/handlesubmit) — exceptions are not swallowed; `SubmitErrorHandler`
- [formState](https://react-hook-form.com/docs/useform/formstate) — `isValidating`, `validatingFields`, `isValid` behavior
- [register](https://react-hook-form.com/docs/useform/register) — `validate`, `deps`
- [@hookform/resolvers](https://github.com/react-hook-form/resolvers) — `zodResolver`, typing of transformed values
- [TypeScript](https://react-hook-form.com/ts) — `Resolver`, `ValidateForm`, `useForm` generics

## React Hook Form

Doc: [react-hook-form.md](react-hook-form.md)

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

## React - Hooks

Doc: [react-hooks.md](react-hooks.md)

Verified on 2026-08-14:

- [Built-in React Hooks](https://react.dev/reference/react/hooks)
- [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
- [react-dom Hooks](https://react.dev/reference/react-dom/hooks)
- [useOptimistic](https://react.dev/reference/react/useOptimistic)

## React.js

Doc: [react-js.md](react-js.md)

Verified directly on **2026-08-14**:

- [React Reference Overview](https://react.dev/reference/react)
- [Hooks](https://react.dev/reference/react/hooks) · [Components](https://react.dev/reference/react/components) · [APIs](https://react.dev/reference/react/apis)
- [Rules of React](https://react.dev/reference/rules)
- [react-dom](https://react.dev/reference/react-dom) · [react-dom/server](https://react.dev/reference/react-dom/server) · [react-dom hooks](https://react.dev/reference/react-dom/hooks)
- [Server Components](https://react.dev/reference/rsc/server-components) · [Directives](https://react.dev/reference/rsc/directives)
- [React Compiler Directives](https://react.dev/reference/react-compiler/directives)
- [useOptimistic](https://react.dev/reference/react/useOptimistic)

**Verification notes** — points where the source contradicts what is assumed out of habit:

- `useEffectEvent` appears in the Hooks index as **stable**, with no experimental marking.
- **`forwardRef` is not deprecated yet.** The banner says it "is no longer necessary" and that it "will be deprecated in a future release" — those are different things.
- **React Compiler is stable 1.0 since 2025-10-07** ([announcement](https://react.dev/blog/2025/10/07/react-compiler-1)), compatible with React 17+. The reference's configuration page does not state a status; I had to go to the blog.
- **`useActionState` works without a framework.** Only `permalink` requires RSC.
- **The taint APIs are experimental** (`experimental_taintObjectReference`), and the doc itself warns against treating them as a security mechanism.
- **`startTransition` accepts an `async` function**; the restriction applies only to `setState` after an `await`.
- `renderToString` and `renderToStaticMarkup` are marked as legacy, with limited functionality.

**About review:** this structure went through a reading test with four agents without context (forms, data fetching, state colocation, performance) and a contradiction audit, on 2026-08-14. The corrections applied included: inverting the order of the state tree (the data's origin became the first question), promoting the satellites' critical rules to § 6.1, creating the canonical IDs table, and fixing three wrong ID citations. When editing this doc, repeating the test is cheaper than trusting a re-read.

## React - Patterns

Doc: [react-patterns.md](react-patterns.md)

- [React — Learn](https://react.dev/learn) and [Reference](https://react.dev/reference/react), verified on 2026-08-14

## React - Performance and Concurrency

Doc: [react-performance-and-concurrency.md](react-performance-and-concurrency.md)

Verified on 2026-08-14:

- [memo](https://react.dev/reference/react/memo) · [useMemo](https://react.dev/reference/react/useMemo) · [useCallback](https://react.dev/reference/react/useCallback)
- [useTransition](https://react.dev/reference/react/useTransition) · [startTransition](https://react.dev/reference/react/startTransition) · [useDeferredValue](https://react.dev/reference/react/useDeferredValue)
- [Activity](https://react.dev/reference/react/Activity) — caveats quoted literally
- [Profiler](https://react.dev/reference/react/Profiler)
- [React Compiler — Configuration](https://react.dev/reference/react-compiler/configuration) · [Directives](https://react.dev/reference/react-compiler/directives)

## React - Performance Measurement

Doc: [react-performance-measurement.md](react-performance-measurement.md)

Verified on 2026-10-03:

- [Profiler](https://react.dev/reference/react/Profiler) — `onRender`, `actualDuration`, the overhead caveat
- [memo](https://react.dev/reference/react/memo) — shallow comparison, why one unstable prop cancels it
- Field record: a DataGrid refactor (rows and cells memoized, 200×10 to 1000×20 cases, JSDOM, `bun`), including two baseline runs of unchanged code and an independent review of the memoized code

## React - Refs and DOM

Doc: [react-refs-and-dom.md](react-refs-and-dom.md)

Verified on 2026-08-14:

- [useRef](https://react.dev/reference/react/useRef) · [useImperativeHandle](https://react.dev/reference/react/useImperativeHandle)
- [forwardRef](https://react.dev/reference/react/forwardRef) — deprecation banner quoted literally
- [Common components — ref callback](https://react.dev/reference/react-dom/components/common) — ref callback cleanup quoted literally
- [createPortal](https://react.dev/reference/react-dom/createPortal) · [flushSync](https://react.dev/reference/react-dom/flushSync)

## React - Rendering and Entrypoints

Doc: [react-rendering-and-entrypoints.md](react-rendering-and-entrypoints.md)

Verified on 2026-08-14:

- [react-dom/client](https://react.dev/reference/react-dom/client) — `createRoot`, `hydrateRoot`
- [react-dom/server](https://react.dev/reference/react-dom/server) — inventory and runtime recommendations
- [react-dom/static](https://react.dev/reference/react-dom/static)
- [StrictMode](https://react.dev/reference/react/StrictMode) · [act](https://react.dev/reference/react/act)
- [react-dom APIs](https://react.dev/reference/react-dom) — preloading family

## React - Rules of React

Doc: [react-rules-of-react.md](react-rules-of-react.md)

Verified on 2026-08-14, with the rules quoted literally:

- [Rules of React](https://react.dev/reference/rules)
- [Components and Hooks must be pure](https://react.dev/reference/rules/components-and-hooks-must-be-pure)
- [React calls Components and Hooks](https://react.dev/reference/rules/react-calls-components-and-hooks)
- [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)

## React - Server Components and Directives

Doc: [react-server-components-and-directives.md](react-server-components-and-directives.md)

Verified on 2026-08-14:

- [Server Components](https://react.dev/reference/rsc/server-components) · [Directives](https://react.dev/reference/rsc/directives)
- ['use client'](https://react.dev/reference/rsc/use-client) — placement rules and serialization table
- ['use server'](https://react.dev/reference/rsc/use-server) · [cache](https://react.dev/reference/react/cache)
- [experimental_taintObjectReference](https://react.dev/reference/react/experimental_taintObjectReference) — warnings quoted literally

## React - State and Reactivity

Doc: [react-state-and-reactivity.md](react-state-and-reactivity.md)

Verified on 2026-08-14:

- [useState](https://react.dev/reference/react/useState) · [useReducer](https://react.dev/reference/react/useReducer)
- [useContext](https://react.dev/reference/react/useContext) · [createContext](https://react.dev/reference/react/createContext)

## React - Suspense and Async

Doc: [react-suspense-and-async.md](react-suspense-and-async.md)

Verified on 2026-08-14:

- [Suspense](https://react.dev/reference/react/Suspense) · [lazy](https://react.dev/reference/react/lazy) · [use](https://react.dev/reference/react/use)
- [Server Components](https://react.dev/reference/rsc/server-components)

## React - Utility Hooks

Doc: [react-utility-hooks.md](react-utility-hooks.md)

Verified on 2026-08-14:

- [useId](https://react.dev/reference/react/useId)
- [useSyncExternalStore](https://react.dev/reference/react/useSyncExternalStore)
- [useDebugValue](https://react.dev/reference/react/useDebugValue)

## Feature-Based Architecture

Doc: [feature-based-architecture.md](feature-based-architecture.md)

- `Feature-Based Architecture in React` — source article (dev.to)
- [Biome — `noImportCycles`](https://biomejs.dev/linter/rules/no-import-cycles/)
- [Biome — `noRestrictedImports`](https://biomejs.dev/linter/rules/no-restricted-imports/)
- [Biome — `noPrivateImports`](https://biomejs.dev/linter/rules/no-private-imports/)
- [Biome — configuration and `overrides`](https://biomejs.dev/reference/configuration/)
- the tc96 commands `scaffold-fba-02-biome` and `scaffold-fba-05-fba` — the scaffold's conventions
