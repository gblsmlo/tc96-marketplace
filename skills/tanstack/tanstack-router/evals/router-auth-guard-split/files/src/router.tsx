import { createRouter } from '@tanstack/react-router'
import { dashboardRoute } from './routes/dashboard'
import { homeRoute } from './routes/home'
import { invoicesRoute } from './routes/invoices'
import { loginRoute } from './routes/login'
import { rootRoute } from './routes/root'
import { settingsRoute } from './routes/settings'

const routeTree = rootRoute.addChildren([homeRoute, loginRoute, invoicesRoute, dashboardRoute, settingsRoute])

export const router = createRouter({ routeTree })

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
