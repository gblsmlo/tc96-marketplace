import { useEffect, useState } from 'react'
import { request } from '../../http'
import type { ActivityEvent, ActivityPage } from '../../types'

export function ActivityFeed() {
  const [events, setEvents] = useState<ActivityEvent[]>([])
  const [cursor, setCursor] = useState<string | null>(null)
  const [hasMore, setHasMore] = useState(true)

  async function load(from: string | null) {
    const res = await request(`/activity${from ? `?cursor=${from}` : ''}`)
    const page: ActivityPage = await res.json()
    setEvents((prev) => [...prev, ...page.events])
    setCursor(page.nextCursor)
    setHasMore(page.nextCursor !== null)
  }

  useEffect(() => {
    load(null)
  }, [])

  return (
    <aside>
      <ul>
        {events.map((event) => (
          <li key={event.id}>
            {event.at} {event.message}
          </li>
        ))}
      </ul>
      {hasMore && (
        <button type="button" onClick={() => load(cursor)}>
          Load more
        </button>
      )}
    </aside>
  )
}
