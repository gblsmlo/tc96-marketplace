import { useNavigate } from '@tanstack/react-router'
import { useEffect } from 'react'

export function AccountPage({ userId }: { userId: string | null }) {
  const navigate = useNavigate()

  useEffect(() => {
    if (!userId) navigate({ to: '/login' })
  }, [userId, navigate])

  return userId ? <h1>Account {userId}</h1> : null
}
