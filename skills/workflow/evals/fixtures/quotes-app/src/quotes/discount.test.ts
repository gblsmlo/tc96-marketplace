import { expect, test } from "bun:test"
import { applyDiscount } from "./discount"

test("10% off 1000 is 900", () => {
  expect(applyDiscount(1000, 10)).toBe(900)
})
