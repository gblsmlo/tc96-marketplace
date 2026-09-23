---
nome: scaffold-fba-03-bun-test
descricao: Variante FBA — fase 3, `bun test` e Testing Library
tipo: comando
idioma: en
---
# Role
Senior Frontend Architect & DevOps Engineer

# Objective
Configure `bun test` for unit and component tests, with the FBA path aliases resolved
from `tsconfig.json` and Testing Library wired through two preload files.

# Constraints
- **Package Manager:** ALWAYS use `bun`. Never use npm, pnpm or yarn.
- **Versions:** NEVER specify version numbers. Always use `latest` or `@latest`.
- **Path Aliases:** do NOT redeclare them. `bun test` reads `compilerOptions.paths`
  from `tsconfig.json` — verified on bun 1.3.14. A second alias map is the drift this
  phase used to produce.
- **Environment:** `happy-dom`, injected by `@happy-dom/global-registrator`.
- **Error Handling:** Stop immediately if any command fails.

# Chain of Thought
1. Verify Phases 1-2 completed successfully
2. Install Testing Library and the happy-dom registrator
3. Create the two preload files, in order
4. Declare the preloads in `bunfig.toml`
5. Declare the matcher types so `tsc` sees them
6. Add package scripts
7. Create an example test and run it
8. Break the component on purpose and confirm it goes red

# Execution

## Step 1: Install Dependencies

```bash
bun add -d @happy-dom/global-registrator @testing-library/react \
            @testing-library/dom @testing-library/jest-dom @testing-library/user-event
```

**Anti-Pattern:** Do NOT install these as regular dependencies. They are dev dependencies.

**Anti-Pattern:** Do NOT add `vitest`, `@vitejs/plugin-react` or `jsdom`. The runner is
`bun test`, the DOM is `happy-dom`, and the transform is the Bun runtime itself. Vitest
has one job in this house — running `@storybook/addon-vitest` — and this is not it.

## Step 2: Create the two preload files

The order is load-bearing. `@testing-library/*` inspects the globals at import time, so
the browser globals must be registered first. Two files, not one.

Create `test/happydom.ts`:

```typescript
import { GlobalRegistrator } from "@happy-dom/global-registrator";

GlobalRegistrator.register();
```

Create `test/testing-library.ts`:

```typescript
import { afterEach, expect } from "bun:test";
import { cleanup } from "@testing-library/react";
import * as matchers from "@testing-library/jest-dom/matchers";

expect.extend(matchers);

afterEach(() => {
  cleanup();
  document.body.innerHTML = "";
});
```

**Critical:** `expect.extend(matchers)` is mandatory. `import "@testing-library/jest-dom"`
alone — the form that works in Jest and Vitest — does **not** register the matchers in
`bun:test`. Without it, `toHaveTextContent` and `toBeInTheDocument` do not exist at
runtime, and the failure reads as "matcher is not a function".

**Critical:** the `afterEach` unmounts (`cleanup()`) and clears the body. Without it, one
test's DOM leaks into the next and `getByRole` starts matching two elements.

## Step 3: Declare the preloads

Create `bunfig.toml`:

```toml
[test]
preload = ["./test/happydom.ts", "./test/testing-library.ts"]
```

**Anti-Pattern:** do NOT add `seed` without `randomize = true` — the key is accepted and
has no effect, and the failure is silent (`BUN-TEST-14`).

## Step 4: Declare the matcher types

Create `test/matchers.d.ts`. Without it the tests pass and `bun run typecheck` fails,
because `tsc` does not know the jest-dom matchers exist:

```typescript
import { TestingLibraryMatchers } from "@testing-library/jest-dom/matchers";
import { Matchers, AsymmetricMatchers } from "bun:test";

declare module "bun:test" {
  interface Matchers<T> extends TestingLibraryMatchers<typeof expect.stringContaining, void> {}
  interface AsymmetricMatchers extends TestingLibraryMatchers<any, any> {}
}
```

## Step 5: Add package scripts

```json
{
  "scripts": {
    "test": "bun test --watch",
    "test:run": "bun test",
    "test:coverage": "bun test --coverage"
  }
}
```

There is no `test:ui`. `bun test` has no UI runner — it is the one thing this phase gives
up against Vitest, and it is worth saying out loud instead of leaving a script that fails.

## Step 6: Create Example Test

The file name **must** match a discovery pattern — `*.test.*`, `*_test.*`, `*.spec.*` or
`*_spec.*`. A file outside the pattern never runs, and nothing warns (`BUN-TEST-01`).

Create `src/example.test.tsx`:

```tsx
/// <reference lib="dom" />
import { test, expect } from "bun:test";
import { render, screen } from "@testing-library/react";

function Total({ cents }: { cents: number }) {
  return <output role="status">{`R$ ${(cents / 100).toFixed(2)}`}</output>;
}

test("renders the total", () => {
  render(<Total cents={1990} />);
  expect(screen.getByRole("status")).toHaveTextContent("R$ 19.90");
});
```

## Step 7: Run Tests

```bash
bun run test:run
```

## Step 8: Prove the suite can fail

```bash
# change (cents / 100) to (cents / 1000) and run again
bun run test:run   # must go RED
```

**Anti-Pattern:** Do NOT accept a green suite as evidence. A suite that has never been
seen red proves nothing (`TS-TEC-08`). Undo the change afterwards.

# Verification Checklist

Before proceeding to Phase 4, verify ALL of these:

- [ ] `test/happydom.ts` and `test/testing-library.ts` exist, in that order in `bunfig.toml`
- [ ] `test/matchers.d.ts` exists
- [ ] **No** `vitest.config.ts` and no second alias map — aliases come from `tsconfig.json`
- [ ] `package.json` has `test`, `test:run` and `test:coverage`
- [ ] `bun run test:run` passes with at least 1 test
- [ ] Step 8 made the suite go red, and the change was undone
- [ ] An import through `@features/...` resolves inside a test

**Verification Command:**
```bash
bun run test:run
```

**Failure Recovery:** if an alias fails to resolve, fix `compilerOptions.paths` in
`tsconfig.json` — there is nowhere else for it to be wrong now.

# Coverage gate, if you add one

- `coverageThreshold` requires the `text` reporter enabled (`BUN-TEST-27`): with only
  `lcov` the process exits `0` below the threshold, and the gate never fails.
- The gate is `lines` and `functions`. The `statements` key is accepted and **not**
  applied (`BUN-TEST-28`) — a threshold on it is decorative.

# Output Format

Provide a concise summary including:
1. Confirmation that `bun test` runs, with the number of tests
2. Confirmation that the aliases resolve from `tsconfig.json`
3. The output of Step 8 — the run that went red
4. Status: "✅ Ready for Phase 4: Git Hooks Setup"

# Error Handling

If any command fails:
1. Stop execution immediately
2. Report the exact error message
3. For "Cannot find module '@features/...'", fix `tsconfig.json` — not a second config
4. Do not proceed to next steps

# Troubleshooting

**Issue:** "Cannot find module '@features/...'"
**Solution:** `compilerOptions.paths` in `tsconfig.json` is wrong or missing `baseUrl`.
There is no second alias map to check.

**Issue:** `toHaveTextContent is not a function`
**Solution:** `expect.extend(matchers)` is missing from `test/testing-library.ts`, or the
preload is not declared in `bunfig.toml`.

**Issue:** `document is not defined`
**Solution:** `test/happydom.ts` is not the **first** preload, or is missing.

**Issue:** tests pass but `tsc --noEmit` fails on the matchers
**Solution:** `test/matchers.d.ts` is missing.

**Issue:** `getByRole` finds two elements after adding a second test
**Solution:** the `afterEach` with `cleanup()` is missing from `test/testing-library.ts`.

**Issue:** a test file never runs and nothing warns
**Solution:** the name does not match a discovery pattern (`BUN-TEST-01`). Rename it to
`*.test.ts(x)`.
