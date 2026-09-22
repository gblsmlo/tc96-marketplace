---
nome: scaffold-02-biome
descricao: Fase 2 — Biome como lint e formatter
tipo: comando
idioma: en
---
# Role 
You are a Senior Frontend Architect and DevOps Engineer. Your goal is to establish a high-performance linting and formatting foundation using Biome. 

# Objective 
Configure **Biome** as the sole provider for linting, formatting, and import organization, completely replacing ESLint and Prettier. This setup must be optimized for a Feature-Based Architecture (FBA) using kebab-case and Barrel files. 
# Task 1: 
Installation Provide the command to install Biome: `bun add -d @biomejs/biome` 
# Task 2: 
Configuration File Generation Generate the `biome.json` file exactly as specified below. This file must be created at the project root.

```json
{
  "$schema": "[https://biomejs.dev/schemas/1.9.4/schema.json](https://biomejs.dev/schemas/1.9.4/schema.json)",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "organizeImports": {
    "enabled": true
  },
  "formatter": {
    "enabled": true,
    "formatWithErrors": false,
    "indentStyle": "tab",
    "indentWidth": 2,
    "lineEnding": "lf",
    "lineWidth": 80
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "suspicious": {
        "noExplicitAny": "off",
        "noArrayIndexKey": "off",
        "noImportCycles": "error"
      },
      "correctness": {
        "useExhaustiveDependencies": "warn"
      },
      "style": {
        "noNonNullAssertion": "off",
        "useSelfClosingElements": "error"
      }
    }
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "jsxQuoteStyle": "double",
      "trailingCommas": "all",
      "semicolons": "always",
      "arrowParentheses": "always"
    }
  }
}
```

# Task 3: Script Integration
Add the following commands to the `scripts` block in `package.json`:
- `"lint": "biome check --write ./src"`
- `"format": "biome format --write ./src"`
- `"ci": "biome ci ./src"`

# Task 4: Architectural Rules for Tooling
Explain the core configurations to the team:
1. **VCS Integration (`vcs.useIgnoreFile`)**: Explains that Biome natively reads `.gitignore`. Manual ignores for `node_modules` or `dist` are unnecessary.
2. **`noImportCycles`**: Highlight that this specific rule natively prevents the circular dependencies in our `index.ts` Barrel files, protecting the architecture.
3. **`organizeImports`**: Keeps FBA feature imports perfectly sorted, reducing merge conflicts.

# Verification Checkpoint
- Ensure NO `.eslintrc`, `.prettierrc`, or `.editorconfig` exists in the repository.
- Verify `biome.json` is at the root.
- Run `bun run lint` to ensure `noImportCycles` is actively protecting the codebase.