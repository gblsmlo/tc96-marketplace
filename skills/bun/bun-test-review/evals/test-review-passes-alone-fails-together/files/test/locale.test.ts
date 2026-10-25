import { beforeAll, expect, test } from "bun:test";
import { getLocale, setLocale } from "../src/registry";

beforeAll(() => {
  setLocale("pt-BR", "BRL");
});

test("setLocale updates the registry", () => {
  expect(getLocale()).toEqual({ locale: "pt-BR", currency: "BRL" });
});
