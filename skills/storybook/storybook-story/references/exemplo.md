# Worked example

Task: *"stories for the design system's `Badge`"*.

**Step 1 — the states.** Variant (info, success, warning, error), size, long label, with an icon. Six states, and none of them is "example".

**Steps 2 and 3:**

```tsx
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import { CheckIcon, AlertIcon } from '../icons';
import { Badge } from './Badge';

const meta = {
 component: Badge,
 title: 'UI/Badge',
 args: { children: 'New', variant: 'info' },
 argTypes: {
 // only what docgen does NOT guess: ReactNode is not serializable
 icon: {
 control: 'select',
 options: ['none', 'check', 'alert'],
 mapping: { none: undefined, check: <CheckIcon />, alert: <AlertIcon /> },
 },
 },
} satisfies Meta<typeof Badge>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Info: Story = {};
export const Success: Story = { args: { variant: 'success' } };
export const Warning: Story = { args: { variant: 'warning' } };
export const Error: Story = { args: { variant: 'error' } };

export const Large: Story = { args: {...Success.args, size: 'lg' } };

export const LongLabel: Story = {
 args: { children: 'Awaiting regional manager approval' },
};

export const WithIcon: Story = { args: { icon: 'check' } };
```

**What these decisions prevented:**

| Decision | Alternative that hurts | Rule |
| --- | --- | --- |
| `args` distinguishing each story | `render: => <Badge variant="error" />` | `SB-CSF-04` |
| `argTypes` only for `icon` | redeclaring `variant` and `size`, which the type already states | `SB-CSF-08` |
| `mapping` for the icon | an icon prop with no usable control in the panel | `SB-CSF-06` |
| `Large` by spreading `Success.args` | duplicating the args, or mutating `Success.args` | `SB-CSF-05` |
| an explicit `title: 'UI/Badge'` | relying on auto-titling in `packages/ui` | `SB-CSF-10` |
| `satisfies`, not an annotation | `const meta: Meta<typeof Badge>` — erases the inference | `SB-CSF-02` |
| `LongLabel` as a story | discovering the overflow in production | `SB-CSF-04` |
| no description in `argTypes` | a second source of truth, diverging from the JSDoc | `SB-DOC-02` |

**The non-obvious gain:** these eight stories are simultaneously the sidebar, the autodocs page with a filled-in props table, **and** eight smoke tests in the runner — without a single line of `play`. Writing a story thinking "demo" pays the runner's cost and receives none of that.
