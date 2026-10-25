import type { Database } from './db/client'

export type SearchFilters = {
  tag?: string
  authorId?: number
  q?: string
  limit?: number
}

export type SearchResult = {
  id: number
  title: string
  publishedAt: Date
  author: { id: number; name: string }
  tags: string[]
}

/** GET /search — TODO */
export async function searchPosts(db: Database, filters: SearchFilters): Promise<SearchResult[]> {
  throw new Error('not implemented')
}
