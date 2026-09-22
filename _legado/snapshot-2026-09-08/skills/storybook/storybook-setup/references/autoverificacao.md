# Autoverificação, e a armadilha de augmentation de tipo

**Só caminho `tanstack-react`.** Sob `react-vite` esta seção é inerte.

O TanStack Router pede `declare module '@tanstack/react-router'` para registrar o tipo do router. Se essa augmentation mora no `main.tsx` do app — o arquivo que monta o DOM — ela **não alcança o programa TS do Storybook**, porque `main.tsx` não pode entrar nesse programa.

**O conserto:** separar a augmentation num módulo próprio (`router.ts`), exportá-lo, e importar **de tipo** onde precisar.

**O sintoma, que não aponta a causa:** os tipos do router caem para o genérico dentro das stories, e `params` deixa de ser checado contra o path — o que faz `SB-TS-02` passar a não pegar nada. Verificado por sabotagem em [[Monorepo com Bun - estrutura e tooling]] § 5.7.

---

## Passo 7 — Autoverificação antes de entregar

| # | Confira | Regra |
| --- | --- | --- |
| 1 | `framework` declarado em `main.ts`, e a escolha registrada | `SB-CFG-01` |
| 2 | os pisos de versão do framework escolhido são cumpridos | Passo 1 |
| 3 | Node ≥ 20.19 / 22.12 — e ≥ 22 se houver Playwright | `SB-CORE-04` |
| 4 | `main.ts` é ESM válido, sem `require` | `SB-CORE-03` |
| 5 | todo `@storybook/*` na mesma versão de `storybook` | `SB-CFG-04` |
| 6 | globs de `stories` relativos a `.storybook/` | `SB-CFG-02` |
| 7 | **a sidebar tem as stories esperadas** | `SB-CFG-02` |
| 8 | alias/plugin/`define` declarados uma vez e herdados | `SB-CFG-06` |
| 9 | `apps/storybook` é folha — nenhum pacote depende dele | `SB-CFG-07` |
| 10 | CSS editável importado em `preview.tsx` | `SB-CFG-03` |
| 11 | `staticDirs` cobre o service worker, se houver MSW | `SB-CFG-05` |
| 12 | augmentation de tipo em módulo próprio (só TanStack) | Passo 6 |
| 13 | nenhum `SB-TS-*` prescrito sob `react-vite`, e vice-versa | § 6.2 do hub |

**Rode:** subir o Storybook, abrir uma story de cada pacote coberto, e conferir que o alias resolve e o CSS aplica. Só então o Passo 3.7.

---

