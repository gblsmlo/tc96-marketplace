import { describe, expect, spyOn, test } from "bun:test";
import { config, formatPrice, priceWithTax } from "../src/price";

describe("price", () => {
  test("applies tax", () => {
    config.taxRate = 0.2;
    expect(priceWithTax(100)).toBe(120);
  });

  test("formats with currency", () => {
    const spy = spyOn(Number.prototype, "toFixed");
    expect(formatPrice(10)).toBe("USD 10.00");
    expect(spy).toHaveBeenCalled();
  });
});
