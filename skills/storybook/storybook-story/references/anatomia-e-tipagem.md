# The question that decides the file, and the anatomy

> **What states does this component have?**

Each answer is a story. The name describes the **condition**, not what the reader should learn:

| ✓ | ✗ |
| --- | --- |
| `Loading`, `Empty`, `WithError`, `Disabled`, `LongLabel` | `Example`, `Demo`, `HowToUse`, `Basic2` |

If the name does not describe a state, it is probably not a story — it is documentation, and its place is MDX or `docs.page` (`SB-DOC-03`).

**Cover the five states of a flow:** loading, empty, success, error, recovery. That is `TS-TIPO-02` in [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md), and at the component level they are cheap — this is where you pay least to cover what the user suffers most.

---

## Step 2 — Anatomy and typing

```tsx
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import { Badge } from './Badge';

const meta = {
 component: Badge,
 title: 'UI/Badge',
} satisfies Meta<typeof Badge>;

export default meta;
type Story = StoryObj<typeof meta>;
```

| Check | Rule |
| --- | --- |
| one `export default` (the `meta`) and one story per named export | `SB-CSF-01` |
| `satisfies Meta<typeof Component>`, **not** an annotation | `SB-CSF-02` |
| the story's type derived through `StoryObj<typeof meta>` | `SB-CSF-02` |
| `Meta`/`StoryObj` from the **framework's** package, not the renderer's | `SB-CORE-02` |
| `title` and `id` as static literals | `SB-CSF-03` |
| in `packages/ui`, `title` declared explicitly | `SB-CSF-10` |
| nothing in the module body beyond pure declarations | `SB-CORE-06` |
| a named export that is not a story goes away, or into `excludeStories` | `SB-CSF-09` |

**Why `satisfies` and not an annotation:** the object's literal type feeds the inference afterwards — `StoryObj<typeof meta>` reads the declared `args`. With an annotation, that information is erased and the story's `args` stop being checked against the props.

**`title` does not mirror the folder tree.** It is the sidebar's hierarchy, which is a product decision — `UI/Badge`, not `packages/ui/src/components/Badge`.
