# Automatic habits that produce violations

> These are not review findings — they are decisions to make **before** writing.
> Each line comes from a reflex (of someone who has written React for years, and of someone generating React
> from old examples on the internet). The **Rule** column is the canonical ID;
> check it in `mapa-de-ids.md` before citing.

---

## 1. State and data

| Habit | Why it fails | Instead of it | Rule |
| --- | --- | --- | --- |
| a `fetch` inside a `useEffect` to load data | it solves neither race conditions, caching, dedupe nor retry; and `<Suspense>` does not work with it | a data-fetching library — [TanStack Query](../../../../knowledge-base/docs/tanstack-query.md), via [React.js](../../../../knowledge-base/docs/react-js.md) § 8 | `REACT-EFFECT-06`, `REACT-ASYNC-03` |
| `useState` + `useEffect` for a computable value (a total, a percentage, an item by id, a filtered list) | it desynchronizes and produces an extra render | compute it in the render, **in the state's owner**, and pass it down ready | `REACT-PAT-01` |
| Syncing a prop into state to "reset" when the entity changes | the same problem, with one more render | change the `key`: `<ProfileForm key={userId} />` | `REACT-PAT-01` |
| Keeping the API response in `useState` as the source of truth | two sources of truth; invalidation becomes your responsibility | Query's cache is the source; `useState` only for what is the client's | `REACT-PAT-03` |
| `useState` for a filter, a tab, pagination, sorting | it does not survive a refresh, is not shareable by link, ignores the back button | typed search params from [TanStack Router](../../../../knowledge-base/docs/tanstack-router.md) | `REACT-PAT-10` |
| Lifting state to the root "just in case" | a global re-render and a warehouse component | the **nearest** common ancestor, and stop there | `REACT-PAT-02` |
| `setCount(count + 1)` when the previous value matters | two `set` calls in the same handler increment once — state is a snapshot | the updater form: `setCount(c => c + 1)` | `REACT-STATE-01` |
| Parallel booleans (`isLoading` + `isError` + `data`) | they admit impossible combinations | a discriminated union | `REACT-STATE-06` |
| Context for frequently written state | every consumer re-renders on every keystroke | an external store | `REACT-STATE-08` |

## 2. Effects

| Habit | Why it fails | Instead of it | Rule |
| --- | --- | --- | --- |
| Interaction logic inside an Effect | it runs outside the interaction's moment and doubles in StrictMode | an event handler | `REACT-EFFECT-05` |
| `eslint-disable` on `exhaustive-deps` to stop the loop | it treats the symptom; the loop is the Effect warning that it should not exist | remove the Effect, or extract the non-reactive part with `useEffectEvent` | `REACT-EFFECT-03` |
| `useEffect(async => …)` | the callback starts returning a Promise, and React expects a cleanup there | declare the `async` function **inside** the Effect | `REACT-EFFECT-12` |
| An Effect with a subscription/timer/listener and no `return` | it leaks between renders and in StrictMode | a cleanup that undoes exactly the setup | `REACT-EFFECT-01` |
| `useLayoutEffect` "to make sure it runs first" | it blocks the paint for no reason | `useEffect`, unless there is a layout measurement | `REACT-EFFECT-10` |

## 3. Composition and boundaries

| Habit | Why it fails | Instead of it | Rule |
| --- | --- | --- | --- |
| A new boolean prop for each visual variation (`showFooter`, `hideHeader`) | the signature grows without limit and the combinations become a matrix | composition through `children`/slots | `REACT-PAT-04` |
| Breaking a large file into components by size | it fragments without creating a concept; prop drilling increases | extract only what has a domain name | `REACT-PAT-05` |
| A single Error Boundary at the root | any error becomes a white screen | a boundary at the feature level | `REACT-PAT-06` |
| A `<Suspense>` with no Error Boundary at a data boundary | the promise's failure has nowhere to stop | an error boundary next to every waiting boundary | `REACT-ASYNC-08` |
| A boundary with no retry/reset button | the user is stuck in the fallback | an explicit recovery path | `REACT-ASYNC-11` |
| Throwing an expected error (validation, a business 404, a 403) to the boundary | a boundary is for the unexpected | an expected error is UI state / the action's return | `REACT-ASYNC-09` |
| `index` as the `key` in a `.map` | internal state sticks to the wrong index when reordering or removing | a stable domain id; `index` only in a static list, with no state in the rows | no ID — [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) § 8 |
| A `fallback` of arbitrary size | a layout shift at the moment of the swap | a fallback with roughly the real content's area | `REACT-ASYNC-02` |

## 4. Performance

| Habit | Why it fails | Instead of it | Rule |
| --- | --- | --- | --- |
| `useMemo`/`useCallback`/`memo` "just in case" | cost with no proven benefit | measure in the Profiler and walk steps 1–3 of the tree first | `REACT-PERF-01` |
| Memoizing manually in a project with the React Compiler | redundant | confirm whether the compiler is active before any memoization | `REACT-PERF-02` |
| `memo` on a component receiving an object/function created inline | the shallow equality never returns true; it only adds cost | stabilize the props, or do not use `memo` | `REACT-PERF-03` |
| `useMemo` to guarantee required identity | the cache can be discarded at any moment | `useRef` when the identity is semantically necessary | `REACT-PERF-05` |
| Memoizing a row in a list of thousands of items | the bottleneck is node volume, not computation | virtualization or pagination | `REACT-PERF-09` |
| `useTransition` to control a text field | transitions are not for an input's value | `useDeferredValue` in the heavy consumer | `REACT-PERF-10` |

## 5. Refs, the DOM and the entrypoint

| Habit | Why it fails | Instead of it | Rule |
| --- | --- | --- | --- |
| `forwardRef` in new code | unnecessary since React 19 — `ref` is a prop | receive `ref` as an ordinary prop | `REACT-REF-03` |
| Reading or writing `ref.current` in the render body | it violates purity | handlers and Effects | `REACT-REF-01` |
| Keeping in a ref something that should repaint the screen | the UI does not update | state | `REACT-REF-02` |
| A portal and "there, it is a modal" | focus, `Esc`, `role`/`aria-modal` and returning focus are still yours | explicit accessibility in the portal | `REACT-REF-07` |
| `createRoot` over HTML coming from the server | it discards the HTML and loses the SSR | `hydrateRoot` | `REACT-DOM-01` |
| Branching the render on `typeof window` | a hydration mismatch | render the same on both sides and adjust in an Effect | `REACT-DOM-03` |
| Removing `<StrictMode>` because "it runs twice" | it is revealing a purity bug, not causing one | fix the impurity | `REACT-DOM-06` |

## 6. Forms, Actions and the server

| Habit | Why it fails | Instead of it | Rule |
| --- | --- | --- | --- |
| `e.preventDefault` com `<form action>` | React already prevents it; this breaks the Action | do not call it | `REACT-FORM-01` |
| A field with no `name`, read through state | `FormData` is indexed by `name` | `name` on every field the Action reads | `REACT-FORM-02` |
| `useFormStatus` in the same component that renders the `<form>` | it reads the **ancestor** `<form>` | call it in a descendant (the submit button) | `REACT-FORM-05` |
| `useOptimistic` over data that lives in Query's cache | two sources of truth diverging | optimism belongs to the mutation, with a snapshot and a rollback | `REACT-FORM-07` |
| `'use client'` at the top of the root file | everything imported from there goes into the bundle | push the boundary downwards | `REACT-RSC-03` |
| A Client Component importing a Server Component | the boundary does not allow it | receive it as `children`/props | `REACT-RSC-04` |
| Passing a function or a class instance across the boundary | props have to be serializable | serializable data, or a Server Function | `REACT-RSC-05` |
| Trusting client validation in a Server Function | it is a public endpoint | authenticate, validate and authorize at the boundary itself | `REACT-RSC-06` |
| `cache` as a cache across requests | its scope is one render pass | a real cache in the data layer | `REACT-RSC-08` |

## 7. Custom Hooks

| Habit | Why it fails | Instead of it | Rule |
| --- | --- | --- | --- |
| Extracting pure, stateless logic into a Hook | it is an ordinary function, testable without rendering | an ordinary function | `REACT-HOOK-05` |
| Naming by the implementation (`useEventListener`) | the name does not state the feature's intent | `useOnlineStatus` | `REACT-HOOK-04` |
| A Hook that returns ten things | it is hiding a component | a small, explicit return | `REACT-HOOK-06` |
| Calling a Hook from inside an ordinary function or a callback | the Hooks rules are inherited | a component or another Hook | `REACT-HOOK-02`, `REACT-HOOK-07` |
| A Hook stored in a variable or passed as an argument | Hooks are not values | call it directly | `REACT-CALL-02` |

---

## Related

- `mapa-de-ids.md` — where each ID is declared
- `autoverificacao.md` — the second pass, over this table
- [React.js](../../../../knowledge-base/docs/react-js.md) § 6.1 — the critical rules that travel with the minimum path
