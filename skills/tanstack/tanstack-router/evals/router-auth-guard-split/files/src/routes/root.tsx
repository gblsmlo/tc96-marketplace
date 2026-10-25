import { createRootRoute, Link, Outlet } from '@tanstack/react-router'

export const rootRoute = createRootRoute({
  component: () => (
    <>
      <nav>
        <Link to="/">Home</Link> <Link to="/invoices">Invoices</Link> <Link to="/dashboard">Dashboard</Link>{' '}
        <Link to="/settings">Settings</Link>
      </nav>
      <Outlet />
    </>
  ),
})
