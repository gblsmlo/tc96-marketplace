import { Elysia, t } from "elysia"
import { eq } from "drizzle-orm"
import { authMiddleware, requireRole } from "./auth"
import { verifyLink } from "../quotes/link"
import { db } from "../db/client"
import { quotes } from "../db/schema"

export const quotesRoute = new Elysia({ prefix: "/quotes" })
  .use(authMiddleware)
  .get("/", async ({ user }) => db.select().from(quotes).where(eq(quotes.sellerId, user!.id)), {
    beforeHandle: requireRole("seller"),
  })
  .post(
    "/:id/decision",
    async ({ params, body, error }) => {
      const [quote] = await db.select().from(quotes).where(eq(quotes.id, params.id))
      if (!quote) return error(404)
      if (quote.status !== "pending") return error(409)
      const status = body.decision === "approve" ? "approved" : "rejected"
      const [saved] = await db.update(quotes).set({ status, decidedAt: new Date() })
        .where(eq(quotes.id, params.id)).returning()
      return saved
    },
    {
      query: t.Object({ token: t.String() }),
      body: t.Object({ decision: t.Union([t.Literal("approve"), t.Literal("reject")]) }),
      // the customer has no session: the signed link is the credential (AC-01, ADR-0001)
      beforeHandle: ({ params, query, error }) => {
        const link = verifyLink(query.token, params.id)
        if (link === "invalid") return error(401)
        if (link === "expired") return error(410)
      },
    },
  )
