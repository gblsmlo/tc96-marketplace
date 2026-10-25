import { expect, test } from "bun:test";
import { formatMoney } from "../../src/formatter";

test("formats in the default locale", () => {
  expect(formatMoney(1234.5)).toBe("$1,234.50");
});
