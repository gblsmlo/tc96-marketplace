import type { QueryClient } from '@tanstack/react-query'
import { createRootRouteWithContext, Link, Outlet } from '@tanstack/react-router'

export const rootRoute = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  component: () => (
    <>
      <nav>
        <Link to="/invoices">Invoices</Link>
      </nav>
      <Outlet />
    </>
  ),
})
