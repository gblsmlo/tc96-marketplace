import { test, expect } from 'bun:test'
import { app } from '../src/app'

test('lists orders for a tenant', async () => {
  const res = await app.handle(new Request('http://localhost/orders?page=1&pageSize=2', { headers: { 'X-Tenant': 'acme' } }))
  expect(res.status).toBe(200)
})
