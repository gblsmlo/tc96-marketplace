# Container

Two requirements that decide whether the deploy is safe, and that are usually missing.

### 4.1 Shutdown

`BUN-SYS-11`: a containerized service **registers a `SIGTERM` (and `SIGINT`) listener** that drains the server.

```ts
const server = Bun.serve({ /* … */ });

for (const signal of ['SIGTERM', 'SIGINT'] as const) {
 process.on(signal, async => {
 await server.stop; // drains: stops accepting, finishes what is in flight
 process.exit(0);
 });
}
```

Without it, the orchestrator sends `SIGTERM`, the process dies immediately, and **in-flight requests are cut** — the symptom is a client error on every deploy, and it gets blamed on the network.

### 4.2 Dockerfile

`BUN-SYS-12`: the production image **installs with `bun install --frozen-lockfile --production`**, runs as **`USER bun`**, and does not use the `latest` tag.

```dockerfile
FROM oven/bun:1.4.0 # pinned tag, never latest
WORKDIR /app
COPY package.json bun.lock./
RUN bun install --frozen-lockfile --production
COPY..
USER bun # not root
CMD ["bun", "run", "start"] # explicit form — BUN-CORE-06
```

And remember `BUN-RT-12`: in production, `node_modules` present or `--no-install`. Without that, auto-install resolves dependencies **at boot**, and the image starts depending on the network to come up.
