export type OrderStatus = 'open' | 'shipped' | 'cancelled'

export interface Order {
  id: string
  number: string
  status: OrderStatus
  total: number
}

export interface Customer {
  id: string
  name: string
}
