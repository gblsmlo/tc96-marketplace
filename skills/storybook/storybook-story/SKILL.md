---
nome: storybook-story
descricao: Write or review a component story — file anatomy, typing with `satisfies`, `args` at the three levels, `argTypes` as an exception, tags and the docs page — citing `SB-CSF-*` and `SB-CTX-*` IDs, with an executable self-check — use when the task is creating a new story, deciding what is `args` and what is environment, composing a variation by spread, offering a control for a non-serializable value, naming the `title` in a design system, or turning on autodocs. Do not use for the test inside the story, which is storybook-test, nor to configure the project, which is storybook-setup.
tipo: skill
familia: storybook
idioma: en
fonte: "[Storybook - Stories e Args](../../../knowledge-base/docs/storybook-stories-e-args.md)"
docs:
  - /storybookjs/storybook
tags:
  - skill
  - storybook
  - frontend
---

# storybook-story

> **Source of this skill:** [Storybook - Stories e Args](../../../knowledge-base/docs/storybook-stories-e-args.md), with the [Storybook](../../../knowledge-base/docs/storybook.md) hub as the router.
> This skill **does not contain** the text of the rules — it says what to decide and what to check.
> **API surface:** resolve it through Context7 — `/storybookjs/storybook`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Storybook](../../../knowledge-base/docs/storybook.md) § 7.

---

## Step 0 — If the story touches routing, discover the path

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-setup/scripts/descobrir-caminho.sh
```

`SB-TS-*` and `SB-RV-*` are **mutually exclusive**, and prescribing the wrong path **fails silently**. If the component does not touch routing, the path changes nothing — but **confirm before assuming**.

---

## When to use

Creating or reviewing `*.stories.tsx`.

| Situation | Go to |
| --- | --- |
| the `play` inside the story | `storybook-test` |
| configuring the project, an empty sidebar, versions | `storybook-setup` |
| deciding **at which level** the test goes | `test-design` |
| the component itself | `react-developer` · `react-review` |

---

## Minimum loading

| Order | Load |
| --- | --- |
| 1 | [Storybook](../../../knowledge-base/docs/storybook.md) § 2 (mental model) and § 6 |
| 2 | [Storybook - Stories e Args](../../../knowledge-base/docs/storybook-stories-e-args.md) |
| 3 | [Storybook - Decorators e Contexto](../../../knowledge-base/docs/storybook-decorators-e-contexto.md) when the story needs an environment |
| 4 | the path note, **if** the story touches routing |

References in this skill:

| File | What for |
| --- | --- |
| `references/anatomia-e-tipagem.md` | the question that decides the file, `satisfies Meta`, `StoryObj<typeof meta>` |
| `references/args-e-docs.md` | `args` at the three levels, `argTypes` as an exception, tags and the docs page |
| `references/autoverificacao.md` | the 14 items |
| `references/antipadroes.md` | the grid, with IDs |
| `references/mapa-de-ids.md` | the 75 `SB-*` by satellite and section |
| `references/exemplo.md` | worked case |
| `scripts/autoverificar.sh` | runs the mechanical items and lists the ones that require reading |

---

## Step 1 — The question that decides the file

**Each story is a named state, not a demo** (`SB-CSF-04`) — and what distinguishes two stories is **`args`**. If two stories differ by anything else, either the component has two responsibilities, or the environment became `args`.

---

## Step 2 — Anatomy and typing

`satisfies Meta<typeof C>` on the `meta`, `StoryObj<typeof meta>` on the stories (`SB-CSF-02`) — that is what makes the `args` autocomplete exist. The `Meta`/`StoryObj` import comes from the **framework's package** (`SB-CORE-02`), not from `@storybook/react`.

---

## Step 3 — `args`, and what is **not** `args`

The environment — router, theme, `QueryClient`, session — goes through a **decorator or loader** (`SB-CTX-03`, `SB-CTX-05`), never through `args`. A non-serializable value needs `mapping` to become a control (`SB-CSF-06`).

A variation is composed by **spread**, without mutating `Story.args` (`SB-CSF-05`).

---

## Step 4 — `argTypes` is an exception

If docgen already infers it, `argTypes` is noise (`SB-CSF-08`). A prop's description lives in the **JSDoc** (`SB-DOC-02`) — duplicating it in `argTypes` creates a second source.

---

## Step 5 — Self-check

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-story/scripts/autoverificar.sh src
```

**Then, start it and look at the sidebar.** A glob that does not match **raises no error** — it gives an empty sidebar (`SB-CFG-02`). And open the docs page: **empty controls are the symptom of a violated `SB-CSF-04`**.

---

## Step 6 — Closing

1. **Empty and error states exist, or their absence was decided** (`TS-TIPO-02`) — they are cheap here and expensive in E2E.
2. **If the story became a test**, the handoff is to `storybook-test`.
3. **If the problem is the component**, and not the story, it is `react-review`.

---

## Example

A `Button` story in a design system: an explicit `title`, `satisfies Meta`, four states named by `args`, the theme through a decorator, and the icon (non-serializable) exposed through `mapping`. What habit would produce: a "Playground" story with `argTypes` rewriting what docgen already infers.

Full case: `references/exemplo.md`.

---

## Related

- [Storybook - Stories e Args](../../../knowledge-base/docs/storybook-stories-e-args.md) — source of this skill
- [Storybook - Decorators e Contexto](../../../knowledge-base/docs/storybook-decorators-e-contexto.md) — the environment that is not `args`
- [Storybook - Docs e Autodocs](../../../knowledge-base/docs/storybook-docs-e-autodocs.md) — the docs page
- `storybook-setup` · `storybook-test` — the sibling skills
