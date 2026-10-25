export type InvoiceStatus = 'pending' | 'approved' | 'rejected'

export interface Invoice {
  id: string
  customerId: string
  number: string
  amount: number
  status: InvoiceStatus
}

export interface InvoiceSummary {
  pendingCount: number
  pendingTotal: number
}

export interface Customer {
  id: string
  name: string
}
