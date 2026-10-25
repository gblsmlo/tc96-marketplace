import { test, expect } from 'bun:test'
import { app } from '../src/app'

test('catalog reports stock', async () => {
  const res = await app.handle(new Request('http://localhost/catalog/ABC-1'))
  expect(await res.json()).toEqual({ sku: 'ABC-1', available: 5 })
})
