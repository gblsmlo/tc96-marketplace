import { exportRoute } from "./routes/export";

Bun.serve({
  port: Number(process.env.PORT ?? 3000),
  routes: {
    "/health": () => Response.json({ ok: true }),
    "/export": exportRoute,
  },
  fetch() {
    return new Response("not found", { status: 404 });
  },
});
