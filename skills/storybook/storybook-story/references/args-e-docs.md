# `args`, `argTypes`, tags and docs

### 3.1 The rule that dominates

> **What distinguishes one story from another is `args`.** State embedded in `render` **NEVER** (`SB-CSF-04`).

It is not style. State in `render` kills three things at once: the reader cannot edit it through the panel, the runner cannot vary it, and the docs table cannot document it.

### 3.2 Three levels, merged by key

`preview` → `meta` → story. The most specific wins, and **overriding a subkey does not knock out its siblings**.

Composition by **spread**, never mutation (`SB-CSF-05`):

```tsx
export const Default: Story = { args: { label: 'New' } };

// ✓ reuses
export const Large: Story = { args: {...Default.args, size: 'lg' } };
// ✗ mutates
// Default.args.size = 'lg';
```

### 3.3 What is **not** `args`

If what distinguishes them is **the world around** — theme, provider, routing, network response, clock —, that is the **environment**, and the environment enters through a decorator, `loaders` or `beforeEach` ([Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md)).

And the pair most often confused: **`globals` is for a variation the reader switches through the toolbar** (theme, locale). What distinguishes two stories is **never** a global — it is `args` (`SB-CTX-05`).

A provider shared by more than one component lives in a **global** decorator in `preview`, not repeated per file (`SB-CTX-03`).

---

## Step 4 — `argTypes` is an exception

**The default is not to write `argTypes`** (`SB-CSF-08`). With `component` declared, docgen infers the type, the possible values and the control. Redeclaring what the type already expresses creates a second source that ages.

When it does come in:

| Case | What to use |
| --- | --- |
| a non-serializable value in a control (function, component, icon) | `mapping` (`SB-CSF-06`) |
| a control docgen cannot guess | the explicit control type |
| hiding it from the docs table | `table: { disable: true }` |
| switching off the control while keeping the row | `control: false` |

> **The silent swap:** `control: false` **keeps** the row in the documentation; what removes the row is `table: { disable: true }`. The two look like synonyms and do different things.

**A prop's description does not go in `argTypes`.** It comes from the JSDoc on the component, which is the single source (`SB-DOC-02`).

---

## Step 5 — Tags and the docs page

| Tag | Effect |
| --- | --- |
| `dev` | appears in the sidebar (applied by default) |
| `test` | enters the runner (applied by default) |
| `autodocs` | generates the docs page (**not** applied by default) |
| `'!tag'` | removes an inherited one |

The prescribed way to turn on autodocs is to **inherit it from `preview`**, not file by file (`SB-DOC-01`).

And the cut between a story's two roles (`SB-DOC-04`):

| The story serves… | Mark it |
| --- | --- |
| documentation only | `'!test'` — out of the runner |
| testing only | `'!autodocs'` — out of the page |

**In a design system, the story feeds the docs page by design** — that is why [Storybook - Docs e Autodocs](../../../../knowledge-base/docs/storybook-docs-e-autodocs.md) is in the minimum loading. And the story the page displays has to express its state through `args`, otherwise the controls show up empty (`SB-DOC-05`, which is an alias of `SB-CSF-04` — cite the canonical one).
