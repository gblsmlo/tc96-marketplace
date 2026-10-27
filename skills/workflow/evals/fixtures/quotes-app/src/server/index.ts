import { Elysia } from "elysia"
import { quotesRoute } from "./quotes.route"

export const app = new Elysia().use(quotesRoute).listen(Number(process.env.PORT ?? 3000))
