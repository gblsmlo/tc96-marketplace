---
titulo: Storybook estruturado por Atomic Design
aliases:
  - Catálogo do Storybook
  - Atomic Design no Storybook
tags:
  - storybook
  - frontend
  - react
  - architecture
  - design-system
---
# Storybook estruturado por Atomic Design

> Nota irmã de [Feature-Based Architecture](feature-based-architecture.md). Aquela decide **onde o código mora**; esta decide
> **em que ordem o catálogo o apresenta**, e qual pergunta classifica uma story nova.
> A referência de API do Storybook — CSF, `args`, `play`, runner — é [Storybook](storybook.md); esta nota não a
> repete e não a substitui.

Esta nota é **condução**, não resumo de Atomic Design. Ela existe para duas decisões concretas:
onde uma story nova entra no catálogo, e o que reprova numa revisão. A seção 9 é o contrato que um
agente carrega.

---

## 1. O problema: um catálogo que cresce por acréscimo

A hierarquia da sidebar do Storybook é uma decisão de produto, não um espelho da árvore de pastas —
`SB-CSF-03` em [Storybook](storybook.md) diz isso explicitamente: `title` é a hierarquia, e ele é literal.

O efeito colateral é que **nada força um critério**. Cada grupo novo entra onde pareceu razoável no
dia em que apareceu, e o argumento é sempre o caso imediato. Um catálogo com sete grupos acumulados
assim tem uma ordem que ninguém consegue reconstruir, e duas decisões passam a exigir ler tudo:

- **onde ponho esta story nova?** — sem critério, a resposta é imitar o vizinho mais parecido;
- **isto já existe?** — o catálogo é o mapa de quem chega, e um mapa sem eixo não orienta.

O caso que expôs isso: um grupo `Layout` criado para documentar o shell de autenticação foi
posicionado **antes** de `Features`, com o argumento informal de "moldura antes da composição que
ela envolve". O argumento não resiste a exame — o shell recebe `children` e nunca importa uma
feature. Não havia regra, só precedente.

---

## 2. A escada, e o que dela se adota

Atomic Design nomeia a escada do indivisível ao concreto:

```
atoms → molecules → organisms → templates → pages
```

**O que esta nota adota é a escada, não o vocabulário.** Os grupos mantêm nomes que significam algo
localmente, e os cinco níveis servem como dois instrumentos: o **critério de ordem** e o **teste de
classificação** de uma story nova.

| Nível | Grupo aqui | O que é |
| --- | --- | --- |
| Atoms · Molecules | `UI` | primitivos indivisíveis: Button, Input, Field |
| Organisms neutros | `Patterns` | composições estáveis sem vocabulário de domínio |
| Organisms de domínio | `Features` | mesma complexidade, com regra e entidade do produto |
| Templates | `Layout` | estrutura de página com conteúdo de espaço reservado |
| Pages | `Pages` | o template preenchido com conteúdo real e estado de rota |

Ordem resultante:

```
Overview · UI · Patterns · Features · Layout · Pages
```

`Overview` **fica fora da escada** — é visão geral do catálogo, não nível de composição. Grupo meta
nunca ganha posição por nível; ele ancora nas pontas.

> **Por que não renomear os grupos para os cinco nomes.** A fronteira atom/molecule é notoriamente
> arbitrária na prática — um `Field` com label, input e mensagem é átomo ou molécula? A discussão
> não produz nenhuma decisão diferente, então o vocabulário é colapsado em `UI` e a energia vai para
> os cortes que **mudam** onde o código mora: neutro × domínio (§ 3) e template × page (§ 4).

---

## 3. `Patterns` × `Features`: o corte que decide

Os dois são organisms. Têm a mesma complexidade estrutural, o mesmo tamanho, muitas vezes a mesma
anatomia. O que os separa **não é reuso nem tamanho**:

> **A pergunta:** este componente carrega vocabulário do produto?
>
> Ou, operacionalmente: dá para levá-lo a outro produto sem editar o texto que ele exibe nem os
> tipos que ele recebe?

| | `Patterns` | `Features` |
| --- | --- | --- |
| Exemplos | `Checklist`, `DetailSheet`, `StateSurface`, `PasswordStrength` | `SignInForm`, `TasksToolbar`, `LeadsListView` |
| Conhece entidade | não — recebe dado já moldado pelo consumidor | sim — nomeia Lead, Task, Workspace |
| Conhece permissão | não | sim |
| Conhece política | não — `PasswordStrength` recebe `{label, met}[]` e ignora qual é a regra | sim — quem decide as linhas é a feature |
| Mora em | `packages/ui/src/patterns` | `apps/web/src/features/<feature>` |

**O corte do catálogo coincide com o corte de ownership**, e é isso que o torna verificável em vez
de editorial: um `Pattern` que precisou importar do domínio não está mal classificado no Storybook —
ele quebrou a fronteira do pacote, e o lint de boundaries pega. Ver [Feature-Based Architecture](feature-based-architecture.md)
§ 2, "Direção da dependência", e [Monorepo com Bun - estrutura e tooling](monorepo-com-bun-estrutura-e-tooling.md).

**Contagem de consumidores não entra na decisão.** Um pattern neutro é compartilhável antes do
segundo uso; um componente com vocabulário de domínio continua da feature mesmo aparecendo em cinco
telas. É a regra oposta à do terceiro consumidor de [Feature-Based Architecture](feature-based-architecture.md) (`REACT-ARCH-08`),
e a diferença é deliberada: lá o risco é abstrair cedo demais dentro de um app; aqui o risco é criar
uma segunda biblioteca de UI dentro do app.

---

## 4. `Layout` é template, e por isso vem **depois** de `Features`

Na definição de Frost, um Template arruma Organisms num esqueleto de página **com conteúdo de espaço
reservado**, sem amarrar dado real. Ele compõe organisms — logo vem depois deles na escada.

Foi o erro que a § 1 descreve: `Layout` estava antes de `Features`, invertendo a ordem de composição.

A consequência prática é uma regra de revisão, não uma preferência:

> **Uma story de `Layout` nunca renderiza um componente real de `Features`.** Ela renderiza um
> placeholder. Amarrar a feature de verdade devolve o template à condição de página — e o shell
> deixa de ser a moldura reutilizável que qualquer página compõe.

### O efeito de segunda ordem: ambiente vira prop

Um shell só é montável como template se puder ser montado **fora da aplicação**. Um shell que lê
ambiente no escopo do módulo não pode:

```tsx
// ✗ o parse roda no import; a casca só sobe onde a variável existir
import { clientEnv } from '@lemind/infra-env/client'

export function AppAuthLayout({ children }) {
  return <span>{clientEnv.VITE_APP_NAME}</span> /* … */
}

// ✓ o ambiente viaja por prop, e a rota continua a única leitora
export function AppAuthLayout({ appName, children }) {
  return <span>{appName}</span> /* … */
}
```

A story é o detector: se o template não sobe, o defeito é do componente, não da story. É o mesmo
mecanismo que `SB-TS-08` / `SB-RV-06` descrevem para acoplamento a rota em [Storybook](storybook.md) — a story
serve como prova de que a peça é montável isolada.

O ganho não é do Storybook. É que a leitura de ambiente volta para a borda, que é onde
[Feature-Based Architecture](feature-based-architecture.md) já a coloca.

---

## 5. Regras normativas (`SB-LAYER-*`)

> **Estas regras são desta nota**, não da § 6 de [Storybook](storybook.md). Ao citar num review, diga a origem
> junto — a família `SB-LAYER-*` não existe naquele inventário.

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.

| ID | Regra |
| --- | --- |
| `SB-LAYER-01` | A ordem do catálogo **MUST** ser `UI → Patterns → Features → Layout → Pages`. |
| `SB-LAYER-02` | Grupo novo **MUST** ser mapeado a um nível antes de entrar. Anexar ao fim da ordem por padrão, **NEVER**. |
| `SB-LAYER-03` | Um organism com vocabulário de produto **MUST** estar em `Features`; sem vocabulário, em `Patterns`. Contagem de consumidores **NEVER** decide. |
| `SB-LAYER-04` | Um `Pattern` **NEVER** importa uma `Feature`. |
| `SB-LAYER-05` | Uma story de `Layout` **NEVER** renderiza um componente real de `Features` — conteúdo de espaço reservado. |
| `SB-LAYER-06` | Uma story de `Pages` **MUST** montar o mesmo shell que a rota aplica, **NEVER** uma réplica dele. |
| `SB-LAYER-07` | Um shell montado como template **NEVER** lê ambiente no escopo do módulo; o ambiente **MUST** viajar por prop, e a rota permanece a única leitora. |
| `SB-LAYER-08` | `storySort.order` no `preview.*` **MUST** ser a fonte da ordem; a ordem de declaração em `main.ts` acompanha, mesmo sem efeito visual. |
| `SB-LAYER-09` | Grupo meta — `Overview` e afins — **NEVER** entra na escada; ancora nas pontas. |
| `SB-LAYER-10` | Toda entrada de `storySort.order` **MUST** casar com um grupo real. Entrada órfã é ignorada em silêncio pelo Storybook e sobrevive a revisão. |

### `SB-LAYER-06` — por que réplica é o antipadrão, não atalho

Uma story de página que recria a coluna, o cabeçalho e a divisão do shell "só para parecer igual"
cria duas fontes para a mesma medida, e uma delas envelhece em silêncio. O shell é documentado uma
vez, no seu próprio grupo, e é lá que seus contratos são aferidos; a página vive **dentro** dele.

Corolário: se o shell não é montável (`SB-LAYER-07`), a resposta certa é consertar o shell — não
escrever a réplica.

---

## 6. Como o catálogo é declarado

Dois arquivos, e só o segundo tem efeito visual:

```ts
// .storybook/main.ts — o diretório vira prefixo do título
stories: [
  { directory: '../src/stories/ui',       files: storyFiles, titlePrefix: 'UI' },
  { directory: '../src/stories/patterns', files: storyFiles, titlePrefix: 'Patterns' },
  { directory: '../src/stories/features', files: storyFiles, titlePrefix: 'Features' },
  { directory: '../src/stories/layouts',  files: storyFiles, titlePrefix: 'Layout' },
  { directory: '../src/stories/pages',    files: storyFiles, titlePrefix: 'Pages' },
]
```

```ts
// .storybook/preview.ts — isto é o que ordena a sidebar
options: {
  storySort: {
    order: ['Overview', 'UI', 'Patterns', 'Features', 'Layout', 'Pages'],
  },
}
```

Com `titlePrefix: 'Layout'` e `title: 'Auth'` no meta, o resultado é `Layout/Auth`. O `title` continua
literal e estático (`SB-CSF-03`); o prefixo monta o resto.

> **A armadilha do `main.ts`.** Reordenar os diretórios ali **não** reordena a sidebar — só
> `storySort.order` faz isso. Manter os dois em concordância é `SB-LAYER-08`, e existe pela mesma
> razão que aliases duplicados existem: quem lê a config depois precisa das duas contando a mesma
> história. Mudança em `main.ts` também **exige reiniciar** o Storybook; o índice não recarrega a
> config a quente.

---

## 7. Antipadrões

| Antipadrão | ID |
| --- | --- |
| Grupo novo anexado ao fim da ordem, sem mapear o nível | `SB-LAYER-02` |
| `Template` posicionado antes dos organisms que ele arruma | `SB-LAYER-01` |
| Componente classificado em `Patterns` por ser reusado, tendo vocabulário de domínio | `SB-LAYER-03` |
| Componente mantido em `Features` por ter um consumidor só, sendo neutro | `SB-LAYER-03` |
| Story de `Layout` montando o formulário real da feature | `SB-LAYER-05` |
| Story de página recriando o shell em vez de montá-lo | `SB-LAYER-06` |
| Shell que só sobe onde a variável de ambiente existe | `SB-LAYER-07` |
| Sidebar reordenada mexendo só em `main.ts` | `SB-LAYER-08` |
| Entrada em `storySort.order` apontando para grupo que não existe mais | `SB-LAYER-10` |

---

## 8. Divergências em relação à fonte

Atomic Design (Brad Frost) é a origem do argumento; esta nota é a fonte de verdade para decisão no
vault. Onde divergem, e por quê:

| Eixo | Frost | Aqui | Motivo |
| --- | --- | --- | --- |
| Vocabulário | atoms, molecules, organisms, templates, pages | `UI`, `Patterns`, `Features`, `Layout`, `Pages` | nomes locais significam mais para quem navega o catálogo |
| Atom × molecule | dois níveis | colapsados em `UI` | a fronteira não produz decisão diferente |
| Organism | um nível | dois: neutro e de domínio | o corte coincide com a fronteira de pacote e vira verificável |
| Template | artefato de wireframe, conteúdo cinza | código de produção com `children` de espaço reservado | o shell é o mesmo que a rota aplica; wireframe separado divergiria |
| Uso | metodologia de construção do design system inteiro | só critério de ordem e teste de classificação | a construção já é regida por [Feature-Based Architecture](feature-based-architecture.md) |

---

## 9. Contrato de skill

### Carregamento mínimo

```
SEMPRE:                  § 2 (escada e mapeamento) + § 5 (regras SB-LAYER-*)

AO CRIAR STORY NOVA:     § 3 (Patterns × Features) — a pergunta de classificação
AO CRIAR GRUPO NOVO:     § 2 + SB-LAYER-02 + § 6 (os dois arquivos)
AO REVISAR CATÁLOGO:     § 7 (antipadrões)
AO DOCUMENTAR UM SHELL:  § 4 (template) + SB-LAYER-05, -06, -07

TAMBÉM:                  [Storybook](storybook.md) § 6 para a API da story em si
                         (esta nota decide em que camada ela entra;
                          aquela decide como ela é escrita)

NUNCA:                   citar SB-LAYER-* como se fosse da § 6 de [Storybook](storybook.md)
```

### Ordem das decisões ao criar uma story

1. **Isto é primitivo indivisível?** → `UI`.
2. **É composição?** Então é organism. **Carrega vocabulário do produto?** Não → `Patterns`.
   Sim → `Features`.
3. **É estrutura de página com conteúdo de espaço reservado?** → `Layout`, e vale `SB-LAYER-05`.
4. **É a estrutura preenchida, variando por estado de rota?** → `Pages`, e vale `SB-LAYER-06`.
5. **Não encaixou em nenhum?** Não invente posição — o mapeamento da § 2 precisa de linha nova, e
   isso é decisão registrada, não exceção silenciosa.

### Como citar um achado

> `SB-LAYER-05` — `src/stories/layouts/auth-layout.stories.tsx:22`
> A story do template monta `SignInForm` em vez de um placeholder.
> Correção: renderizar conteúdo de espaço reservado; a composição real pertence a `pages/Login`.
> Regra desta nota, não da § 6 de [Storybook](storybook.md).

### Invariantes

1. **A escada é critério, não taxonomia.** Renomear grupo para "organisms" não melhora nada; o que
   melhora é aplicar a pergunta da § 3.
2. **Ownership antes de catálogo.** Se a classificação no Storybook briga com onde o arquivo mora,
   quem está errado é o arquivo.
3. **Story é detector.** Peça que não monta isolada tem defeito próprio; a story não é o lugar de
   contornar isso.
4. **Registrar, não excepcionar.** Grupo que não encaixa vira linha nova no mapeamento, com decisão
   registrada.

---

## Aplicação de referência

Aplicado no monorepo `lemind`, registrado como decisão `028 — a escada do Atomic Design ordena o
catálogo do Storybook`. As autoridades do catálogo naquele repositório, na ordem:

```text
UI/*                              primitivos de packages/ui/src/components
Patterns/DetailSheet/{Shell,Content}
Patterns/Checklist
Patterns/Audit Trail
Patterns/PasswordStrength
Features/Tasks/{DetailSheet,Views,Toolbar}
Features/Pipeline/{Views,Toolbar}
Features/Leads/Preview
Features/Auth/Password/{SignIn,SignUp,ForgottenPassword,ResetPassword}
Features/Auth/TwoFactor
Layout/Auth
pages/{Login,Register,ResetPassword}
```

Dois detalhes que só aparecem na aplicação real:

- **`Features/Auth` é agrupada por provider**, não por tipo de componente — `Password` reúne entrada,
  cadastro e as duas etapas da recuperação; `TwoFactor` é grupo irmão porque é outro fator. O nível
  da escada decide a posição; o agrupamento **dentro** do nível é vocabulário de produto.
- **`PasswordStrength` nasceu em `Patterns` com um consumidor só**, por `SB-LAYER-03`: ele recebe
  `{label, met}[]` e não conhece a política de senha, que mora na feature.

---

## Relacionados

- [Storybook](storybook.md) — a referência de API: CSF, `args`, `play`, runner, e as famílias `SB-*` da § 6
- [Feature-Based Architecture](feature-based-architecture.md) — nota irmã: onde o código mora e quem importa quem
- [Storybook - Stories e Args](storybook-stories-e-args.md) — como a story é escrita depois que a camada foi decidida
- [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md) — o catálogo como documentação
- `storybook-story` — a skill que escreve o arquivo de story
- [React - Patterns](react-patterns.md) — decisão dentro do componente
- [Monorepo com Bun - estrutura e tooling](monorepo-com-bun-estrutura-e-tooling.md) — a fronteira de pacote que torna o corte da § 3 verificável
- [Architecture in React](architecture-in-react.md) — nota mãe dos eixos de decisão
- `Product Design` — o design system do lado do produto
- [Frontend roadmap](frontend-roadmap.md) — trilha de estudos

## Fontes consultadas

- Brad Frost, *Atomic Design* — <https://atomicdesign.bradfrost.com/chapter-2/>
- [Storybook — `storySort`](https://storybook.js.org/docs/writing-stories/naming-components-and-hierarchy)
- [Storybook — `main.ts` stories](https://storybook.js.org/docs/api/main-config/main-config-stories)
- Decisão `028` do monorepo `lemind` — a aplicação de referência
