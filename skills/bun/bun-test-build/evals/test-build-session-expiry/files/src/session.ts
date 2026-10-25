import { record } from "./audit";

const TTL_MS = 30 * 60_000;
const lastAccess = new Map<string, number>();
const expired = new Set<string>();

export function recordAccess(id: string): void {
  lastAccess.set(id, Date.now());
  expired.delete(id);
}

export function sessionExpired(id: string): boolean {
  const last = lastAccess.get(id);
  if (last === undefined) return true;
  const isExpired = Date.now() - last >= TTL_MS;
  if (isExpired && !expired.has(id)) {
    expired.add(id);
    record("session.expired", { id });
  }
  return isExpired;
}
