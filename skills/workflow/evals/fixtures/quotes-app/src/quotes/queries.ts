import { queryOptions } from "@tanstack/react-query"

export const quotesQuery = queryOptions({
  queryKey: ["quotes"],
  queryFn: async () => (await fetch("/quotes")).json(),
})
