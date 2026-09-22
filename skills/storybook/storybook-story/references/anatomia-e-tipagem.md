# A pergunta que decide o arquivo, e a anatomia

> **Que estados este componente tem?**

Cada resposta é uma story. O nome descreve a **condição**, não o que o leitor deveria aprender:

| ✓ | ✗ |
| --- | --- |
| `Loading`, `Vazio`, `ComErro`, `Desabilitado`, `RotuloLongo` | `Exemplo`, `Demo`, `ComoUsar`, `Basico2` |

Se o nome não descreve um estado, provavelmente não é uma story — é documentação, e o lugar dela é MDX ou `docs.page` (`SB-DOC-03`).

**Cubra os cinco estados de um fluxo:** carregando, vazio, sucesso, erro, recuperação. É `TS-TIPO-02` em `Docs/Teste de Software - Tipos e Atributos de Qualidade.md`, e no nível de componente eles são baratos — é aqui que se paga menos por cobrir o que o usuário mais sofre.

---

## Passo 2 — Anatomia e tipagem

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

| Confira | Regra |
| --- | --- |
| um `export default` (o `meta`) e uma story por named export | `SB-CSF-01` |
| `satisfies Meta<typeof Componente>`, **não** anotação | `SB-CSF-02` |
| tipo da story derivado por `StoryObj<typeof meta>` | `SB-CSF-02` |
| `Meta`/`StoryObj` do pacote do **framework**, não do renderer | `SB-CORE-02` |
| `title` e `id` literais estáticos | `SB-CSF-03` |
| em `packages/ui`, `title` declarado explicitamente | `SB-CSF-10` |
| nada no corpo do módulo além de declaração pura | `SB-CORE-06` |
| named export que não é story sai, ou vai em `excludeStories` | `SB-CSF-09` |

**Por que `satisfies` e não anotação:** o tipo literal do objeto alimenta a inferência depois — `StoryObj<typeof meta>` lê os `args` declarados. Com anotação, essa informação é apagada e os `args` da story deixam de ser checados contra as props.

**`title` não reflete a árvore de pastas.** Ele é a hierarquia da sidebar, que é uma decisão de produto — `UI/Badge`, não `packages/ui/src/components/Badge`.

---

