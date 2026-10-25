import { expect, test } from "bun:test";
import { priceWithTax } from "../src/price";

test("tax on zero is zero", () => {
  expect(priceWithTax(0)).toBe(0);
});
