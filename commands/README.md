# Comandos — pontos de entrada nomeados

Um comando é o que **a pessoa invoca**: `/scaffold-projeto`, `/configurar-antigravity`.
Não é uma quarta camada da cadeia — papel → procedimento → regra continua sendo a
cadeia, e um comando roteia para as mesmas skills e para a mesma regra.

A diferença em relação a um agente: o agente recebe uma tarefa em contexto próprio e
decide o que carregar; o comando é um roteiro fixo, com fases numeradas e portões.

## Scaffold de projeto TanStack Start

O orquestrador, que chama as fases: [`scaffold-projeto`](scaffold-projeto.md) —
orquestra o scaffold completo de um projeto TanStack Start, fase a fase.

As 10 fases, executáveis uma a uma:

| Fase | O que faz |
| --- | --- |
| [`scaffold-01-tanstack-start`](scaffold-01-tanstack-start.md) | Fase 1 — base TanStack Start com TypeScript, Tailwind e Vite |
| [`scaffold-02-biome`](scaffold-02-biome.md) | Fase 2 — Biome como lint e formatter |
| [`scaffold-03-vitest`](scaffold-03-vitest.md) | Fase 3 — Vitest e Testing Library |
| [`scaffold-04-git-hooks`](scaffold-04-git-hooks.md) | Fase 4 — git hooks e portões de commit |
| [`scaffold-05-fba`](scaffold-05-fba.md) | Fase 5 — estrutura de diretórios Feature-Based Architecture |
| [`scaffold-06-shadcn`](scaffold-06-shadcn.md) | Fase 6 — shadcn/ui e tokens de design |
| [`scaffold-07-workos-authkit`](scaffold-07-workos-authkit.md) | Fase 7 — autenticação com WorkOS AuthKit |
| [`scaffold-08-scripts`](scaffold-08-scripts.md) | Fase 8 — scripts de package e tarefas do projeto |
| [`scaffold-09-feature-exemplo`](scaffold-09-feature-exemplo.md) | Fase 9 — feature de exemplo ponta a ponta |
| [`scaffold-10-verificacao`](scaffold-10-verificacao.md) | Fase 10 — verificação final do scaffold |

## Variante FBA

Cinco fases com o mesmo recorte, mais detalhadas e com o teste de fronteira de
[Feature-Based Architecture](../knowledge-base/pages/feature-based-architecture.md)
escrito por extenso:

| Fase | O que faz |
| --- | --- |
| [`scaffold-fba-01-start`](scaffold-fba-01-start.md) | Variante FBA — fase 1, base do projeto |
| [`scaffold-fba-02-biome`](scaffold-fba-02-biome.md) | Variante FBA — fase 2, Biome |
| [`scaffold-fba-03-vitest`](scaffold-fba-03-vitest.md) | Variante FBA — fase 3, Vitest |
| [`scaffold-fba-04-git-hooks`](scaffold-fba-04-git-hooks.md) | Variante FBA — fase 4, git hooks |
| [`scaffold-fba-05-fba`](scaffold-fba-05-fba.md) | Variante FBA — fase 5, estrutura de diretórios |

## Ambiente

[`configurar-antigravity`](configurar-antigravity.md) — configura o agente do Antigravity com as regras desta casa.

## Anatomia

| Campo | Para quê |
| --- | --- |
| `nome:` | igual ao arquivo; é o que vira `/nome` no runtime |
| `descricao:` | a linha que a pessoa lê na lista de comandos |
| `tipo: comando` | o que faz o adaptador emitir este arquivo |
| `idioma:` | `en` — o corpo veio assim do build anterior, e não foi traduzido |
| `tags:` | quando o comando original trazia |

Quem emite: `build/claude-code.sh` escreve `commands/<nome>.md` com `description:`,
para os comandos declarados em `PLUGINS`; `build/agents-md.sh` escreve a tabela
**Comandos** no `AGENTS.md` e copia o corpo sem frontmatter.

## O que está declarado, e não conferido

Estes 17 arquivos vieram do build anterior **sem revisão de conteúdo**. Duas
coisas visíveis, que valem uma decisão antes de rodar qualquer um deles em projeto novo:

- eles usam **`pnpm`**, e o stack desta casa é **Bun** (`bun-workspace`, `bun-runtime`);
- `scaffold-01…10` e `scaffold-fba-01…05` cobrem o mesmo terreno com detalhe diferente,
  e nada declara qual dos dois é o caminho corrente.
