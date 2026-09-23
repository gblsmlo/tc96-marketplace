# Route through the decision trees

> This file **does not copy** the trees. They live in [React.js](../../../../knowledge-base/react-js.md) § 5 and change there.
> Here is what the tree does not say: **which** one to walk, what question decides it,
> where the path usually goes wrong, and when to stop before reaching the end.

---

## Which tree, from the task's symptom

| The task's sentence contains… | Tree in [React.js](../../../../knowledge-base/react-js.md) § 5 | The question that decides |
| --- | --- | --- |
| "store", "remember", "keep", "selected", "open/closed" | *Preciso guardar um valor. Onde?* | **Where the data comes from** — not "which Hook" |
| "when X changes", "on mount", "synchronize", "listener", "timer" | *Preciso rodar um efeito colateral. Onde?* | **Does this respond to an interaction?** If yes, you are done: it is a handler |
| "freezes", "slow", "lag while typing", "big list" | *A UI trava durante uma atualização* | **Did you measure?** Without the Profiler, the path does not even begin |
| "load", "fetch", "await", "promise", "submit" | *Preciso lidar com algo assíncrono* | **Where the data lives** — a cache, the server, or nowhere |

If the task contains two of those phrases, it is **two** decisions. Walk both trees
separately, one per data owner, before writing any line.

---

## The four path mistakes

Each one produces code that compiles, runs, and is wrong.

**1. Starting at the state tree's second question.**
The order is *which mechanism* → *in which component*. Choosing `useState` and only then
asking where it lives guarantees that remote data and URL state become local state
(`REACT-PAT-03`, `REACT-PAT-10`). The first question is about the **origin**.

**2. Treating the effect tree as a classification, not as a filter.**
It is designed to **eliminate** the Effect. The first two branches — interaction, and
"is there a nameable external system?" — discard most of the `useEffect` calls one
writes out of habit. Reaching `useEffect` without being able to **name the external system**
means the path was skipped.

**3. Entering the performance tree at step 5.**
Steps 0–3 are unnecessary state, state lifted too high, and composition. `memo` is
step 5, after measuring (`REACT-PERF-01`). With the React Compiler active, manual memoization
is redundant (`REACT-PERF-02`) — confirm first.

**4. Not checking the stack's bridge.**
[React.js](../../../../knowledge-base/react-js.md) § 8 lists what is **already solved** in this stack: remote data, caching,
URL state, optimism, boundary validation, complex forms, frequently written global
state. The raw primitive where the bridge exists is not simplicity — it is
a regression, and it goes unnoticed in review because the code "works".

---

## Stopping before the end: the four short exits

| If the answer is… | Stop here | Do not walk the rest |
| --- | --- | --- |
| the data comes from the server | [TanStack Query](../../../../knowledge-base/tanstack-query.md) ([React.js](../../../../knowledge-base/react-js.md) § 8) | no `useState` branch applies |
| the value is derivable from what already exists | compute it in the render | there is no Hook to choose |
| the state has to survive a refresh / be shareable by link | [TanStack Router](../../../../knowledge-base/tanstack-router.md) search params | `useState` is out of the question |
| the code responds to a click, a submit, a keystroke | an event handler | it is not an Effect, it has no dependencies |

Three of the four exits end **with no Hook at all**. That is the expected result:
the tree exists to reduce the surface, not to choose between equivalent APIs.

---

## After choosing the API

1. Confirm the **source package** in [React.js](../../../../knowledge-base/react-js.md) § 3 — `react`, `react-dom`,
 `react-dom/client`. Half of all import errors die here.
2. Find the **satellite** in [React.js](../../../../knowledge-base/react-js.md) § 4 and open **only it**.
3. If the API is not in § 4, it **has not been verified** in this doc. Consult react.dev,
 declare the limitation, and propose updating the note — do not assert behavior
 ([React.js](../../../../knowledge-base/react-js.md) § 7, invariant 1).

---

## Related

- [React.js](../../../../knowledge-base/react-js.md) § 5 — the trees themselves
- [React.js](../../../../knowledge-base/react-js.md) § 8 — the bridges with the stack
- `habitos-de-ia.md` — what the path avoids, habit by habit
