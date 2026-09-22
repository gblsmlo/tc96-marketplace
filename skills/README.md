# Skills — índice

Skills são **procedimentos**: dizem o que carregar, em que ordem, qual passo seguir e como
reportar. Elas **não** repetem o texto da regra — roteiam para `knowledge-base/` e citam
por ID. Cada skill declara sua nota-fonte no frontmatter (`fonte:`), para que uma
atualização da regra propague sem reescrever a skill.

Cada skill é um **pacote**: um diretório com `SKILL.md`, `references/` e, quase sempre,
`scripts/`. O que entra no contexto antes de a skill decidir o que abrir é só o `SKILL.md`.

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

## Ainda no formato antigo

Estas famílias seguem com o frontmatter do Claude Code (`name:`/`description:`) e wikilinks
`[[...]]` que dependem do vault. Os adaptadores de `build/` **ignoram** o que não tem
`tipo:` neutro, então elas não quebram o build — só não saem nele.

| Família | Skills | Agente que as carrega |
| --- | --- | --- |
| **test** | `teste-design` · `teste-review` · `teste-diagnose` | `qa-engineer` |
| **playwright** | `playwright-build` · `playwright-review` · `playwright-diagnose` | `qa-engineer` |
| **http** | `http-contract` · `http-cache` · `http-diagnose` · `http-review` | `backend-developer` |
| **bun** | `bun-runtime` · `bun-workspace` · `bun-migrate` · `bun-test-build` · `bun-test-review` | `backend-developer` |
| **elysia** | `elysia-build` · `elysia-schema` · `elysia-diagnose` | `backend-developer` |
| **drizzle** | `drizzle-review` | `backend-developer` |

Para migrar uma família, acrescente o domínio dela em `knowledge-base/dominio.txt` e rode
a importação descrita em [`../README.md`](../README.md).
