import { test, expect } from 'bun:test'
import { auth } from '../src/auth'

test('auth rejects a request without a token', async () => {
  const res = await auth.handle(new Request('http://localhost/auth/me'))
  expect(res.status).not.toBe(200)
})

test('auth accepts a valid token', async () => {
  const res = await auth.handle(new Request('http://localhost/auth/me', { headers: { authorization: 'Bearer tok-valid' } }))
  expect(res.status).toBe(200)
})
