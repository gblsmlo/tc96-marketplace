<div align="center">

# tc96-marketplace
Agents, skills and rules for this house's stack, written once as a neutral source and built for each agent runtime

![Version](https://img.shields.io/badge/version-0.9.0-0EA5E9?style=flat&labelColor=18181B)
![Claude Code](https://img.shields.io/badge/Claude_Code-plugins-D97757?style=flat&logo=claude&logoColor=white&labelColor=18181B)
![AGENTS.md](https://img.shields.io/badge/AGENTS.md-target-FFFFFF?style=flat&labelColor=18181B)
![Context7](https://img.shields.io/badge/Context7-API_surface-0EA5E9?style=flat&labelColor=18181B)
![License](https://img.shields.io/github/license/gblsmlo/tc96-marketplace?style=flat&colorA=18181B&colorB=0EA5E9)

</div>

> **Status:** 0.9.0. Families still in the old frontmatter format are skipped by the build until they migrate.

## ✨ Overview

- **Source, not an installation**: nothing here is specific to an agent runtime. Claude Code is one build target; leaving it costs a new adapter, not a content rewrite
- **Three layers**: an agent says *who* does the work, a skill says *how*, the knowledge base says *what* is correct
- **Cited by ID, never copied**: a layer cites the one below it (`REACT-*`, `TSQ-*`, `RHF-*`, `SB-*`, `TW-*`, `HTTP-*`, `BUN-*`, `ELYSIA-*`, `DRZ-*`, `PW-*`, `TS-*`, `WF-*`). A copied rule becomes a stale replica the next day
- **API surface from Context7**: a skill declares a library ID; the runtime resolves the signature for the installed version
- **Self-contained**: every link is relative markdown and resolves inside the repository. `bash build/verificar.sh` fails on any link that points outside
- **Sliced plugins**: enable only the stack a project has: core, frontend, backend, Tailwind, E2E. `tc96-tailwind` is self-contained — it carries its own docs and works without any other tc96 plugin

## Installation

```
/plugin marketplace add gblsmlo/tc96-marketplace
/plugin install tc96-core@tc96-marketplace
```

**Quick Start:** to enable it for a whole project, Claude Code on the web included, commit this to the project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "tc96-marketplace": { "source": { "source": "github", "repo": "gblsmlo/tc96-marketplace" } }
  },
  "enabledPlugins": { "tc96-core@tc96-marketplace": true, "tc96-frontend@tc96-marketplace": true, "tc96-tailwind@tc96-marketplace": true }
}
```

### How it works

| Layer | Where | Answers | Owns the divergence |
| --- | --- | --- | --- |
| **role** | [`agents/`](agents/) | *who* does the work, with what context, and what they deliver | — |
| **procedure** | [`skills/`](skills/README.md) | *how* to do it, in what order, and how to report it | diverges from the agent → agent bug |
| **rule** | [`knowledge-base/`](knowledge-base/MANIFESTO.md) | *what* is correct, by ID | diverges from the skill → skill bug |

- **Commands:** [`commands/`](commands/README.md) is a fourth artifact type, not a fourth layer. A command is an entry point a person invokes directly (`/scaffold-projeto`) and it routes into the same skills and rules
- **API surface:** how an API behaves *in this version* comes from [Context7](https://context7.com/), through the library ID in a skill's `docs:`. What is *correct*, and which ID a review cites, comes from `knowledge-base/`. The registry is [`build/context7.json`](build/context7.json)
- **No upstream library:** a skill that declares no `docs:` has none. Testing is a concept and HTTP is a set of RFCs, so the absence is information, not a gap
- **Both sources:** when a note exists and the library is on Context7, the rule ID comes from the note and only the signature from Context7, as with Hono and `HONO-*`

### Requirements

- Claude Code with plugin marketplaces, or any runtime that reads `AGENTS.md`
- Context7 available in the runtime, for skills that declare `docs:`
- Bash and Python 3 to run the build. Bun is not required

## Plugins

| Plugin | Contents | Enable |
| --- | --- | --- |
| `tc96-core` | HTTP contract and cache, test design and suite audit, the four-pillar delivery workflow, 10 cross-stack agents, the scaffold commands | always |
| `tc96-frontend` | React, TanStack Router and Query, React Hook Form and Storybook skills, plus `frontend-developer`. The React family carries its own normative docs (`REACT-*`, `RHF-*`) in `skills/react/docs/`, and each of its five skills also packages alone | projects with a frontend |
| `tc96-tailwind` | Tailwind CSS v4: setup, build and review skills, with their own normative docs (`TW-*`) in `skills/tailwind/docs/`. **Self-contained**: no tc96 knowledge-base note is needed | projects with Tailwind, with or without the rest of tc96 |
| `tc96-backend` | Bun runtime and tests, Elysia and Drizzle skills, plus `backend-developer` | projects with a backend |
| `tc96-e2e` | Playwright: writing, review and diagnosis of E2E tests | projects with an E2E suite |

The `kb` family (`kb-coverage`) audits this repository's own coverage and is not shipped in any plugin.

## Updating

The marketplace resolves straight from GitHub, so a consumer only needs:

```
/plugin marketplace update tc96-marketplace
```

After changing skills, agents, commands or the knowledge base, rebuild and commit `dist/claude-code/` and `.claude-plugin/`:

```bash
bash build/claude-code.sh
```

Every build wipes `dist/claude-code/` before rewriting it. `dist/agents-md/` stays ignored.

## Development

```bash
# Regenerate the knowledge-base index (knowledge-base/MANIFESTO.md)
bash build/indexar.sh

# Dry run: fails if the index is stale
bash build/indexar.sh --verificar

# Check library IDs against the Context7 catalog
bash build/context7.sh --verificar

# Broken links, vault syntax, frontmatter
bash build/verificar.sh

# Build the targets
bash build/claude-code.sh              # -> dist/claude-code/plugins/<plugin>/
bash build/agents-md.sh                # -> dist/agents-md/
```

### Neutral frontmatter

Frontmatter declares **capability**, never a runtime's tool name. Each adapter translates it:

| Neutral source | Claude Code | AGENTS.md |
| --- | --- | --- |
| `nome:` | `name:` | file's H1 |
| `descricao:` | `description:` | **When to use** blockquote |
| `capacidades: [ler, buscar, executar]` | `tools: Read, Grep, Glob, Bash` | — |
| `modelo: alto \| medio \| rapido` | `model: opus \| sonnet \| haiku` | — |
| `tipo: skill \| agente \| comando` | dropped, the layout separates them | dropped |
| `docs: [/websites/tanstack_query]` | `docs:`, resolved through Context7 | **API surface** table |
| `familia:` | dropped, flattened layout | subdirectory |

Adapters process **only** entries with a neutral `tipo:`. A family still in the old format is skipped silently, which lets a migration happen one family at a time.

Links are relative markdown, never wikilinks, so the source is navigable outside Obsidian and each adapter rewrites the nesting its layout needs.

### Generated files

ID maps are generated by a script inside the skill: `mapa-de-ids.md` by `scripts/gerar-mapa-de-ids.sh` from the knowledge base, or `id-map.md` by `scripts/generate-id-map.sh` in the test, react and tailwind families (react and tailwind read their own `docs/`). Don't edit them by hand. Running the generator reproduces what is versioned byte for byte, timestamp aside.

## Project Structure

```text
agents/                # 12 roles (English)
skills/                # 38 skills across 12 families (English)
├── workflow/          # Research, planning, implementation, validation
├── test/              # Test level, suite audit, flakiness diagnosis
├── http/  tanstack/  storybook/  playwright/
├── react/             # self-contained: its own docs/ (the REACT-* and RHF-* rules) travel with it
├── tailwind/          # self-contained: its own docs/ (the TW-* rules) travel with it
├── bun/  elysia/  drizzle/
└── kb/                # Coverage audit of this repository, not shipped
commands/              # 18 commands (English body, descricao in Portuguese)
knowledge-base/        # 131 notes, no subfolders (Portuguese: the rule, and its ID)
build/                 # Adapters, index, standalone .skill packager, link and frontmatter checks
dist/claude-code/      # Built plugins, committed
.claude-plugin/        # marketplace.json
```

The knowledge base is this project's own content. Each note has a `titulo:` in its frontmatter, the label skills use when they link to it.

> **Two families carry their own docs.** `skills/tailwind/docs/` holds the Tailwind CSS notes and `skills/react/docs/` the React, React Hook Form and Feature-Based Architecture notes (all in English). The build copies them to `docs/<family>/` in the plugin, and they cite tc96 notes only by name in a code span, never by link. `bash build/skill-packages.sh` also emits one standalone `dist/skills/<skill>.skill` per skill of these families, with its docs closure inside; `build/verificar.sh` opens each one in isolation.

> **Zettels are out of scope.** The reasoning layer is not extracted, and citations to it are removed. The chain is role → procedure → rule. Course-fundamentals maps are excluded for the same reason: the product and management agents cite them **by name, in a code span**, and say they have no rule ID.

## Contributing

1. Check existing [issues](https://github.com/gblsmlo/tc96-marketplace/issues) or create a new one
2. Create a feature branch
3. Run `bash build/verificar.sh` and `bash build/indexar.sh --verificar`, then `bash build/claude-code.sh`
4. Submit a Pull Request with a clear description, committing `dist/claude-code/` alongside the source

## License

MIT License - see [LICENSE](./LICENSE) for details.
