---
nome: scaffold-07-workos-authkit
descricao: Fase 7 — autenticação com WorkOS AuthKit
tipo: comando
idioma: en
---
# Phase 7: WorkOS AuthKit Integration

**Role:** Senior Frontend Architect & DevOps Engineer
**Objective:** Configure WorkOS AuthKit with TanStack Start middleware.

**Priority:** High - Authentication foundation
**Constraint:** Proper middleware integration with protected routes

---

## Commands

```bash
bun add @workos/authkit-tanstack-react-start
```

---

## Configuration

### 7.1: Start Instance with AuthKit Middleware

```bash
cat > src/start.ts <<'EOF'
import { createStart } from '@tanstack/react-start';
import { authkitMiddleware } from '@workos/authkit-tanstack-react-start';

/**
 * Configure TanStack Start with AuthKit middleware.
 * The middleware runs on every server request and provides auth context.
 */
export const startInstance = createStart(() => {
  return {
    // Run AuthKit middleware on every request
    requestMiddleware: [authkitMiddleware()],
  };
});
EOF
```

### 7.2: Router Configuration

```bash
cat > src/router.tsx <<'EOF'
import { createRouter } from '@tanstack/react-router';
import { routeTree } from './routeTree.gen';

export function getRouter() {
  const router = createRouter({
    routeTree,
    scrollRestoration: true,
  });

  return router;
}
EOF
```

### 7.3: Protected Route Layout

```bash
cat > src/routes/_authenticated.tsx <<'EOF'
import { createFileRoute, redirect } from "@tanstack/react-router";
import { getAuth, getSignInUrl } from "@workos/authkit-tanstack-react-start";

export const Route = createFileRoute("/_authenticated")({
  loader: async ({ location }) => {
    // Loader runs on server (even during client-side navigation via RPC)
    const { user } = await getAuth();

    if (!user) {
      const path = location.pathname;
      const href = await getSignInUrl({ data: { returnPathname: path } });

      throw redirect({ href });
    }
  },
});
EOF
```

### 7.4: Root Layout with AuthProvider

```bash
cat > src/routes/__root.tsx <<'EOF'
import { Box, Button, Card, Container, Flex } from '@radix-ui/themes';
import { HeadContent, Link, Outlet, Scripts, createRootRoute } from '@tanstack/react-router';
import { TanStackRouterDevtools } from '@tanstack/react-router-devtools';
import { Suspense } from 'react';
import { getSignInUrl } from '@workos/authkit-tanstack-react-start';
import { AuthKitProvider, getAuthAction } from '@workos/authkit-tanstack-react-start/client';
import { Footer } from '@components/layout';
import { SignInButton } from '@features/auth/components';
import appCssUrl from '../app.css?url';
import type { ReactNode } from 'react';

export const Route = createRootRoute({
  head: () => ({
    meta: [
      {
        charSet: 'utf-8',
      },
      {
        name: 'viewport',
        content: 'width=device-width, initial-scale=1',
      },
      {
        title: 'AuthKit Example in TanStack Start',
      },
    ],
    links: [{ rel: 'stylesheet', href: appCssUrl }],
  }),
  loader: async () => {
    const auth = await getAuthAction();
    const url = await getSignInUrl();
    return {
      auth,
      url,
    };
  },
  component: RootComponent,
  notFoundComponent: () => <div>Not Found</div>,
});

function RootComponent() {
  const { auth, url } = Route.useLoaderData();
  return (
    <RootDocument>
      <AuthKitProvider initialAuth={auth}>
        <Container>
          <Flex direction="column" gap="5" p="5" height="100vh">
            <Box asChild flexGrow="1">
              <Card size="4">
                <Flex direction="column" height="100%">
                  <Flex asChild justify="between">
                    <header>
                      <Flex gap="4">
                        <Button asChild variant="soft">
                          <Link to="/">Home</Link>
                        </Button>
                        <Button asChild variant="soft">
                          <Link to="/account">Account</Link>
                        </Button>
                      </Flex>
                      <Suspense fallback={<div>Loading...</div>}>
                        <SignInButton user={auth.user} url={url} />
                      </Suspense>
                    </header>
                  </Flex>
                  <Flex flexGrow="1" align="center" justify="center">
                    <main>
                      <Outlet />
                    </main>
                  </Flex>
                </Flex>
              </Card>
            </Box>
            <Footer />
          </Flex>
        </Container>
        <TanStackRouterDevtools position="bottom-right" />
      </AuthKitProvider>
    </RootDocument>
  );
}

function RootDocument({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  );
}
EOF
```

---

## Verification Checkpoint

- [ ] WorkOS AuthKit is installed
- [ ] `src/start.ts` has AuthKit middleware
- [ ] `src/routes/_authenticated.tsx` protects routes
- [ ] Root layout provides AuthKit context

---

## Next Phase

After verification, proceed to **Phase 8: Package.json Scripts**
