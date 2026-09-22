# Exemplo trabalhado

Tarefa: *"stories do `Badge` do design system"*.

**Passo 1 — os estados.** Variante (info, sucesso, alerta, erro), tamanho, rótulo longo, com ícone. Seis estados, e nenhum é "exemplo".

**Passo 2 e 3:**

```tsx
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import { CheckIcon, AlertIcon } from '../icons';
import { Badge } from './Badge';

const meta = {
 component: Badge,
 title: 'UI/Badge',
 args: { children: 'Novo', variante: 'info' },
 argTypes: {
 // só o que o docgen NÃO adivinha: ReactNode não é serializável
 icone: {
 control: 'select',
 options: ['nenhum', 'check', 'alerta'],
 mapping: { nenhum: undefined, check: <CheckIcon />, alerta: <AlertIcon /> },
 },
 },
} satisfies Meta<typeof Badge>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Info: Story = {};
export const Sucesso: Story = { args: { variante: 'sucesso' } };
export const Alerta: Story = { args: { variante: 'alerta' } };
export const Erro: Story = { args: { variante: 'erro' } };

export const Grande: Story = { args: {...Sucesso.args, tamanho: 'lg' } };

export const RotuloLongo: Story = {
 args: { children: 'Aguardando aprovação do gerente regional' },
};

export const ComIcone: Story = { args: { icone: 'check' } };
```

**O que as decisões evitaram:**

| Decisão | Alternativa que dói | Regra |
| --- | --- | --- |
| `args` distinguindo cada story | `render: => <Badge variante="erro" />` | `SB-CSF-04` |
| `argTypes` só para `icone` | redeclarar `variante` e `tamanho`, que o tipo já diz | `SB-CSF-08` |
| `mapping` para o ícone | prop de ícone sem controle usável no painel | `SB-CSF-06` |
| `Grande` por spread de `Sucesso.args` | duplicar os args, ou mutar `Sucesso.args` | `SB-CSF-05` |
| `title: 'UI/Badge'` explícito | contar com auto-título em `packages/ui` | `SB-CSF-10` |
| `satisfies`, não anotação | `const meta: Meta<typeof Badge>` — apaga a inferência | `SB-CSF-02` |
| `RotuloLongo` como story | descobrir o overflow em produção | `SB-CSF-04` |
| nenhuma descrição em `argTypes` | segunda fonte de verdade, divergindo do JSDoc | `SB-DOC-02` |

**O ganho que não é óbvio:** essas oito stories são simultaneamente a sidebar, a página de autodocs com tabela de props preenchida, **e** oito smoke tests no runner — sem uma linha de `play`. Escrever story pensando em "demo" paga o custo do runner e não recebe nada disso.

---

