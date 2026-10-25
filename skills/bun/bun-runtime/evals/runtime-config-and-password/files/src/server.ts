// In-memory session registry: lives for the whole life of the process.
const sessions = new Map<string, { user: string; lastAccess: number }>();

const server = Bun.serve({
  port: Number(process.env.PORT ?? 3000),
  routes: {
    "/health": () => Response.json({ ok: true, sessions: sessions.size }),
    "/login": async (req) => {
      const { user } = (await req.json()) as { user: string };
      const id = crypto.randomUUID();
      sessions.set(id, { user, lastAccess: Date.now() });
      return Response.json({ id });
    },
  },
  fetch() {
    return new Response("not found", { status: 404 });
  },
});

console.log(`listening on ${server.port}`);
