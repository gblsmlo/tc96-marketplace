---
titulo: Storybook - Stories e Args
Link: https://storybook.js.org/docs/writing-stories
tags:
  - storybook
  - react
  - frontend
  - csf
  - agent-context
source: "Documentação oficial do Storybook — Writing Stories, Args, Controls, Naming, Tags, CSF API"
verificado-em: 2026-08-19
---

# Storybook — Stories e Args

> Satélite de [Storybook](storybook.md). Cobre o formato do arquivo de stories e a superfície de entrada que o Storybook controla: `args`, `argTypes`, `render`, `tags`, título e hierarquia.
>
> O modelo mental está na § 2 do hub e não é repetido aqui. A afirmação que mais importa para este satélite é a **4**: args são a única entrada controlada, e tudo o mais é ambiente — ambiente é o assunto de [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md).

Caso guia: `packages/ui`, o design system do monorepo. Componentes puros, sem acoplamento a rota.

> **Vale nos dois caminhos de framework.** Os exemplos escrevem o token `@storybook/tanstack-react`; sob [Storybook - React Vite](storybook-react-vite.md), troque por `@storybook/react-vite`. Nada mais nesta nota diverge entre os frameworks.

---

## 1. Anatomia do arquivo

Um arquivo de stories tem exatamente duas coisas: um `export default` — o **meta** — e um named export por story.

```tsx
// packages/ui/src/button/Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import { Button } from './Button';

const meta = {
  title: 'UI/Ações/Button',
  component: Button,
  args: {
    children: 'Salvar',
    variant: 'primary',
  },
} satisfies Meta<typeof Button>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Primary: Story = {};

export const Secondary: Story = {
  args: { variant: 'secondary' },
};

export const Disabled: Story = {
  args: { disabled: true },
};

export const RotuloLongo: Story = {
  name: 'Rótulo longo',
  args: { children: 'Salvar e continuar editando este registro' },
};
```

Quatro coisas a notar, porque cada uma é uma decisão:

1. **`Primary` é `{}`.** O estado primário já é o default do `meta.args`. Uma story vazia não é preguiça — é a afirmação de que aquele é o estado base.
2. **Cada story muda uma coisa.** `variant`, `disabled`, `children`. Story que muda três args de uma vez não isola nada e falha sem dizer o quê.
3. **`RotuloLongo` existe porque é um caso de quebra.** Rótulo longo é o estado que revela overflow, truncamento e quebra de layout. É o tipo de story que só aparece se você escrever pensando em estado, não em demo.
4. **`name` só entra quando o export não serve.** O Storybook converte `RotuloLongo` em `"Rotulo Longo"` — sem acento. `name` corrige o rótulo sem forçar um nome de export inválido em TS.

### 1.1 O corpo do módulo não roda

O Storybook monta o índice da sidebar **lendo o arquivo estaticamente**, sem executá-lo. Três consequências práticas:

- **`title` precisa ser literal.** Uma template string como ``title: `UI/${grupo}/Button` `` não é legível estaticamente e falha. O mesmo vale para `id`.
- **Nada de efeito colateral nem de não-determinismo no topo do módulo.** Um `const dados = await carregar()` ou um `Math.random()` no corpo do arquivo produz índice inconsistente. Dado assíncrono é `loaders`; setup imperativo é `beforeEach`. **Computação pura é permitida** — um `gerarLinhas(10_000)` determinístico no topo do módulo é legítimo, e é o que `SB-CORE-06` deixa passar de propósito. Ver [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md).
- **Uma story não pode depender de outra.** Não existe ordem garantida, e o runner pode executar uma story isolada. Estado compartilhado que atravessa stories é bug (`SB-CTX-04`).

### 1.2 Título, hierarquia e hoisting

`title` usa `/` para aninhar. `'UI/Ações/Button'` produz `UI → Ações → Button` na sidebar.

**Hoisting de story única:** quando um componente tem só uma story cujo nome exibido coincide com o último segmento do `title`, essa story substitui a pasta na UI. Como o Storybook aplica *start case* aos nomes de export (`myStory` vira `"My Story"`), o nome do componente precisa casar com essa forma para o hoisting acontecer.

**Ordenação** é do projeto, não do arquivo — `storySort` em `.storybook/preview.tsx`:

```tsx
const preview = {
  parameters: {
    options: {
      storySort: {
        method: 'alphabetical',
        order: ['Introdução', 'Tokens', 'UI', '*'],
        includeNames: true,
      },
    },
  },
} satisfies Preview;
```

`*` posiciona tudo que não casou com o `order`.

**Sobre auto-título:** a fonte trata `title` como opcional e, quando omitido, gera o título automaticamente — mas a página de naming **não declara o mecanismo**; ela redireciona para a configuração de carregamento de stories. Esta doc não verificou a derivação, e por isso prescreve `title` explícito em `packages/ui` (`SB-CSF-10`): num design system a hierarquia da sidebar é decisão de produto, não subproduto da árvore de pastas.

### 1.3 Exports que não são stories

Todo named export é lido como story. Um helper exportado no mesmo arquivo aparece na sidebar como story quebrada. Duas saídas:

```tsx
// preferida: não exportar
const dadosBase = { id: '1', nome: 'Ada' };
```

```tsx
// quando o export é necessário (reuso entre arquivos de story)
export const dadosBase = { id: '1', nome: 'Ada' };

const meta = {
  component: Tabela,
  excludeStories: ['dadosBase'],
} satisfies Meta<typeof Tabela>;
```

`includeStories` é o inverso, por lista branca. Ambos aceitam string, array ou regex.

### 1.4 Regras — `SB-CSF-01`, `SB-CSF-03`, `SB-CSF-09`, `SB-CSF-10`

| ID | Regra |
| --- | --- |
| `SB-CSF-01` | Um arquivo de stories **MUST** ter exatamente um `export default` (o `meta`) e uma story por named export. |
| `SB-CSF-03` | `title` e `id` **MUST** ser literais estáticos. Template string, concatenação ou valor computado **NEVER**. |
| `SB-CSF-09` | Named export que não é story **MUST** deixar de ser exportado, ou ser listado em `excludeStories`. |
| `SB-CSF-10` | Em `packages/ui`, `title` **MUST** ser declarado explicitamente. † |

---

## 2. Tipagem

### 2.1 `satisfies`, não anotação

```tsx
// ✅ correto
const meta = {
  component: Button,
  args: { children: 'Salvar', variant: 'primary' },
} satisfies Meta<typeof Button>;

type Story = StoryObj<typeof meta>;
```

`satisfies` verifica o objeto contra `Meta<typeof Button>` **sem alargar o tipo**. O `meta` continua sabendo exatamente quais args foram declarados — e é dessa informação que `StoryObj<typeof meta>` vive: ela sabe que `children` e `variant` já têm valor, então uma story pode ser `{}` mesmo que as props sejam obrigatórias no componente.

### 2.2 Os dois erros de tipagem

```tsx
// ❌ anotação em vez de satisfies
const meta: Meta<typeof Button> = {
  component: Button,
  args: { children: 'Salvar', variant: 'primary' },
};
// o tipo do meta passa a ser Meta<typeof Button> genérico.
// StoryObj<typeof meta> perde o conhecimento dos args declarados,
// e toda story volta a exigir as props obrigatórias.

// ❌ tipar a story pelo componente
type Story = StoryObj<typeof Button>;
// mesmo efeito: a story não sabe o que o meta já preencheu.
```

O sintoma dos dois é idêntico e reconhecível: **`export const Primary: Story = {}` passa a dar erro de prop obrigatória faltando**. Quando isso aparece, o defeito é a tipagem, não a story.

### 2.3 Regras — `SB-CSF-02`

| ID | Regra |
| --- | --- |
| `SB-CSF-02` | `meta` **MUST** ser declarado com `satisfies Meta<typeof Componente>`, e o tipo da story derivado por `StoryObj<typeof meta>`. |

---

## 3. Args

### 3.1 Três níveis, merge por chave

`args` existem em projeto (`preview`), componente (`meta`) e story. O mais específico vence, e o merge é **por chave**: definir `variant` na story não apaga `children` do `meta`.

```tsx
// .storybook/preview.tsx — vale para tudo
const preview = { args: { tamanho: 'md' } } satisfies Preview;

// meta — vale para o componente
args: { children: 'Salvar', variant: 'primary' }

// story — vale para esta story
args: { variant: 'secondary' }

// resultado renderizado:
// { tamanho: 'md', children: 'Salvar', variant: 'secondary' }
```

> Arg global é raro e perigoso: ele injeta a mesma prop em **todo** componente do catálogo. Só faz sentido para uma prop que literalmente todo componente aceita. Variação de ambiente (tema, locale) não é arg — é `globals`, e vive em [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md).

### 3.2 Composição por spread

```tsx
export const Secondary: Story = {
  args: { variant: 'secondary' },
};

export const SecondaryDisabled: Story = {
  args: { ...Secondary.args, disabled: true },
};
```

Ler `Secondary.args` é permitido e é a forma prescrita de reuso. **Mutar não**: `Secondary.args.disabled = true` altera a outra story, e como não há ordem garantida entre stories, o resultado depende de quem renderizou primeiro.

### 3.3 O que **não** é arg

Aqui está a fronteira que mais rende código errado. `args` são a entrada que o Storybook controla e o leitor edita. Se o que distingue duas stories não pode virar arg, ele não pertence ao arquivo de stories — pertence ao ambiente.

| O que distingue as stories | Onde vai |
| --- | --- |
| uma prop | `args` |
| markup ou provider em volta | `decorators` |
| dado assíncrono a carregar | `loaders` |
| relógio, comportamento de mock | `beforeEach` |
| resposta de rede | MSW ou `sb.mock` — [Storybook - Mocking](storybook-mocking.md) |
| tema, locale | `globals` |

```tsx
// ❌ estado embutido no render: nada disso é controlável nem documentável
export const Carregando: Story = {
  render: () => <Tabela linhas={[]} carregando={true} />,
};

// ✅ o estado é arg
export const Carregando: Story = {
  args: { linhas: [], carregando: true },
};
```

O custo do primeiro não é estético: o painel de controles fica vazio, a tabela de props do autodocs não documenta nada, e o runner não consegue variar a entrada.

### 3.4 Escrever arg de dentro da story

Componente controlado precisa que o valor mude quando o usuário interage. `useArgs` faz o ciclo voltar ao arg:

```tsx
import { useArgs } from 'storybook/preview-api';

export const Controlado: Story = {
  render: function Render(args) {
    const [{ marcado }, atualizarArgs] = useArgs();
    return (
      <Checkbox
        {...args}
        marcado={marcado}
        onChange={() => atualizarArgs({ marcado: !marcado })}
      />
    );
  },
};
```

**Caveat da fonte, literal:** não misture a API de hooks do Storybook com os hooks do React. Efeitos e re-render disparados por hooks do React não passam pelo contexto de hooks do Storybook. Um `useState` ao lado de `useArgs` no mesmo `render` produz duas fontes de verdade que divergem — e a que o painel de controles mostra é a que está errada.

Note também o `render: function Render(args)`, com nome. Componente anônimo em `render` com hook dentro quebra as regras de Hooks do React (`REACT-HOOK-02` em [React - Rules of React](react-rules-of-react.md)).

### 3.5 Regras — `SB-CSF-04`, `SB-CSF-05`, `SB-CSF-07`

| ID | Regra |
| --- | --- |
| `SB-CSF-04` | O que distingue uma story de outra **MUST** ser `args`. Estado embutido em `render` **NEVER**. |
| `SB-CSF-05` | `args` de outra story **MUST** ser reusado por spread. Mutar `Story.args` **NEVER**. |
| `SB-CSF-07` | Hooks do Storybook **NEVER** são misturados com Hooks do React no mesmo `render`. |

---

## 4. `argTypes` e controles

### 4.1 O default é não escrever `argTypes`

Com `component` declarado no `meta`, o Storybook usa `react-docgen` para inferir os controles e **gerar os `argTypes` automaticamente** a partir dos tipos do componente. Um `argTypes` escrito à mão que só repete o que o tipo já diz é duplicação que sai de sincronia na primeira refatoração.

Escreva `argTypes` quando a inferência não alcança:

| Situação | O que declarar |
| --- | --- |
| union de strings que deve virar rádio | `control: 'radio'` + `options` |
| número com faixa | `control: { type: 'range', min, max, step }` |
| valor não serializável (ReactNode) | `mapping` |
| prop que não deve ter controle | `control: false` |
| prop que não deve nem aparecer | `table: { disable: true }` |

### 4.2 Tipos de controle

| Tipo do dado | Controles |
| --- | --- |
| boolean | `boolean` |
| number | `number`, `range` |
| string | `text`, `color`, `date` |
| enum | `radio`, `inline-radio`, `check`, `inline-check`, `select`, `multi-select` |
| object / array | `object` |
| arquivo | `file` (aceita `accept`) |

```tsx
const meta = {
  title: 'UI/Ações/Button',
  component: Button,
  argTypes: {
    // o docgen já infere um select da union; 'radio' é escolha de APRESENTAÇÃO,
    // não redeclaração do tipo — é o que salva isto de SB-CSF-08
    variant: { control: 'radio' },
    tamanho: { control: { type: 'range', min: 1, max: 5, step: 1 } },
    // control: false, não table.disable — o callback é público e precisa
    // continuar documentado (§ 4.3)
    onClick: { control: false },
  },
  parameters: { controls: { sort: 'requiredFirst' } },
} satisfies Meta<typeof Button>;
```

> Note que `variant` **não** repete `options`. Quando a union já está no tipo do componente, o docgen fornece as opções; declarar `control: 'radio'` só troca o widget. Repetir `options: ['primary', 'secondary', 'ghost']` cria a segunda fonte de verdade que `SB-CSF-08` proíbe — e é o que quebra quando alguém adiciona uma variante ao tipo.

`controls.sort` aceita `'none'` (default), `'alpha'` e `'requiredFirst'`. Num design system, `'requiredFirst'` é o mais útil: coloca no topo o que o consumidor é obrigado a passar.

### 4.3 `control: false` × `table: { disable: true }`

Distinção que a fonte faz e que costuma ser trocada:

- **`control: false`** — some o controle, **mantém a linha na documentação**. Para prop que existe e importa, mas não é editável ao vivo.
- **`table: { disable: true }`** — some a linha inteira, controle e documentação. Para ruído que não deve ser documentado.

### 4.4 `mapping` para valor não serializável

Um controle só transporta valor serializável. Para oferecer um `ReactNode` num select, `options` lista os rótulos e `mapping` traduz para o valor real:

```tsx
argTypes: {
  icone: {
    control: { type: 'select' },
    options: ['Nenhum', 'Salvar', 'Excluir'],
    mapping: {
      Nenhum: undefined,
      Salvar: <IconeDisquete />,
      Excluir: <IconeLixeira />,
    },
  },
}
```

### 4.5 Regras — `SB-CSF-06`, `SB-CSF-08`

| ID | Regra |
| --- | --- |
| `SB-CSF-06` | Valor não serializável oferecido em controle **MUST** passar por `mapping`. |
| `SB-CSF-08` | `argTypes` **MUST** ser exceção: com `component` declarado, o docgen infere. Redeclarar o que o tipo já expressa **NEVER**. † |

---

## 5. `render`

`render` é para **estrutura**, nunca para estado (`SB-CSF-04`). Três usos legítimos:

```tsx
// 1. o componente precisa de um contexto de composição
export const DentroDeToolbar: Story = {
  args: { variant: 'ghost' },
  render: (args) => (
    <Toolbar>
      <Button {...args} />
    </Toolbar>
  ),
};

// 2. a story exercita mais de um componente junto
export const GrupoDeBotoes: Story = {
  render: (args) => (
    <ButtonGroup>
      <Button {...args} variant="primary">Salvar</Button>
      <Button {...args} variant="ghost">Cancelar</Button>
    </ButtonGroup>
  ),
};

// 3. a API do componente não é "props para um elemento"
export const ComRenderProp: Story = {
  render: (args) => (
    <Combobox {...args}>{(item) => <Opcao item={item} />}</Combobox>
  ),
};
```

Em todos, `args` é **espalhado** no componente. `render` que ignora `args` desliga o painel de controles — é o mesmo defeito da § 3.3 com outra roupa.

`render` declarado no `meta` vale para todas as stories daquele componente; declarado na story, só para ela, e sobrescreve o do `meta`.

---

## 6. Tags

Tags decidem **onde a story aparece**. Quatro governam isso, e **três delas são aplicadas por default**:

| Tag | Aplicada por default | Efeito |
| --- | --- | --- |
| `dev` | sim | renderiza na sidebar |
| `test` | sim | entra nas rodadas do runner / addon-vitest |
| `manifest` | sim | entra nos manifests de componente e de docs |
| `autodocs` | **não** | entra na página de docs — ver [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) |

Duas outras são aplicadas automaticamente por detecção: `play-fn` em story com `play`, e `test-fn` em definições pelo método experimental `.test`.

Tags acumulam pelos três níveis, e `'!tag'` remove uma herdada:

```tsx
// .storybook/preview.tsx — autodocs para todo o catálogo
const preview = { tags: ['autodocs'] } satisfies Preview;

// meta — este componente é interno, não documenta
const meta = {
  component: BotaoInterno,
  tags: ['!autodocs', 'interno'],
} satisfies Meta<typeof BotaoInterno>;

// story — caso de quebra que serve ao teste, mas polui a sidebar e a doc
export const CemMilLinhas: Story = {
  tags: ['!dev', '!autodocs'],
  args: { linhas: gerarLinhas(100_000) },
};
```

O último padrão é o mais útil num design system: `!dev` mantém a story no runner e fora da vitrine. É como se escreve caso de estresse sem sujar o catálogo.

**Os eixos são independentes.** `dev` controla a sidebar, `test` o runner, `autodocs` a página de docs. Uma story `'!dev'` **continua** aparecendo no autodocs, porque as tags não se implicam. Um caso de estresse que não deve aparecer em lugar nenhum além do runner precisa das duas remoções: `tags: ['!dev', '!autodocs']`.

Tag própria (`'interno'`, `'experimental'`) serve para filtro na sidebar e para `include`/`exclude` do addon-vitest — ver [Storybook - Testes e Interações](storybook-testes-e-interacoes.md).

---

## 7. Antipadrões

### 7.1 Story como demo

```tsx
// ❌
export const ExemploDeUso: Story = {
  render: () => (
    <div>
      <h2>Como usar o Button</h2>
      <p>Use variant primary para a ação principal.</p>
      <Button variant="primary">Salvar</Button>
    </div>
  ),
};
```

Isso é documentação vestida de story: entra no runner, quebra sem informar nada, e a prosa deveria estar em MDX ou na descrição do autodocs. Ver [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md).

### 7.2 Uma story por combinação

Seis variantes × três tamanhos × dois estados não são 36 stories. Variantes são `args` com controle — o leitor combina. Escreva story para os estados que **importam**: o default, os de quebra (rótulo longo, lista vazia, erro), e os que o teste precisa fixar.

### 7.3 `args` que não casa com prop

`args` cuja chave não existe nas props do componente passa silenciosamente pelo `satisfies` quando o componente aceita props extras, e nunca tem efeito. Sintoma: a story renderiza igual a outra. Confira o nome antes de investigar o componente.

### 7.4 `title` refletindo a árvore de pastas

`'packages/ui/src/button/Button'` é caminho de arquivo, não hierarquia de design system. Quem consome o catálogo pensa em *Ações*, *Formulário*, *Feedback* — não em `src`.

### 7.5 `argTypes` copiando o tipo do componente

Reescrever à mão o que o docgen já inferiu cria duas fontes de verdade. Na primeira renomeação de prop, a tabela de docs mostra o nome antigo (`SB-CSF-08`).

### 7.6 `useState` para simular controle

```tsx
// ❌ o painel de controles fica dessincronizado do que está na tela
export const Controlado: Story = {
  render: (args) => {
    const [valor, setValor] = useState(args.valor);
    return <Input {...args} valor={valor} onChange={setValor} />;
  },
};
```

O arg vira valor inicial e para de ter efeito; editar o controle não muda nada. É `useArgs` (§ 3.4), e sem hook do React ao lado (`SB-CSF-07`).

---

## Relacionados

- [Storybook](storybook.md) — hub: modelo mental, árvores de decisão, contrato de skill
- [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) — tudo que não é `args`
- [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) — o que fazer com a prosa que não cabe numa story
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — `play`, e o que `tags: ['test']` habilita
- [React - Rules of React](react-rules-of-react.md) — `render` com hook é componente, e as regras valem
- [React - Patterns](react-patterns.md) — o que é componente de design system e o que não é

## Fontes consultadas

Verificadas diretamente em **2026-08-19**:

- [Writing Stories](https://storybook.js.org/docs/writing-stories)
- [Args](https://storybook.js.org/docs/writing-stories/args)
- [Naming components and hierarchy](https://storybook.js.org/docs/writing-stories/naming-components-and-hierarchy)
- [Tags](https://storybook.js.org/docs/writing-stories/tags)
- [Controls](https://storybook.js.org/docs/essentials/controls)
- [CSF API](https://storybook.js.org/docs/api/csf)

**Notas de verificação:**

- **A página de naming não declara o mecanismo de auto-título.** Ela marca `title` como opcional e remete à configuração de carregamento de stories. Não verificado aqui — daí `SB-CSF-10`.
- **`options` mora em `argTypes`, ao lado de `control`**, não dentro dele.
- **`control: false` mantém a linha na documentação**; quem apaga a linha é `table: { disable: true }`. São coisas diferentes e a troca é silenciosa.
- **Os controles são inferidos por `react-docgen` a partir de `component`** — a doc é explícita que declarar `component` já gera os `argTypes`.
- **`controls.sort` tem três valores:** `'none'` (default), `'alpha'`, `'requiredFirst'`.
- **`dev`, `test` e `manifest` são aplicadas por default; `autodocs` não.** Existem ainda `play-fn` e `test-fn`, aplicadas por detecção.
- **A fonte proíbe misturar a API de hooks do Storybook com hooks do React** em `render`: efeitos e re-render do React não passam pelo contexto de hooks do Storybook.
- **Hoisting de story única depende do *start case*** aplicado ao nome do export coincidir com o último segmento do `title`.
