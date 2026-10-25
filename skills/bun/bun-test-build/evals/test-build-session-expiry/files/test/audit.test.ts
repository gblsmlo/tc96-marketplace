import { describe, expect, spyOn, test } from "bun:test";
import { record } from "../src/audit";

describe("audit.record", () => {
  test("writes one JSON line with the event name", () => {
    const log = spyOn(console, "log");
    record("x", { a: 1 });
    expect(log).toHaveBeenCalledTimes(1);
    expect(JSON.parse(log.mock.calls[0][0] as string)).toEqual({ event: "x", a: 1 });
  });
});
