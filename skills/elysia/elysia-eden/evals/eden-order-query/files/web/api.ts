import { treaty } from '@elysia/eden'
import { App } from '../server/app'

export const createApi = (baseUrl: string, fetcher?: typeof fetch) =>
  treaty<App>(baseUrl, fetcher ? { fetcher } : {})

export const api = createApi('http://localhost:3000')
