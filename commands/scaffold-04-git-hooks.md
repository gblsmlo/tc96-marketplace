---
nome: scaffold-04-git-hooks
descricao: Fase 4 — git hooks e portões de commit
tipo: comando
idioma: en
---
# Phase 4: Git & Hooks Setup

**Role:** Senior Frontend Architect & DevOps Engineer
**Objective:** Initialize Git, Husky, lint-staged, and Commitlint.

**Priority:** High - Version control foundation
**Constraint:** Proper error handling in pre-commit hooks

---
## Commands

```bash
git init
pnpm add -D husky lint-staged @commitlint/cli @commitlint/config-conventional
pnpm exec husky init
```

---
## Configuration

### 4.1: Pre-commit Hook

```bash
cat > .husky/pre-commit <<'EOF'
pnpm lint-staged

# Run lint-staged with error handling
if ! pnpm lint-staged; then
  echo "❌ Pre-commit checks failed. Please fix the issues above and try again."
  echo "💡 You can run 'pnpm biome check --write src' to fix issues automatically."
  exit 1
fi

echo "✅ Pre-commit checks passed!"
EOF
chmod +x .husky/pre-commit
```

### 4.2: Commit Message Hook

```bash
echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
chmod +x .husky/commit-msg
```

### 4.3: Commitlint Configuration

```bash
cat > .commitlintrc.json <<'EOF'
{
  "extends": ["@commitlint/config-conventional"]
}
EOF
```

---

## Verification Checkpoint

- [ ] `.husky/pre-commit` hook exists and is executable with lint-staged error handling
- [ ] `.husky/commit-msg` hook exists and is executable
- [ ] `.commitlintrc.json` extends conventional config

---

## Next Phase

After verification, proceed to **Phase 5: FBA Directory Structure**
