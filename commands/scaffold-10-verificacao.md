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
pnpm install

# Lint check
pnpm biome check --write src

# Test execution
pnpm test:run

# Build verification
pnpm build
```

---

## Final Checklist

- [ ] `docs/` directory is present and intact
- [ ] `.agent/` directory is present and intact
- [ ] All biome checks pass (0 errors, 0 warnings)
- [ ] All tests pass (0 failures)
- [ ] Build succeeds with no errors
- [ ] No data loss occurred during scaffolding
- [ ] Git hooks are configured and executable with lint-staged
- [ ] lint-staged is configured with error handling in pre-commit hook
- [ ] Path aliases work in all contexts (TypeScript, Vitest, TanStack Start)
- [ ] Shadcn UI components are properly configured
- [ ] WorkOS AuthKit is properly integrated

---

## Success Criteria

The scaffolding is complete when:
1. All 10 phases are executed in order
2. All verification checkpoints pass
3. Final checklist shows 11/11 items checked
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
- **Testing**: Vitest + React Testing Library
- **Git Hooks**: Husky + lint-staged + Commitlint
- **Package Manager**: pnpm
