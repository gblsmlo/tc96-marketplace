---
Link: https://storybook.js.org/docs/writing-docs/autodocs
tags:
 - storybook
 - documentacao
 - design-system
 - agent-context
source: "Documentação oficial do Storybook — Autodocs, Controls, Tags"
verificado-em: 2026-08-19
---

# Storybook — Docs e Autodocs

> Satélite de [Storybook](storybook.md). Cobre a página de documentação que o Storybook gera a partir das stories: a tag `autodocs`, doc blocks, MDX, `subcomponents` e sumário.
>
> **Vale nos dois caminhos de framework.** Os exemplos escrevem o token `@storybook/tanstack-react`; sob [Storybook - React Vite](storybook-react-vite.md), troque por `@storybook/react-vite`. Nada mais nesta nota diverge entre os frameworks.
>
> É o satélite mais próximo do valor de um design system — a página de docs é o que o consumidor de `packages/ui` lê antes de usar um componente. E é o que se degrada mais rápido, porque quase tudo nela é derivado: se a story está mal escrita, a documentação sai mal escrita sozinha.

---

## 1. Conceito: a documentação é derivada

A página de autodocs é montada a partir de três fontes, e **nenhuma delas é prosa escrita à mão**:

| Fonte | Vira o quê na página |
| --- | --- |
| tipos e JSDoc do componente, via docgen | a tabela de props, com tipo, default e descrição |
| `args` e `argTypes` | os controles interativos ao lado de cada prop |
| as próprias stories | os exemplos renderizados |

Daí a consequência que governa este satélite: **melhorar a documentação quase nunca é escrever documentação.** É escrever JSDoc no componente, e escrever story que expresse estado por `args` (`SB-DOC-05`). Uma story com `render` hardcoded produz uma página com tabela de controles vazia — o defeito da § 3.3 de [Storybook - Stories e Args](storybook-stories-e-args.md) reaparece aqui como documentação inútil.

---

## 2. Ligar

Autodocs é controlado por **tag**: a página é gerada quando a tag `autodocs` alcança o arquivo. Como tags acumulam pelos três níveis (ver [Storybook - Stories e Args](storybook-stories-e-args.md) § 6), ligar no `preview` já satisfaz todo o catálogo — e é por isso que `SB-DOC-01` fala em *alcançar*, não em *declarar no arquivo*. Declarar de novo no `meta` de um arquivo que já herda do projeto é duplicação (§ 2).

```tsx
//.storybook/preview.tsx — o catálogo inteiro documenta
const preview = {
 tags: ['autodocs'],
} satisfies Preview;
```

```tsx
// meta — só este componente
const meta = {
 title: 'UI/Ações/Button',
 component: Button,
 tags: ['autodocs'],
} satisfies Meta<typeof Button>;
```

```tsx
// meta — este componente é interno e não documenta
const meta = {
 title: 'UI/Interno/BotaoInterno',
 component: BotaoInterno,
 tags: ['!autodocs'],
} satisfies Meta<typeof BotaoInterno>;
```

Num design system a escolha certa é **ligar no projeto e desligar nas exceções**. O inverso — ligar arquivo a arquivo — garante que o componente novo nasce sem documentação, e ninguém percebe.

Configuração de projeto, em `main.ts`:

| Opção | O que faz |
| --- | --- |
| `docs.defaultName` | renomeia a página gerada (o default é `"Docs"`) |
| `docs.docsMode` | modo em que só páginas de documentação aparecem |

`docsMode` é o que transforma o Storybook em site de documentação: útil para o build público do design system, mantendo o build interno com as stories visíveis.

### 2.1 Regras — `SB-DOC-01`, `SB-DOC-05`

| ID | Regra |
| --- | --- |
| `SB-DOC-01` | A página de docs **MUST** ter a tag `autodocs` alcançando o arquivo — herdada do `preview` (a forma prescrita), ou declarada no `meta` ou numa story. |
| `SB-DOC-05` | A story que a página exibe **MUST** expressar seu estado por `args`. Estado em `render` **NEVER** — a tabela de controles sai vazia. † |

---

## 3. De onde vem o texto

### 3.1 Descrição de prop: JSDoc no componente

```tsx
// packages/ui/src/button/Button.tsx
export interface ButtonProps {
 /** Hierarquia visual da ação. `primary` é a ação principal da tela. */
 variant?: 'primary' | 'secondary' | 'ghost';
 /** Desabilita o botão e remove ele da ordem de foco. */
 disabled?: boolean;
}
```

O docgen extrai isso e monta a tabela. **A fonte da descrição é o componente, e só ele** (`SB-DOC-02`). Repetir a descrição em `argTypes.description` cria uma segunda verdade que diverge na primeira refatoração — o mesmo defeito que `SB-CSF-08` descreve para os controles.

Isso tem um efeito colateral desejável: escrever a documentação do design system passa a ser escrever JSDoc no código, que é onde quem consome o pacote pelo editor também vai ler.

> **Sobrescrever descrição por parameter.** A API de docs expõe configuração de descrição além do docgen. **Não verificado nesta doc** — o que está verificado é o caminho do docgen. Se precisar sobrescrever, consulte a referência de parameters antes de escrever.

### 3.2 O que fazer com a prosa que não é de prop

Prosa — quando usar cada variante, regra de espaçamento, o que não fazer — não cabe numa story (`SB-DOC-03`). Dois lugares:

**Template customizado com doc blocks**, para mudar a estrutura de todas as páginas:

```tsx
//.storybook/preview.tsx
import { Title, Subtitle, Description, Primary, Controls, Stories } from '@storybook/addon-docs/blocks';

const preview = {
 parameters: {
 docs: {
 page: => (
 <>
 <Title />
 <Subtitle />
 <Description />
 <Primary />
 <Controls />
 <Stories />
 </>
 ),
 },
 },
} satisfies Preview;
```

**MDX**, para a página que precisa de texto próprio. É também o caminho para páginas que não são de componente — introdução, tokens, princípios — que entram pelos globs `*.mdx` de `main.ts`. Um MDX marcado com `<Meta isTemplate />` serve de template.

### 3.3 Sumário

```tsx
parameters: {
 docs: { toc: true },
}
```

Aceita opções: `headingSelector`, `title`, `disable`, `ignoreSelector`.

---

## 4. `subcomponents`

Documenta componentes relacionados na mesma página, com abas separadas na tabela de props:

```tsx
const meta = {
 component: Lista,
 subcomponents: { ItemDaLista },
} satisfies Meta<typeof Lista>;
```

Serve para API composta — `Lista`/`ItemDaLista`, `Accordion`/`AccordionItem` — onde documentar em páginas separadas esconde a relação. Não serve para agrupar componentes que apenas aparecem juntos: aí são páginas distintas com stories de composição.

---

## 5. Story de documentação × story de teste

As duas convivem no mesmo arquivo, e as tags separam:

```tsx
// caso de estresse: precisa rodar no runner, não precisa aparecer na vitrine
export const DezMilLinhas: Story = {
 tags: ['!dev'],
 args: { linhas: gerarLinhas(10_000) },
};

// exemplo de composição: aparece na doc, não acrescenta nada ao runner
export const EmFormulario: Story = {
 tags: ['!test'],
 render: (args) => (
 <Formulario>
 <Campo {...args} />
 </Formulario>
 ),
};
```

| Tag removida | Efeito |
| --- | --- |
| `'!dev'` | sai da sidebar, continua no runner |
| `'!test'` | sai do runner, continua na sidebar e na doc |
| `'!autodocs'` | sai da página de docs |

Essa é a ferramenta que evita o dilema entre "catálogo limpo" e "cobertura de teste" (`SB-DOC-04`).

### 5.1 Regras — `SB-DOC-02`, `SB-DOC-03`, `SB-DOC-04`

| ID | Regra |
| --- | --- |
| `SB-DOC-02` | Descrição de prop **MUST** ter fonte única: o JSDoc no componente. Duplicar em `argTypes.description` **NEVER**. † |
| `SB-DOC-03` | Prosa de documentação **MUST** morar em MDX ou em `docs.page`. Story usada como texto **NEVER**. † |
| `SB-DOC-04` | Story que serve só à documentação **MUST** sair do runner com `'!test'`; story que serve só ao teste **MUST** sair da sidebar com `'!dev'`. † |

---

## 6. Antipadrões

### 6.1 Documentar em `argTypes` o que o JSDoc já diz

Duas fontes, uma delas envelhece calada (`SB-DOC-02`).

### 6.2 Story que é um artigo

```tsx
export const Diretrizes: Story = {
 render: => <article><h2>Quando usar</h2>{/* três parágrafos */}</article>,
};
```

Entra no runner, quebra sem informar nada, e o texto não é indexável como documentação. É MDX (`SB-DOC-03`).

### 6.3 Ligar autodocs arquivo a arquivo

Componente novo nasce sem página, e ninguém nota porque não há erro. Ligue no `preview` e desligue nas exceções.

### 6.4 Página bonita, controles vazios

Sintoma clássico de story com estado em `render`. A página parece completa e não deixa o consumidor experimentar nada — que é a única coisa que a página de docs faz melhor que um README (`SB-DOC-05`).

### 6.5 `subcomponents` como pasta

Empilhar seis componentes soltos numa página só porque pertencem ao mesmo domínio. `subcomponents` é para API composta; agrupamento é hierarquia de `title`.

---

## Relacionados

- [Storybook](storybook.md) — hub
- [Storybook - Stories e Args](storybook-stories-e-args.md) — `args`, `argTypes` e tags, de onde a página é derivada
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — o outro consumidor das mesmas stories
- [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) — os globs de `*.mdx` e `docs` em `main.ts`
- `TypeScript` — o JSDoc que vira tabela de props

## Fontes consultadas

Verificadas diretamente em **2026-08-19**:

- [Autodocs](https://storybook.js.org/docs/writing-docs/autodocs)
- [Controls](https://storybook.js.org/docs/essentials/controls)
- [Tags](https://storybook.js.org/docs/writing-stories/tags)

**Notas de verificação:**

- **Autodocs é controlado por tag**, não por uma opção de ligar/desligar: a página existe quando há `autodocs` no arquivo. `'!autodocs'` desliga.
- **`defaultName` e `docsMode` são as opções de `docs` em `main.ts`.**
- **Os controles e os `argTypes` são inferidos por `react-docgen` a partir de `component`** — a documentação de prop vem do código, não do arquivo de story.
- **Doc blocks verificados:** `Title`, `Subtitle`, `Description`, `Primary`, `Controls`, `Stories`.
- **`<Meta isTemplate />` é o mecanismo de template em MDX.**
- **`toc` aceita `headingSelector`, `title`, `disable` e `ignoreSelector`.**
- **`subcomponents` produz abas na tabela de argTypes**, não páginas separadas.
- **Sobrescrever descrição por `parameters.docs` não foi verificado aqui.** O caminho verificado é o docgen.
