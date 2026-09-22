---
nome: scaffold-01-tanstack-start
descricao: Fase 1 — base TanStack Start com TypeScript, Tailwind e Vite
tipo: comando
idioma: en
---
# Phase 1: TanStack Start Foundation

**Role:** Senior Frontend Architect & DevOps Engineer
**Objective:** Initialize TanStack Start with TypeScript, Tailwind, and Vite.

**Priority:** High - Foundation phase
**Constraint:** No business logic implementation - focus purely on configuration and structure setup

---

## Project Stack

- **React 19** with latest features
- **TanStack Router** - File-based routing
- **TanStack Start** - Full-stack React framework
- **WorkOS AuthKit** - Authentication and authorization
- **Vite** - Build tool and dev server
- **TypeScript** - Type safety

---

## Commands

```bash
# Create project using TanStack Start CLI
pnpm create @tanstack/start@latest . --tailwind --yes
```

---

## Post-Init Configuration

### 1. Restore backed-up directories

```bash
mv /tmp/project-backup-*/* . 2>/dev/null || true
rm -rf /tmp/project-backup-*
```

### 2. Create app.config.ts for TanStack Start with FBA path aliases

```bash
cat > app.config.ts <<'EOF'
import { defineConfig } from '@tanstack/start/config'
import viteTsConfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  vite: {
    plugins: [
      viteTsConfigPaths({
        projects: ['./tsconfig.json'],
      }),
    ],
  },
})
EOF
```

### 3. Update tsconfig.json with FBA path aliases

```bash
cat > tsconfig.json <<'EOF'
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
    "baseUrl": ".",
    "paths": {
      "@features/*": ["./src/features/*"],
      "@components/*": ["./src/components/*"],
      "@routes/*": ["./src/routes/*"],
      "@types/*": ["./src/types/*"],
      "@libs/*": ["./src/libs/*"],
      "@hooks/*": ["./src/hooks/*"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.tsx", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules", ".output", ".vinxi"]
}
EOF
```

---

## Verification Checkpoint

- [ ] `package.json` exists with TanStack Start dependencies
- [ ] `tsconfig.json` contains path aliases `@features/*`, `@components/*`, `@routes/*`, `@types/*`, `@libs/*`, `@hooks/*`
- [ ] `app.config.ts` exists with Vite path alias configuration
- [ ] `docs/` and `.agent/` directories are restored

---

## Next Phase

After verification, proceed to **Phase 2: Tooling Configuration (Biome)**
