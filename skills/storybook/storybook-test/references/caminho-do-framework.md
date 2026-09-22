# The framework path — the Step 0 you do not skip

**Before anything else**, read the `framework` field in `.storybook/main.ts` (`SB-CFG-01`):

| `framework` | Path | Note to load |
| --- | --- | --- |
| `@storybook/tanstack-react` | **A** | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) · family `SB-TS-*` |
| `@storybook/react-vite` | **B** | [Storybook - React Vite](../../../../knowledge-base/docs/storybook-react-vite.md) · family `SB-RV-*` |

This is not a formality. It is the only structure in this vault where **prescribing the wrong path fails silently**:

- under `react-vite`, `parameters.tanstack.*` has **no effect at all** — no error, no warning (`SB-RV-04`);
- under `tanstack-react`, a decorator with `RouterProvider` creates a **second** router, and the symptom appears far from the cause (`SB-TS-03`).

**The two families are mutually exclusive.** Citing `SB-TS-*` against a `react-vite` project is an invalid finding, and vice versa — and `SB-TS-03`/`SB-RV-05` and `SB-TS-08`/`SB-RV-06` are **pairs by path**, not canonical and alias ([Storybook](../../../../knowledge-base/docs/storybook.md) § 6.2).

If the component under test touches neither routing nor the router, the path changes nothing — but confirm before assuming that, because under `tanstack-react` the redirection of `@tanstack/react-router` to the mock layer is **global**, not opt-in per story.

---


---

## Why this step differs from every other in the vault

It is the **only structure where prescribing the wrong path fails silently**. There is no error,
no warning, no type complaining:

| Under… | The mistake | The symptom |
| --- | --- | --- |
| `react-vite` | `parameters.tanstack.*` | **no effect** — the story renders, and what you configured is ignored (`SB-RV-04`) |
| `tanstack-react` | a decorator with `RouterProvider` | a **second** router; the symptom appears far from the cause (`SB-TS-03`) |

The `descobrir-caminho.sh` script in `storybook-setup` reads the field and **already looks for the
corresponding contradiction** in the code.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-setup/scripts/descobrir-caminho.sh
```
