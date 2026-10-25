export interface Order {
  id: string
  number: string
  total: number
  createdAt: string
}

export interface OrdersPage {
  items: Order[]
  total: number
  hasMore: boolean
}

export interface ActivityEvent {
  id: string
  message: string
  at: string
}

export interface ActivityPage {
  events: ActivityEvent[]
  nextCursor: string | null
}
