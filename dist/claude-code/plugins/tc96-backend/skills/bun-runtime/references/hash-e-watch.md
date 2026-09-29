# Hashing, passwords, and `--watch` × `--hot`

```
Is it a password, token or secret?
├── YES → Bun.password (argon2id by default)
└── NO  → Bun.hash (non-cryptographic — cache key, dedup)
```

`BUN-RT-10` is categorical: `Bun.hash` **never** touches a password, token or secret. The names look alike and the guarantees are opposite.

---

## Step 6 — `--watch` × `--hot`

| Flag | What it does | When |
| --- | --- | --- |
| `--watch` | restarts the process | when state has to be clean |
| `--hot` | reloads **keeping** process state | server development |

`BUN-RT-11`: `--hot` **never** where the result depends on clean state — test, job, startup check. The symptom is a result that changes between runs without the code changing.

And in production, `BUN-RT-12`: `node_modules` present, or `--no-install`. Without that, **auto-install** resolves dependencies at runtime, which makes the image depend on the network at boot.
