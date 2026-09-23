# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| A story as a demo, with no named state | `SB-CSF-04` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| State embedded in `render` | `SB-CSF-04` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| One story per props combination | § 7.2 of the satellite | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| `useState` in `render` to simulate a control | `SB-CSF-07` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| Mutating `Story.args` to compose a variation | `SB-CSF-05` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| `title` mirroring the folder tree | `SB-CSF-03` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| `title` from a template string or a computed value | `SB-CSF-03` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| `argTypes` copying the component's type | `SB-CSF-08` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| A `Meta<…>` annotation instead of `satisfies` | `SB-CSF-02` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| A non-serializable value in a control, without `mapping` | `SB-CSF-06` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| A helper exported from the stories file | `SB-CSF-09` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| A side effect in the module body | `SB-CORE-06` | [Storybook](../../../../knowledge-base/storybook.md) |
| A story that depends on another | `SB-CORE-05` | [Storybook](../../../../knowledge-base/storybook.md) |
| `Meta`/`StoryObj` from the renderer | `SB-CORE-02` | [Storybook](../../../../knowledge-base/storybook.md) |
| Documenting in `argTypes` what the JSDoc already says | `SB-DOC-02` | [Storybook - Docs e Autodocs](../../../../knowledge-base/storybook-docs-e-autodocs.md) |
| A story that is a prose article | `SB-DOC-03` | [Storybook - Docs e Autodocs](../../../../knowledge-base/storybook-docs-e-autodocs.md) |
| Turning on autodocs file by file | `SB-DOC-01` | [Storybook - Docs e Autodocs](../../../../knowledge-base/storybook-docs-e-autodocs.md) |
| A pretty docs page with empty controls | `SB-CSF-04` | [Storybook - Docs e Autodocs](../../../../knowledge-base/storybook-docs-e-autodocs.md) |
| `subcomponents` used as a folder | § 6.5 of the satellite | [Storybook - Docs e Autodocs](../../../../knowledge-base/storybook-docs-e-autodocs.md) |
| `globals` where `args` was correct | `SB-CTX-05` | [Storybook - Decorators e Contexto](../../../../knowledge-base/storybook-decorators-e-contexto.md) |
| A provider repeated per story file | `SB-CTX-03` | [Storybook - Decorators e Contexto](../../../../knowledge-base/storybook-decorators-e-contexto.md) |
| A `packages/ui` component that requires routing | `SB-TS-08` / `SB-RV-06` | the path note |

