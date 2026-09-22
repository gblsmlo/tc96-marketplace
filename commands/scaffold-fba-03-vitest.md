---
nome: scaffold-fba-03-vitest
descricao: Variante FBA — fase 3, Vitest
tipo: comando
idioma: en
---
# Role
Senior Frontend Architect & DevOps Engineer

# Objective
Configure Vitest testing framework with FBA path aliases, testing-library integration, and proper setup files. This establishes the testing foundation for the project.

# Constraints
- **Package Manager:** ALWAYS use `pnpm`. Never use npm or yarn.
- **Versions:** NEVER specify version numbers. Always use `latest` or `@latest`.
- **Path Aliases:** Must match Phase 1 FBA aliases exactly.
- **Environment:** Use `happy-dom` for lightweight browser simulation.
- **Error Handling:** Stop immediately if any command fails.

# Chain of Thought
1. Verify Phases 1-2 completed successfully
2. Install Vitest and testing dependencies
3. Create vitest.config.ts with path aliases
4. Create test setup file
5. Add npm scripts
6. Create example test to verify setup
7. Run tests to confirm everything works

# Execution

## Step 1: Install Dependencies

```bash
pnpm add -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/dom @testing-library/jest-dom happy-dom
```

**Anti-Pattern:** Do NOT install `@testing-library/jest-dom` as a regular dependency. It's a dev dependency.

## Step 2: Create Vitest Configuration

Create `vitest.config.ts`:

```typescript
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
```

**Critical:** These aliases MUST match the aliases in `tsconfig.json` from Phase 1 exactly.

**Anti-Pattern:** Do NOT use different alias names than defined in tsconfig.json.

## Step 3: Create Test Setup File

Create `src/setupTests.ts`:

```typescript
import '@testing-library/jest-dom';
```

## Step 4: Add NPM Scripts

Update `package.json` scripts section:

```json
{
  "scripts": {
    "test": "vitest",
    "test:run": "vitest run",
    "test:ui": "vitest --ui"
  }
}
```

## Step 5: Create Example Test

Create `src/example.test.ts` to verify setup:

```typescript
import { describe, it, expect } from 'vitest';

describe('Vitest Setup', () => {
  it('should work with basic assertions', () => {
    expect(true).toBe(true);
  });

  it('should work with jest-dom matchers', () => {
    const element = document.createElement('div');
    element.className = 'test-class';
    expect(element).toHaveClass('test-class');
  });
});
```

## Step 6: Run Tests

```bash
pnpm test:run
```

**Anti-Pattern:** Do NOT skip running tests to verify setup. Always confirm tests pass.

# Verification Checklist

Before proceeding to Phase 4, verify ALL of these:

- [ ] `vitest.config.ts` exists with all FBA path aliases
- [ ] `src/setupTests.ts` exists with jest-dom import
- [ ] `package.json` has `test`, `test:run`, and `test:ui` scripts
- [ ] `pnpm test:run` executes successfully (at least 1 test passes)
- [ ] Path aliases resolve correctly (no "Cannot find module" errors)

**Verification Command:**
```bash
# Test the setup
pnpm test:run
```

**Failure Recovery:** If tests fail, check that path aliases in vitest.config.ts match tsconfig.json exactly.

# Output Format

Provide a concise summary including:
1. Confirmation that Vitest is installed
2. Confirmation that path aliases are configured
3. Test execution results
4. Status: "✅ Ready for Phase 4: Git Hooks Setup"

# Error Handling

If any command fails:
1. Stop execution immediately
2. Report the exact error message
3. For "Cannot find module" errors, verify path aliases match tsconfig.json
4. Do not proceed to next steps

# Troubleshooting

**Issue:** "Cannot find module '@features/...'"
**Solution:** Check that vitest.config.ts resolve.alias matches tsconfig.json paths exactly.

**Issue:** "jest-dom matchers not found"
**Solution:** Ensure `src/setupTests.ts` is imported in vitest.config.ts test.setupFiles.

**Issue:** Tests run but UI doesn't open with `test:ui`
**Solution:** Install `@vitest/ui` package: `pnpm add -D @vitest/ui`

**Issue:** React hooks not working in tests
**Solution:** Verify `@vitejs/plugin-react` is installed and included in vitest.config.ts plugins.
