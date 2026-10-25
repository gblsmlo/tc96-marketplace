import { describe, expect, test } from "bun:test";
import { total } from "../src/cart";

describe("cart", () => {
  test.only("sums items", () => {
    expect(total([{ price: 2, qty: 3 }])).toBe(6);
  });

  test("empty cart is zero", () => {
    expect(total([])).toBe(0);
  });
});
