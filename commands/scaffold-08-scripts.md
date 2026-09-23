---
nome: scaffold-08-scripts
descricao: Fase 8 — scripts de package e tarefas do projeto
tipo: comando
idioma: en
---
# Phase 8: Package.json Scripts

**Role:** Senior Frontend Architect & DevOps Engineer
**Objective:** Ensure all required package scripts and lint-staged configuration are present.

**Priority:** High - Build and development scripts
**Constraint:** Preserve existing scripts, add missing ones

---

## Commands

```bash
bun -e "
const pkg = await Bun.file('package.json').json();
pkg.scripts = {
  ...pkg.scripts,
  'dev': 'vinxi dev',
  'build': 'vinxi build',
  'start': 'vinxi start',
  'preview': 'vinxi preview',
  'lint': 'biome check src',
  'lint:fix': 'biome check --write src',
  'lint:format': 'biome format --write src',
  'lint:staged': 'biome check src --staged --write',
  'typecheck': 'tsc --noEmit',
  'test': 'bun test --watch',
  'test:run': 'bun test',
  'prepare': 'husky'
};
pkg['lint-staged'] = {
  '*.{js,ts,cjs,mjs,d.cts,d.mts,jsx,tsx,json,jsonc}': [
    'bun run lint:staged --no-errors-on-unmatched'
  ]
};
pkg.husky = {
  hooks: {
    'pre-commit': 'lint-staged'
  }
};
await Bun.write('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
```

---

## Script Reference

### Development Scripts
- `dev` - Start development server
- `build` - Build for production
- `start` - Start production server
- `preview` - Preview production build

### Linting Scripts
- `lint` - Check code with Biome
- `lint:fix` - Fix issues automatically
- `lint:format` - Format code
- `lint:staged` - Check staged files

### Type Check
- `typecheck` - `tsc --noEmit`. The Bun runtime transpiles **without checking a single
  type** (`BUN-CORE-02`), so without this step in CI the project's types are decorative.

### Testing Scripts
- `test` - `bun test --watch`
- `test:run` - `bun test`, one pass

There is no `test:ui`: `bun test` has no UI runner.

### Git Hooks
- `prepare` - Initialize Husky

---

## lint-staged Configuration

```json
{
  "*.{js,ts,cjs,mjs,d.cts,d.mts,jsx,tsx,json,jsonc}": [
    "bun run lint:staged --no-errors-on-unmatched"
  ]
}
```

---

## Verification Checkpoint

- [ ] All scripts are present in `package.json`
- [ ] `lint-staged` configuration exists in `package.json`
- [ ] `husky.hooks.pre-commit` is configured
- [ ] Original scripts (dev, build, start, preview) are preserved

---

## Next Phase

After verification, proceed to **Phase 9: Example Feature Implementation**
