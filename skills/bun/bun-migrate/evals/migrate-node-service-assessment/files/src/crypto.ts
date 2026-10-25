import { createCipheriv, randomBytes } from "node:crypto";

const KEY = Buffer.from(process.env.SEAL_KEY ?? "0".repeat(64), "hex");

export function sealPayload(plain: string): Buffer {
  const nonce = randomBytes(12);
  const cipher = createCipheriv("chacha20-poly1305", KEY, nonce, { authTagLength: 16 });
  const enc = Buffer.concat([cipher.update(plain, "utf8"), cipher.final()]);
  return Buffer.concat([nonce, cipher.getAuthTag(), enc]);
}
