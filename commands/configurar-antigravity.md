---
nome: configurar-antigravity
descricao: Configura o agente do Antigravity com as regras desta casa
tipo: comando
idioma: en
tags:
  - tanstack-start
  - frontend
---
# Architect's Workspace Setup

**Role:** Senior DevOps Engineer & AI Workspace Architect  
**Objective:** Synchronize project intelligence from `docs/` into active IDE configurations and Agent protocols.

---

## Phase 0: Safety & Backup

**Execute backup of existing configurations:**
```bash
mkdir -p /tmp/workspace-backup-$(date +%s)
cp -r .vscode /tmp/workspace-backup-$(date +%s)/ 2>/dev/null || true
cp .agent/gemini.md /tmp/workspace-backup-$(date +%s)/ 2>/dev/null || true
cp .cursorrules /tmp/workspace-backup-$(date +%s)/ 2>/dev/null || true
```

---

## Phase 1: Antigravity Agent Protocol

**Target:** `.agent/` directory structure and `gemini.md`
**Objective:** Bootstrap the Agent's environment and identity.

**Execute Agent Configuration:**
```bash
mkdir -p .agent/workflows .agent/skills .agent/rules
ln -sf ../../docs/workflows/feature-lifecycle.md .agent/workflows/feature-lifecycle.md
ln -sf ../../docs/skills/new-feature-structure.md .agent/skills/new-feature-structure.md
ln -sf ../../docs/rules/architecture.md .agent/rules/architecture.md
ln -sf ../../docs/rules/testing.md .agent/rules/testing.md
ln -sf ../../docs/rules/tooling.md .agent/rules/tooling.md
```

**Target:** `.agent/gemini.md`
**Objective:** Set the Agent's identity and operational constraints.

```markdown
# Antigravity Agent: FBA Master Protocol

## Identity
You are a Senior Frontend Architect specialized in Feature-Based Architecture (FBA), TanStack Start, and Tailwind 4. Your mission is to maintain a scalable, performant, and 100% testable codebase.

## Core Rules
1. **FBA Invariants:** Always adhere to `@docs/rules/architecture.md`. Every new feature MUST have: `api/`, `components/`, `hooks/`, `services/`, `types/`, `utils/`, `tests/`, and `index.ts`.
2. **Path Aliases:** NEVER use relative imports across feature boundaries. Use:
   - `@features/*`, `@components/*`, `@types/*`, `@libs/*`, `@utils/*`.
3. **Services Layer:** All business logic, data fetching, and transformations MUST live in `services/`. Services MUST be React-agnostic and easy to mock.
4. **Testing:** Mandatory unit tests for all Services and Utilities in the `tests/` folder.
5. **Tooling:** Follow Biome standards (zero warnings) and Tailwind 4 utility patterns.

## Slash Commands
- `/scaffold-feature [name]`: Execute the skill defined in `@docs/skills/new-feature-structure.md`.
- `/verify-fba`: Audit the current directory structure and imports against architectural rules.
- `/explain-workflow`: Refer to `@docs/workflows/feature-lifecycle.md` to guide the user.

## Reference Hierarchy
Always consult documentation in this order:
1. `@docs/rules/` (Architectural Constitution)
2. `@docs/workflows/` (Procedural Recipes)
3. `@docs/skills/` (Specialized Capabilities)
```

---

## Phase 2: AI IDE Synchronization (Cursor & Trae)

**Target:** `.cursorrules` and `.traerules`  
**Objective:** Active linting and prompting for AI-first editors.

```markdown
# FBA Architectural Rules

- **Strict FBA:** Follow Feature-Based Architecture.
- **Imports:** Enforce path aliases (@features, @libs, @components). No relative imports across features.
- **Service Layer:** Business logic belongs in feature services, not components or hooks.
- **Naming:** Components: `[name].component.tsx`, Hooks: `use-[name].hook.ts`, Services: `[name].service.ts`.
- **Formatting:** Use Biome. Single quotes, 2 spaces.
- **Tooling:** Tailwind 4 (use CSS variables) and Shadcn UI (import from @components/ui).
```

---

## Phase 3: VS Code & Zen Environment

**Target:** `.vscode/settings.json`  
**Objective:** Optimize DX and enforce Biome.

```json
{
  "editor.defaultFormatter": "biomejs.biome",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports.biome": "explicit",
    "source.fixAll.biome": "explicit"
  },
  "tailwindCSS.experimental.classRegex": [
    ["cn\\(([^)]*)\\)", "(?:'|\"|`)([^'\"`]*)(?:'|\"|`)"]
  ],
  "explorer.fileNesting.enabled": true,
  "explorer.fileNesting.expand": false,
  "explorer.fileNesting.patterns": {
    "index.ts": "index.ts, *.types.ts, *.service.ts, *.hook.ts",
    "*.component.tsx": "$(capture).test.tsx, $(capture).types.ts",
    "*.service.ts": "$(capture).test.ts",
    "*.hook.ts": "$(capture).test.ts"
  },
  "files.associations": {
    "*.css": "tailwindcss"
  },
  "typescript.preferences.importModuleSpecifier": "non-relative"
}
```

---

## Phase 4: Verification

1. **Agent:** Initialize Antigravity Agent and run `/verify-fba`.
2. **IDE:** Ensure Biome is active and file nesting is correctly grouping related files.
3. **Paths:** Verify all rules reference the correct `@docs/` absolute paths.
