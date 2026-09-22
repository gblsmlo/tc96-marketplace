---
nome: scaffold-06-shadcn
descricao: Fase 6 — shadcn/ui e tokens de design
tipo: comando
idioma: en
---
# Phase 6: Shadcn UI Integration

**Role:** Senior Frontend Architect & DevOps Engineer
**Objective:** Initialize Shadcn UI and configure for FBA compliance.

**Priority:** High - UI foundation
**Constraint:** Components must use FBA path aliases

---

## Commands

```bash
pnpm dlx shadcn@latest init -d
pnpm dlx shadcn@latest add button card badge input -y
```

---

## Configuration

Create `components.json`:

```bash
cat > components.json <<'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "src/app.css",
    "baseColor": "zinc",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@components",
    "utils": "@libs/utils",
    "ui": "@components/ui"
  }
}
EOF
```

---

## Path Corrections

```bash
# Ensure libs is used (not lib) for FBA compliance
mkdir -p src/libs

# Fix import paths in shadcn components to use FBA structure
# Components will be placed in src/components/ui/
```

---

## Verification Checkpoint

- [ ] `src/libs/utils.ts` exists (cn function)
- [ ] `src/components/ui/` contains shadcn components
- [ ] All UI component imports reference `@libs/utils`
- [ ] `components.json` has correct aliases for FBA

---

## Next Phase

After verification, proceed to **Phase 7: WorkOS AuthKit Integration**
