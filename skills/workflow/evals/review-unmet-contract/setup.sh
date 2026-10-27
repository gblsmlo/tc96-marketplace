#!/usr/bin/env bash
# The delivery's feature branch with L1a and L2a merged, then L3b's branch cut from it: the
# approval routes behind the signed link and their tests. C10 (AC-03, reject) has no test.
set -eu
D=2026-10-26-quotes
git() { command git -c user.name=eval -c user.email=eval@example.com "$@"; }

git checkout -q -b "feat/$D"
mkdir -p src/contracts
cat > src/contracts/quote.ts <<'TS'
import { t } from "elysia"

export const QuoteStatus = t.Union([t.Literal("pending"), t.Literal("approved"), t.Literal("rejected")])
export const DecisionBody = t.Object({ decision: t.Union([t.Literal("approve"), t.Literal("reject")]) })
export const DiscountPct = t.Integer({ minimum: 0, maximum: 50 })

export type QuoteRow = {
  id: string
  sellerId: string
  customerEmail: string
  listPrice: number
  discountPct: number
  status: "pending" | "approved" | "rejected"
  sentAt: Date
  decidedAt: Date | null
}
TS
cat > src/db/quotes.ts <<'TS'
import { and, eq } from "drizzle-orm"
import type { db } from "./client"
import { quotes } from "./schema"
import type { QuoteRow } from "../contracts/quote"

export type Database = typeof db

export async function listQuotesBySeller(db: Database, input: { sellerId: string }): Promise<QuoteRow[]> {
  return db.select().from(quotes).where(eq(quotes.sellerId, input.sellerId))
}

export async function findQuote(db: Database, input: { id: string }): Promise<QuoteRow | null> {
  const [row] = await db.select().from(quotes).where(eq(quotes.id, input.id))
  return row ?? null
}

/** Decides a quote once (AC-04): the update applies only while the quote is pending. */
export async function decideQuote(
  db: Database,
  input: { id: string; decision: "approve" | "reject"; now: Date },
): Promise<{ ok: true; quote: QuoteRow } | { ok: false; reason: "not-found" | "already-decided" }> {
  const status = input.decision === "approve" ? "approved" : "rejected"
  const [quote] = await db.update(quotes).set({ status, decidedAt: input.now })
    .where(and(eq(quotes.id, input.id), eq(quotes.status, "pending"))).returning()
  if (quote) return { ok: true, quote }
  return (await findQuote(db, { id: input.id })) ? { ok: false, reason: "already-decided" } : { ok: false, reason: "not-found" }
}
TS
git add -A
git commit -q -m "Merge L1a and L2a into feat/$D"

git checkout -q -b "feat/$D-L3b"
cat >> src/quotes/link.ts <<'TS'

/** The token verifyLink accepts: "<issuedAt>.<hmac>" over the quote ID and its issue date (ADR-0001). */
export function signLink(quoteId: string, issuedAt: number): string {
  const signature = createHmac("sha256", linkKey()).update(`${quoteId}.${issuedAt}`).digest("hex")
  return `${issuedAt}.${signature}`
}
TS
cat > src/server/quotes.route.ts <<'TS'
import { Elysia, t } from "elysia"
import { eq } from "drizzle-orm"
import { authMiddleware, requireRole } from "./auth"
import { verifyLink } from "../quotes/link"
import { db } from "../db/client"
import { quotes } from "../db/schema"
import { decideQuote, findQuote } from "../db/quotes"
import { DecisionBody } from "../contracts/quote"

// The customer has no session: the signed link is the credential (AC-01, ADR-0001).
function linkGuard({ params, query, error }: {
  params: { id: string }
  query: { token: string }
  error: (code: number) => unknown
}) {
  const link = verifyLink(query.token, params.id)
  if (link === "invalid") return error(401)
  if (link === "expired") return error(410)
}

export const quotesRoute = new Elysia({ prefix: "/quotes" })
  .use(authMiddleware)
  .get("/", async ({ user }) => db.select().from(quotes).where(eq(quotes.sellerId, user!.id)), {
    beforeHandle: requireRole("seller"),
  })
  .get(
    "/:id",
    async ({ params, error }) => (await findQuote(db, { id: params.id })) ?? error(404),
    { query: t.Object({ token: t.String() }), beforeHandle: linkGuard },
  )
  .post(
    "/:id/decision",
    async ({ params, body, error }) => {
      const result = await decideQuote(db, { id: params.id, decision: body.decision, now: new Date() })
      if (result.ok) return result.quote
      return error(result.reason === "not-found" ? 404 : 409)
    },
    { query: t.Object({ token: t.String() }), body: DecisionBody, beforeHandle: linkGuard },
  )
TS
cat > src/server/approval.test.ts <<'TS'
import { afterEach, beforeEach, expect, mock, setSystemTime, test } from "bun:test"
import type { QuoteRow } from "../contracts/quote"

process.env.LINK_KEY = "test-link-key"

// The repository is L2a's; here it is an in-memory double, so the routes are tested through
// app.handle with no database.
const store = new Map<string, QuoteRow>()
mock.module("../db/quotes", () => ({
  findQuote: async (_db: unknown, { id }: { id: string }) => store.get(id) ?? null,
  decideQuote: async (_db: unknown, { id, decision, now }: { id: string; decision: "approve" | "reject"; now: Date }) => {
    const quote = store.get(id)
    if (!quote) return { ok: false, reason: "not-found" }
    if (quote.status !== "pending") return { ok: false, reason: "already-decided" }
    const next: QuoteRow = { ...quote, status: decision === "approve" ? "approved" : "rejected", decidedAt: now }
    store.set(id, next)
    return { ok: true, quote: next }
  },
}))
const { quotesRoute } = await import("./quotes.route")
const { signLink } = await import("../quotes/link")

const DAY = 24 * 60 * 60 * 1000
const NOW = Date.parse("2026-10-26T12:00:00Z")
const quote = (id: string, status: QuoteRow["status"] = "pending"): QuoteRow => ({
  id, sellerId: "s1", customerEmail: "c@x.com", listPrice: 1000, discountPct: 0, status,
  sentAt: new Date(NOW - DAY), decidedAt: null,
})
const open = (id: string, token: string) =>
  quotesRoute.handle(new Request(`http://localhost/quotes/${id}?token=${token}`))
const decide = (id: string, token: string, decision: string) =>
  quotesRoute.handle(new Request(`http://localhost/quotes/${id}/decision?token=${token}`, {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ decision }),
  }))

beforeEach(() => { store.clear(); setSystemTime(new Date(NOW)) })
afterEach(() => { setSystemTime() })

test("C08 (AC-01): a valid link with no session cookie opens the quote", async () => {
  store.set("q1", quote("q1"))
  const res = await open("q1", signLink("q1", NOW))
  expect(res.status).toBe(200)
  expect((await res.json()).id).toBe("q1")
})

test("C09 (AC-02): approving a pending quote approves it", async () => {
  store.set("q1", quote("q1"))
  const res = await decide("q1", signLink("q1", NOW), "approve")
  expect(res.status).toBe(200)
  expect((await res.json()).status).toBe("approved")
})

test("C11 (AC-04): deciding an approved quote again returns 409 and keeps the status", async () => {
  store.set("q1", quote("q1", "approved"))
  const res = await decide("q1", signLink("q1", NOW), "reject")
  expect(res.status).toBe(409)
  expect(store.get("q1")?.status).toBe("approved")
})

test("C12 (AC-05): a link is valid until 30 days and expired 1 ms after", async () => {
  store.set("q1", quote("q1"))
  expect((await open("q1", signLink("q1", NOW - 30 * DAY + 1))).status).toBe(200)
  expect((await open("q1", signLink("q1", NOW - 30 * DAY - 1))).status).toBe(410)
})

test("I1 (ADR-0001): a changed signature or another quote's token is refused with 401", async () => {
  store.set("q1", quote("q1"))
  const token = signLink("q1", NOW)
  const tampered = `${token.slice(0, -1)}${token.endsWith("0") ? "1" : "0"}`
  expect((await open("q1", tampered)).status).toBe(401)
  expect((await open("q1", signLink("q2", NOW))).status).toBe(401)
})
TS
git add -A
git commit -q -m "feat(quotes): open and decide a quote with its signed link [$D L3b]"
mkdir -p ".sdd/run/$D"
git diff "feat/$D...HEAD" > ".sdd/run/$D/L3b.diff"
