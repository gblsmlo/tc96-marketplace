import { createRoute, useNavigate } from '@tanstack/react-router'
import { useEffect } from 'react'
import { useAuth } from '../auth'
import { rootRoute } from './root'

function SettingsPage() {
  const auth = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    if (!auth.user) navigate({ to: '/login' })
  }, [auth.user, navigate])

  if (!auth.user) return null
  return <h1>Settings for {auth.user.name}</h1>
}

export const settingsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/settings',
  component: SettingsPage,
})
