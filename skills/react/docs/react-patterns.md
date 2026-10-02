---
titulo: React - Patterns
Link: https://react.dev/learn
tags:
  - react
  - patterns
  - architecture
  - agent-context
source: "react.dev (Learn + Reference)"
verificado-em: 2026-08-14
---

# React — Patterns

> A **decision** structure: where state lives, what to compose, what to extract, where to draw boundaries. It does not repeat the API surface — for a Hook signature, go to [React - Hooks](react-hooks.md); for the full API map, [React.js](react-js.md) § 4.
>
> **This note's role:** it is the bridge between the official reference and the structural decisions the skills make. Each pattern names the satellite that develops the idea — the satellite carries the reasoning, this note is the actionable index.

Entry point: [React.js](react-js.md) · Normative base: [React - Rules of React](react-rules-of-react.md)

---

## 1. The axis that organizes everything

React patterns resolve into three questions, in this order:

1. **Whose data is this?** — decides state placement
2. **Who provides the variable content?** — decides composition
3. **Where should a failure or a wait stop?** — decides boundaries

The order matters: composition chosen before deciding data ownership almost always produces prop drilling.

---

## 2. State ownership and placement

### Classify before placing

| Nature of the data | Where it lives |
| --- | --- |
| Derivable from what already exists | **nowhere** — compute it during render |
| Local to one component | `useState` / `useReducer` in it |
| Shared by siblings | in the closest common ancestor (*lifting*) |
| Broad, read often, written rarely | Context |
| Broad, written often | external store |
| Coming from the server | it is not client state |
| Persisted in the browser | needs a version and validation |

**The rule that saves the most code:** before creating state, ask whether the value is derivable. Percentage, total, button availability, selected item from an id — they are almost always derived.

### Where to compute the derived value when two siblings consume it

Compute it **once, in the state owner**, and pass the result down. Repeating the same `filter` in each child duplicates work and lets the two diverge.

```tsx
function Screen() {
  const [filter, setFilter] = useState('')
  const [products, setProducts] = useState<Product[]>([])

  // computed once, in the state owner
  const visible = products.filter((p) => p.name.includes(filter))
  const total = visible.reduce((s, p) => s + p.price, 0)

  return (
    <>
      <FilterField value={filter} onChange={setFilter} />
      <ProductList products={visible} />
      <Summary count={visible.length} total={total} />
    </>
  )
}
```

The children receive ready data and do not know a filter exists — they stay reusable. Only memoize (`useMemo`) if the computation proves expensive under measurement (`REACT-PERF-01`).

### Filter, tab, pagination: does this belong in the URL?

A question most code skips. State belongs in the URL when it needs to **survive a refresh**, **be shareable by link** or **work with the back button**. Search filter, active tab, page, sort order and date range almost always meet at least one criterion.

When it does, the source of truth is the route — in my stack, the typed search params of `TanStack Router` — and not `useState`. Ephemeral UI state (open menu, hover, focus, field draft) stays in `useState`.

| ID | Rule |
| --- | --- |
| `REACT-PAT-10` | State that needs to survive a refresh, be shareable by link or respond to the back button **MUST** live in the URL, not in `useState`. |

| ID             | Rule                                                                                                         |
| -------------- | ------------------------------------------------------------------------------------------------------------ |
| `REACT-PAT-01` | A value derivable from existing props/state **NEVER** becomes its own state.                                 |
| `REACT-PAT-02` | State **MUST** live in the closest common ancestor of the components that read it — not above, not duplicated. |
| `REACT-PAT-03` | Remote data is **NEVER** stored in `useState` as the source of truth.                                        |

### Placement: lift the minimum

Lifting state to the root "just in case" costs re-renders across the whole tree and turns the top component into a dumping ground. Lift to the common ancestor and stop there. When lifting too far starts to hurt like prop drilling, the answer is composition (§ 3) before Context.

### Resetting state with `key`

Changing a component's `key` makes React discard the instance and create another from scratch — the idiomatic way to reset state when the logical identity changes.

```tsx
// When the user changes, the form restarts completely
<ProfileForm key={userId} userId={userId} />
```

This replaces the antipattern of syncing props into state inside a `useEffect`.

---

## 3. Composition

React's central pattern, and the one that most reduces boolean configuration props.

### Children and slots

A component controls the common structure and behavior; the consumer provides the variable content.

```tsx
type CardProps = {
  children: React.ReactNode
  footer?: React.ReactNode
}

function Card({ children, footer }: CardProps) {
  return (
    <section>
      {children}
      {footer && <footer>{footer}</footer>}
    </section>
  )
}
```

The sign that composition is missing: props like `showFooter`, `footerButtonLabel`, `hideHeader` piling up in the signature. Each new variation becomes a prop; with composition, it becomes content.

### Composition against prop drilling

Passing JSX as children avoids forwarding props through intermediate levels that do not use them — usually before reaching for Context.

```tsx
// Instead of Layout forwarding `user` to Header forwarding to Avatar:
<Layout header={<Header avatar={<Avatar user={user} />} />}>
  <Content />
</Layout>
```

### When to extract a component

The vault's criterion, in: extract when the component represents a concept, repeats, isolates relevant behavior, or reduces the parent's cognitive load. **Splitting every visual block into a file is not good design** — excessive fragmentation increases navigation and prop passing.

For visual variants.

| ID | Rule |
| --- | --- |
| `REACT-PAT-04` | Content variation **MUST** be solved by composition before a new boolean prop. |
| `REACT-PAT-05` | Component extraction **MUST** have a conceptual justification, not just file size. |

---

## 4. Controlled × uncontrolled

| | Controlled | Uncontrolled |
| --- | --- | --- |
| Source of truth | parent state | DOM / internal state |
| Use | when the parent needs to read or react to every change | when only the final value matters |
| Cost | re-render per keystroke | less flexible |

Practical pattern: a component can offer both modes — controlled `value` prop, uncontrolled `defaultValue` — but **never switch between them at runtime**.

Scale of choice for forms, from simplest to most complex:

| Form | Tool |
| --- | --- |
| Few fields, validation on submit | uncontrolled fields + `<form action>` and `useActionState` — [React - Forms and Actions](react-forms-and-actions.md) |
| Per-field validation while typing, field arrays, wizard, dependencies between fields | React Hook Form — |

In both cases schema validation is Zod. Native Actions are not "for toys": they cover the simple case well, and it is the most common case.

---

## 5. Logic extraction

### Custom Hook × pure function × component

```
Does the logic need state or React Hooks?
├── NO → plain function. Testable without rendering. Prefer it whenever possible.
└── YES
    ├── Does it also produce its own UI? → component
    └── Does it only coordinate state/synchronization? → custom Hook
```

Detail in and in rules `REACT-HOOK-04..07` in [React - Hooks](react-hooks.md).

### What not to extract

Logic used once, with no synchronization boundary, gains nothing from becoming a Hook — it only gains a file and an indirection. The extraction trigger is real repetition or a boundary with an external system.

---

## 6. Boundaries

Boundaries are where the tree decides what to do with **failure**, **waiting** and **environment**. Defining them is an architecture decision, not a detail.

### Failure boundary — Error Boundary

Isolates a render failure so it does not take down the whole application.

Place it at the **feature level**, not only at the root: a single boundary at the root turns any error into a blank screen. Distinguish an expected error (UI state) from an unexpected one (boundary), as in.

### Waiting boundary — `<Suspense>`

Defines which piece of the UI shows a fallback while something loads. Placed too high, it hides the whole page for a secondary piece of data. See [React - Suspense and Async](react-suspense-and-async.md).

### Environment boundary — `'use client'`

Marks where code starts going into the client bundle. Everything imported from there goes along. The pattern that preserves the benefit of RSC is **pushing the boundary down**: Server Components fetch data and pass the rendered result as children to small interactive Client Components. See [React - Server Components and Directives](react-server-components-and-directives.md).

### Trust boundary — server

A Server Function runs on the server, but still receives untrusted input: always validate, authenticate and authorize..

| ID             | Rule                                                                                                           |
| -------------- | -------------------------------------------------------------------------------------------------------------- |
| `REACT-PAT-06` | Error Boundaries **MUST** exist at the feature level, not only at the root.                                    |
| `REACT-PAT-07` | An expected error is **NEVER** thrown to a boundary — it is UI state.                                          |
| `REACT-PAT-08` | The `'use client'` boundary **MUST** sit as low as possible in the tree.                                       |
| `REACT-PAT-09` | Every server function **MUST** validate input at its own boundary, regardless of client-side validation.      |

---

## 7. Data flow

Data flows down through props; changes flow up through callbacks. This single direction is what makes the origin of any change traceable — developed in.

Practical consequence for agents: when a component needs to change something it does not own, the answer is **not** a ref to the parent nor a global event. It is lifting state (§ 2) or composing (§ 3).

File organization by capability, not by technical type: [Feature-Based Architecture](feature-based-architecture.md). Separation by data origin: § 2 of this note.

---

## 8. Antipatterns

| Antipattern | Why it fails | Fix |
| --- | --- | --- |
| State mirroring props via `useEffect` | desyncs and causes an extra render | compute during render, or `key` to reset |
| `useEffect` to fetch data | race conditions, waterfalls, no cache | TanStack Query |
| Boolean prop per content variation | signature grows without limit | composition through children/slots |
| Context for frequently written state | re-renders every consumer | external store · |
| State lifted to the root "just in case" | global re-render, dumping-ground component | closest common ancestor |
| A single Error Boundary at the root | any error becomes a blank screen | boundary per feature |
| `'use client'` at the top of the tree | cancels the benefit of RSC | push the boundary down |
| Mutating props or state directly | violates `REACT-PURE-03`, inconsistent render | create a new value |
| `index` as `key` in a reorderable list | state sticks to the wrong index | stable domain id |

The last one deserves an example, because it is the quietest mistake on the list:

```tsx
// WRONG — when item 0 is removed, each row's internal state shifts
{items.map((item, i) => <Row key={i} item={item} />)}

// RIGHT
{items.map((item) => <Row key={item.id} item={item} />)}
```

`index` as key is only acceptable when the list is static, never reordered and has no internal state in its rows.

---

## 9. Use by an agent

When you receive a structure task ("where do I put this", "how do I organize this", "should this be a hook"), answer in the order of § 1 and cite the rule:

> `REACT-PAT-01` — `total` is derivable from `items`. Do not create state; compute it during render.

When reviewing code, the table in § 8 is the checklist. When proposing a refactor, cite the section — this note carries the decision; the satellite carries the reasoning.

---

## Related

- [React.js](react-js.md) — hub, API map and decision trees
- [React - Hooks](react-hooks.md) — API surface per Hook
- [React - Rules of React](react-rules-of-react.md) — normative base
- `Frontend roadmap` — study track that consumes these notes

## Sources consulted

- [React — Learn](https://react.dev/learn) and [Reference](https://react.dev/reference/react), verified on 2026-08-14
