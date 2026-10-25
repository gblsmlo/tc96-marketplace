import { QueryClient } from '@tanstack/react-query'

// too many requests on every tab switch, see #412
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: { refetchOnWindowFocus: false },
  },
})
