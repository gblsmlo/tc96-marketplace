# Exemplo trabalhado

Tarefa: *"testar que o formulário de convite envia o e-mail digitado, e que mostra o erro do servidor no campo"*.

**Passo 0.** `main.ts` declara `framework: '@storybook/react-vite'` → caminho **B**. O componente não toca rota, então nada de `SB-RV-01`; e `parameters.tanstack.*` seria no-op se alguém tentasse (`SB-RV-04`).

**Passo 1.** A story existe e o que a distingue são `args`. Ok.

**Passo 3 antes do 2** — o componente chama `enviarConvite` de um módulo do projeto, então o mock vem primeiro:

```tsx
// .storybook/preview.tsx — o preview decide O QUÊ é mockado
import { sb } from 'storybook/test';
sb.mock(import('../src/features/convites/api.ts'));
```

**Passo 2** — a story decide **como** se comporta:

```tsx
import type { Meta, StoryObj } from '@storybook/react-vite';
import { expect, fn, mocked } from 'storybook/test';
import { enviarConvite } from '../src/features/convites/api';
import { FormConvite } from './FormConvite';

const meta = {
  component: FormConvite,
  args: { onEnviado: fn() },
} satisfies Meta<typeof FormConvite>;

export default meta;
type Story = StoryObj<typeof meta>;

export const EnviaOEmail: Story = {
  beforeEach: () => {
    mocked(enviarConvite).mockResolvedValue({ id: 'cv_1' });
  },
  play: async ({ args, canvas, userEvent, step }) => {
    await step('preencher', async () => {
      await userEvent.type(canvas.getByRole('textbox', { name: 'E-mail' }), 'ada@x.com');
    });
    await step('enviar', async () => {
      await userEvent.click(canvas.getByRole('button', { name: 'Enviar convite' }));
    });
    await expect(args.onEnviado).toHaveBeenCalledWith({ id: 'cv_1' });
  },
};

export const ErroDoServidorNoCampo: Story = {
  beforeEach: () => {
    mocked(enviarConvite).mockRejectedValue(new ConviteDuplicado('ada@x.com'));
  },
  play: async ({ canvas, userEvent }) => {
    await userEvent.type(canvas.getByRole('textbox', { name: 'E-mail' }), 'ada@x.com');
    await userEvent.click(canvas.getByRole('button', { name: 'Enviar convite' }));
    // a mensagem chega depois da promise rejeitar — findBy, não getBy
    await expect(await canvas.findByRole('alert')).toHaveTextContent(/já foi convidado/i);
  },
};
```

**O que cada decisão evitou:**

| Decisão | Alternativa que fica **verde e errada** | Regra |
| --- | --- | --- |
| `fn()` em `meta.args` | função no `render`, e a asserção sem alvo | `SB-TEST-03` |
| `sb.mock()` no preview | no arquivo de story — não funciona, e não avisa | `SB-MOCK-01` |
| `mocked()` em `beforeEach` | comportamento no topo do módulo, vazando entre stories | `SB-MOCK-04`, `SB-CORE-06` |
| `findByRole('alert')` na story de erro | `getByRole` — passa local, falha em CI | `SB-TEST-10` |
| `await` em toda `expect` | asserção que passa sempre | `SB-TEST-01` |
| query por papel e nome acessível | `.form-error` ou `data-testid` | `SB-TEST-06` |
| **duas** stories, uma por estado | um `play` com `if` cobrindo os dois | `SB-CSF-04` |
| import de `@storybook/react-vite` | `@storybook/react` | `SB-CORE-02` |

A última linha da tabela é a que mais rende: **o estado de erro é uma story, não um ramo dentro da story de sucesso.** Ele aparece na sidebar, entra na página de docs, e o runner o executa — três coisas que um `if` dentro da `play` não dá.

---

