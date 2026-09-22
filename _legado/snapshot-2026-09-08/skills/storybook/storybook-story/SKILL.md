---
name: storybook-story
description: Escrever ou revisar story de componente — anatomia do arquivo, tipagem com `satisfies`, `args` nos três níveis, `argTypes` como exceção, tags e a página de docs — citando IDs `SB-CSF-*` e `SB-CTX-*`, com autoverificação executável — use quando a tarefa for criar story nova, decidir o que é `args` e o que é ambiente, compor variação por spread, oferecer controle para valor não serializável, nomear `title` num design system, ou ligar autodocs. Não use para o teste dentro da story, que é storybook-test, nem para configurar o projeto, que é storybook-setup.
tags:
  - skill
  - storybook
  - frontend
fonte: "[[Storybook - Stories e Args]]"
---

# storybook-story

> **Fonte desta skill:** [[Storybook - Stories e Args]], com o hub [[Storybook]] como roteador.
> Esta skill **não contém** o texto das regras — ela diz o que decidir e o que conferir.

Contrato que esta skill implementa: [[Storybook]] § 7.

---

## Passo 0 — Se a story tocar rota, descubra o caminho

```bash
bash ~/.claude/skills/storybook-setup/scripts/descobrir-caminho.sh
```

`SB-TS-*` e `SB-RV-*` são **mutuamente exclusivas**, e prescrever o caminho errado **falha em silêncio**. Se o componente não toca rota, o caminho não muda nada — mas **confirme antes de assumir**.

---

## Quando usar

Criar ou revisar `*.stories.tsx`.

| Situação | Vá para |
| --- | --- |
| a `play` dentro da story | [[storybook-test]] |
| configurar o projeto, sidebar vazia, versões | [[storybook-setup]] |
| decidir **em que nível** o teste vai | [[teste-design]] |
| o componente em si | [[react-developer]] · [[react-review]] |

---

## Carregamento mínimo

| Ordem | Carregar |
| --- | --- |
| 1 | [[Storybook]] § 2 (modelo mental) e § 6 |
| 2 | [[Storybook - Stories e Args]] |
| 3 | [[Storybook - Decorators e Contexto]] quando a story precisar de ambiente |
| 4 | a nota do caminho, **se** a story tocar rota |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/anatomia-e-tipagem.md` | a pergunta que decide o arquivo, `satisfies Meta`, `StoryObj<typeof meta>` |
| `references/args-e-docs.md` | `args` nos três níveis, `argTypes` como exceção, tags e a página de docs |
| `references/autoverificacao.md` | os 14 itens |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 75 `SB-*` por satélite e seção |
| `references/exemplo.md` | caso trabalhado |
| `scripts/autoverificar.sh` | roda os itens mecânicos e lista os que exigem leitura |

---

## Passo 1 — A pergunta que decide o arquivo

**Cada story é um estado nomeado, não uma demo** (`SB-CSF-04`) — e o que distingue duas stories é **`args`**. Se duas stories diferem por outra coisa, ou o componente tem duas responsabilidades, ou o ambiente virou `args`.

---

## Passo 2 — Anatomia e tipagem

`satisfies Meta<typeof C>` no `meta`, `StoryObj<typeof meta>` nas stories (`SB-CSF-02`) — é o que faz o autocomplete de `args` existir. Import de `Meta`/`StoryObj` vem do **pacote do framework** (`SB-CORE-02`), não de `@storybook/react`.

---

## Passo 3 — `args`, e o que **não** é `args`

Ambiente — router, tema, `QueryClient`, sessão — vai por **decorator ou loader** (`SB-CTX-03`, `SB-CTX-05`), nunca por `args`. Valor não serializável precisa de `mapping` para virar controle (`SB-CSF-06`).

Variação se compõe por **spread**, sem mutar `Story.args` (`SB-CSF-05`).

---

## Passo 4 — `argTypes` é exceção

Se o docgen já infere, `argTypes` é ruído (`SB-CSF-08`). Descrição de prop mora no **JSDoc** (`SB-DOC-02`) — duplicá-la em `argTypes` cria segunda fonte.

---

## Passo 5 — Autoverificar

```bash
bash ~/.claude/skills/storybook-story/scripts/autoverificar.sh src
```

**Depois, suba e olhe a sidebar.** Glob que não casa **não dá erro** — dá sidebar vazia (`SB-CFG-02`). E abra a página de docs: **controles vazios são o sintoma de `SB-CSF-04` violada**.

---

## Passo 6 — Fechar

1. **Estados vazio e de erro existem, ou a ausência foi decidida** (`TS-TIPO-02`) — são baratos aqui e caros no E2E.
2. **Se a story virou teste**, o bastão é de [[storybook-test]].
3. **Se o problema é o componente**, e não a story, é [[react-review]].

---

## Exemplo

Story de `Botao` num design system: `title` explícito, `satisfies Meta`, quatro estados nomeados por `args`, tema por decorator, e o ícone (não serializável) exposto por `mapping`. O que o hábito produziria: uma story "Playground" com `argTypes` reescrevendo o que o docgen já infere.

Caso completo: `references/exemplo.md`.

---

## Relacionados

- [[Storybook - Stories e Args]] — fonte desta skill
- [[Storybook - Decorators e Contexto]] — o ambiente que não é `args`
- [[Storybook - Docs e Autodocs]] — a página de docs
- [[storybook-setup]] · [[storybook-test]] — as skills irmãs
