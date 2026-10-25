# Container

Three requirements that decide whether the deploy is safe, and that are usually missing. The first
two are about the signal: the orchestrator sends `SIGTERM`, and two separate things have to be true
for the server to drain instead of dying mid-request.

### 4.1 The signal has to reach Bun — exec form, never shell form

```dockerfile
CMD bun src/index.ts                                    # ✗ shell form: PID 1 is /bin/sh -c
CMD ["bun", "run", "src/index.ts"]                      # ✓ exec form: PID 1 is bun
ENTRYPOINT ["bun", "run", "--no-env-file", "src/index.ts"]  # ✓ and the .env guard of BUN-SYS-12
```

With the **shell form**, Docker runs the command as `/bin/sh -c "…"`, and the shell is PID 1. Docker's
own reference warns that, in this form, the executable does not receive Unix signals: `docker stop`
and the orchestrator's `SIGTERM` go to the shell. Whether the shell forwards them depends on the
shell, so treat it as "the signal does not arrive". The process is then killed by `SIGKILL` at the end
of the grace period, and every in-flight request is cut.

**This is the half that hides behind 4.2.** You can add a perfect `SIGTERM` listener and still see
cut requests on every deploy, because the listener never runs. Check the `CMD`/`ENTRYPOINT` form
**before** debugging the handler. `scripts/enumerate.sh` § 5 flags a shell-form line.

The exec form also matters for `bun run <script>`: `BUN-CORE-06` asks for the explicit form in
automation, and the JSON array is where that explicit form lives in a Dockerfile.

### 4.2 Bun has to drain — the `SIGTERM` listener

`BUN-SYS-11`: a containerized service **registers a `SIGTERM` (and `SIGINT`) listener** that drains the server, and finishes with `process.exit()`.

```ts
const server = Bun.serve({ /* … */ });

for (const signal of ["SIGTERM", "SIGINT"] as const) {
  process.on(signal, async () => {
    await server.stop(); // drains: stops accepting, finishes what is in flight
    process.exit(0);     // the listener suppressed the default exit; this restores it
  });
}
```

Without the listener, the process dies immediately and **in-flight requests are cut**. With the
listener and without `process.exit()`, the process stays up until the orchestrator's `SIGKILL`, 30 s
later. The symptom of both is a client error on every deploy, and it gets blamed on the network.

**Prove it locally**, without Docker: start the server, send a slow request, `kill -TERM` the process
while it is in flight, and check that the request completes and the process exits `0`.

```bash
bun run src/index.ts & PID=$!; sleep 0.5
curl -s -o /dev/null -w '%{http_code}\n' localhost:3000/slow & sleep 0.2
kill -TERM $PID; wait $PID; echo "bun exit=$?"   # expect the curl to print 200, and exit=0
```

### 4.3 The image

`BUN-SYS-12`: the production image **installs with `bun install --frozen-lockfile --production`**, runs as **`USER bun`**, does not use the `latest` tag, and passes `--no-env-file` so a stray `.env` cannot override what the orchestrator injects.

```dockerfile
FROM oven/bun:1.4.3                                   # pinned to the patch, never latest
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile --production
COPY . .
USER bun                                              # not root
ENTRYPOINT ["bun", "run", "--no-env-file", "src/index.ts"]   # exec form — 4.1
```

`oven/bun:1` is a floating tag too: it moves with every 1.x release. Pin the version you tested.

And remember `BUN-RT-12`: in production, `node_modules` present or `--no-install`. Without that, auto-install resolves dependencies **at boot**, and the image starts depending on the network to come up.

**`--smol` is not a container mode.** It raises garbage-collection frequency to trade CPU for memory.
Use it only when a measured memory limit says so.
