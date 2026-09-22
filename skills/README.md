# Skills — índice

Skills são **procedimentos**: dizem o que carregar, em que ordem, qual passo seguir e como
reportar. Elas **não** repetem o texto da regra — roteiam para `knowledge-base/` e citam
por ID. Cada skill declara sua nota-fonte no frontmatter (`fonte:`), para que uma
atualização da regra propague sem reescrever a skill.

Cada skill é um **pacote**: um diretório com `SKILL.md`, `references/` e, quase sempre,
`scripts/`. O que entra no contexto antes de a skill decidir o que abrir é só o `SKILL.md`.

Duas fontes, separadas pela pergunta: **superfície de API** (assinatura, opção,
comportamento por versão) vem do Context7, pelo library ID que a skill declara em `docs:`;
**regra e ID de citação** vêm de `knowledge-base/`. Skill sem `docs:` não tem biblioteca
upstream — teste é conceito, HTTP são RFCs.

```
skills/<familia>/
├── README.md          o índice da família e as decisões dela
└── <skill>/
    ├── SKILL.md       frontmatter neutro + o procedimento
    ├── references/    material de apoio, um arquivo por decisão
    └── scripts/       as sondas, e o gerador do mapa de IDs
```

## Migradas para a fonte neutra

| Família | Skills | Índice |
| --- | --- | --- |
| **react** | `react-developer` · `react-review` · `react-structure` · `react-hook-form` | [react/](react/README.md) |
| **tanstack** | `tanstack-query` · `tanstack-router` | [tanstack/](tanstack/README.md) |
| **storybook** | `storybook-setup` · `storybook-story` · `storybook-test` | [storybook/](storybook/README.md) |
| **test** | `test-design` · `test-review` · `test-diagnose` | [test/](test/README.md) |
| **playwright** | `playwright-build` · `playwright-review` · `playwright-diagnose` | [playwright/](playwright/README.md) |
| **bun** | `bun-runtime` · `bun-workspace` · `bun-migrate` · `bun-test-build` · `bun-test-review` | [bun/](bun/README.md) |
| **elysia** | `elysia-build` · `elysia-schema` · `elysia-diagnose` | [elysia/](elysia/README.md) |
| **http** | `http-contract` · `http-cache` · `http-diagnose` · `http-review` | [http/](http/README.md) |
| **drizzle** | `drizzle-review` | [drizzle/](drizzle/README.md) |

## Todas migradas

As 9 famílias estão na fonte neutra. Não há mais família no formato antigo do Claude Code.

O importador (`build/importar-do-plugin.py`) fica como registro de proveniência: ele pula
skill com `idioma: en`, porque o build hermes de origem só tem português.
