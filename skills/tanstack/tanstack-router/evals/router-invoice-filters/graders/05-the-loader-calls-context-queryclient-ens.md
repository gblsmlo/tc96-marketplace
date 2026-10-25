---
type: llm
focus: trace
weight: 1
---

The loader warms the cache with a cache-respecting read (context.queryClient.ensureQueryData, or queryClient.query with staleTime: 'static') using the same queryOptions object (or factory) the component passes to useQuery or useSuspenseQuery, and that key includes status, page and sort
