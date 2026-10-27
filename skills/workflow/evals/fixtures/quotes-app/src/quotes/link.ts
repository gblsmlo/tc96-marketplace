import { createHmac, timingSafeEqual } from "node:crypto"

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000

/** The signing key; a missing key is a startup error, never an empty secret. */
export function linkKey(): string {
  const key = process.env.LINK_KEY
  if (!key) throw new Error("LINK_KEY is not set")
  return key
}

/** Verifies a signed quote link (ADR-0001): "valid", "expired" (AC-05) or "invalid". */
export function verifyLink(token: string | undefined, quoteId: string, now = Date.now()) {
  if (!token) return "invalid"
  const [issuedAt, signature] = token.split(".")
  const expected = createHmac("sha256", linkKey()).update(`${quoteId}.${issuedAt}`).digest("hex")
  if (!signature || signature.length !== expected.length) return "invalid"
  if (!timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) return "invalid"
  return now - Number(issuedAt) > THIRTY_DAYS_MS ? "expired" : "valid"
}
