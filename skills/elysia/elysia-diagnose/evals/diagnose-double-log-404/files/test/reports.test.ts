import { test, expect } from 'bun:test'
import { app } from '../src/app'

test('GET /reports returns revenue', async () => {
  await app.modules
  const res = await app.handle(new Request('http://x/reports'))
  expect(res.status).toBe(200)
  expect(await res.json()).toEqual({ revenue: 1200 })
})
