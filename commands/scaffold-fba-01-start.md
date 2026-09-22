---
nome: scaffold-fba-01-start
descricao: Variante FBA — fase 1, base do projeto
tipo: comando
idioma: en
---
# Role

Senior Frontend Architect & DevOps Engineer

# Objective

Initialize a new frontend project with framework-specific tooling, path aliases for Feature-Based Architecture (FBA), and TypeScript configuration. This phase establishes the foundation for all subsequent tooling.

# Constraints

- **Package Manager:** ALWAYS use `bun`. Never use npm, pnpm or yarn.
- **Versions:** NEVER specify version numbers. Always use `latest` or `@latest`.
- **Architecture:** Must support Feature-Based Architecture (FBA) with path aliases.
- **Documentation:** Preserve existing `docs/` and `.agent/` directories if they exist.
- **Error Handling:** Stop immediately if any command fails. Do not proceed to next steps.

# Chain of Thought

1. Check if framework selection is needed or if one is pre-determined
2. Execute framework initialization with bun
3. Configure TypeScript path aliases for FBA
4. Set up framework-specific path resolution
5. Verify all files exist before proceeding

# Execution

## Step 1: Framework Selection

Choose ONE framework command based on project requirements:

### Option A: Next.js (Recommended for SSR/SSG)

```bash
bun create next-app@latest . --typescript --tailwind --eslint --app --src-dir --no-import-alias --yes
```

### Option B: TanStack Start (Recommended for SPA with file-based routing)

```bash
bunx @tanstack/create-start@latest . --tailwind --yes
```

### Option C: Vue (Recommended for Vue ecosystem)

```bash
bun create vue@latest . --typescript --yes
```

**Anti-Pattern:** Do NOT run multiple framework commands. Choose only ONE.

## Step 2: TypeScript Path Aliases Configuration

Create or update `tsconfig.json` with FBA path aliases:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "react-jsx",
    "incremental": true,
    "paths": {
      "@features/*": ["./src/features/*"],
      "@components/*": ["./src/components/*"],
      "@routes/*": ["./src/routes/*"],

      "@hooks": ["./src/hooks"],
      "@libs": ["./src/libs"],
      "@app-types": ["./src/types"]
    }
  },
  "include": ["src"],
  "exclude": ["node_modules", ".next", ".vinxi", "dist"]
}
```

**Anti-Pattern:** Do NOT use `"@/*"` alias. Always use explicit FBA aliases like `@features/*`.

**Four constraints on this block — each of them breaks the build if ignored:**

1. **No `baseUrl`.** TypeScript 7 removed it: `error TS5102: Option 'baseUrl' has been removed`. It is a hard error, not a warning, and since this scaffold installs `typescript@latest` every new project lands on TS 7+. It is unnecessary — `paths` with no `baseUrl` resolves relative to the folder holding `tsconfig.json`, which is what the `./src/...` entries already assume. Verified against tsc 7.0.2.
2. **Never alias `@types/*`.** That is the npm scope for declaration packages, and `paths` resolves before `node_modules`, so the alias shadows `@types/react`, `@types/node` and friends. Use `@app-types`.
3. **`@libs`, plural, pointing at `src/libs`.** Phase 5 creates `src/libs`. An `@lib/* → ./src/lib/*` entry aliases a directory that never gets created.
4. **Bare entries for barrel-only layers.** A `"@libs/*"` mapping only matches specifiers with a subpath — `import { httpClient } from '@libs'` does not resolve against it. Layers reached only through their barrel (`@hooks`, `@libs`, `@app-types`) take the bare form; layers where the subpath is the real address (`@features/auth`, `@components/ui`) take `/*`. Declaring both forms for one layer re-opens the deep-import hole that Phase 5 closes.

These aliases must be reproduced verbatim in `vite.config.ts` and `vitest.config.ts` below. Three files that have to agree is the classic source of "builds fine, tests cannot resolve the module".

## Step 3: Framework-Specific Configuration

### For Next.js

Create `next.config.mjs`:

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
};

export default nextConfig;
```

### For TanStack Start (Vite-based)

Create `vite.config.ts`:

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@features': path.resolve(__dirname, './src/features'),
      '@components': path.resolve(__dirname, './src/components'),
      '@routes': path.resolve(__dirname, './src/routes'),
      '@app-types': path.resolve(__dirname, './src/types'),
      '@libs': path.resolve(__dirname, './src/libs'),
      '@hooks': path.resolve(__dirname, './src/hooks')
    }
  }
})
```

### For Vue

Create `vite.config.ts`:

```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@features': path.resolve(__dirname, './src/features'),
      '@components': path.resolve(__dirname, './src/components'),
      '@routes': path.resolve(__dirname, './src/routes'),
      '@app-types': path.resolve(__dirname, './src/types'),
      '@libs': path.resolve(__dirname, './src/libs'),
      '@hooks': path.resolve(__dirname, './src/hooks')
    }
  }
})
```

**Anti-Pattern:** Do NOT use default Vite/Next.js path aliases. Always configure explicit FBA aliases.

# Verification Checklist

Before proceeding to Phase 2, verify ALL of these:

- [ ] `package.json` exists with framework dependencies
- [ ] `tsconfig.json` contains the FBA path aliases: `@features/*`, `@components/*`, `@routes/*` (wildcard) and `@hooks`, `@libs`, `@app-types` (bare)
- [ ] `tsconfig.json` contains NO `baseUrl` and NO `@types/*` alias
- [ ] The alias names in `vite.config.ts` and `vitest.config.ts` match `tsconfig.json` exactly — `@libs` not `@lib`, `@app-types` not `@types`
- [ ] Framework config file exists (next.config.mjs, vite.config.ts, or vue.config.ts)
- [ ] `docs/` directory is preserved (if it existed before)
- [ ] `.agent/` directory is preserved (if it existed before)

**Failure Recovery:** If any check fails, stop and report the specific error. Do not proceed.

# Output Format

Provide a concise summary including:
1. Which framework was initialized
2. Confirmation that all path aliases are configured
3. List of created/modified files
4. Status: "✅ Ready for Phase 2: Biome Configuration"

# Error Handling

If any command fails:
1. Stop execution immediately
2. Report the exact error message
3. Suggest the fix
4. Do not proceed to next steps
