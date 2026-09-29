# The story before the test, and the `play`

A good `play` on a badly argued story does not save the file. Check first:

| Check | Rule |
| --- | --- |
| what distinguishes this story from another is `args`, not code in `render` | `SB-CSF-04` |
| `meta` with `satisfies Meta<typeof Component>`, the story with `StoryObj<typeof meta>` | `SB-CSF-02` |
| `Meta` and `StoryObj` imported from the **framework's package**, not the renderer's | `SB-CORE-02` |
| a static literal `title` | `SB-CSF-03` |
| nothing in the module body beyond pure declarations | `SB-CORE-06` |
| the story does not depend on another having run first | `SB-CORE-05` |

**`SB-CSF-04` matters most here**, and it is a prerequisite of the test: state embedded in `render` is not controllable through `args`, so the runner cannot vary it and the docs table cannot document it. The test gets stuck on one case.

---

## Step 2 — Writing the `play`

### 2.1 The context

```ts
play: async ({ args, canvas, userEvent, step, mount }) => { … }
```

`canvas` already comes with the Testing Library queries scoped to the story's root — there is no need for `within(canvasElement)`. `userEvent` comes from the context (and also exists in `storybook/test`).

### 2.2 The four rules that decide nearly everything

| Rule | What it requires |
| --- | --- |
| `SB-TEST-01` | **every** `expect` is `await`ed — without it the assertion asserts nothing and always passes |
| `SB-TEST-10` | if the story depends on something async, the **first** query is `findBy…`, never `getBy…` |
| `SB-TEST-03` | a prop callback is `fn` in `args`, and the assertion reads `args.onX` |
| `SB-TEST-08` | an interaction is `userEvent`, not a hand-dispatched event |

`SB-TEST-10` is the one that produces the classic flake: `play` runs after the **render**, not after the **network**. In a story with MSW, `useQuery` or a `loader`, the moment `play` starts is the loading one — `getByRole` is synchronous and fails there. It passes on a fast machine, fails in CI.

### 2.3 `mount`, when it is required

If there is code to run **before** the render — freezing the clock, seeding data, mounting with your own props — destructuring `mount` and calling it is required (`SB-TEST-02`). Without it, Storybook has already started rendering and the setup arrives late.

### 2.4 `step` and what to assert

`step` groups interactions under a label and is what makes the Interactions panel legible.

And the cut: **`play` asserts what the user observes, never internal implementation** (`SB-TEST-09`). Render counts, hook state, internal function calls — none of that. Query by role or accessible label when one exists (`SB-TEST-06`).
