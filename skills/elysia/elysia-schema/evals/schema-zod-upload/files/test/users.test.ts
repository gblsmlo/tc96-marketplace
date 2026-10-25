import { test, expect } from 'bun:test'
import { app } from '../src/app'

test('signs up', async () => {
  const res = await app.handle(new Request('http://localhost/users', {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ name: 'Ana', email: 'ana@example.com', password: 'correct-horse-battery' }),
  }))
  expect(res.status).toBe(201)
})
