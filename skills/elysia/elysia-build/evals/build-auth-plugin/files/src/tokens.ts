export type User = { id: number; name: string; role: 'admin' | 'member' }

export const tokens = new Map<string, User>([
  ['tok-ana', { id: 1, name: 'Ana', role: 'admin' }],
  ['tok-bob', { id: 2, name: 'Bob', role: 'member' }],
])
