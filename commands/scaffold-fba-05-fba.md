---
nome: scaffold-fba-05-fba
descricao: Variante FBA — fase 5, estrutura de diretórios
tipo: comando
idioma: en
---
# Role
Senior Frontend Architect & DevOps Engineer

# Objective
Create the Feature-Based Architecture (FBA) directory structure with barrel files, enforce kebab-case naming, and establish anti-cycle rules. This phase implements the architectural foundation for scalable frontend development.

# Reference
The architecture this phase scaffolds is specified in the knowledge-base note [Feature-Based Architecture](../knowledge-base/pages/feature-based-architecture.md) — § 2 (layers and dependency direction), § 4 (the `REACT-ARCH-*` rule table), § 7 (Biome enforcement). That note is the source of truth: if this prompt and the note disagree, the note wins and this prompt is the bug. The procedure for applying the rules to real code is `Skill/react-structure.md`.

# Constraints
- **Naming Convention:** Strict kebab-case for ALL files and directories (e.g., `user-profile.tsx`, NOT `UserProfile.tsx`)
- **Path Aliases:** Every top-level folder under `src/` must have a `@` alias
- **Barrel Pattern:** Every module root (each feature, each shared layer) has an `index.ts` declaring its public API. Subfolders inside a feature do not get barrels — they are internal and reached by relative path
- **No Empty Folders:** Create a directory only when a file goes into it in the same commit
- **Tooling:** Biome enforces import hygiene
- **Error Handling:** Stop immediately if any command fails

# Chain of Thought
1. Verify Phases 1-4 completed successfully
2. Create module roots only — no subfolders inside features
3. Create one empty barrel (index.ts) per module root
4. Provide tsconfig.json path aliases reference
5. Provide biome.json configuration for import rules
6. Document the anti-cycle architecture rules
7. Provide simple code examples demonstrating proper patterns
8. Verify structure is correct

# Execution

## Step 1: Create Directory Structure

Run these commands to create the FBA structure:

Create **module roots only**. No subfolders.

```bash
# Features — one folder per product capability
mkdir -p src/features/auth
mkdir -p src/features/user-profile

# Shared layers
mkdir -p src/components/ui
mkdir -p src/components/layout
mkdir -p src/hooks
mkdir -p src/libs
mkdir -p src/types
```

Every directory above receives an `index.ts` in Step 2, so none of them is left empty.

**Two folders are deliberately NOT created here:**

- **`src/routes/`** belongs to the framework. TanStack Start / Router creates it during Phase 1, together with `__root.tsx`. If it does not exist yet, it gets created along with the first route file — never as an empty shell. The `@routes/*` alias in Step 3 is declared regardless; an alias pointing at a folder that will exist is fine, an empty folder is not.
- **`src/assets/`** gets created when the first asset lands in it.

Both follow the same rule as feature subfolders: **a directory appears in the same commit as its first file.**

**Do not pre-create `api/`, `components/`, `hooks/`, `stores/`, `types/` or `utils/` inside a feature.** Open each one at the moment a file actually belongs in it — `mkdir` and the file in the same commit. An empty directory advertises structure that does not exist, and a skeleton of seven empty folders pushes whoever comes next to fill them just because they are there. Step 6 shows the growth pattern.

**Names must match everywhere.** The feature directories created here are the ones that get barrel files in Step 2 and aliases in Step 3 — `user-profile`, not `account`. Likewise `src/libs` (plural), which is what the `@libs` alias points at.

## Step 2: Create Barrel Files

Every module root gets an `index.ts`. They start **empty** — a barrel declares the public surface, and at bootstrap there is nothing public yet. Exports are added in the same commit as the file they expose.

```bash
for m in \
  src/features/auth \
  src/features/user-profile \
  src/components/ui \
  src/components/layout \
  src/hooks \
  src/libs \
  src/types
do
  printf '// Public API. Only re-exports — no logic, no side effects.\nexport {}\n' > "$m/index.ts"
done
```

`export {}` makes the file a module rather than a global script, which keeps `isolatedModules` and the alias resolution happy while the barrel is still empty.

**Do not create barrels that export files you have not written.** An `index.ts` re-exporting `./hooks/use-auth` before that file exists produces a project that does not compile — and `noUnusedImports` will not save you, because the failure is module resolution, not lint.

For reference, this is what a barrel looks like once the feature has grown (do **not** create this now — Step 6 builds it one line at a time):

```typescript
// src/features/auth/index.ts
export { useAuth } from './hooks/use-auth';
export { LoginForm } from './components/login-form';
export type { AuthState } from './types/auth-types';
```

**Anti-Pattern:** Barrel files must ONLY contain exports. Never add logic or side effects.

**Keep the surface small.** A barrel that re-exports everything declares nothing. Export only what another layer actually consumes; internal components stay internal.

## Step 3: TypeScript Path Aliases Reference

Ensure `tsconfig.json` contains these paths (from Phase 1):

```json
{
  "compilerOptions": {
    "paths": {
      "@features/*": ["./src/features/*"],
      "@components/*": ["./src/components/*"],
      "@routes/*": ["./src/routes/*"],

      "@hooks": ["./src/hooks"],
      "@libs": ["./src/libs"],
      "@app-types": ["./src/types"]
    }
  }
}
```

**Three things here are deliberate and easy to get wrong.**

**0. Do NOT add `baseUrl`.** TypeScript 7 removed it — `error TS5102: Option 'baseUrl' has been removed`, which is a hard configuration error, not a warning. Since this scaffold installs `typescript@latest` (the "never pin versions" constraint from Phase 2), any project it creates lands on TS 7+ and a `baseUrl` in `tsconfig.json` makes `tsc --noEmit` fail before it typechecks a single file. It is not needed: a `paths` map with no `baseUrl` resolves relative to the directory holding `tsconfig.json`, which is exactly what the `./src/...` entries above assume. Verified against tsc 7.0.2.

**1. Never alias `@types/*`.** That prefix is the npm scope for declaration packages (`@types/node`, `@types/react`), and TypeScript resolves `paths` *before* `node_modules`. An `@types/*` alias puts the project on a collision course with the ecosystem. Use `@app-types`, or any prefix that does not exist in the registry.

**2. Wildcard vs. bare entries are not interchangeable.** A `"@libs/*"` mapping only matches specifiers with something after the slash — `import { httpClient } from '@libs'` does **not** resolve against it. Layers consumed only through their barrel (`@hooks`, `@libs`, `@app-types`) get the bare entry. Layers where the subpath is the real address (`@features/auth`, `@components/ui`) get the `/*` entry. Declaring both forms for the same layer re-opens the deep-import door that Step 5 Rule 2 closes.

These same aliases must also exist in `vite.config.ts` and `vitest.config.ts`. Three files that have to agree is the classic source of "builds fine, tests can't resolve the module".

## Step 4: Biome Import Governance

The full configuration is written in Phase 2 — do not duplicate it here, just verify these keys landed:

```json
{
  "linter": {
    "rules": {
      "correctness": { "noUnusedImports": "error" },
      "suspicious": { "noImportCycles": "error" },
      "style": { "noRestrictedImports": { "level": "error", "options": { "patterns": ["… see Phase 2 …"] } } }
    }
  },
  "assist": { "actions": { "source": { "organizeImports": "on" } } }
}
```

`noImportCycles` belongs to **`suspicious`**, not `nursery` — it was promoted in Biome v2.0.0, and under `nursery` it is an unknown key that silently never runs. None of these rules is on by default; they run only because Phase 2 lists them explicitly.

**What each architecture rule below is actually enforced by:**

| Rule | ID | Enforced by |
| --- | --- | --- |
| Rule 1 — internal imports are relative | `REACT-ARCH-04` | `noImportCycles` (importing your own barrel closes a cycle through `index.ts`) |
| Rule 2 — external imports go through the barrel | `REACT-ARCH-05` | `noRestrictedImports` patterns |
| Rule 3 — barrel holds only exports | `REACT-ARCH-03` | review only |
| Rule 4 — `export type` for types | `REACT-ARCH-11` | review only |
| Generic layer knows no domain | `REACT-ARCH-06` | `noRestrictedImports` override on `src/components/**`, `src/hooks/**`, `src/libs/**`, `src/types/**` |
| Features never import routes | `REACT-ARCH-07` | `noRestrictedImports` override on `src/features/**` |

## Step 5: Architecture Rules

### Rule 1: Internal Import Rule (`REACT-ARCH-04`)
Inside a feature, ALWAYS use relative paths for internal imports. NEVER import from the feature's own alias or barrel.

✅ **Correct:**
```typescript
// src/features/auth/components/login-form.tsx
import { useAuth } from '../hooks/use-auth'; // Relative import
import { AuthTypes } from '../types/auth-types'; // Relative import
```

❌ **Incorrect:**
```typescript
// src/features/auth/components/login-form.tsx
import { useAuth } from '@features/auth/hooks/use-auth'; // NEVER use alias for internal
import { useAuth } from '@features/auth'; // NEVER import from barrel internally
```

### Rule 2: External Import Rule (`REACT-ARCH-05`)
When importing from other features, ALWAYS use the barrel alias.

Sibling features MAY import each other, but only through the barrel — never a deep path. When a **third** feature needs the same thing, stop importing sideways and extract it to `src/features/core/<capability>/`, then cut the direct edges (`REACT-ARCH-08`). Two consumers is a coincidence; three is a pattern. Do not create `features/core/` before that — a shared layer with no consumers becomes a dumping ground.

✅ **Correct:**
```typescript
// src/features/user-profile/components/user-card.tsx
import { useAuth } from '@features/auth'; // Import from barrel
import { Button } from '@components/ui'; // Import from barrel
import { useLocalStorage } from '@hooks'; // Import from shared
```

❌ **Incorrect:**
```typescript
// src/features/user-profile/components/user-card.tsx
import { useAuth } from '@features/auth/hooks/use-auth'; // Deep import - AVOID
import { Button } from '@components/ui/button'; // Deep import - AVOID
```

### Rule 3: Barrel File Rule (`REACT-ARCH-03`)
Barrel files (`index.ts`) must only contain `export` statements. No logic, no side effects.

✅ **Correct:**
```typescript
// src/features/auth/index.ts
export { useAuth } from './hooks/use-auth';
export { LoginForm } from './components/login-form';
export type { AuthState } from './types/auth-types';
```

❌ **Incorrect:**
```typescript
// src/features/auth/index.ts
export { useAuth } from './hooks/use-auth';

// NEVER add logic here
const initAuth = () => console.log('init');
initAuth();
```

### Rule 4: Type-Only Exports (`REACT-ARCH-11`)
Use `export type` for type exports to assist tree-shaking.

✅ **Correct:**
```typescript
export type { User } from './types/user-types';
export type { ApiResponse } from '@app-types';
```

## Step 6: Practical Example — growing a feature from an empty root

This is the pattern to repeat for every file added from now on: **open the folder, write the file, then add the line to the barrel — in that order, in one commit.**

Right now every barrel is `export {}` and no feature has a single subfolder. The block below grows `auth` from nothing. **Run it as written** — every `mkdir` is paired with the file that justifies it, in the same command, so no empty directory ever exists.

React must be a dependency before this compiles:

```bash
pnpm add react react-dom
pnpm add -D @types/react @types/react-dom typescript
```

```bash
# --- A shared primitive, so the feature has a real barrel to import from ---
cat > src/components/ui/button.tsx <<'EOF'
import type { ReactNode } from 'react'

export function Button({ children, onClick }: { children: ReactNode; onClick?: () => void }) {
  return (
    <button type="button" onClick={onClick}>
      {children}
    </button>
  )
}
EOF
cat > src/components/ui/index.ts <<'EOF'
// Public API. Only re-exports — no logic, no side effects.
export { Button } from './button'
EOF

# --- The feature opens exactly the two subfolders it needs, with their files ---
mkdir -p src/features/auth/hooks
cat > src/features/auth/hooks/use-auth.ts <<'EOF'
import { useState } from 'react'

export function useAuth() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  return {
    isAuthenticated,
    login: () => setIsAuthenticated(true),
    logout: () => setIsAuthenticated(false),
  }
}
EOF

mkdir -p src/features/auth/components
cat > src/features/auth/components/login-form.tsx <<'EOF'
import { useAuth } from '../hooks/use-auth'   // Internal: RELATIVE path (REACT-ARCH-04)
import { Button } from '@components/ui'       // External: BARREL alias (REACT-ARCH-05)

export function LoginForm() {
  const { login } = useAuth()
  return (
    <form>
      <Button onClick={login}>Login</Button>
    </form>
  )
}
EOF

# --- Only now does the barrel declare what exists ---
cat > src/features/auth/index.ts <<'EOF'
// Public API. Only re-exports — no logic, no side effects.
export { LoginForm } from './components/login-form'
EOF
```

Now normalize formatting and import order **before** verifying:

```bash
pnpm lint        # biome check --write . — applies formatting and sorts imports
pnpm lint:check  # biome check src — must now pass with zero errors
```

This two-step is not ceremony. Heredocs in a Markdown prompt cannot stay byte-identical to a formatter the project owns: this scaffold sets `indentStyle: "tab"` and `organizeImports`, while the blocks above are written with spaces and in reading order. Running `--write` once reconciles the files with the project's own configuration; `lint:check` then proves the result is clean. Never skip the second command — `pnpm lint` fixes and would exit 0 even on a genuinely broken import boundary it happened to autofix.

Three things this block demonstrates, and one it deliberately avoids:

- `api/`, `stores/` and `utils/` were **not** created — this feature has no file that belongs in them yet.
- `login-form.tsx` reaches its own hook by relative path and the shared primitive by barrel alias. Those are Rules 1 and 2 in the same file.
- The barrel exports `LoginForm` only. `useAuth` stays internal, because nothing outside the feature calls it — a small public surface is the point of the barrel, not an accident.
- **No consumer example.** Wiring `LoginForm` into a page belongs to the routing phase, not here. An `app.tsx` importing `Header`/`Footer` from a barrel that is still `export {}` would fail `tsc --noEmit` — exactly the failure the checklist below is meant to catch.

# Verification Checklist

Verify the FBA structure:

- [ ] All directories use kebab-case naming (`REACT-ARCH-12`)
- [ ] Every feature and every shared layer has an `index.ts` barrel file (`REACT-ARCH-02`)
- [ ] Barrel files contain only export statements (`REACT-ARCH-03`)
- [ ] **No empty directories** — every folder that exists holds at least one file
- [ ] **No barrel re-exports a module that does not exist** — the project typechecks
- [ ] No subfolders were pre-created inside a feature
- [ ] Feature directory names match the barrels in Step 2 and the mkdir in Step 1
- [ ] `src/libs` is plural, matching the `@libs` alias
- [ ] No `@types/*` alias exists — it is `@app-types`
- [ ] Barrel-only layers (`@hooks`, `@libs`, `@app-types`) use the **bare** paths entry, not `/*`
- [ ] `tsconfig.json` has NO `baseUrl` — TypeScript 7 removed it and `tsc` errors out (TS5102)
- [ ] The same aliases exist in `tsconfig.json`, `vite.config.ts` AND `vitest.config.ts`. If those two files do not exist yet, this item is **unverified**, not passed — do not tick it
- [ ] `noImportCycles` is under `suspicious`, not `nursery`
- [ ] `noRestrictedImports` overrides exist for `src/features/**` and for the generic layers
- [ ] Example files demonstrate correct import patterns

**Verification Command:**
Every check below either prints nothing on success or asserts explicitly. A command that only lists files proves nothing — do not treat `find src -type d` as a passing check.

```bash
fail=0
chk() { if [ -z "$2" ]; then echo "✅ $1"; else echo "❌ $1"; echo "$2"; fail=1; fi }

# --- Structure ---
chk "no empty directories"        "$(find src -type d -empty)"
chk "kebab-case only"             "$(find src -name '*[A-Z_]*' -not -path '*/node_modules/*')"
chk "no pre-created subfolders"   "$(find src/features -mindepth 2 -type d -empty)"

# --- Barrels: one per module root ---
for m in src/features/* src/components/ui src/components/layout src/hooks src/libs src/types; do
  [ -d "$m" ] && [ ! -f "$m/index.ts" ] && { echo "❌ missing barrel: $m/index.ts"; fail=1; }
done

# --- Aliases: these are the checklist items no `find` can confirm ---
chk "no baseUrl (removed in TS 7)"  "$(grep -n '\"baseUrl\"' tsconfig.json)"
chk "no @types/* alias"             "$(grep -n '\"@types/' tsconfig.json)"
chk "@libs is bare, not @libs/*"    "$(grep -n '\"@libs/\*\"\|\"@hooks/\*\"\|\"@app-types/\*\"' tsconfig.json)"
for a in @features @components @hooks @libs @app-types; do
  grep -q "\"$a" tsconfig.json || { echo "❌ alias missing from tsconfig: $a"; fail=1; }
done
# vite/vitest must agree with tsconfig — only checkable if they exist
for f in vite.config.ts vitest.config.ts; do
  if [ -f "$f" ]; then
    for a in @features @components @libs; do
      grep -q "$a" "$f" || { echo "❌ $a declared in tsconfig but not in $f"; fail=1; }
    done
  else
    echo "⚠️  $f absent — alias parity UNVERIFIED, not passed"
  fi
done

# --- Compilation: catches barrels re-exporting files that were never written ---
pnpm tsc --noEmit || fail=1

# --- Import boundaries: non-mutating. NOT `pnpm lint`, which rewrites files ---
pnpm lint:check || fail=1

[ "$fail" -eq 0 ] && echo "PHASE 5 OK" || echo "PHASE 5 FAILED"
```

**Failure Recovery:**
- Empty directory found → delete it. Recreate it when a file goes into it.
- `tsc` cannot resolve a module re-exported by a barrel → the barrel got ahead of the code. Remove the export line, or write the file it points at.
- Structure doesn't match → recreate directories with correct kebab-case names.

# Output Format

Provide a concise summary including:
1. Directory structure created
2. Confirmation that all barrel files exist
3. Confirmation that anti-cycle rules are documented
4. Status: "✅ FBA Structure Complete - All Phases Finished"

# Error Handling

If any command fails:
1. Stop execution immediately
2. Report the exact error message
3. Do not proceed to next steps

# Troubleshooting

**Issue:** Biome reports import cycle errors
**Solution:** Check that you're not importing from a barrel file inside the same feature. Use relative imports for internal feature imports.

**Issue:** TypeScript can't resolve `@features/*` aliases
**Solution:** Verify paths in tsconfig.json match the directory structure exactly.

**Issue:** `import { httpClient } from '@libs'` fails, but `'@libs/http-client'` works
**Solution:** The paths entry is `"@libs/*"`, which only matches specifiers with a subpath. Add the bare entry `"@libs": ["./src/libs"]`. Same for `@hooks` and `@app-types`.

**Issue:** `@types/node` or another declaration package stops resolving
**Solution:** A `paths` alias named `@types/*` is shadowing the npm scope, because `paths` resolves before `node_modules`. Rename it to `@app-types`.

**Issue:** Tests can't find modules with path aliases
**Solution:** Ensure vitest.config.ts resolve.alias matches tsconfig.json paths.

**Issue:** Biome accepts the config but never flags a deep import
**Solution:** Check that `noImportCycles` is under `suspicious` (not `nursery`) and that `noRestrictedImports` is present. Neither is enabled by default. If the file lives under an `overrides` entry, remember overrides are first-match-wins and replace the top-level rule — the pattern has to be repeated inside that override.
