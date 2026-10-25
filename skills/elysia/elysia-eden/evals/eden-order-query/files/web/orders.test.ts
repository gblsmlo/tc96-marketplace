import { test, expect } from 'bun:test'
import { QueryClient } from '@tanstack/query-core'
import { app } from '../server/app'
import { createApi } from './api'
import { orderQuery } from './orders'

const api = createApi('http://localhost', ((input: RequestInfo | URL, init?: RequestInit) => app.handle(new Request(input, init))) as typeof fetch)

test('loads an order', async () => {
  const client = new QueryClient()
  const result = await client.fetchQuery(orderQuery(api, 1))
  expect(result.data?.sku).toBe('SKU-1')
})
