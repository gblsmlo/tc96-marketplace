# File, environment, process and shell

The tree is in § 5 of the hub. The summary, and the four errors it prevents:

```
Is it file CONTENT (read, write, stream)?
├── YES → Bun.file / Bun.write
└── NO — it is a DIRECTORY operation (mkdir, readdir, rm, stat)
     → node:fs (BUN-RT-01)
```

| Error | Why | Rule |
| --- | --- | --- |
| treating `Bun.file(path)` as a read | the reference is **lazy**; nothing is read until `.text`/`.json`/`.bytes` | `BUN-RT-02` |
| checking existence via `size === 0` | that is also the size of a file that does not exist — use `await file.exists` | `BUN-RT-03` |
| forgetting `.end` on a `FileSink` | the process **never exits** | `BUN-RT-04` |
| using `Bun.file` for `readdir`/`mkdir` | it only handles content | `BUN-RT-01` |

`BUN-RT-03` is the most insidious: the code appears to work, and the "missing file" branch is never exercised.

---

## Step 3 — Environment

| Rule | What it requires |
| --- | --- |
| `BUN-RT-05` | a production secret **never** comes from a `.env` loaded by the runtime |
| `BUN-RT-06` | an environment variable is **validated at startup**; the type from interface merging is no guarantee |
| `BUN-RT-07` | a literal `$` in a `.env` value **needs** `\` — Bun expands variables by default |

**`BUN-RT-06` is the one the stack already solves:** validate with Zod at startup — `Zod - Validação de Ambiente`. Interface merging gives autocomplete and does **not** guarantee the variable exists; the type says `string` and the value is `undefined`.

**`BUN-RT-07` produces a bug nobody looks for in the right place:** a password with `$` in `.env` arrives truncated, and the symptom is an authentication failure.

---

## Step 4 — Process and shell

```
Do I need to run something external?
├── command with a runtime value → Bun.$ with INTERPOLATION (BUN-SYS-01)
├── long-running process         → Bun.spawn
└── and NEVER in an HTTP handler → Bun.spawnSync / node:fs *Sync (BUN-RT-08)
```

| Rule | What it requires |
| --- | --- |
| `BUN-RT-08` | a server handler **never** calls `Bun.spawnSync` nor `node:fs` `*Sync` — it blocks the event loop of the whole process |
| `BUN-RT-09` | a subprocess of unguaranteed duration gets a `timeout` or `signal` |
| `BUN-SYS-01` | a command with a runtime value uses `Bun.$` interpolation; `child_process.exec` with a concatenated string **never** |

**`Bun.$` interpolation escapes for you** — that is what makes `BUN-SYS-01` a security rule, not a style one. But the guarantees **stop** inside an `sh -c`/`bash -c` (`BUN-SYS-02`), and a runtime argument starting with `-` needs `--` or rejection (`BUN-SYS-03`).

**`BUN-RT-08` is the one that shows up most in generated code:** a `readFileSync` in a handler looks harmless and stops the whole server under load.
