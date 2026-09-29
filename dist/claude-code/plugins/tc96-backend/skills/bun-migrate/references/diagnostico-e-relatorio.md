# Diagnosis, finding format and the cut

| Symptom | Likely cause | Rule |
| --- | --- | --- |
| `Bun is not defined` | running under `node`, or a `node` shebang without `--bun` | `BUN-CORE-01` |
| type error only at runtime | there is no `tsc --noEmit` in CI | `BUN-CORE-02` |
| `require` fails on a project module | top-level `await` in the module | `BUN-CORE-04` |
| runtime flag ignored | it came after the subcommand | `BUN-CORE-07` |
| empty trace, constant metric | `async_hooks` is a stub | `BUN-SYS-09` |
| trace disappears on entering a worker | `AsyncLocalStorage` does not cross | `BUN-SYS-06` |
| malformed message between processes | "advanced" IPC between Bun and Node | `BUN-SYS-10` |
| unsupported cipher or curve | crypto gap | `BUN-SYS-08` |
| client error on every deploy | no `SIGTERM` drain | `BUN-SYS-11` |
| container does not start without network | auto-install at boot | `BUN-RT-12` |
| external command with injection | concatenated `child_process.exec` | `BUN-SYS-01` |

**The first two rows resolve most "it does not run"**, and neither of them is about module compatibility.

---

## Step 6 — Output format of a finding

```
`RULE-ID` — <where>
Symptom: <how it presents>
Evidence: <the output of the enumeration command, or the log>
Cause: <one sentence>
Fix: <concrete change, or "blocks the migration">
See the corresponding satellite.
```

### Example

```
`BUN-SYS-09` — node_modules/@elastic/apm-node (transitive dependency)
Symptom: after migrating, the APM installs and runs, with no error, and no trace appears
 in the dashboard.
Evidence: Step 1, second search — 14 occurrences of require('async_hooks') inside
 @elastic/apm-node; none in our code.
Cause: createHook and executionAsyncId are stubs in Bun — they return a value instead of
 throwing, so the instrumentation registers and is never called.
Fix: this is not a configuration fix. Either the service stays on Node, or observability
 becomes explicit instrumentation (OpenTelemetry with manual context propagation, and the
 trace id in the message to the worker — BUN-SYS-06).
See Bun - Shell, FFI e Compat Node.
```

Rules of the format: **ID checked against § 6**; **evidence is the output of the enumeration**, not an impression; and when the gap **blocks**, say so instead of proposing a workaround.

---

## Step 7 — The cut: what is not an incompatibility

Four cases that present as "Bun does not support it" and are not:

| Symptom | It is not compatibility — it is |
| --- | --- |
| type error at runtime | missing `tsc --noEmit` (`BUN-CORE-02`) |
| `Bun is not defined` | wrong process (`BUN-CORE-01`) |
| a dependency did not install its binary | `trustedDependencies` replacing the default list — `bun-workspace` (`BUN-PKG-04`) |
| result changes between runs | `--hot` where `--watch` was needed (`BUN-RT-11`) |

**And the inverse, more dangerous:** concluding it "works" because nothing errored. The `async_hooks` stubs (§ 2.2) are exactly that — and it is why `BUN-CORE-05` forbids assuming.
