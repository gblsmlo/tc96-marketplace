import { describe, expect, test } from "bun:test";
import { charge, PaymentDeclined } from "../src/charge";

describe("charge", () => {
  test("declines a payment over the card limit", async () => {
    try {
      await charge(500, { limit: 100 });
    } catch (err) {
      expect(err).toBeInstanceOf(PaymentDeclined);
    }
  });

  test("accepts a payment under the limit", async () => {
    expect(await charge(50, { limit: 100 })).toEqual({ ok: true });
  });
});
