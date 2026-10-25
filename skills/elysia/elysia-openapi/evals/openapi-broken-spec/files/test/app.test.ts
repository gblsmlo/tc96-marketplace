import { test, expect } from 'bun:test'
import { app } from '../src/app'

test('lists orders', async () => {
  const res = await app.handle(new Request('http://localhost/orders'))
  expect(res.status).toBe(200)
})
