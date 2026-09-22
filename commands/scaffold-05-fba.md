---
nome: scaffold-05-fba
descricao: Fase 5 — estrutura de diretórios Feature-Based Architecture
tipo: comando
idioma: en
---
# Role
You are a Senior Frontend Architect and DevOps Engineer specialized in modular software design, Scalable Project Foundations, and automated linting governance.

# Objective
Create a framework-agnostic, Feature-Based Architecture (FBA) foundation. The goal is to provide a highly maintainable directory structure, a robust TypeScript configuration, and a Biome/Linting setup to prevent Barrel File issues (Circular Dependencies and Self-Imports).

# Context & Constraints
- **Architecture:** Feature-Based Architecture (FBA).
- **Naming Convention:** Strict **kebab-case** for ALL files and directories.
- **Path Aliases:** Every top-level folder under `src/` must have a `@` alias.
- **Public API Pattern (Barrels):** Every directory must use an `index.ts` to export its public API.
- **Tooling:** Use **Biome** for linting and formatting.

# 1. Directory Structure Execution
Generate a `mkdir -p` and `touch` command block that creates:
- `src/features/auth-module/{api,components,hooks,stores,types,utils,index.ts}`
- `src/features/account-settings/{api,components,hooks,types,utils,index.ts}`
- `src/components/{ui,layout,index.ts}`
- `src/hooks/index.ts`, `src/libs/index.ts`, `src/types/index.ts`, `src/assets/`

# 2. TypeScript Configuration (Path Aliases)
Provide a `compilerOptions` snippet for `tsconfig.json` including:
- `"baseUrl": "."`
- Paths for: `@features/*`, `@components/*`, `@hooks/*`, `@libs/*`, `@types/*`, `@assets/*`.

# 3. Biome Governance (Anti-Cycle & Linting)
Provide a `biome.json` configuration snippet that focuses on:
- **noSelfImport:** To prevent a file from importing from its own index/barrel.
- **noRelativeImports:** (Optional/Discussion) To enforce alias usage for external modules.
- **noUnusedImports:** To keep barrels clean.
- **Organize Imports:** To ensure consistent import ordering.
*Note: Since Biome's `no-cycle` is under development/refined via `no-restricted-imports`, provide a way to block internal barrel imports.*

# 4. Architecture & Anti-Cycle Rules
Document:
1. **The Internal Import Rule:** Internal feature files MUST use relative paths (e.g., `../hooks/use-auth`). NEVER import from the feature's own alias or `index.ts`.
2. **The Barrel Role:** `index.ts` must only contain `export` statements. No logic or side effects.
3. **Type-Only Exports:** Use `export type { ... }` to assist tree-shaking and prevent runtime cycles.

# 5. Implementation Blueprint
Show a concrete code example:
- `src/features/auth-module/components/login-form.tsx` (using relative internal imports).
- `src/features/auth-module/index.ts` (the barrel export).
- `src/main.tsx` (the consumer using `@features/auth-module`).

# Output Format
1. **Infrastructure Script**: Shell command block.
2. **Type System**: `tsconfig.json` paths.
3. **Linting Config**: `biome.json` snippet.
4. **Architecture Manifesto**: Core rules for the team.
5. **Code Proof**: The multi-file "Anti-Cycle" pattern.

# Chain of Thought
- Ensure all directory names are kebab-case.
- Verify the Biome configuration specifically addresses import hygiene.
- Ensure the code example demonstrates the prevention of self-imports.