# Worked example

Task: *"test that the invite form sends the typed email, and that it shows the server's error in the field"*.

**Step 0.** `main.ts` declares `framework: '@storybook/react-vite'` → path **B**. The component does not touch routing, so no `SB-RV-01`; and `parameters.tanstack.*` would be a no-op if anyone tried (`SB-RV-04`).

**Step 1.** The story exists and what distinguishes it is `args`. Fine.

**Step 3 before 2** — the component calls `sendInvite` from a project module, so the mock comes first:

```tsx
//.storybook/preview.tsx — the preview decides WHAT is mocked
import { sb } from 'storybook/test';
sb.mock(import('../src/features/invites/api.ts'));
```

**Step 2** — the story decides **how** it behaves:

```tsx
import type { Meta, StoryObj } from '@storybook/react-vite';
import { expect, fn, mocked } from 'storybook/test';
import { sendInvite } from '../src/features/invites/api';
import { InviteForm } from './InviteForm';

const meta = {
 component: InviteForm,
 args: { onSent: fn },
} satisfies Meta<typeof InviteForm>;

export default meta;
type Story = StoryObj<typeof meta>;

export const SendsTheEmail: Story = {
 beforeEach: => {
 mocked(sendInvite).mockResolvedValue({ id: 'inv_1' });
 },
 play: async ({ args, canvas, userEvent, step }) => {
 await step('fill in', async => {
 await userEvent.type(canvas.getByRole('textbox', { name: 'Email' }), 'ada@x.com');
 });
 await step('send', async => {
 await userEvent.click(canvas.getByRole('button', { name: 'Send invite' }));
 });
 await expect(args.onSent).toHaveBeenCalledWith({ id: 'inv_1' });
 },
};

export const ServerErrorInTheField: Story = {
 beforeEach: => {
 mocked(sendInvite).mockRejectedValue(new DuplicateInvite('ada@x.com'));
 },
 play: async ({ canvas, userEvent }) => {
 await userEvent.type(canvas.getByRole('textbox', { name: 'Email' }), 'ada@x.com');
 await userEvent.click(canvas.getByRole('button', { name: 'Send invite' }));
 // the message arrives after the promise rejects — findBy, not getBy
 await expect(await canvas.findByRole('alert')).toHaveTextContent(/already been invited/i);
 },
};
```

**What each decision prevented:**

| Decision | Alternative that goes **green and wrong** | Rule |
| --- | --- | --- |
| `fn` in `meta.args` | a function in `render`, and the assertion with no target | `SB-TEST-03` |
| `sb.mock` in the preview | in the story file — it does not work, and it does not warn | `SB-MOCK-01` |
| `mocked` in `beforeEach` | behavior at the top of the module, leaking between stories | `SB-MOCK-04`, `SB-CORE-06` |
| `findByRole('alert')` in the error story | `getByRole` — passes locally, fails in CI | `SB-TEST-10` |
| `await` on every `expect` | an assertion that always passes | `SB-TEST-01` |
| queries by role and accessible name | `.form-error` or `data-testid` | `SB-TEST-06` |
| **two** stories, one per state | one `play` with an `if` covering both | `SB-CSF-04` |
| importing from `@storybook/react-vite` | `@storybook/react` | `SB-CORE-02` |

The last row of the table pays most: **the error state is a story, not a branch inside the success story.** It appears in the sidebar, enters the docs page, and the runner executes it — three things an `if` inside the `play` does not give.
