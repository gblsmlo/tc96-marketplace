import { createRoute, useNavigate } from '@tanstack/react-router'
import { useState, type FormEvent } from 'react'
import { useAuth } from '../auth'
import { rootRoute } from './root'

function LoginPage() {
  const auth = useAuth()
  const navigate = useNavigate()
  const [error, setError] = useState<string | null>(null)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    try {
      await auth.login(String(form.get('email')), String(form.get('password')))
      navigate({ to: '/' })
    } catch {
      setError('Invalid credentials')
    }
  }

  return (
    <form onSubmit={onSubmit}>
      <input name="email" type="email" />
      <input name="password" type="password" />
      {error && <p role="alert">{error}</p>}
      <button type="submit">Sign in</button>
    </form>
  )
}

export const loginRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/login',
  component: LoginPage,
})
