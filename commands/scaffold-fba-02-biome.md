---
nome: scaffold-fba-02-biome
descricao: Variante FBA — fase 2, Biome
tipo: comando
idioma: en
---
# Role
Senior Frontend Architect & DevOps Engineer

# Objective
Configure Biome as the exclusive linting, formatting, and import organization tool. This setup replaces ESLint and Prettier entirely, optimizing for Feature-Based Architecture (FBA) with kebab-case naming and barrel files.

# Constraints
- **Package Manager:** ALWAYS use `bun`. Never use npm, pnpm or yarn.
- **Versions:** NEVER specify version numbers. Always use `latest` or `@latest`.
- **Exclusivity:** Biome MUST be the only linting/formatting tool. Remove ESLint and Prettier completely.
- **FBA Compliance:** Configuration must enforce FBA patterns (kebab-case, barrel files, no circular imports).
- **Error Handling:** Stop immediately if any command fails.

# Chain of Thought
1. Verify project was initialized in Phase 1
2. Remove any existing ESLint/Prettier configurations
3. Install Biome with bun
4. Create biome.json with FBA-specific rules
5. Add package scripts for linting
6. Configure VS Code settings for Biome
7. Verify no competing tools remain

# Execution

## Step 1: Remove Competing Tools

Before installing Biome, remove ESLint and Prettier:

```bash
# Remove ESLint and Prettier packages, whichever of them are present.
# `bun remove` takes several names at once, removes only what is a dependency
# and still exits 0 when a name is absent — verified on bun 1.3.14. The guard
# loop this step used to carry existed for pnpm, which exits 1 on a missing
# name (ERR_PNPM_CANNOT_REMOVE_MISSING_DEPS) and would abort a clean project.
bun remove eslint prettier eslint-config-next eslint-plugin-react \
           @typescript-eslint/eslint-plugin @typescript-eslint/parser

# Remove configuration files
rm -f .eslintrc .eslintrc.js .eslintrc.json .eslintrc.cjs .eslintrc.mjs
rm -f .prettierrc .prettierrc.js .prettierrc.json .prettierrc.toml .prettierrc.yaml .prettierrc.yml
rm -f .editorconfig
rm -f .eslintignore .prettierignore
```

**Anti-Pattern:** Never keep ESLint or Prettier configuration files alongside Biome. This creates conflicting rules.

## Step 2: Install Biome

```bash
bun add -d @biomejs/biome
```

**Anti-Pattern:** Do NOT use `npm install` or `yarn add`. Always use `bun install` / `bun add`.

## Step 3: Create Biome Configuration

Create `biome.json` at the project root:




```json
{
  "$schema": "https://biomejs.dev/schemas/latest/schema.json",
  "assist": {
    "actions": {
      "source": {
        "useSortedKeys": "off",
        "organizeImports": "on"
      }
    }
  },
  "css": {
    "parser": {
      "tailwindDirectives": true,
      "cssModules": false
    }
  },
  "files": {
    "includes": ["**/*.{ts,tsx,js,jsx,cjs,mjs,json}", "!**/node_modules", "!**/.next", "!**/dist"]
  },
  "formatter": {
    "attributePosition": "auto",
    "enabled": true,
    "formatWithErrors": false,
    "indentStyle": "tab",
    "indentWidth": 2,
    "lineEnding": "lf",
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "arrowParentheses": "always",
      "bracketSameLine": false,
      "bracketSpacing": true,
      "quoteProperties": "asNeeded",
      "quoteStyle": "single",
      "semicolons": "asNeeded",
      "trailingCommas": "all"
    }
  },
  "linter": {
    "rules": {
      "correctness": {
        "noUnusedImports": "error"
      },
      "suspicious": {
        "noExplicitAny": "warn",
        "noImportCycles": "error"
      },
      "style": {
        "noRestrictedImports": {
          "level": "error",
          "options": {
            "patterns": [
              {
                "group": ["@features/*/*", "@features/*/*/**"],
                "message": "REACT-ARCH-05: deep import em feature. Importe pelo barrel: @features/<feature>."
              },
              {
                "group": ["@components/*/*", "@components/*/*/**"],
                "message": "REACT-ARCH-05: deep import em componente compartilhado. Importe @components/ui ou @components/layout."
              }
            ]
          }
        }
      }
    }
  },
  "overrides": [
    {
      "includes": ["src/features/**"],
      "linter": {
        "rules": {
          "style": {
            "noRestrictedImports": {
              "level": "error",
              "options": {
                "patterns": [
                  {
                    "group": ["@routes/**"],
                    "message": "REACT-ARCH-07: feature nao importa rota. A rota conhece a feature, nunca o contrario."
                  },
                  {
                    "group": ["@features/*/*", "@features/*/*/**"],
                    "message": "REACT-ARCH-05: deep import em feature. Importe pelo barrel: @features/<feature>."
                  }
                ]
              }
            }
          }
        }
      }
    },
    {
      "includes": ["src/components/**", "src/hooks/**", "src/libs/**", "src/types/**"],
      "linter": {
        "rules": {
          "style": {
            "noRestrictedImports": {
              "level": "error",
              "options": {
                "patterns": [
                  {
                    "group": ["@features/**", "@routes/**"],
                    "message": "REACT-ARCH-06: camada generica nao conhece dominio nem rota. Inverta a dependencia via prop ou parametro."
                  }
                ]
              }
            }
          }
        }
      }
    }
  ]
}
```

**Key FBA Rules Explained:**

| Rule | Group | Since | Enforces |
| --- | --- | --- | --- |
| `noUnusedImports` | `correctness` | — | dead exports in barrel files |
| `noImportCycles` | `suspicious` | Biome v2.0.0 | `REACT-ARCH-04`, `REACT-ARCH-10` — importing your own barrel from inside a feature closes a cycle through `index.ts` |
| `noRestrictedImports` | `style` | `patterns` since v2.2.0 | `REACT-ARCH-05` (deep imports), `REACT-ARCH-06`, `REACT-ARCH-07` (layer direction) |
| `organizeImports` | assist | — | sorted imports, fewer merge conflicts |

**None of these three lint rules is recommended by default** — they only run because they are listed explicitly above. Do NOT move `noImportCycles` to `nursery`: it was promoted to `suspicious` in Biome v2.0.0, and under `nursery` it is an unknown key that never runs.

`overrides` is **first-match-wins** — the Biome docs state that if a file can match three patterns, only the first one is used. That is why the deep-import pattern is repeated inside the `src/features/**` override: an override replaces the top-level rule for matching files instead of merging with it. Keep the `src/features/**` entry before the generic-layer entry; the two sets of globs do not overlap.

`noPrivateImports` looks like it would enforce feature boundaries. It does not — `@package` visibility is relative to the declaring folder, so a feature's `index.ts` cannot re-export a `@package` symbol from its own `components/` subfolder. Do not add it for this purpose.

**Reference:** the rules above are defined in the knowledge-base note [Feature-Based Architecture](../knowledge-base/pages/feature-based-architecture.md) § 4 (rule table) and § 7 (enforcement). That note is the source of truth; if this prompt and the note disagree, the note wins.

**Anti-Pattern:** Do NOT use `"@tc96/biome-config"` or other extends. Use explicit configuration.

## Step 4: Add NPM Scripts

Update `package.json` scripts section:

```json
{
  "scripts": {
    "lint": "biome check --write .",
    "lint:check": "biome check src",
    "lint:format": "biome format --write .",
    "lint:ci": "biome ci .",
    "lint:staged": "biome check --staged --write .",
    "lint:unsafe": "biome check --unsafe --write ."
  }
}
```

## Step 5: Configure VS Code

Create or update `.vscode/settings.json`:

```json
{
  "editor.defaultFormatter": "biomejs.biome",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.biome": "always",
    "source.organizeImports.biome": "always"
  },
  "editor.tabSize": 2,
  "editor.insertSpaces": false,
  "[typescript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[typescriptreact]": { "editor.defaultFormatter": "biomejs.biome" }
}
```

## Step 6: Create VS Code Extensions Recommendations

Create `.vscode/extensions.json`:

```json
{
  "recommendations": ["biomejs.biome"],
  "unwantedRecommendations": ["dbaeumer.vscode-eslint", "esbenp.prettier-vscode"]
}
```

**Anti-Pattern:** Do NOT leave ESLint or Prettier extensions in recommendations.

# Verification Checklist

Before proceeding to Phase 3, verify ALL of these:

- [ ] NO `.eslintrc*`, `.prettierrc*`, or `.editorconfig` files exist
- [ ] `biome.json` exists at project root
- [ ] `@biomejs/biome` is in `devDependencies`
- [ ] `bun run lint:check` runs successfully — use this, NOT `bun run lint`. `lint` is `biome check --write .`, which fixes files before reporting; a command that repairs the problem cannot prove its absence. `lint:check` is `biome check src`, non-mutating and scoped, and matches the acceptance command in [Feature-Based Architecture](../knowledge-base/pages/feature-based-architecture.md) § 7 and `Skill/react-structure.md`
- [ ] VS Code settings are configured for Biome
- [ ] No eslint/prettier packages remain in dependencies

**Verification Command:**

```bash
# Check for competing tools.
# Do NOT use `ls a* b* c && ... || ...` here: `ls` exits non-zero when ANY argument
# fails to match, so with only .eslintrc.json left behind it still takes the || branch
# and prints the success message. The check would be green with the defect present.
found=$(find . -maxdepth 1 \( -name '.eslintrc*' -o -name '.prettierrc*' -o -name '.editorconfig' \) -print)
[ -z "$found" ] && echo "✅ No competing files" || { echo "❌ Found competing config files:"; echo "$found"; }

# Test Biome works — non-mutating, this is the acceptance check
bun run lint:check
```

**Failure Recovery:** If any ESLint/Prettier files remain, remove them and re-run Phase 2.

# Output Format

Provide a concise summary including:
1. Confirmation that ESLint/Prettier were removed
2. Confirmation that Biome is installed and configured
3. List of created/modified files
4. Status: "✅ Ready for Phase 3: Vitest Configuration"

# Error Handling

If any command fails:
1. Stop execution immediately
2. Report the exact error message
3. For Biome configuration errors, check JSON syntax
4. Do not proceed to next steps

# Troubleshooting

**Issue:** Biome reports errors in `node_modules`
**Solution:** Ensure the `"!**/node_modules"` entry is present inside the `files.includes` array. Biome v2 has no `files.exclude` key — exclusion is a negated pattern inside `includes`.

**Issue:** Format on save not working in VS Code
**Solution:** Verify Biome extension is installed and `.vscode/settings.json` exists

**Issue:** `noImportCycles` rule not available
**Solution:** It belongs to the `suspicious` group (promoted in Biome v2.0.0), NOT `nursery`. If it is listed under `nursery`, Biome treats it as an unknown key and the rule silently never runs. Check `biome --version` is 2.x.

**Issue:** `noRestrictedImports` reports nothing even though deep imports exist
**Solution:** Two causes. (1) The `patterns` option requires Biome v2.2.0+ — on older versions only `paths` works. (2) The file is matched by an `overrides` entry that replaced the top-level rule; `overrides` is first-match-wins and does not merge, so the pattern must be repeated inside that override.

**Issue:** A rule fires on files it should not, or the wrong override applies
**Solution:** `overrides` order matters — the first matching `includes` wins. Reorder the array so the most specific entry comes first.
