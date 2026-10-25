import { createContext, useContext, useState, type ReactNode } from 'react'
import { request } from './http'

export interface User {
  id: string
  name: string
}

export interface Auth {
  user: User | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<Auth | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)

  async function login(email: string, password: string) {
    const res = await request('/session', { method: 'POST', body: JSON.stringify({ email, password }) })
    if (!res.ok) throw new Error('Invalid credentials')
    setUser((await res.json()) as User)
  }

  return <AuthContext.Provider value={{ user, login, logout: () => setUser(null) }}>{children}</AuthContext.Provider>
}

export function useAuth(): Auth {
  const auth = useContext(AuthContext)
  if (!auth) throw new Error('useAuth outside AuthProvider')
  return auth
}
