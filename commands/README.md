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
| [`scaffold-03-bun-test`](scaffold-03-bun-test.md) | Fase 3 — `bun test`, happy-dom e Testing Library |
| [`scaffold-04-git-hooks`](scaffold-04-git-hooks.md) | Fase 4 — git hooks e portões de commit |
| [`scaffold-05-fba`](scaffold-05-fba.md) | Fase 5 — estrutura de diretórios Feature-Based Architecture |
| [`scaffold-06-shadcn`](scaffold-06-shadcn.md) | Fase 6 — shadcn/ui e tokens de design |
| [`scaffold-07-workos-authkit`](scaffold-07-workos-authkit.md) | Fase 7 — autenticação com WorkOS AuthKit |
| [`scaffold-08-scripts`](scaffold-08-scripts.md) | Fase 8 — scripts de package e tarefas do projeto |
| [`scaffold-09-feature-exemplo`](scaffold-09-feature-exemplo.md) | Fase 9 — feature de exemplo ponta a ponta |
| [`scaffold-10-verificacao`](scaffold-10-verificacao.md) | Fase 10 — verificação final do scaffold |

## Variante FBA

Cinco fases com o mesmo recorte, mais detalhadas e com o teste de fronteira de
[Feature-Based Architecture](../knowledge-base/feature-based-architecture.md)
escrito por extenso:

| Fase | O que faz |
| --- | --- |
| [`scaffold-fba-01-start`](scaffold-fba-01-start.md) | Variante FBA — fase 1, base do projeto |
| [`scaffold-fba-02-biome`](scaffold-fba-02-biome.md) | Variante FBA — fase 2, Biome |
| [`scaffold-fba-03-bun-test`](scaffold-fba-03-bun-test.md) | Variante FBA — fase 3, `bun test` e Testing Library |
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

## Bun, desde 2026-09-22

O gerenciador e o runner são **Bun**, não pnpm. O que a migração fixou, por regra:

| Regra | O que entrou |
| --- | --- |
| `BUN-CORE-06` | script do `package.json` é chamado na forma longa `bun run <script>` |
| `BUN-CORE-02` | `typecheck: tsc --noEmit` nos scripts, e `bunx tsc --noEmit` no portão da fase 10 — o runtime transpila **sem** checar tipo |
| `BUN-PKG-01/02` | o checklist final cobra `bun.lock` commitado, e `bun ci` no CI |

Equivalências usadas: `pnpm add -D` → `bun add -d` · `pnpm dlx`/`pnpm exec`/`npx` → `bunx`
· `node -e` → `bun -e` com `Bun.file`/`Bun.write` · `pnpm-lock.yaml` → `bun.lock`.

**As fases 3 rodam em `bun test`**, não em Vitest — `scaffold-03-bun-test` e
`scaffold-fba-03-bun-test`. O `vitest.config.ts` sumiu junto: `bun test` lê
`compilerOptions.paths` do `tsconfig.json` (verificado no bun 1.3.14), e o mapa de alias
duplicado — cuja divergência com o `tsconfig` era o modo de falha documentado da fase —
deixou de existir. O que se perde é o `test:ui`, que o `bun test` não tem.

`bunx @tanstack/create-start@latest` em vez de `bun create @tanstack/start@latest`: o
`bun create <t>` roda `bunx create-<t>`, e essa regra não resolve pacote com escopo. O
pacote real é [`@tanstack/create-start`](https://www.npmjs.com/package/@tanstack/create-start).

**Um passo desapareceu.** A fase `scaffold-fba-02-biome` carregava um laço com `node -e`
para conferir se cada pacote era dependência antes de removê-lo — contorno de `pnpm`, que
sai com 1 em nome ausente. `bun remove` aceita vários nomes, remove o que existe e sai 0
(verificado no bun 1.3.14), então o laço virou uma linha.

## O que está declarado, e não conferido

Estes 17 arquivos vieram do build anterior **sem revisão de conteúdo**. O que a migração
para Bun encostou, e não resolveu:

- **`vinxi` nos scripts `dev`/`build`/`start`.** É o driver antigo do TanStack Start; as
  versões atuais rodam sobre Vite direto.
- **`biome.json` com `$schema` da 1.9.4**, e no formato da v1 (`organizeImports` na raiz).
  O `bun add -d @biomejs/biome` instala hoje a **2.5.14**, onde essa chave mudou de lugar.
  E o valor do `$schema` está escrito como link markdown, não como URL.
- `scaffold-01…10` e `scaffold-fba-01…05` cobrem o mesmo terreno com detalhe diferente,
  e nada declara qual dos dois é o caminho corrente.
