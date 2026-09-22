---
nome: scaffold-03-vitest
descricao: Fase 3 — Vitest e Testing Library
tipo: comando
idioma: en
---
# Phase 3: Testing Infrastructure (Vitest)

**Role:** Senior Frontend Architect & DevOps Engineer
**Objective:** Install and configure Vitest with path aliases.

**Priority:** High - Testing foundation
**Constraint:** Path aliases must match FBA structure

---

## Commands

```bash
pnpm add -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/dom @testing-library/jest-dom happy-dom
```

---
## Configuration

### 1. Create `vitest.config.ts`

```bash
cat > vitest.config.ts <<'EOF'
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "happy-dom",
    setupFiles: ["./src/setupTests.ts"],
    globals: true,
  },
  resolve: {
    alias: {
      "@features": path.resolve(__dirname, "./src/features"),
      "@components": path.resolve(__dirname, "./src/components"),
      "@routes": path.resolve(__dirname, "./src/routes"),
      "@types": path.resolve(__dirname, "./src/types"),
      "@libs": path.resolve(__dirname, "./src/libs"),
      "@hooks": path.resolve(__dirname, "./src/hooks")
    },
  },
});
EOF
```

### 2. Create test setup file

```bash
cat > src/setupTests.ts <<'EOF'
import '@testing-library/jest-dom';
EOF
```

---

## Verification Checkpoint

- [ ] `vitest.config.ts` exists with path aliases `@features`, `@components`, `@routes`, `@types`, `@libs`, `@hooks`
- [ ] `src/setupTests.ts` exists with jest-dom import

---

## Next Phase

After verification, proceed to Phase 4: Git & Hooks Setup
