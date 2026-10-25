import { createRoute } from '@tanstack/react-router'
import { rootRoute } from './root'

export const homeRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: () => <h1>Welcome</h1>,
})
