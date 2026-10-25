import http from "node:http";
import { AsyncLocalStorage } from "node:async_hooks";
import apm from "fake-apm";
import { sealPayload } from "./crypto";

apm.start();
export const requestContext = new AsyncLocalStorage<{ requestId: string }>();

const server = http.createServer((req, res) => {
  requestContext.run({ requestId: crypto.randomUUID() }, () => {
    const span = apm.currentSpan();
    const body = sealPayload(JSON.stringify({ path: req.url, span }));
    res.writeHead(200, { "content-type": "application/octet-stream" });
    res.end(body);
  });
});

server.listen(Number(process.env.PORT ?? 3000));
