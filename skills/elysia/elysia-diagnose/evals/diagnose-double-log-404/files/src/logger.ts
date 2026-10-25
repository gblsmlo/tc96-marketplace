import { Elysia } from 'elysia'

export const requestLog: string[] = []

export const logger = new Elysia()
  .onAfterResponse({ as: 'global' }, function logRequest({ request, set }) {
    requestLog.push(`${request.method} ${new URL(request.url).pathname} ${set.status ?? 200}`)
  })
