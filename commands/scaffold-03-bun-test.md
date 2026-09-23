---
nome: scaffold-03-bun-test
descricao: Fase 3 — `bun test`, happy-dom e Testing Library
tipo: comando
idioma: en
---
# Phase 3: Testing Infrastructure (`bun test`)

**Role:** Senior Frontend Architect & DevOps Engineer
**Objective:** Configure `bun test` for unit and component tests.

**Priority:** High - Testing foundation
**Constraint:** No second alias map — `bun test` reads `paths` from `tsconfig.json`

---

## Why there is no `vitest.config.ts` here

`bun test` resolves `compilerOptions.paths` from `tsconfig.json` on its own — verified on
bun 1.3.14 with `@features/*`. The alias map that had to be **duplicated** in
`vitest.config.ts`, and whose drift from `tsconfig.json` was this phase's documented
failure mode, stops existing. One source of truth for aliases, not two.

Vitest still has a place in this house: it is the runner of `@storybook/addon-vitest`.
A unit test outside Storybook is `bun test`.

---

## Commands

```bash
bun add -d @happy-dom/global-registrator @testing-library/react \
            @testing-library/dom @testing-library/jest-dom @testing-library/user-event
```

---

## Configuration

### 1. Two preload files, in this order

The order is load-bearing: `@testing-library/*` inspects the globals at import time, so
the browser globals have to exist first.

```bash
mkdir -p test

cat > test/happydom.ts <<'EOF'
import { GlobalRegistrator } from "@happy-dom/global-registrator";

GlobalRegistrator.register();
EOF

cat > test/testing-library.ts <<'EOF'
import { afterEach, expect } from "bun:test";
import { cleanup } from "@testing-library/react";
import * as matchers from "@testing-library/jest-dom/matchers";

expect.extend(matchers);

afterEach(() => {
  cleanup();
  document.body.innerHTML = "";
});
EOF
```

**`expect.extend(matchers)` is mandatory.** `import "@testing-library/jest-dom"` alone —
the form that works in Jest and Vitest — does **not** register the matchers in `bun:test`.
Without it, `toHaveTextContent` and `toBeInTheDocument` do not exist at runtime.

### 2. `bunfig.toml`

```bash
cat > bunfig.toml <<'EOF'
[test]
preload = ["./test/happydom.ts", "./test/testing-library.ts"]
EOF
```

### 3. Types for the matchers

Without this file `tsc` does not know `toHaveTextContent`, and `bun run typecheck` fails.

```bash
cat > test/matchers.d.ts <<'EOF'
import { TestingLibraryMatchers } from "@testing-library/jest-dom/matchers";
import { Matchers, AsymmetricMatchers } from "bun:test";

declare module "bun:test" {
  interface Matchers<T> extends TestingLibraryMatchers<typeof expect.stringContaining, void> {}
  interface AsymmetricMatchers extends TestingLibraryMatchers<any, any> {}
}
EOF
```

---

## Example test

The file name **must** match a discovery pattern — `*.test.*`, `*_test.*`, `*.spec.*` or
`*_spec.*`. A file outside the pattern never runs, and nothing warns (`BUN-TEST-01`).

```bash
cat > src/example.test.tsx <<'EOF'
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
EOF
```

---

## Scripts

```bash
bun -e "
const pkg = await Bun.file('package.json').json();
pkg.scripts = {
  ...pkg.scripts,
  'test': 'bun test --watch',
  'test:run': 'bun test',
  'test:coverage': 'bun test --coverage'
};
await Bun.write('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
```

There is no `test:ui`: `bun test` has no UI runner. That is a real loss against Vitest,
and it is the only one this phase gives up.

---

## Verification Checkpoint

- [ ] `test/happydom.ts` and `test/testing-library.ts` exist, **in that order** in `bunfig.toml`
- [ ] `test/matchers.d.ts` exists — without it `tsc` does not see the jest-dom matchers
- [ ] **No** `vitest.config.ts`: the aliases come from `tsconfig.json`
- [ ] `bun run test:run` passes with at least one test
- [ ] **Break the component on purpose and confirm the test goes RED** (`TS-TEC-08`).
      A green suite that never fails is not a suite.
- [ ] An import through `@features/...` resolves inside a test

---

## If you add a coverage gate

- `coverageThreshold` needs the `text` reporter enabled (`BUN-TEST-27`): with only
  `lcov`, the process exits `0` below the threshold.
- The gate is `lines` and `functions`. The `statements` key is accepted and **not**
  applied (`BUN-TEST-28`).

---

## Next Phase

After verification, proceed to Phase 4: Git & Hooks Setup
