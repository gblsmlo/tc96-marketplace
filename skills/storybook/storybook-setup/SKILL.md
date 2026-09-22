---
nome: storybook-setup
descricao: Configurar Storybook num projeto ou monorepo — escolher entre os dois frameworks pelos pisos de versão, `main.ts`, `preview.tsx`, de onde a config do Vite é herdada, CSS e tema — citando IDs `SB-CFG-*` e `SB-CORE-*`, com um script que descobre o caminho e confere os pisos — use quando a tarefa for instalar Storybook do zero, migrar da linha 8 ou 9, decidir o framework, consertar sidebar vazia, alinhar versões de pacote, ou recortar `apps/storybook` num monorepo. Não use para escrever story, que é storybook-story, para o teste dentro dela, que é storybook-test, nem para cobertura e CI, que é o satélite Cobertura e CI.
tipo: skill
familia: storybook
fonte: "[Storybook - Configuração e Builder](../../../knowledge-base/docs/storybook-configuracao-e-builder.md)"
tags:
  - skill
  - storybook
  - frontend
---

# storybook-setup

> **Fonte desta skill:** [Storybook - Configuração e Builder](../../../knowledge-base/docs/storybook-configuracao-e-builder.md), com o hub [Storybook](../../../knowledge-base/docs/storybook.md) como roteador.
> Esta skill **não contém** o texto das regras — ela diz o que decidir, em que ordem, e o que conferir.

Contrato que esta skill implementa: [Storybook](../../../knowledge-base/docs/storybook.md) § 7.

---

## Quando usar

Instalar, migrar ou reconfigurar Storybook.

| Situação | Vá para |
| --- | --- |
| escrever story | `storybook-story` |
| teste de interação dentro da story | `storybook-test` |
| cobertura e job de CI | [Storybook - Cobertura e CI](../../../knowledge-base/docs/storybook-cobertura-e-ci.md) |
| teste de jornada | `playwright-build` · teste de unidade | `bun-test-build` |

---

## Passo 1 — Escolher o framework

**A decisão que tudo depois pressupõe**, e é **praticamente irreversível**: a automigração `react-vite-to-tanstack-react` é unidirecional.

```
Alguma story vai importar @tanstack/react-router —
direta ou transitivamente (um <Link> dentro de um componente conta)?
├── NÃO, e nunca vai → @storybook/react-vite (React ≥ 16.8 · Vite ≥ 5)
└── SIM, ou provavelmente
 ├── o projeto está em React ≥ 18 E Vite ≥ 7?
 │ ├── SIM → @storybook/tanstack-react
 │ └── NÃO → @storybook/react-vite + router à mão (transição)
```

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-setup/scripts/descobrir-caminho.sh
```

O script lê o campo `framework`, confere os pisos, e **procura a contradição de caminho no código** — que é o achado que falha em silêncio.

Três fatos que mudam a decisão: `tanstack-react` cobra **Vite ≥ 7** (adotá-lo em Vite 5/6 é agendar migração de Vite antes de qualquer story); **TanStack Start não é requisito**; e o redirecionamento para a camada de mock é **global**, não opt-in.

**Num monorepo, a pergunta não é sobre `packages/ui`** — é sobre o pacote mais exigente que o Storybook vai cobrir.

Detalhe: `references/escolher-o-framework.md`.

---

## Carregamento mínimo

| Ordem | Carregar |
| --- | --- |
| 1 | [Storybook](../../../knowledge-base/docs/storybook.md) § 5.1 (a árvore de framework) e § 6.2 (as famílias mutuamente exclusivas) |
| 2 | [Storybook - Configuração e Builder](../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| 3 | a nota do **caminho escolhido**: [Storybook - TanStack React](../../../knowledge-base/docs/storybook-tanstack-react.md) ou [Storybook - React Vite](../../../knowledge-base/docs/storybook-react-vite.md) |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/escolher-o-framework.md` | a árvore, os pisos, e os três fatos não óbvios |
| `references/sequencia-e-vite.md` | a sequência de sete passos, e de onde a config do Vite é herdada |
| `references/autoverificacao.md` | a checklist, e a armadilha de augmentation de tipo |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 75 `SB-*` por satélite e seção |
| `references/exemplo.md` | caso trabalhado |
| `scripts/descobrir-caminho.sh` | lê o `framework`, confere pisos e acha contradição |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa nas três skills |

---

## Passo 2 — A sequência

`references/sequencia-e-vite.md`: a ordem de sete passos que a doc oficial nunca dá, e **de onde a config do Vite é herdada** — que é a causa da maioria dos "funciona no app e quebra no Storybook".

---

## Passo 3 — Autoverificar

`references/autoverificacao.md`, mais a armadilha de **augmentation de tipo**.

**Suba e olhe a sidebar.** Glob que não casa **não dá erro** — dá sidebar vazia (`SB-CFG-02`).

---

## Passo 4 — Fechar, e passar o bastão

1. **Registre a escolha de framework.** Ela determina qual nota carregar pelo resto da vida do projeto.
2. **Citar a família do caminho errado é achado inválido** (`SB-TS-*` × `SB-RV-*`).
3. Story → `storybook-story`; teste dentro dela → `storybook-test`; cobertura e CI → [Storybook - Cobertura e CI](../../../knowledge-base/docs/storybook-cobertura-e-ci.md).

---

## Exemplo

Monorepo com `packages/ui` e `apps/web`: a pergunta não é sobre `ui`, é sobre `web`, onde toda página importa `Link`. O projeto está em Vite 6 — então `tanstack-react` exige **migração de Vite antes da primeira story**, e a saída de transição é `react-vite` com router à mão.

Caso completo: `references/exemplo.md`.

---

## Relacionados

- [Storybook - Configuração e Builder](../../../knowledge-base/docs/storybook-configuracao-e-builder.md) — fonte desta skill
- [Storybook](../../../knowledge-base/docs/storybook.md) § 5.1, § 6.2, § 7
- `storybook-story` · `storybook-test` — as skills irmãs
- [Storybook - TanStack React](../../../knowledge-base/docs/storybook-tanstack-react.md) · [Storybook - React Vite](../../../knowledge-base/docs/storybook-react-vite.md) — as duas notas de caminho
