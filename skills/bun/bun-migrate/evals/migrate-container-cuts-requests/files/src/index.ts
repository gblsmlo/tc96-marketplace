const server = Bun.serve({
  port: 3000,
  routes: {
    "/health": () => Response.json({ ok: true }),
    "/checkout": async (req) => {
      const order = await req.json();
      await Bun.sleep(1500); // payment provider round-trip
      return Response.json({ ok: true, order });
    },
  },
  fetch() {
    return new Response("not found", { status: 404 });
  },
});

console.log(`checkout-api on ${server.port}`);
