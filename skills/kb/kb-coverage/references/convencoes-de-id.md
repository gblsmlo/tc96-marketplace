# ID conventions, by family

A hit from `buscar-tema.sh` is worth more when a citable ID sits near it. This table says what
a real ID looks like in each family, so a plausible-looking string can be told apart from
prose that merely uses capital letters and hyphens.

| Família | Prefixo(s) | Onde a regra vive |
| --- | --- | --- |
| react (padrões de componente) | `REACT-PAT-*` | `docs/react-patterns.md` |
| react (estrutura/fronteiras) | `REACT-ARCH-*` | `pages/feature-based-architecture.md` |
| react (Server Components/Actions) | `REACT-RSC-*` | `docs/react-server-components-e-diretivas.md` |
| react (Hooks) | `REACT-HOOK-*` | `docs/react-hooks.md` |
| react (pureza) | `REACT-PURE-*` | `docs/react-rules-of-react.md`, `docs/react-renderizacao-e-entrypoints.md` |
| react (performance) | `REACT-PERF-*` | `docs/react-performance-e-concorrencia.md` |
| react (formulários) | `RHF-*` | `docs/react-hook-form*.md` (três satélites) |
| tanstack (query) | `TSQ-*` | `docs/tanstack-query*.md` |
| tanstack (router) | `TSR-*` | `docs/tanstack-router*.md` |
| http | `HTTP-*`, `HTTP-CACHE-*`, `HTTP-CORS-*`, `HTTP-NEG-*` | `docs/http*.md` (um satélite por sufixo) |
| elysia | `ELYSIA-CORE-*`, `ELYSIA-APP-*`, `ELYSIA-TYPE-*`, `ELYSIA-LIFE-*` | `docs/elysia*.md` |
| drizzle | `DRZ-*` | `docs/drizzle-orm.md` + satélites de schema/queries |
| bun | `BUN-RT-*`, `BUN-SYS-*`, `BUN-PKG-*`, `BUN-CORE-*`, `BUN-TEST-*` | `docs/bun*.md` |
| test (estratégia) | `TS-*` | `docs/teste-de-software*.md` |
| playwright | `PW-*` | `docs/playwright*.md` |
| storybook | `SB-CFG-*`, `SB-CORE-*`, `SB-CSF-*`, `SB-CTX-*`, `SB-TEST-*`, `SB-MOCK-*` | `docs/storybook*.md` |
| workflow (quatro pilares) | `WF-CORE-*`, `WF-RES-*`, `WF-PLAN-*`, `WF-IMPL-*`, `WF-VAL-*` | `docs/fluxo-de-entrega-quatro-pilares.md` |
| páginas normativas (não-`docs/`) | `REACT-ARCH-*`, `BFF-*`, `MONO-*` | `pages/feature-based-architecture.md`, `pages/fronteira-do-bff-forma-jornada-e-regra.md`, `pages/monorepo-com-bun-estrutura-e-tooling.md` — `architecture-in-react.md` § 5 explains why these three pages carry IDs when the rest of `pages/` does not |

## What is not an ID

- A capitalized term in backticks that is not one of the prefixes above (`useState`,
  `queryOptions`) — an API name, not a rule.
- A heading anchor (`## 7. Fluxo de dados`) — a section title, not a citable rule.
- A prose reference to another vault's convention (e.g. a Biome rule name like
  `noImportCycles`) — real, but it is the **enforcement mechanism** for an ID, not the ID
  itself; cite the ID it enforces (`references/mapa-de-ids.md` of the owning skill has the
  mapping, e.g. `noImportCycles` → `REACT-ARCH-04`, `REACT-ARCH-10`).

## Regenerating vs. this file

Each family skill already generates its own exhaustive `references/mapa-de-ids.md` from its
source doc (see e.g. `skills/react/react-structure/scripts/gerar-mapa-de-ids.sh`). This file
is not a copy of those — it is the one-line-per-family index that tells you *which* prefix to
expect before you go looking, so a `buscar-tema.sh` hit near `REACT-PAT-04` is instantly
recognizable as a react-patterns rule, without opening that skill's own map first.
