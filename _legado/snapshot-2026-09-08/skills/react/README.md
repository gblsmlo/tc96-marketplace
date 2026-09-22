# Skills de React — família agrupada

Quatro skills, um diretório cada, com `references/` e `scripts/` próprios. É o primeiro
grupo do vault organizado como **pacote** e não como arquivo solto: a anatomia comum
descrita em [[Skills/README|Skill — Índice]] continua valendo, e o que muda é só que o
material de apoio ganhou arquivo próprio em vez de inchar o `SKILL.md`.

| Skill | A pergunta que ela responde | Fonte | Apoio interno |
| --- | --- | --- | --- |
| [[react-developer]] | escrever componente, Hook ou feature **nova** | [[React - Patterns]] | 4 referências + 3 exemplos + 1 script |
| [[react-review]] | este código que **já existe** está correto? | [[React - Rules of React]] | 4 referências + 1 relatório + 2 scripts |
| [[react-structure]] | **onde** o arquivo mora, quem importa quem | [[Feature-Based Architecture]] | 3 referências + 1 relatório + 2 scripts |
| [[react-hook-form]] | formulário: captura, validação, submissão | [[React Hook Form]] | 4 referências + 1 exemplo + 2 scripts |

Dois eixos separam as quatro. Entre `react-developer` e `react-review`, **novo × já
existe** — e está nas primeiras palavras de cada `description`. Entre elas e as outras
duas, **interior × fronteira**: `react-structure` cuida de onde o código mora e de quem
pode importar quem; `react-hook-form` cuida de uma capacidade inteira (captura de
formulário) que tem família de regras própria, `RHF-*`.

**Num PR, a ordem é `react-structure` → `react-review`.** Mover um arquivo pode apagar o
achado de interior, então revisar o interior primeiro é trabalho jogado fora.

## O que cada pacote contém

```
react-developer/
├── SKILL.md
└── references/
    ├── arvores-de-decisao.md          qual árvore percorrer, 4 erros de percurso, saídas curtas
    ├── habitos-de-ia.md               7 seções de reflexos que produzem violação, com ID
    ├── autoverificacao.md             3 passadas + 10 sondas rg antes de entregar
    ├── mapa-de-ids.md                 gerado: ID → satélite → seção
    ├── exemplo-painel-de-faturas.md   caminho feliz
│   ├── exemplo-fronteira-de-servidor.md   variante robusta: Server Function, validação, boundaries
│   └── exemplo-antipadrao-corrigido.md    antes e depois, defeito por ID
└── scripts/
    └── autoverificar.sh               roda as 10 sondas do Passo 5 sobre o código recém-escrito

react-review/
├── SKILL.md
├── references/
│   ├── sondas.md                      15 sondas, falsos positivos, e o que elas não pegam
│   ├── grade-de-varredura.md          5 níveis na ordem que falha mais, com ID por antipadrão
│   ├── severidade-e-relatorio.md      classificação, formato de achado, o corte achado × opinião
│   ├── mapa-de-ids.md                 gerado: ID → satélite → seção
│   └── exemplo-relatorio-de-pr.md     relatório inteiro, das sondas ao fechamento
└── scripts/
    ├── sondas.sh                      roda as 15 sondas e imprime o ID a citar
    └── gerar-mapa-de-ids.sh           regenera mapa-de-ids.md de developer e review

react-structure/
├── SKILL.md
├── references/
│   ├── arvore-de-colocacao.md         5 perguntas, a árvore, importar × duplicar × extrair
│   ├── varredura-de-imports.md        ordem da varredura, o que a sonda não pega, formato
│   ├── mapa-de-ids.md                 gerado: ID → severidade → quem faz valer → seção
│   └── exemplo-revisao-de-estrutura.md   revisão de PR inteira
└── scripts/
    ├── sondas-imports.sh              8 sondas de fronteira, começando por enforcement
    └── gerar-mapa-de-ids.sh           regenera a partir de Pages/Feature-Based Architecture.md

react-hook-form/
├── SKILL.md
├── references/
│   ├── tarefas.md                     as 5 tarefas, ordem das decisões, o que verificar
│   ├── dono-da-submissao.md           isSubmitting × isPending — escolher um e declarar
│   ├── diagnostico.md                 sintoma → causa provável → satélite
│   ├── mapa-de-ids.md                 gerado: 81 IDs RHF-* + regra de citação entre docs
│   └── exemplo-lancamento-de-fatura.md   do Passo 0 ao submit
└── scripts/
    ├── sondas.sh                      12 sondas de formulário existente
    └── gerar-mapa-de-ids.sh           regenera a partir de Docs/React Hook Form*
```

**`mapa-de-ids.md` é gerado, não escrito** — nas quatro. Ele indexa os IDs por satélite e
seção, e nunca carrega o **texto** da regra: cópia de regra dentro de skill vira réplica
desatualizada. Três geradores, um por família, porque as fontes e as colunas diferem:

| Gerador | Família | Fonte | Colunas |
| --- | --- | --- | --- |
| `react-review/scripts/gerar-mapa-de-ids.sh` | 105 `REACT-*` | `Docs/React*` | satélite · seção · apelidos |
| `react-structure/scripts/gerar-mapa-de-ids.sh` | 12 `REACT-ARCH-*` | `Pages/Feature-Based Architecture.md` | **severidade** · **quem faz valer** · seção |
| `react-hook-form/scripts/gerar-mapa-de-ids.sh` | 81 `RHF-*` | `Docs/React Hook Form*` | satélite · seção · citação entre docs |

Depois de editar qualquer nota-fonte, rode o gerador correspondente e reinstale:

```bash
bash Skills/react/react-review/scripts/gerar-mapa-de-ids.sh
bash Skills/react/react-structure/scripts/gerar-mapa-de-ids.sh
bash Skills/react/react-hook-form/scripts/gerar-mapa-de-ids.sh
bash Skills/react/instalar.sh
```

A coluna **quem faz valer** só existe em `REACT-ARCH-*`, e é a mais acionável do grupo:
ela separa o que o Biome pega do que depende de revisão humana — e é o que decide se um
achado volta no PR seguinte.

## As vizinhas — o que **não** é destas duas

Um PR de frontend quase nunca é só React. Quando o assunto for de outra camada, o
procedimento e os IDs pertencem à skill daquela camada:

| Camada | Skill | Doc-fonte |
| --- | --- | --- |
| dado remoto, cache, invalidação, otimismo | [[tanstack-query]] | [[TanStack Query]] |
| rota, navegação, search params, loader | [[tanstack-router]] | [[TanStack Router]] |
| componente confirmado lento, fix medido | `react-component-performance` (pack externo) | — |
| configurar Storybook, escrever story | [[storybook-setup]] · [[storybook-story]] | [[Storybook]] |
| teste de interação na story, runner **Vitest** | [[storybook-test]] | [[Storybook - Testes e Interações]] § 4 |
| **nível** do teste: unidade × integração × e2e | [[teste-design]] | [[Teste de Software - Níveis e Escopo]] |
| a suíte como sistema: protege? é confiável? | [[teste-review]] · [[teste-diagnose]] | [[Teste de Software]] |
| **unidade e integração** em `bun test` | [[bun-test-build]] · [[bun-test-review]] | [[Bun - Testes]] |
| **e2e** | [[playwright-build]] · [[playwright-review]] · [[playwright-diagnose]] | [[Playwright]] |
| rota, schema e lifecycle de API | [[elysia-build]] · [[elysia-schema]] · [[elysia-diagnose]] | [[Elysia]] |
| persistência: schema, migração, query | [[drizzle-review]] | [[Drizzle ORM]] |
| contrato HTTP: método, status, cache, CORS | [[http-contract]] · [[http-cache]] · [[http-diagnose]] · [[http-review]] | [[HTTP]] |
| runtime, dependências, migração de Node | [[bun-runtime]] · [[bun-workspace]] · [[bun-migrate]] | [[Bun]] |

Duas fronteiras que costumam ser cruzadas na direção errada:

- **Teste: conceito antes de ferramenta.** *Em que nível* é [[teste-design]]; *como escrever*
  é a skill da ferramenta. Pular a primeira produz E2E por default.
- **Vitest não é skill deste vault.** Aparece como runner do `@storybook/addon-vitest`,
  rodando story em browser real via Playwright ([[Storybook - Testes e Interações]] § 4;
  o corte entre Vitest 3 e 4 na § 4.2). Unidade fora do Storybook é `bun test`.

## Validação

As quatro passam em `skill-validator check` com **0 erros**. Restam dois avisos por skill,
`unrecognized field: "tags"` e `unrecognized field: "fonte"` — são convenção deste vault
(a anatomia comum exige `fonte:` no frontmatter para a atualização da doc propagar) e
ficam por decisão, não por descuido.

```bash
for s in Skills/react/*/; do skill-validator check "$s"; done
```

<!-- tokens:inicio -->
## Orçamento de contexto

Medido por `skill-validator` (tiktoken), em 2026-09-05. **O número que importa é o da
coluna `SKILL.md`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

| Skill | `SKILL.md` | maior `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| [[react-developer]] | 2.804 | `mapa-de-ids.md` (3.539) | 14.791 | 7 |
| [[react-hook-form]] | 2.223 | `mapa-de-ids.md` (3.424) | 10.308 | 5 |
| [[react-review]] | 2.531 | `mapa-de-ids.md` (3.539) | 12.304 | 5 |
| [[react-structure]] | 2.775 | `exemplo-revisao-de-estrutura.md` (1.210) | 6.534 | 4 |

Carregar as 4 skills deste grupo de uma vez custaria **10.333 tokens** só de `SKILL.md`,
e **43.937** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.

Regenerar: `bash Skills/tokens.sh`
<!-- tokens:fim -->

## Relacionados

- [[Skills/README|Skill — Índice]] — o índice geral e a anatomia comum
- [[React.js]] § 7 — o contrato que as duas implementam
