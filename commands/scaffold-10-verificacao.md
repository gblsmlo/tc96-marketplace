---
nome: scaffold-10-verificacao
descricao: Fase 10 — verificação final do scaffold
tipo: comando
idioma: en
---
# Phase 10: Final Verification Suite

**Role:** Senior Frontend Architect & DevOps Engineer
**Objective:** Run complete validation to ensure zero errors.

**Priority:** CRITICAL - Final validation
**Constraint:** All checks must pass before considering scaffolding complete

---

## Commands

```bash
# Install dependencies
bun install

# Lint check
bunx biome check --write src

# Type check — the Bun runtime transpiles without checking types (`BUN-CORE-02`).
# Without this step the build is green and the types mean nothing.
bunx tsc --noEmit

# Test execution
bun run test:run

# Build verification
bun run build
```

---

## Final Checklist

- [ ] `docs/` directory is present and intact
- [ ] `.agent/` directory is present and intact
- [ ] All biome checks pass (0 errors, 0 warnings)
- [ ] `bunx tsc --noEmit` passes (`BUN-CORE-02`)
- [ ] `bun.lock` is committed (`BUN-PKG-01`) — CI must run `bun ci`, not `bun install`
- [ ] All tests pass (0 failures)
- [ ] Build succeeds with no errors
- [ ] No data loss occurred during scaffolding
- [ ] Git hooks are configured and executable with lint-staged
- [ ] lint-staged is configured with error handling in pre-commit hook
- [ ] Path aliases work in all contexts — one map, in `tsconfig.json`: `bun test` and TanStack Start both read it
- [ ] Shadcn UI components are properly configured
- [ ] WorkOS AuthKit is properly integrated

---

## Success Criteria

The scaffolding is complete when:
1. All 10 phases are executed in order
2. All verification checkpoints pass
3. Final checklist shows 13/13 items checked
4. No errors in any validation command
5. Existing documentation and agent configs are preserved
6. FBA structure is properly implemented
7. lint-staged is configured with proper error handling
8. Shadcn UI replaces Radix UI Themes
9. Biome is the only linting/formatting tool (no ESLint/Prettier)

---

## Emergency Rollback

If any phase fails critically:
```bash
# Restore from backup
rm -rf node_modules .vinxi .output dist build
mv /tmp/project-backup-*/* . 2>/dev/null || true
# Re-run from Phase 0
```

---

## Post-Execution: Documentation Scaffolding

Upon successful completion of all phases, create the following documentation structure:

```bash
mkdir -p docs/plans docs/rules docs/skills docs/workflows docs/logs
echo "# Task Plans" > docs/plans/README.md
echo "# Project Rules" > docs/rules/README.md
echo "# Agent Skills" > docs/skills/README.md
echo "# Workflows" > docs/workflows/README.md
```

---

## Technology Stack Summary

- **Framework**: TanStack Start with TanStack Router
- **UI**: Shadcn UI + Tailwind CSS
- **Auth**: WorkOS AuthKit
- **Lint/Format**: Biome (no ESLint/Prettier)
- **Testing**: `bun test` + happy-dom + React Testing Library
- **Git Hooks**: Husky + lint-staged + Commitlint
- **Package Manager**: bun
