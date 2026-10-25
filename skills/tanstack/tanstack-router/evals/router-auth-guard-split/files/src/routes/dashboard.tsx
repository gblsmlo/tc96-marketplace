import { createRoute } from '@tanstack/react-router'
import { Charts } from '../features/dashboard/Charts'
import { request } from '../http'
import { rootRoute } from './root'

function DashboardPage() {
  const { series } = dashboardRoute.useLoaderData()
  return <Charts series={series} />
}

export const dashboardRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/dashboard',
  loader: async ({ abortController }) => {
    const res = await request('/dashboard/revenue', { signal: abortController.signal })
    if (!res.ok) throw new Error(`GET /dashboard/revenue failed: ${res.status}`)
    return (await res.json()) as { series: number[] }
  },
  errorComponent: () => <p>Could not load the dashboard.</p>,
  component: DashboardPage,
})
