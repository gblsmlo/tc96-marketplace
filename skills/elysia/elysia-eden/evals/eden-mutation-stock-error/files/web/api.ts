import { treaty } from '@elysia/eden'
import type { App } from '../server/app'

export const createApi = (baseUrl: string, fetcher?: typeof fetch) =>
  treaty<App>(baseUrl, { parseDate: false, ...(fetcher ? { fetcher } : {}) })
