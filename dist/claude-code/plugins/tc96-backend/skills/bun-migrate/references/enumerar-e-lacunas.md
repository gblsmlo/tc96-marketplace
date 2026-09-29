# Enumerate before migrating, and the four gaps

`BUN-SYS-07` is the step that cannot be skipped: enumerate the `node:*` modules used **by the code and by transitive dependencies**.

```bash
# in your own code
grep -rnoE "from ['\"]node:[a-z_/]+" src/ | sort -u
grep -rnoE "require\(['\"]node:[a-z_/]+" src/ | sort -u

# and in the dependencies — this is the half that usually gets missed
grep -rhoE "require\(['\"](node:)?(async_hooks|worker_threads|crypto|vm|cluster|dgram|inspector|perf_hooks|v8|repl)['\"]" node_modules/ 2>/dev/null | sort | uniq -c | sort -rn | head -20
```

**The second search is the one that changes the plan.** A dependency using `async_hooks` for tracing, or `crypto` for a specific cipher, decides the feasibility of the migration — and it does not appear in the project's own code.

---

## Step 2 — The four gaps that matter

### 2.1 Crypto

`BUN-SYS-08`: code that depends on **`secp256k1`**, **`argon2`**, **`ed448`/`x448`** or the **CCM/OCB/XTS/`chacha20-poly1305`** ciphers does not assume support — check first.

This rules out entire migrations: a blockchain signing library (`secp256k1`) or a token library with a 448-bit Edwards curve stops on day 1. And `argon2` usually arrives through a password-hashing dependency — in that case the way out is `Bun.password`, which does argon2id natively (`BUN-RT-10`).

### 2.2 Async hooks are stubs

`BUN-SYS-09`: **observability never rests on `createHook`, `executionAsyncId` or `eventLoopUtilization`** in Bun — they are stubs that **return a value** instead of throwing.

This is the worst kind of incompatibility: the APM installs, runs, does not error, and produces an empty trace or a constant metric. The absence of an exception is what lets the failure pass through the migration and show up weeks later, as "we lost observability".

### 2.3 `AsyncLocalStorage` does not cross `Worker`

`BUN-SYS-06`: tracing context (trace id, request id) **has to go explicitly in the message** to the `Worker`. `AsyncLocalStorage` does not cross the boundary.

Symptom: the trace disappears when work is delegated to a worker, and the two halves of the request show up disconnected.

### 2.4 IPC across runtimes

`BUN-SYS-10`: IPC between a Bun process and a Node process **uses JSON**. `serialization: "advanced"` only works **between two Bun processes**.

Symptom: a message arrives malformed or empty in a hybrid pipeline, with no clear error.

---

## Step 3 — What does not go to production

`BUN-SYS-05`: **`bun:ffi` and `cc` never enter a production path** — the docs themselves declare them experimental and recommend Node-API. If the migration depends on FFI, the way is Node-API, not `bun:ffi`.
