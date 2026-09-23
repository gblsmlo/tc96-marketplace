---
gerado-por: manual audit, 2026-09-23
verificado-em: 2026-09-23
---

# Seed index, by family

**Seed, not exhaustive.** These rows were opened and verified against the files on disk on
2026-09-23, during the audit that filled in `frontend-roadmap.md`'s "Revisão por tema" table.
Anything not listed here is not "unknown" or "gap" — it just has not been checked yet. Run
Step 2 (`scripts/buscar-tema.sh`) for it.

Before reusing a row, re-open the cited section. A stale seed entry reads exactly as
confident as a fresh one — the only way to catch drift is to check.

## React / frontend (the 17 themes of `frontend-roadmap.md`)

| Tema | Status | Nota de entrada | Skill(s) |
| --- | --- | --- | --- |
| Arquitetura e responsabilidades | Coberto | `pages/architecture-in-react.md` | (router — no single skill) |
| Estrutura de pastas e fronteiras | Coberto | `pages/feature-based-architecture.md` | `react-structure` |
| Coesão por capacidade | Coberto | `pages/feature-based-architecture.md` § 1 | `react-structure` |
| Contratos full-stack | Coberto | `docs/elysia-schema-e-eden.md` § 7 | `elysia-schema` |
| Composition | Coberto | `docs/react-patterns.md` § 3 (`REACT-PAT-04/05`) | `react-developer` |
| Clean Code | **Gap confirmado** (dangling ref.) | — | none — `agents/code-reviewer.md` and `agents/frontend-developer.md` cite a hub that does not exist in `knowledge-base/` |
| Testes | Coberto | `docs/teste-de-software.md` | `test-design`, `test-review`, `test-diagnose`, plus `bun-test-*`/`playwright-*` |
| Data flow | Coberto (thin) | `docs/react-patterns.md` § 7 | `react-developer` |
| Zod | Coberto | `docs/elysia-schema-e-eden.md` § 2 (boundary) + `docs/react-hook-form-validacao-e-resolvers.md` (forms) | `elysia-schema`, `react-hook-form` |
| React Hook Form | Coberto | `docs/react-hook-form.md` | `react-hook-form` |
| Hooks | Coberto | `docs/react-hooks.md` | `react-developer`, `react-review` |
| Persistência (browser) | **Parcial** | `docs/react-patterns.md` § 2, one unlinked row, no `REACT-PAT-*` ID | none |
| Cache | Coberto (layered, not fragmented — see `mentioned-vs-developed.md`) | `docs/tanstack-query-cache-e-frescor.md` + `docs/http-cache-e-requisicoes-condicionais.md` | `tanstack-query`, `http-cache` |
| TanStack Query | Coberto | `docs/tanstack-query.md` | `tanstack-query` |
| Optimistic update | Coberto | `docs/tanstack-query-mutations-e-invalidacao.md` | `tanstack-query` |
| Server Actions | Coberto | `docs/react-server-components-e-diretivas.md` (`REACT-RSC-06`) | `react-developer`, `react-review`, `react-hook-form` |
| Error handling | Coberto (fragmented across 3 layers) | `docs/react-patterns.md` § 6 + `docs/react-hook-form-validacao-e-resolvers.md` + `elysia-build`'s error taxonomy | `react-developer`, `react-hook-form`, `elysia-build` |

Also noted, not itself a row of the table: `pages/architecture-in-react.md` § 2 has several
more router cells left blank even though the content exists elsewhere (e.g. "Direção do
dado", "Agrupar por domínio, não por tipo") — that page is behind its own content and is worth
a separate pass, not folded into this index.

## Other families — hub doc as the default anchor

Not yet audited topic-by-topic; these are the entry point a live search should treat as
"home base" for that family, per `skills/README.md`.

| Família | Hub doc | Skills |
| --- | --- | --- |
| tanstack (router) | `docs/tanstack-router.md` | `tanstack-router` |
| http | `docs/http.md` | `http-contract`, `http-cache`, `http-diagnose`, `http-review` |
| elysia | `docs/elysia.md` | `elysia-build`, `elysia-schema`, `elysia-diagnose` |
| drizzle | `docs/drizzle-orm.md` | `drizzle-review` (no build skill yet — the skill's own description says so) |
| bun | `docs/bun.md` | `bun-runtime`, `bun-workspace`, `bun-migrate`, `bun-test-build`, `bun-test-review` |
| test | `docs/teste-de-software.md` | `test-design`, `test-review`, `test-diagnose` |
| playwright | `docs/playwright.md` | `playwright-build`, `playwright-review`, `playwright-diagnose` |
| storybook | `docs/storybook.md` | `storybook-setup`, `storybook-story`, `storybook-test` |

## Known structural gaps (not topic-specific)

- **Drizzle has review coverage but no build skill.** `skills/drizzle/drizzle-review/SKILL.md`
  says so directly: "Do not use to write a new schema or query — follow the decision trees in
  Drizzle ORM § 5 directly, because there is no build skill yet." Any topic that needs
  *writing* a schema/query (not just reviewing one) inherits this gap.
- **`architecture-in-react.md` § 2 is a router with several blank cells** despite the
  underlying content existing (see above). Treat a blank cell there as "not yet routed", not
  as "not documented" — check the doc layer before concluding gap.
