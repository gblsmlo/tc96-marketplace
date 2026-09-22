# `args`, `argTypes`, tags e docs

### 3.1 A regra que domina

> **O que distingue uma story de outra é `args`.** Estado embutido em `render` **NEVER** (`SB-CSF-04`).

Não é estilo. Estado em `render` mata três coisas de uma vez: o leitor não pode editar pelo painel, o runner não pode variar, e a tabela de docs não pode documentar.

### 3.2 Três níveis, merge por chave

`preview` → `meta` → story. O mais específico vence, e **sobrescrever uma subchave não derruba as irmãs**.

Composição por **spread**, nunca mutação (`SB-CSF-05`):

```tsx
export const Padrao: Story = { args: { rotulo: 'Novo' } };

// ✓ reusa
export const Grande: Story = { args: {...Padrao.args, tamanho: 'lg' } };
// ✗ muta
// Padrao.args.tamanho = 'lg';
```

### 3.3 O que **não** é `args`

Se o que distingue é **o mundo em volta** — tema, provider, rota, resposta de rede, relógio —, é **ambiente**, e ambiente entra por decorator, `loaders` ou `beforeEach` ([Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md)).

E o par que mais se confunde: **`globals` é para variação que o leitor troca pela toolbar** (tema, locale). O que distingue duas stories **nunca** é global — é `args` (`SB-CTX-05`).

Provider compartilhado por mais de um componente vive em decorator **global** do `preview`, não repetido por arquivo (`SB-CTX-03`).

---

## Passo 4 — `argTypes` é exceção

**O default é não escrever `argTypes`** (`SB-CSF-08`). Com `component` declarado, o docgen infere tipo, valores possíveis e controle. Redeclarar o que o tipo já expressa cria uma segunda fonte que envelhece.

Quando entra:

| Caso | O que usar |
| --- | --- |
| valor não serializável num controle (função, componente, ícone) | `mapping` (`SB-CSF-06`) |
| controle que o docgen não adivinha | o tipo de controle explícito |
| esconder da tabela de docs | `table: { disable: true }` |
| desligar o controle mantendo a linha | `control: false` |

> **A troca silenciosa:** `control: false` **mantém** a linha na documentação; quem apaga a linha é `table: { disable: true }`. Os dois parecem sinônimos e fazem coisas diferentes.

**Descrição de prop não vai em `argTypes`.** Ela vem do JSDoc no componente, que é fonte única (`SB-DOC-02`).

---

## Passo 5 — Tags e a página de docs

| Tag | Efeito |
| --- | --- |
| `dev` | aparece na sidebar (aplicada por padrão) |
| `test` | entra no runner (aplicada por padrão) |
| `autodocs` | gera a página de docs (**não** é aplicada por padrão) |
| `'!tag'` | remove uma herdada |

A forma prescrita de ligar autodocs é **herdar do `preview`**, não arquivo a arquivo (`SB-DOC-01`).

E o corte entre os dois papéis de uma story (`SB-DOC-04`):

| A story serve a… | Marque |
| --- | --- |
| só documentação | `'!test'` — sai do runner |
| só teste | `'!autodocs'` — sai da página |

**Num design system, a story alimenta a página de docs por desenho** — é por isso que [Storybook - Docs e Autodocs](../../../../knowledge-base/docs/storybook-docs-e-autodocs.md) entra no carregamento mínimo. E a story que a página exibe precisa expressar seu estado por `args`, senão os controles aparecem vazios (`SB-DOC-05`, que é apelido de `SB-CSF-04` — cite o canônico).

---

