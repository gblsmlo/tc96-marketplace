# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-story/scripts/autoverificar.sh src
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | each story is a **named state**, not a demo | `SB-CSF-04` |
| 2 | what distinguishes the stories is `args` | `SB-CSF-04` |
| 3 | `satisfies Meta<…>` + `StoryObj<typeof meta>` | `SB-CSF-02` |
| 4 | `Meta`/`StoryObj` imported from the framework's package | `SB-CORE-02` |
| 5 | `title` literal, and explicit in `packages/ui` | `SB-CSF-03`, `SB-CSF-10` |
| 6 | no `argTypes` that docgen would already infer | `SB-CSF-08` |
| 7 | prop descriptions only in the JSDoc | `SB-DOC-02` |
| 8 | variations reused by spread, without mutating `Story.args` | `SB-CSF-05` |
| 9 | environment through a decorator/loader, not through `args` | `SB-CTX-03`, `SB-CTX-05` |
| 10 | a non-serializable value goes through `mapping` | `SB-CSF-06` |
| 11 | a non-story export removed or in `excludeStories` | `SB-CSF-09` |
| 12 | the module body has no side effects | `SB-CORE-06` |
| 13 | no story depends on another having run | `SB-CORE-05` |
| 14 | empty and error states exist, or their absence was decided | `TS-TIPO-02` |

**Then, start it and look at the sidebar.** A glob that does not match **raises no error** — it gives an empty sidebar (`SB-CFG-02`). And open the docs page: empty controls are the symptom of a violated `SB-CSF-04`.
