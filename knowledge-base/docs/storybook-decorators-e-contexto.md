---
titulo: Storybook - Decorators e Contexto
Link: https://storybook.js.org/docs/writing-stories/decorators
tags:
 - storybook
 - react
 - contexto
 - agent-context
source: "Documentação oficial do Storybook — Decorators, Parameters, Toolbars and globals, Loaders"
verificado-em: 2026-08-19
---

# Storybook — Decorators e Contexto

> Satélite de [Storybook](storybook.md). Cobre tudo que a story precisa e que **não** é `args`: decorators, `parameters`, `globals`, `loaders` e `beforeEach`.
>
> **Uma divergência de caminho.** Sob `@storybook/react-vite`, o decorator é o mecanismo prescrito para dar um router à story (§ 2.5). Sob `@storybook/tanstack-react`, isso é proibido — o framework já embrulha. O resto da nota vale igual nos dois.
>
> A fronteira está na § 3.3 de [Storybook - Stories e Args](storybook-stories-e-args.md): se o que distingue duas stories é uma prop, é `args`. Se é o mundo em volta, é assunto desta nota.

---

## 1. As cinco ferramentas, e quando cada uma serve

| Ferramenta | O que injeta | Quando roda | Níveis |
| --- | --- | --- | --- |
| `decorators` | markup e contexto React em volta | envolve o render | P C S |
| `parameters` | metadado estático para Storybook e addons | lido, não executado | P C S |
| `globals` | variação que o **leitor** troca na toolbar | lido no render | P C S |
| `loaders` | dado assíncrono, em paralelo | antes do render | P C S |
| `beforeEach` | setup imperativo, com desfazer | antes do render | P C S |

`P` projeto (`preview`), `C` componente (`meta`), `S` story.

A regra de escolha, em uma frase: **decorator para o que embrulha, loader para o que carrega, `beforeEach` para o que precisa ser desfeito, `parameters` para o que configura, `globals` para o que o leitor decide.**

---

## 2. Decorators

### 2.1 Assinatura e ordem

Um decorator recebe a story e o contexto:

```tsx
const meta = {
 component: Card,
 decorators: [
 (Story) => (
 <div style={{ padding: '3em' }}>
 <Story />
 </div>
 ),
 ],
} satisfies Meta<typeof Card>;
```

O segundo parâmetro é o contexto da story, com — entre outros campos — `args`, `argTypes`, `globals`, `parameters`, `hooks` e `viewMode` (`'story'` ou `'docs'`).

**A ordem é fixa e vale a pena decorar:**

```
global (na ordem de definição)
 └── componente (na ordem de definição)
 └── story (o mais INTERNO)
 └── o componente
```

Ou seja: o decorator global é o mais externo, e o da story é o que fica colado no componente. Um `ThemeProvider` global embrulha o decorator de layout do `meta`, que embrulha o da story. É a ordem que se quer por default — provider por fora, ajuste fino por dentro.

### 2.2 O uso legítimo: provider

```tsx
//.storybook/preview.tsx
const preview = {
 decorators: [
 (Story) => (
 <IntlProvider locale="pt-BR">
 <TooltipProvider>
 <Story />
 </TooltipProvider>
 </IntlProvider>
 ),
 ],
} satisfies Preview;
```

Provider é ambiente compartilhado por todo o catálogo. Repetir isso em cada arquivo de story é o erro mais comum de configuração — e a consequência não é só duplicação: quando um provider ganha uma prop nova, metade das stories fica para trás (`SB-CTX-03`).

### 2.3 Tema: `globals` + decorator

Tema é o caso onde as duas ferramentas se encontram. `globalTypes` declara o controle da toolbar, `initialGlobals` dá o valor inicial, e um decorator global lê o valor e aplica:

```tsx
//.storybook/preview.tsx
const preview = {
 globalTypes: {
 theme: {
 description: 'Tema do design system',
 toolbar: {
 title: 'Tema',
 icon: 'circlehollow',
 items: ['light', 'dark'],
 dynamicTitle: true,
 },
 },
 },
 initialGlobals: {
 theme: 'light',
 },
 decorators: [
 (Story, context) => (
 <div data-theme={context.globals.theme}>
 <Story />
 </div>
 ),
 ],
} satisfies Preview;
```

`items` aceita strings ou objetos `MenuItem` — `value` e `title` obrigatórios, `right` e `icon` opcionais:

```tsx
items: [
 { value: 'pt-BR', right: '🇧🇷', title: 'Português' },
 { value: 'en-US', right: '🇺🇸', title: 'English' },
]
```

Uma story pode fixar um global, quando o estado que ela documenta **é** aquele ambiente:

```tsx
export const NoTemaEscuro: Story = {
 globals: { theme: 'dark' },
};
```

Isso é legítimo e é diferente de usar global como arg: aqui o tema é o assunto da story. O que `SB-CTX-05` proíbe é o contrário — usar global para carregar uma diferença que é prop do componente.

### 2.4 Ler global dentro do render

```tsx
export const ComLocale: Story = {
 render: (args, { globals: { locale } }) => (
 <Legenda texto={legendaPara(locale)} {...args} />
 ),
};
```

### 2.5 Decorator de router: depende do caminho

Este é o único ponto desta nota em que a resposta muda conforme o framework.

| Caminho | Como a story ganha um router |
| --- | --- |
| `@storybook/tanstack-react` | **automático.** Decorator com `RouterProvider` é proibido — cria um segundo router competindo (`SB-TS-03`) |
| `@storybook/react-vite` | **por decorator**, com `createMemoryHistory` + `createRouter`. É o mecanismo prescrito — ver [Storybook - React Vite](storybook-react-vite.md) § 4 |

`SB-CTX-06` cobre os dois casos sem contradição, porque é condicional ao framework: *não embrulhe o que o framework já embrulha*. Sob `react-vite`, o framework não embrulha nada — então o decorator é a resposta certa, e a regra não se aplica.

### 2.6 Regras — `SB-CTX-02`, `SB-CTX-03`, `SB-CTX-05`, `SB-CTX-06`

| ID | Regra |
| --- | --- |
| `SB-CTX-02` | A ordem de decorator é global → componente → story, com o de story **mais interno**. Código que depende de outra ordem **NEVER**. |
| `SB-CTX-03` | Provider compartilhado por mais de um componente **MUST** viver em decorator global de `preview`. † |
| `SB-CTX-05` | `globals` são para variação que o leitor troca. O que distingue duas stories **NEVER** é global — é `args`. † |
| `SB-CTX-06` | Decorator **NEVER** embrulha o que o framework já embrulha. † |

---

## 3. `parameters`

### 3.1 Merge por chave

Esta é a mecânica que mais rende configuração duplicada quando não se conhece. Parameters dos três níveis fazem **merge por chave**, e a fonte é explícita: *"os parâmetros são combinados, então chaves só são sobrescritas, nunca descartadas"*.

```tsx
// preview.tsx
parameters: {
 a11y: { test: 'error', config: { rules: [/* … */] } },
 layout: 'centered',
}

// story
parameters: {
 a11y: { test: 'todo' },
}

// efetivo nessa story:
// a11y.test === 'todo'
// a11y.config → PRESERVADO do projeto
// layout → PRESERVADO do projeto
```

A consequência prática é a que interessa: **subir configuração para o `preview` não engessa nada.** Uma story continua podendo sobrescrever um detalhe sem repetir o resto. Quem não sabe disso acaba repetindo o bloco inteiro em cada arquivo, por medo de perder o que estava lá.

### 3.2 Os mais usados

| Parameter | Para que |
| --- | --- |
| `layout` | `'centered'`, `'padded'`, `'fullscreen'` |
| `backgrounds` | opções de fundo do canvas |
| `a11y` | `context`, `config`, `options`, `test` — [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| `docs` | `page`, `toc`, `description` — [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) |
| `controls` | `sort`, e comportamento do painel — [Storybook - Stories e Args](storybook-stories-e-args.md) |
| `tanstack.router` | rota, params, contexto — [Storybook - TanStack React](storybook-tanstack-react.md) |

`layout` num design system merece decisão consciente: `'centered'` para componente atômico, `'fullscreen'` para composição de página, `'padded'` (o default) para o resto.

### 3.3 Regras — `SB-CTX-01`

| ID | Regra |
| --- | --- |
| `SB-CTX-01` | `parameters` fazem merge por chave: sobrescrever uma subchave **NEVER** derruba as irmãs. |

---

## 4. `loaders`

Funções assíncronas que rodam **antes** do render e cujo retorno entra no contexto:

```tsx
export const ComDadoRemoto: Story = {
 loaders: [
 async => ({
 tarefa: await (await fetch('https://exemplo/tarefas/1')).json,
 }),
 ],
 render: (args, { loaded: { tarefa } }) => <Tarefa {...args} {...tarefa} />,
};
```

Três fatos que decidem uso:

- **Rodam em paralelo.** Quando duas chaves colidem, vence a última — na ordem projeto → componente → story.
- **O dado chega em `context.loaded`**, não em `args`.
- **A própria fonte chama loaders de escape hatch**, e diz que `args` é a forma recomendada de gerenciar dado de story.

Esse último ponto é o que importa num design system: um componente de `packages/ui` que precisa de `loaders` está buscando dado sozinho, e provavelmente devia receber o dado por prop. O loader é para o caso raro em que o dado remoto é parte do cenário, não do componente. Para simular rede, o caminho é [Storybook - Mocking](storybook-mocking.md) — não um loader que chama `fetch` de verdade.

---

## 5. `beforeEach`

Setup imperativo, com desfazer opcional no retorno:

```tsx
const meta = {
 component: Agenda,
 async beforeEach {
 MockDate.set('2026-02-14');
 return => MockDate.reset;
 },
} satisfies Meta<typeof Agenda>;
```

`beforeEach` **recebe o contexto da story**, e é assim que addons entregam a própria API — o `msw` de `beforeEach({ msw })` em [Storybook - Mocking](storybook-mocking.md) § 3.2 vem do `mswLoader` registrado no `preview`, não de um import. Por isso as três formas abaixo são a mesma coisa, e todas aparecem nesta estrutura:

```tsx
beforeEach: => { /* … */ } // sem usar o contexto
async beforeEach { /* … */ } // method shorthand
beforeEach({ msw }) { /* … */ } // desestruturando o contexto
```

O retorno é a função de limpeza, e ela roda depois da story. Dois usos dominam:

1. **Congelar o mundo** — relógio, `Math.random`, locale do sistema. Sem isso, uma story de data vira teste instável.
2. **Definir comportamento de mock** — via `mocked`, o assunto de [Storybook - Mocking](storybook-mocking.md) § 2.4.

**Mocks criados por `fn` são a exceção declarada:** a fonte afirma que não é necessário restaurá-los na limpeza, porque o Storybook já faz isso entre stories (`SB-TEST-07`). Se a mesma garantia vale para o comportamento definido com `mocked` sobre um módulo de `sb.mock`, a fonte **não diz** — está aberto em [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md).

### 5.1 O caso que mais aparece: cache compartilhado

Um `QueryClient` criado uma vez no `preview` é compartilhado por todas as stories. Sem reset, a segunda story renderiza com o cache preenchido pela primeira — e o resultado depende da ordem, que não é garantida (`SB-CTX-04`; a ausência de ordem entre stories é `SB-CORE-05`):

```tsx
//.storybook/preview.tsx
const queryClient = new QueryClient({
 defaultOptions: { queries: { retry: false, staleTime: Infinity } },
});

const preview = {
 beforeEach: => {
 queryClient.clear;
 },
} satisfies Preview;
```

O detalhe completo, incluindo por que `retry: false` e como o client entra no contexto do router, está em [Storybook - TanStack React](storybook-tanstack-react.md) § 5.

### 5.2 Regras — `SB-CTX-04`, `SB-CTX-07`, `SB-CTX-08`

| ID | Regra |
| --- | --- |
| `SB-CTX-04` | Estado mutável compartilhado entre stories **MUST** ser resetado em `beforeEach`. |
| `SB-CTX-07` | Dado assíncrono necessário ao render **MUST** vir de `loaders`; setup imperativo com desfazer **MUST** vir de `beforeEach`. † |
| `SB-CTX-08` | `beforeEach` que altera estado global do ambiente (relógio, `Math.random`, locale, store) **MUST** retornar a função de limpeza. Comportamento de mock definido por `mocked` é caso à parte — ver [Storybook - Mocking](storybook-mocking.md) § 2.4 e a pendência aberta em [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md). |

---

## 6. Antipadrões

### 6.1 Provider repetido em cada arquivo de story

```tsx
// ❌ em Button.stories.tsx, Card.stories.tsx, Input.stories.tsx…
decorators: [(Story) => <ThemeProvider><Story /></ThemeProvider>],
```

Pertence ao `preview` (`SB-CTX-03`). O sintoma aparece quando o provider muda: metade do catálogo fica para trás, e as stories esquecidas quebram de um jeito que não aponta para a causa.

### 6.2 Repetir o bloco inteiro de `parameters` por medo do merge

```tsx
// ❌ copiar todo o a11y.config do preview só para trocar o test
parameters: {
 a11y: { test: 'todo', config: { rules: [/* cópia do preview */] } },
}
```

Merge é por chave (`SB-CTX-01`). `{ a11y: { test: 'todo' } }` basta.

### 6.3 Global como se fosse arg

```tsx
// ❌ 'variante' é prop do componente, não ambiente do catálogo
globalTypes: { variante: { toolbar: { items: ['primary', 'secondary'] } } },
```

O controle vira global da sidebar inteira e afeta componentes que nem têm essa prop. É `argTypes` com `options` (`SB-CTX-05`).

### 6.4 `loaders` chamando a API de verdade

Story que faz `fetch` real depende de rede em CI, fica lenta e falha por motivo alheio ao componente. Rede se mocka — [Storybook - Mocking](storybook-mocking.md).

### 6.5 `beforeEach` sem limpeza

Congelar o relógio e não restaurar contamina as stories seguintes, que passam a renderizar com a data fixa de outra story (`SB-CTX-08`).

### 6.6 Decorator embrulhando o que o framework já embrulha

Sob `@storybook/tanstack-react`, escrever um decorator com `RouterProvider` cria um segundo router competindo com o que o framework monta. Ver `SB-TS-03` em [Storybook - TanStack React](storybook-tanstack-react.md).

**Atenção ao caminho:** sob `@storybook/react-vite` esse mesmo decorator é o correto, não o antipadrão. Ver § 2.5.

---

## Relacionados

- [Storybook](storybook.md) — hub
- [Storybook - Stories e Args](storybook-stories-e-args.md) — a fronteira entre `args` e ambiente
- [Storybook - Mocking](storybook-mocking.md) — quando o ambiente a injetar é rede ou módulo
- [Storybook - TanStack React](storybook-tanstack-react.md) — o contexto que o framework já injeta
- [Storybook - React Vite](storybook-react-vite.md) — o contexto que você injeta à mão
- [React - Estado e Reatividade](react-estado-e-reatividade.md) — Context em React, e o custo dele

## Fontes consultadas

Verificadas diretamente em **2026-08-19**:

- [Decorators](https://storybook.js.org/docs/writing-stories/decorators)
- [Parameters](https://storybook.js.org/docs/writing-stories/parameters)
- [Toolbars and globals](https://storybook.js.org/docs/essentials/toolbars-and-globals)
- [Loaders](https://storybook.js.org/docs/writing-stories/loaders)

**Notas de verificação:**

- **Parameters fazem merge, e chaves nunca são descartadas** — só sobrescritas. É afirmação literal da fonte, e é o que permite sobrescrever uma subchave sem repetir o bloco.
- **Ordem de decorator: global → componente → story, com o de story mais interno.**
- **Loaders rodam em paralelo**, e na colisão de chave vence o último, na ordem projeto → componente → story.
- **A fonte chama loaders de escape hatch** e recomenda `args` como forma padrão de gerenciar dado de story.
- **Dado de loader chega em `context.loaded`**, não em `args`.
- **`beforeEach` retorna a função de limpeza**, e a fonte diz explicitamente que mocks `fn` **não** precisam ser restaurados ali — o Storybook já faz.
- **`globalTypes` declara o controle da toolbar; `initialGlobals` dá o valor inicial.** São campos distintos, ambos em `preview`.
- **`globals` também é aceito em `meta` e em story**, para fixar o ambiente de um componente ou de uma story específica.
- **`useGlobals` tem duas origens diferentes:** `storybook/preview-api` para uso dentro do preview, e `storybook/manager-api` para código de addon. Não são o mesmo import.
