---
nome: scaffold-09-feature-exemplo
descricao: Fase 9 — feature de exemplo ponta a ponta
tipo: comando
idioma: en
---
# Phase 9: Example Feature Implementation

**Role:** Senior Frontend Architect & DevOps Engineer
**Objective:** Create complete example feature following FBA standards.

**Priority:** Medium - Demonstrate FBA patterns
**Constraint:** Use path aliases, index files, and FBA structure

---

## Files to Create

### 9.1: Auth Feature Types

```bash
cat > src/features/auth/types/index.ts <<'EOF'
import type { User } from '@workos/authkit-tanstack-react-start';

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
}

export interface SignInButtonProps {
  large?: boolean;
  user: User | null;
  url: string;
}
EOF
```

---

### 9.2: Auth Feature Components

```bash
cat > src/features/auth/components/sign-in-button.tsx <<'EOF'
import { Button, Flex } from '@radix-ui/themes';
import { Link } from '@tanstack/react-router';
import type { User } from '@workos/authkit-tanstack-react-start';

interface SignInButtonProps {
  large?: boolean;
  user: User | null;
  url: string;
}

export function SignInButton({ large, user, url }: SignInButtonProps) {
  if (user) {
    return (
      <Flex gap="3">
        <Button asChild size={large ? '3' : '2'}>
          <Link to="/logout" reloadDocument>
            Sign Out
          </Link>
        </Button>
      </Flex>
    );
  }

  return (
    <Button asChild size={large ? '3' : '2'}>
      <a href={url}>Sign In{large && ' with AuthKit'}</a>
    </Button>
  );
}
EOF
```

```bash
cat > src/features/auth/components/index.ts <<'EOF'
export * from './sign-in-button';
EOF
```

---
### 9.3: Shared Layout Components

```bash
cat > src/components/layout/footer.tsx <<'EOF'
import { Card, Grid, Heading, Text } from '@radix-ui/themes';

export function Footer() {
  return (
    <Grid columns={{ initial: '1', sm: '3' }} gap={{ initial: '3', sm: '5' }}>
      <Card size="4" asChild variant="classic">
        <a href="https://workos.com/docs" rel="noreferrer" target="_blank">
          <Heading size="4" mb="1">
            Documentation
          </Heading>
          <Text color="gray">View integration guides and SDK documentation.</Text>
        </a>
      </Card>
      <Card size="4" asChild variant="classic">
        <a href="https://workos.com/docs/reference" rel="noreferrer" target="_blank">
          <Heading size="4" mb="1">
            API Reference
          </Heading>
          <Text color="gray">Every WorkOS API method and endpoint documented.</Text>
        </a>
      </Card>
      <Card size="4" asChild variant="classic">
        <a href="https://workos.com" rel="noreferrer" target="_blank">
          <Heading size="4" mb="1">
            WorkOS
          </Heading>
          <Text color="gray">Learn more about other WorkOS products.</Text>
        </a>
      </Card>
    </Grid>
  );
}
EOF
```

```bash
cat > src/components/layout/index.ts <<'EOF'
export * from './footer';
EOF
```

---
### 9.4: Shared Utilities

```bash
cat > src/libs/utils.ts <<'EOF'
export function cn(...classes: (string | undefined | null | false)[]): string {
  return classes.filter(Boolean).join(' ');
}
EOF
```

---
## FBA Import Order Pattern

Organize imports in this order:
1. React/TanStack imports
2. Third-party libraries (WorkOS)
3. Feature imports (`@features/*`)
4. Shared imports (`@components/*`, `@libs/*`, `@types/*`, `@hooks/*`)
5. Relative imports (`./`, `../`)
6. Type-only imports

---
## Verification Checkpoint

- [ ] Auth feature is properly structured
- [ ] Components use FBA path aliases
- [ ] Index files export all public APIs
- [ ] Shared utilities are in `src/libs/`

---

## Next Phase

After verification, proceed to **Phase 10: Final Verification Suite**
