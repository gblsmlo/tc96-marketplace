import { test, expect } from 'bun:test'
import { QueryClient } from '@tanstack/query-core'
import { app } from '../server/app'
import { createApi } from './api'
import { createOrderMutation } from './create-order'

const api = createApi('http://localhost', ((input: RequestInfo | URL, init?: RequestInit) => app.handle(new Request(input, init))) as typeof fetch)

test('creates an order', async () => {
  const m = createOrderMutation(new QueryClient(), api)
  const order = await m.mutate({ sku: 'ABC-1', quantity: 1 })
  expect(order?.sku).toBe('ABC-1')
})
